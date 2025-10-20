use crate::netfetch::save_file_from_url;
use mlua::prelude::*;
use regex::Regex;
use std::sync::OnceLock;
use std::{
    collections::HashMap,
    env, fs,
    path::{Component, Path, PathBuf},
    sync::Mutex,
};
use url::Url;
use walkdir::WalkDir;

#[inline]
fn is_font_path(p: &Path) -> bool {
    // Detect common font file extensions. Extend if you want to support WOFF/WOFF2, etc.
    match p
        .extension()
        .and_then(|e| e.to_str())
        .map(|s| s.to_ascii_lowercase())
    {
        Some(ext) => matches!(ext.as_str(), "ttf" | "otf" | "ttc"),
        None => false,
    }
}

// ---- Helpers ----------------------------------------------------------------

fn canonical_to_string(p: &Path) -> Option<String> {
    // Return canonical absolute path if possible; otherwise fall back to a lossless string of `p`.
    match fs::canonicalize(p) {
        Ok(abs) => Some(abs.to_string_lossy().into_owned()),
        Err(_) => Some(p.to_string_lossy().into_owned()),
    }
}

fn is_ignore_case() -> bool {
    // Case-insensitive lookup is toggled by env var SP_IGNORECASE=1.
    matches!(env::var("SP_IGNORECASE"), Ok(ref v) if v == "1")
}

fn norm_sep_lower(s: &str) -> String {
    // Normalize separators (backslash -> slash) and lowercase for stable indexing/lookup.
    s.replace('\\', "/").to_lowercase()
}

fn strip_drive(p: &Path) -> PathBuf {
    // Convert paths with Windows drive prefixes like "C:\foo\bar" -> "foo/bar" for relative indexing.
    // On non-Windows, this returns the path unchanged.
    let mut comps = p.components();
    let first_is_prefix = matches!(comps.next(), Some(Component::Prefix(_)));
    if first_is_prefix {
        comps.as_path().to_path_buf()
    } else {
        p.to_path_buf()
    }
}

// ---- File list state --------------------------------------------------------

struct RegexReplacer {
    re: Regex,
    replacement: String,
}

/// In-memory file index used to resolve input strings to real files.
/// We maintain two indexes:
/// - by_basename (case-insensitive): "foo.ttf" -> "/abs/path/dir/foo.ttf"
/// - by_relpath_lower (normalized, lowercased): "dir/sub/foo.ttf" -> "/abs/path/dir/sub/foo.ttf"
/// For transparency and diagnostics we also record duplicates for both indices.
struct Filelist {
    dirs: Vec<PathBuf>,
    by_basename: HashMap<String, PathBuf>, // lower(basename) -> full path
    by_relpath_lower: HashMap<String, PathBuf>, // lower(relpath)  -> full path
    dupes_basename: HashMap<String, Vec<PathBuf>>, // same basename seen multiple times
    dupes_relpath_lower: HashMap<String, Vec<PathBuf>>, // same normalized relative path seen multiple times
    path_rewrite: Option<RegexReplacer>,                // optional runtime regex-based rewrite
}

impl Filelist {
    fn new() -> Self {
        Self {
            dirs: Vec::new(),
            by_basename: HashMap::new(),
            by_relpath_lower: HashMap::new(),
            dupes_basename: HashMap::new(),
            dupes_relpath_lower: HashMap::new(),
            path_rewrite: None,
        }
    }

    fn clear_and_set(&mut self, dirs: Vec<PathBuf>) {
        // Replace the directory set (deduplicated) and rebuild the indices from scratch.
        self.dirs.clear();
        for d in dirs {
            if d.is_dir() && !self.dirs.iter().any(|x| x == &d) {
                self.dirs.push(d);
            }
        }
        self.rebuild_index();

        crate::logging::log_with(
            "info",
            "Filelist rebuilt",
            &[
                ("dirs", &self.dirs.len().to_string()),
                ("files_indexed", &self.by_basename.len().to_string()),
            ],
        );
    }

    fn add_dir(&mut self, dir: &Path) {
        // Incrementally add a new directory to the index.
        if dir.is_dir() {
            if !self.dirs.iter().any(|d| d == dir) {
                self.dirs.push(dir.to_path_buf());
                self.index_dir(dir);
                crate::logging::log_with(
                    "debug",
                    "Added dir",
                    &[("dir", &dir.to_string_lossy().to_string())],
                );
            } else {
                crate::logging::log_with(
                    "debug",
                    "Dir already present (ignored)",
                    &[("dir", &dir.to_string_lossy().to_string())],
                );
            }
        } else {
            crate::logging::log_with(
                "warn",
                "sdAddDir: not a directory or not accessible",
                &[("dir", &dir.to_string_lossy().to_string())],
            );
        }
    }

