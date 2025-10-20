use crate::config::{rewrite_path, verbosity};
use mlua::prelude::*;
use std::env;
use std::fs;
use std::path::Path;
use std::process::Command;
use std::time::{SystemTime, UNIX_EPOCH};

#[derive(thiserror::Error, Debug)]
pub enum ImgConvError {
    #[error("no handler executable specified")]
    NoHandler,
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),
    #[error("process failed with exit status: {0}")]
    Exit(String),
}
type Result<T> = std::result::Result<T, ImgConvError>;

/* =========================
Internal helpers (Go parity)
========================= */

fn convert_image(filename: &str, handler: &str) -> Result<String> {
    // Apply global path rewrite first (env-driven mapping).
    let filename = rewrite_path(filename);
    // Use the input's basename as a default output stem if not otherwise specified.
    let base = Path::new(&filename)
        .file_name()
        .map(|s| s.to_string_lossy().to_string())
        .unwrap_or_else(|| "out".to_string());
    convert_file(&filename, &base, handler)
}

fn convert_file(inputfilename: &str, baseoutputfilename: &str, handler: &str) -> Result<String> {
    // Normalize input through the global rewrite.
    let inputfilename = rewrite_path(inputfilename);

    // Resolve/prepare the cache directory:
    // - IMGCACHE overrides default
    // - default is $TMPDIR/imagecache
    let rawimgcache = match env::var("IMGCACHE") {
        Ok(v) if !v.is_empty() => v,
        _ => {
            let mut p = env::temp_dir();
            p.push("imagecache");
            p.to_string_lossy().to_string()
        }
    };
    fs::create_dir_all(&rawimgcache)?;

    // Compute initial output path under the cache; allow later rewrite to change it.
    let mut outfile = Path::new(&rawimgcache)
        .join(baseoutputfilename)
        .to_string_lossy()
        .to_string();
    outfile = rewrite_path(&outfile);

    // Cheap cache hit: if CACHEMETHOD != "none" and file already exists, return it.
    if env::var("CACHEMETHOD").unwrap_or_default() != "none" && Path::new(&outfile).exists() {
        return Ok(outfile);
    }

    // `handler` is a shell-like command string with placeholders:
    //   %%input%%  → input file
    //   %%output%% → output file (may also *redefine* outfile if it's at the start of an arg)
    let args_raw = split_args(handler)?;
    if args_raw.is_empty() {
        return Err(ImgConvError::NoHandler);
    }

    // Expand placeholders and pick up a possibly overridden outfile.
    let mut args: Vec<String> = Vec::with_capacity(args_raw.len());
    for a in args_raw {
        let repl = a
            .replace("%%input%%", &inputfilename)
            .replace("%%output%%", &outfile);
        // If a tool expects the output path as the *first token of an argument*,
        // accept that as the authoritative outfile (matches existing behavior).
        if repl.starts_with(&outfile) {
            outfile = repl.clone();
        }
        args.push(repl);
    }

    let executable = &args[0];
    let exec_args = &args[1..];

    // Launch the external converter; bubble up IO and non-zero exit as structured errors.
    let status = Command::new(executable).args(exec_args).status()?;
    if !status.success() {
        return Err(ImgConvError::Exit(format!("{status}")));
    }
    Ok(outfile)
}

/// Shell-like argument splitter (supports quotes and basic escapes) — **public within crate for pro.rs**
pub(crate) fn split_args(s: &str) -> Result<Vec<String>> {
    #[derive(PartialEq)]
    enum Mode {
        Normal,
        SingleQ,
        DoubleQ,
    }

    // Minimal, deterministic tokenizer:
    // - In Normal mode, backslash escapes the next char.
    // - In '...' single quotes, characters are taken verbatim until the next '.
    // - In "..." double quotes, backslash escapes a small set (n, t, r, ", \).
    // - Whitespace splits tokens unless inside quotes.
    let mut args: Vec<String> = Vec::new();
    let mut cur = String::new();
    let mut mode = Mode::Normal;
    let mut escaped = false;

    for ch in s.chars() {
        match mode {
            Mode::Normal => {
                if escaped {
                    cur.push(ch);
                    escaped = false;
                } else {
                    match ch {
                        '\\' => escaped = true,
                        '\'' => mode = Mode::SingleQ,
                        '"' => mode = Mode::DoubleQ,
                        c if c.is_whitespace() => {
                            if !cur.is_empty() {
                                args.push(std::mem::take(&mut cur));
                            }
                        }
                        c => cur.push(c),
                    }
                }
            }
            Mode::SingleQ => {
                if ch == '\'' {
                    mode = Mode::Normal;
                } else {
                    cur.push(ch);
                }
            }
            Mode::DoubleQ => {
                if escaped {
                    cur.push(match ch {
                        'n' => '\n',
                        't' => '\t',
                        'r' => '\r',
                        '"' => '"',
                        '\\' => '\\',
                        other => other,
                    });
                    escaped = false;
                } else {
                    match ch {
                        '\\' => escaped = true,
                        '"' => mode = Mode::Normal,
                        c => cur.push(c),
                    }
                }
            }
        }
    }
    // Trailing backslash means a literal backslash at end.
    if escaped {
        cur.push('\\');
    }
    // Push final token if present.
    if !cur.is_empty() {
        args.push(cur);
    }
    Ok(args)
}

