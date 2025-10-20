use regex::{Captures, Regex};
use std::sync::OnceLock;
use std::{env, path::PathBuf};

pub(crate) static IGNOREFILE: OnceLock<String> = OnceLock::new();
pub(crate) static VERBOSITY: OnceLock<i32> = OnceLock::new();
pub(crate) static PATH_REWRITE: OnceLock<Option<PathRewriter>> = OnceLock::new();

/// Simple multi-pair path rewriter:
/// - Builds one regex with *alternating* capture groups for each "from" pattern
/// - Replaces matches with the corresponding "to" string
/// - Longest "from" wins by sorting pairs descending by length (prevents partial overshadowing)
pub(crate) struct PathRewriter {
    re: Regex,
    replacements: Vec<String>,
}

impl PathRewriter {
    /// Create a rewriter from pairs of (from, to).
    /// Returns None if no pairs are provided or the combined regex fails to compile.
    pub(crate) fn new(pairs: &[(String, String)]) -> Option<Self> {
        if pairs.is_empty() {
            return None;
        }
        // Sort by descending "from" length so longer literals take precedence over shorter ones.
        let mut pairs_sorted = pairs.to_vec();
        pairs_sorted.sort_by(|a, b| b.0.len().cmp(&a.0.len()));

        // Build an alternation like: (from1)|(from2)|...
        // Each group aligns with the same index in `replacements`.
        let mut groups = Vec::new();
        let mut repls = Vec::new();
        for (from, to) in pairs_sorted {
            groups.push(format!("({})", regex::escape(&from)));
            repls.push(to);
        }
        let re = Regex::new(&groups.join("|")).ok()?;
        Some(Self {
            re,
            replacements: repls,
        })
    }

    /// Apply all rewrites in one pass. For each match, figure out which capture
    /// group triggered and substitute the corresponding replacement string.
    pub(crate) fn apply(&self, input: &str) -> String {
        self.re
            .replace_all(input, |caps: &Captures| {
                // Find the first non-empty capture (skip 0 which is the whole match).
                let idx = caps
                    .iter()
                    .enumerate()
                    .skip(1)
                    .find(|(_, m)| m.is_some())
                    .map(|(i, _)| i - 1)
                    .unwrap_or(0);
                self.replacements[idx].clone()
            })
            .into_owned()
    }
}

/// Initialize global config from environment variables.
/// - IGNOREFILE = "<cwd>/<SP_JOBNAME>.pdf"
/// - VERBOSITY = parsed SP_VERBOSITY (default 0)
/// - PATH_REWRITE = parsed SPEEDATA_PATH_REWRITE like "from1=>to1;from2=>to2"
pub fn init_from_env() {
    // Compute ignorefile path based on current working directory and job name.
    let wd: PathBuf = env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    let jobname = env::var("SP_JOBNAME").unwrap_or_default();
    let ignore = wd
        .join(format!("{jobname}.pdf"))
        .to_string_lossy()
        .to_string();
    let _ = IGNOREFILE.set(ignore);

    // Verbosity (integer), defaults to 0 on missing/invalid input.
    let verbosity = env::var("SP_VERBOSITY")
        .ok()
        .and_then(|v| v.parse::<i32>().ok())
        .unwrap_or(0);
    let _ = VERBOSITY.set(verbosity);

    // Global path rewrite: SPEEDATA_PATH_REWRITE="from1=>to1;from2=>to2"
    if let Ok(spec) = std::env::var("SPEEDATA_PATH_REWRITE") {
        let pairs: Vec<(String, String)> = spec
            .split(';')
            .filter_map(|p| p.split_once("=>"))
            .map(|(a, b)| (a.to_string(), b.to_string()))
            .collect();
        if let Some(pr) = PathRewriter::new(&pairs) {
            PATH_REWRITE.set(Some(pr)).ok();
        }
    } else {
        PATH_REWRITE.set(None).ok();
    }
}

// ----- Getters / Utilities ---------------------------------------------------

/// Global verbosity level, default 0.
pub fn verbosity() -> i32 {
    *VERBOSITY.get().unwrap_or(&0)
}

/// Apply global path rewrite if configured; otherwise returns `input` unchanged.
pub fn rewrite_path(input: &str) -> String {
    match PATH_REWRITE.get().and_then(|o| o.as_ref()) {
        Some(rw) => rw.apply(input),
        None => input.to_string(),
    }
}