    fn set_path_rewrite(&mut self, pat: Option<(String, String)>) -> LuaResult<()> {
        // Configure or clear the runtime regex-based path rewrite.
        // Invalid regex patterns are surfaced as Lua errors for clear feedback.
        match pat {
            Some((pattern, replacement)) if !pattern.is_empty() => {
                let re = Regex::new(&pattern).map_err(LuaError::external)?;
                self.path_rewrite = Some(RegexReplacer { re, replacement });
                crate::logging::log_simple("info", "Set path rewrite regex");
            }
            _ => {
                self.path_rewrite = None;
                crate::logging::log_simple("info", "Cleared path rewrite regex");
            }
        }
        Ok(())
    }

    fn warn_dupes(&self, where_: &str, key: &str, primary: &Path, dupes: &[PathBuf]) {
        // Emit a warning for each duplicate so the user sees all collisions.
        // `primary` indicates which file path wins during lookup.
        for dupe in dupes {
            crate::logging::log_with(
                "warn",
                "Found duplicate entry in file lookup",
                &[
                    ("scope", where_),
                    ("key", key),
                    ("file", &dupe.to_string_lossy().to_string()),
                    ("using", &primary.to_string_lossy().to_string()),
                ],
            );
        }
    }

    fn apply_rewrite<'a>(&self, s: &'a str) -> String {
        // Apply the runtime regex rewrite (global replace), if configured.
        if let Some(rr) = &self.path_rewrite {
            rr.re.replace_all(s, rr.replacement.as_str()).to_string()
        } else {
            s.to_string()
        }
    }

    /// Resolve a string into a concrete file path, supporting:
    /// - global config path rewrites (`crate::config::rewrite_path`)
    /// - runtime regex path rewrites (`sdSetPathRewrite`)
    /// - HTTP/HTTPS URLs (download to local cache via `save_file_from_url`)
    /// - file:// URLs
    /// - absolute/relative local paths
    fn get_full_path(&mut self, input: &str) -> Option<String> {
        // 1) Apply global rewrite, then runtime regex rewrite.
        let tmp = crate::config::rewrite_path(input);
        let mut name = self.apply_rewrite(&tmp);
        if is_ignore_case() {
            name = name.to_lowercase();
        }

        // 2) URL handling (http, https, file). Unknown schemes fall back to path lookup.
        if let Ok(u) = Url::parse(&name) {
            match u.scheme() {
                "http" | "https" => {
                    return match save_file_from_url(&name) {
                        Ok(local) if !local.is_empty() => Some(local),
                        Ok(_) => None, // 404 or deliberate empty -> treat as miss
                        Err(e) => {
                            crate::logging::log_with(
                                "error",
                                "save_file_from_url failed",
                                &[("error", &e.to_string())],
                            );
                            None
                        }
                    };
                }
                "file" => {
                    // file://host/path
                    // On Windows: host becomes drive (e.g. "C"), so "C:/path".
                    // On POSIX: host is usually empty; we use u.path() directly.
                    let host = u.host_str().unwrap_or("");
                    let mut path_s = u.path().to_string();
                    if !host.is_empty() {
                        path_s = format!("{host}:{}", path_s);
                    }
                    return self.lookup(&path_s);
                }
                _ => {
                    // Unknown scheme -> try local path semantics below.
                }
            }
        }

        // 3) No URL scheme recognized -> local path lookup.
        self.lookup(&name)
    }

    /// Core lookup logic over absolute paths, relative subpaths, and basenames.
    /// Honors SP_IGNORECASE for case-insensitive matching.
    fn lookup(&self, name_in: &str) -> Option<String> {
        let name = if is_ignore_case() {
            name_in.to_lowercase()
        } else {
            name_in.to_string()
        };
        crate::logging::log_simple("debug", &format!("Lookup file: {}", name));
        let p = Path::new(&name);

        // 1) Absolute path that exists -> return canonical form.
        if p.is_absolute() && p.exists() {
            let s = canonical_to_string(p);
            if let Some(ref path) = s {
                crate::logging::log_simple("debug", &format!("Lookup hit (absolute): {}", path));
            }
            return s;
        }

        // 2) Contains a path separator? Treat as a subpath below any indexed dir.
        if name.contains('/') || name.contains('\\') {
            if is_ignore_case() {
                // Fast path: try normalized relative index first (case-insensitive).
                let key = norm_sep_lower(&name);
                if let Some(full) = self.by_relpath_lower.get(&key) {
                    if let Some(dupes) = self.dupes_relpath_lower.get(&key) {
                        self.warn_dupes("relpath", &key, full, dupes);
                    }
                    let s = canonical_to_string(full);
                    if let Some(ref path) = s {
                        crate::logging::log_simple(
                            "debug",
                            &format!("Lookup hit (relpath idx, ci): {}", path),
                        );
                    }
                    return s;
                }
            }
            // Fallback: walk each base dir and test existence.
            for dir in &self.dirs {
                let cand = dir.join(p);
                if cand.exists() {
                    let s = canonical_to_string(&cand);
                    if let Some(ref path) = s {
                        crate::logging::log_simple(
                            "debug",
                            &format!("Lookup hit (subpath): {}", path),
                        );
                    }
                    return s;
                }
            }
            crate::logging::log_simple("debug", "Lookup miss (subpath)");
            return None;
        }

        // 3) Pure basename -> check case-insensitive basename index.
        let key = name.to_lowercase();
        if let Some(full) = self.by_basename.get(&key) {
            if let Some(dupes) = self.dupes_basename.get(&key) {
                self.warn_dupes("basename", &key, full, dupes);
            }
            let s = canonical_to_string(full);
            if let Some(ref path) = s {
                crate::logging::log_simple("debug", &format!("Lookup hit (basename): {}", path));
            }
            return s;
        }

        // 4) Direct stat() on the input (Go parity).
        if Path::new(&name).exists() {
            let s = canonical_to_string(Path::new(&name));
            if let Some(ref path) = s {
                crate::logging::log_simple("debug", &format!("Lookup hit (direct): {}", path));
            }
            return s;
        }

        // No match.
        crate::logging::log_simple("debug", "Lookup miss");
        None
    }

    // --- Index construction ---------------------------------------------------

    fn rebuild_index(&mut self) {
        // Rebuild both indices and duplicate maps from the current directory set.
        self.by_basename.clear();
        self.by_relpath_lower.clear();
        self.dupes_basename.clear();
        self.dupes_relpath_lower.clear();

        let dirs_snapshot: Vec<PathBuf> = self.dirs.clone();
        for dir in &dirs_snapshot {
            self.index_dir(dir);
        }
    }

    fn index_dir(&mut self, dir: &Path) {
        // Walk the directory and index all files by basename and normalized relative path.
        for entry in WalkDir::new(dir).into_iter().filter_map(Result::ok) {
            if entry.file_type().is_file() {
                let path = entry.path().to_path_buf();

                // Basename index (case-insensitive)
                if let Some(name) = path.file_name().and_then(|s| s.to_str()) {
                    let key = name.to_lowercase();
                    match self.by_basename.get(&key) {
                        None => {
                            self.by_basename.insert(key.clone(), path.clone());
                        }
                        Some(existing) if existing != &path => {
                            // Record and warn about duplicates; the first encountered path "wins".
                            self.dupes_basename
                                .entry(key.clone())
                                .or_default()
                                .push(path.clone());
                            crate::logging::log_with(
                                "warn",
                                "Index: duplicate basename",
                                &[
                                    ("basename", name),
                                    ("keeping", &existing.to_string_lossy().to_string()),
                                    ("also", &path.to_string_lossy().to_string()),
                                ],
                            );
                        }
                        _ => {}
                    }
                }

                // Relative path index (normalize separators and lowercase)
                let rel_norm = if let Ok(rel) = path.strip_prefix(dir) {
                    norm_sep_lower(&rel.to_string_lossy())
                } else {
                    // If strip_prefix fails (e.g., symlink or different root), fall back to a
                    // drive-less normalized path to keep it searchable.
                    norm_sep_lower(&strip_drive(&path).to_string_lossy())
                };

                match self.by_relpath_lower.get(&rel_norm) {
                    None => {
                        self.by_relpath_lower.insert(rel_norm.clone(), path.clone());
                    }
                    Some(existing) if existing != &path => {
                        // Track duplicates for diagnostics but keep the first encountered path.
                        self.dupes_relpath_lower
                            .entry(rel_norm)
                            .or_default()
                            .push(path.clone());
                    }
                    _ => {}
                }
            }
        }
    }
}