fn write_contents_to_tempfile(contents: &str) -> Result<String> {
    // Deterministic, unique temporary filename under $TMPDIR:
    // speedata-<pid>-<nanos>.tmp
    let mut p = env::temp_dir();
    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .unwrap_or_default()
        .as_nanos();
    let pid = std::process::id();
    let fname = format!("speedata-{pid}-{nanos}.tmp");
    p.push(fname);

    fs::write(&p, contents.as_bytes())?;
    Ok(p.to_string_lossy().to_string())
}

fn convert_contents(contents: &str, handler: &str) -> Result<String> {
    // Write content to a temp file, use its MD5 as output stem (stable cache key).
    let inputfilename = write_contents_to_tempfile(contents)?;
    let hashed = format!("{:x}", ::md5::compute(contents.as_bytes()));
    let res = convert_file(&inputfilename, &hashed, handler);

    // Clean up temp input unless verbosity > 0 (leave crumbs for debugging).
    let verbosity = verbosity();
    if verbosity == 0 {
        let _ = fs::remove_file(&inputfilename);
    }

    res
}

fn convert_svg_image(filename: &str) -> Result<String> {
    // Expand and canonicalize the SVG path (best effort).
    let filename = rewrite_path(filename);
    let svgfile = std::fs::canonicalize(&filename)
        .map(|p| p.to_string_lossy().to_string())
        .unwrap_or_else(|_| filename.to_string());

    // Same cache strategy as raster conversion.
    let rawimgcache = match env::var("IMGCACHE") {
        Ok(v) if !v.is_empty() => v,
        _ => {
            let mut p = env::temp_dir();
            p.push("imagecache");
            p.to_string_lossy().to_string()
        }
    };
    fs::create_dir_all(&rawimgcache)?;

    // Cache key is MD5 of the canonical SVG file path (fast and stable).
    let hashed = format!("{:x}", md5::compute(svgfile.as_bytes()));
    let pdffile = Path::new(&rawimgcache)
        .join(format!("{hashed}.pdf"))
        .to_string_lossy()
        .to_string();
    let pdffile = rewrite_path(&pdffile);

    // Respect CACHEMETHOD for early return on cache hit.
    if env::var("CACHEMETHOD").unwrap_or_default() != "none" && Path::new(&pdffile).exists() {
        return Ok(pdffile);
    }

    // External tool selection via environment:
    // - SP_INKSCAPE      : path to executable (required)
    // - SP_INKSCAPECMD   : extra arguments string (optional, shell-like)
    let binary = env::var("SP_INKSCAPE").map_err(|_| ImgConvError::NoHandler)?;
    let mut args = {
        let s = env::var("SP_INKSCAPECMD").unwrap_or_default();
        if s.is_empty() {
            Vec::new()
        } else {
            split_args(&s)?
        }
    };
    // Convention: append output then input (keeps freedom for user-specified argv before them).
    args.push(pdffile.clone());
    args.push(svgfile.clone());

    let status = Command::new(&binary).args(&args).status()?;
    if !status.success() {
        return Err(ImgConvError::Exit(format!("{status}")));
    }
    Ok(pdffile)
}

/* =========================
Lua subtable (shared)
========================= */

pub(crate) fn lua_subtable(lua: &Lua) -> LuaResult<LuaTable> {
    let t = lua.create_table()?;

    // sdConvertImage(filename, handler) -> string | (0 values on error)
    let f = lua.create_function(|lua, (filename, handler): (String, String)| {
        match convert_image(&filename, &handler) {
            Ok(path) => Ok(mlua::MultiValue::from_vec(vec![mlua::Value::String(
                lua.create_string(&path)?,
            )])),
            // Return zero Lua values on failure (Go parity).
            Err(_e) => Ok(mlua::MultiValue::new()),
        }
    })?;

    // sdConvertSVGImage(filename) -> string | 0
    let f_svg =
        lua.create_function(|lua, filename: String| match convert_svg_image(&filename) {
            Ok(path) => Ok(mlua::MultiValue::from_vec(vec![mlua::Value::String(
                lua.create_string(&path)?,
            )])),
            Err(_e) => Ok(mlua::MultiValue::new()),
        })?;

    // sdConvertContents(contents, handler) -> string | 0
    let f_contents = lua.create_function(|lua, (contents, handler): (String, String)| {
        match convert_contents(&contents, &handler) {
            Ok(path) => Ok(mlua::MultiValue::from_vec(vec![mlua::Value::String(
                lua.create_string(&path)?,
            )])),
            Err(_e) => Ok(mlua::MultiValue::new()),
        }
    })?;

    // sdReloadImage is only available in the pro build.
    #[cfg(feature = "pro")]
    {
        let sd_reload_image = lua.create_function(|_, tbl: LuaTable| {
            let filename: String = tbl.get("filename")?;
            let width: i64 = tbl.get("width")?;
            let height: i64 = tbl.get("height")?;
            let imagetype: String = tbl.get("imagetype")?;
            let resizehandler: Option<String> = tbl.get("resizehandler")?;

            match crate::imageconv::resize_image(
                &filename,
                &imagetype,
                width,
                height,
                resizehandler.as_deref(),
            ) {
                Ok(dest) => Ok(dest),
                Err(e) => {
                    let err_s = e.to_string();
                    crate::logging::log_with("error", "sdReloadImage failed", &[("error", &err_s)]);
                    Err(mlua::Error::external(e))
                }
            }
        })?;
        t.set("reload_image", sd_reload_image)?;
    }

    t.set("convert", f)?;
    t.set("convert_svg_image", f_svg)?;
    t.set("convert_contents", f_contents)?;
    Ok(t)
}
