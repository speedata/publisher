use mlua::prelude::*;
use regex::{Captures, Regex};

/// Expands an XPath-style replacement pattern inside a regex `replace_all` callback.
/// Behavior:
/// - `$12` → capture group 12 if it exists, otherwise group 1 followed by the literal "2"
/// - `$$`  → literal `$`
/// - `$` at end of string → literal `$`
///
/// This mimics XPath’s more forgiving `$` substitution rules instead of Rust’s stricter ones.
fn expand_xpath(caps: &Captures, repl: &str) -> String {
    let mut out = String::with_capacity(repl.len());
    let bytes = repl.as_bytes();
    let mut i = 0usize;
    let max_idx = caps.len().saturating_sub(1); // ignore group 0 (the full match)

    while i < bytes.len() {
        let b = bytes[i];
        if b != b'$' {
            out.push(bytes[i] as char);
            i += 1;
            continue;
        }

        // Found a `$`
        i += 1;
        if i >= bytes.len() {
            // Trailing `$` → treat as literal
            out.push('$');
            break;
        }

        // `$$` → literal `$`
        if bytes[i] == b'$' {
            out.push('$');
            i += 1;
            continue;
        }

        // Try numeric reference `$<digits>`
        let start = i;
        while i < bytes.len() && bytes[i].is_ascii_digit() {
            i += 1;
        }
        if start == i {
            // No digits after `$` → treat as literal `$` and process next char normally
            out.push('$');
            continue;
        }

        let digits = &repl[start..i];

        // Greedy back-off: try to find the longest valid capture index.
        // XPath-like behavior: `$12` = group 12 or, if missing, group 1 + "2".
        let mut used = 0usize;
        let mut group_text: Option<&str> = None;

        for end in (1..=digits.len()).rev() {
            if let Ok(n) = digits[..end].parse::<usize>() {
                if n >= 1 && n <= max_idx {
                    group_text = caps.get(n).map(|m| m.as_str());
                    if group_text.is_some() {
                        used = end;
                        break;
                    }
                }
            }
        }

        if let Some(gt) = group_text {
            out.push_str(gt);
            // Remaining digits (if `$1**2**`) are treated literally.
            out.push_str(&digits[used..]);
        } else {
            // No valid group: leave the digits literal (without `$`).
            out.push_str(digits);
        }
    }

    out
}

/// Exposes Lua string utilities built around regex and XPath-like replacements.
pub fn lua_subtable(lua: &Lua) -> LuaResult<LuaTable> {
    let tbl = lua.create_table()?;

    // contains(haystack, needle) -> boolean
    tbl.set(
        "contains",
        lua.create_function(|_, (haystack, needle): (String, String)| {
            Ok(haystack.contains(&needle))
        })?,
    )?;

    // matches(text, pattern) -> boolean
    // Returns true if the regex matches anywhere in the string.
    tbl.set(
        "matches",
        lua.create_function(|_, (text, pattern): (String, String)| {
            let re = Regex::new(&pattern)
                .map_err(|e| LuaError::RuntimeError(format!("invalid regex: {}", e)))?;
            Ok(re.is_match(&text))
        })?,
    )?;

    // tokenize(text, pattern) -> { parts... }
    // Splits the string around all matches of the regex and returns a Lua array (1-based).
    tbl.set(
        "tokenize",
        lua.create_function(|lua, (text, pattern): (String, String)| {
            let re = Regex::new(&pattern)
                .map_err(|e| LuaError::RuntimeError(format!("invalid regex: {}", e)))?;
            let parts: Vec<&str> = re.split(&text).collect();

            let out = lua.create_table_with_capacity(parts.len(), 0)?;
            for (i, s) in parts.iter().enumerate() {
                out.set((i + 1) as i64, *s)?;
            }
            Ok(out)
        })?,
    )?;

    // replace(text, pattern, repl) -> string
    // Performs regex substitution, expanding `$n` placeholders via expand_xpath().
    tbl.set(
        "replace",
        lua.create_function(|_, (text, pattern, repl): (String, String, String)| {
            let re = Regex::new(&pattern)
                .map_err(|e| LuaError::RuntimeError(format!("invalid regex: {}", e)))?;
            let out = re.replace_all(&text, |caps: &Captures| expand_xpath(caps, &repl));
            Ok(out.into_owned())
        })?,
    )?;

    Ok(tbl)
}