/// Global singleton storing the file index.
/// Access is guarded by a Mutex; callers should keep critical sections brief.
static FILELIST: OnceLock<Mutex<Filelist>> = OnceLock::new();

fn with_filelist<R>(f: impl FnOnce(&mut Filelist) -> R) -> R {
    // Helper to access the global Filelist in a scoped, thread-safe way.
    let m = FILELIST.get_or_init(|| Mutex::new(Filelist::new()));
    let mut fl = m.lock().expect("filelist mutex poisoned");
    f(&mut fl)
}

// ---------- Lua exposed functions (public API) ----------

/// Exposed functions:
/// - sdBuildFilelist()
/// - sdAddDir(path)
/// - sdSetPathRewrite(pattern, replacement | nil)
/// - lookup_file(filename)    // including URL/file:// handling and SP_IGNORECASE
pub fn lua_subtable(lua: &Lua) -> LuaResult<LuaTable> {
    let t = lua.create_table()?;

    // list_fonts(): return a 1-based Lua array of all discovered font files (deduplicated + sorted).
    t.set(
        "list_fonts",
        lua.create_function(|lua, ()| {
            use std::collections::BTreeSet;

            // We collect across all sources (both indices and their duplicate lists) into a set for stable ordering.
            let mut fonts: Vec<String> = Vec::new();

            with_filelist(|fl| {
                let mut set = BTreeSet::<String>::new();

                // 1) Unique relative-path index
                for p in fl.by_relpath_lower.values() {
                    if is_font_path(p.as_path()) {
                        set.insert(p.to_string_lossy().into_owned());
                    }
                }

                // 2) Duplicates by relative path
                for vecp in fl.dupes_relpath_lower.values() {
                    for p in vecp {
                        if is_font_path(p.as_path()) {
                            set.insert(p.to_string_lossy().into_owned());
                        }
                    }
                }

                // 3) Basename index (may add additional files not covered above)
                for p in fl.by_basename.values() {
                    if is_font_path(p.as_path()) {
                        set.insert(p.to_string_lossy().into_owned());
                    }
                }

                // 4) Duplicates by basename
                for vecp in fl.dupes_basename.values() {
                    for p in vecp {
                        if is_font_path(p.as_path()) {
                            set.insert(p.to_string_lossy().into_owned());
                        }
                    }
                }

                fonts.extend(set.into_iter());
            });

            // Return as a 1-based Lua array for idiomatic consumption in Lua code.
            let tbl = lua.create_table_with_capacity(fonts.len(), 0)?;
            for (i, f) in fonts.into_iter().enumerate() {
                tbl.raw_set(i + 1, f)?;
            }
            Ok(tbl)
        })?,
    )?;

    // sdBuildFilelist(): build initial directory set from environment and index them.
    t.set(
        "sdBuildFilelist",
        lua.create_function(|_, ()| {
            let mut dirs: Vec<PathBuf> = Vec::new();

            // Helper to parse PATH-like env vars into a vector of paths. Optionally skip empties.
            let mut push_env_list = |key: &str, only_if_nonempty: bool| match env::var_os(key) {
                Some(val) if !(only_if_nonempty && val.is_empty()) => {
                    for p in env::split_paths(&val) {
                        if !p.as_os_str().is_empty() {
                            crate::logging::log_simple(
                                "debug",
                                &format!("Env {} += {}", key, p.to_string_lossy()),
                            );
                            dirs.push(p);
                        }
                    }
                }
                _ => {
                    crate::logging::log_simple("debug", &format!("Env {} not set / empty", key));
                }
            };

            // Base inputs for file lookup. SP_FONT_PATH is often dense; ignore if empty.
            push_env_list("PUBLISHER_BASE_PATH", false);
            push_env_list("SP_FONT_PATH", true);
            push_env_list("SP_EXTRA_DIRS", false);

            with_filelist(|fl| fl.clear_and_set(dirs));
            Ok(())
        })?,
    )?;

    // sdAddDir(path: string): add a directory incrementally.
    t.set(
        "sdAddDir",
        lua.create_function(|_, dir: String| {
            if dir.trim().is_empty() {
                crate::logging::log_simple(
                    "error",
                    "sdAddDir requires one non-empty string argument",
                );
                return Ok(());
            }
            with_filelist(|fl| fl.add_dir(Path::new(&dir)));
            Ok(())
        })?,
    )?;

    // sdSetPathRewrite(pattern: string, replacement: string) or (nil) to clear
    t.set(
        "sdSetPathRewrite",
        lua.create_function(|_, (pat, repl): (Option<String>, Option<String>)| {
            with_filelist(|fl| {
                if let Some(p) = pat {
                    let r = repl.unwrap_or_default();
                    fl.set_path_rewrite(Some((p, r)))
                } else {
                    fl.set_path_rewrite(None)
                }
            })?;
            Ok(())
        })?,
    )?;

    // lookup_file(name: string) -> string|nil  (Go: GetFullPath)
    t.set(
        "lookup_file",
        lua.create_function(|_, name: String| {
            if name.trim().is_empty() {
                crate::logging::log_simple("warn", "lookup_file: empty filename");
                return Ok(None::<String>);
            }
            let res = with_filelist(|fl| fl.get_full_path(&name));
            Ok(res)
        })?,
    )?;

    Ok(t)
}
