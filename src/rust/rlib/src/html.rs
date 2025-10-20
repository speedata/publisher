use mlua::prelude::*;
use mlua::Value as LuaValue;
use mlua::{Lua, Result as LuaResult, Table as LuaTable, Variadic};

use std::borrow::Cow;
use std::collections::BTreeMap;
use std::{fs, io::Read, path::Path};

use kuchiki::NodeRef;
use kuchiki::{parse_html, traits::*};

use url::Url;

use lightningcss::rules::{page::PageSelector, CssRule};
use lightningcss::stylesheet::{ParserOptions, StyleSheet};
use lightningcss::traits::ToCss;

// ===============================
// Markdown (comrak + syntect)
// ===============================

/// Normalize theme names for fuzzy matching:
/// - lowercase
/// - keep only ASCII alphanumerics (strip spaces, dots, brackets, dashes, underscores)
fn norm_theme_key<S: AsRef<str>>(s: S) -> String {
    s.as_ref()
        .chars()
        .filter(|c| c.is_ascii_alphanumeric())
        .flat_map(|c| c.to_lowercase())
        .collect()
}

/// Resolve a theme key case-insensitively and tolerant to punctuation.
/// Falls back to "base16-ocean.dark".
fn resolve_theme_key<'a>(
    input: Option<&str>,
    themes: &'a syntect::highlighting::ThemeSet,
) -> Cow<'a, str> {
    let want = match input {
        Some(s) if !s.is_empty() => norm_theme_key(s),
        _ => String::new(),
    };
    if !want.is_empty() {
        for key in themes.themes.keys() {
            if norm_theme_key(key) == want {
                return Cow::Borrowed(key.as_str());
            }
        }
    }
    Cow::Borrowed("base16-ocean.dark")
}

/// Internal representation of Markdown extensions and options.
struct ExtCfg {
    exts: Vec<String>,
    use_highlight: bool,
    theme_name: Option<String>,
    with_classes: bool, // currently unused (class-based highlighting pipeline)
}

fn apply_ext_token(cfg: &mut ExtCfg, token: &str) {
    match token {
        // known feature toggles
        "gfm" | "table" | "strikethrough" | "linkify" | "definitionlist" | "footnote"
        | "typographer" | "highlight" => {
            if token == "highlight" {
                cfg.use_highlight = true;
            }
            cfg.exts.push(token.to_string());
        }
        // syntactic sugar for theme/adapter options
        _ => {
            if let Some(rest) = token.strip_prefix("hlstyle_") {
                cfg.theme_name = Some(rest.to_string());
            } else if let Some(rest) = token.strip_prefix("hloption_") {
                if rest.eq_ignore_ascii_case("withclasses") {
                    cfg.with_classes = true;
                }
            }
        }
    }
}

fn parse_extensions(val: Option<LuaValue>) -> ExtCfg {
    // Accept either a single string or a Lua array of strings.
    let mut cfg = ExtCfg {
        exts: Vec::new(),
        use_highlight: false,
        theme_name: None,
        with_classes: false,
    };
    match val {
        None | Some(LuaValue::Nil) => {}
        Some(LuaValue::String(s)) => {
            if let Ok(arg) = s.to_str() {
                apply_ext_token(&mut cfg, arg.trim());
            }
        }
        Some(LuaValue::Table(t)) => {
            let len = t.len().unwrap_or(0);
            for i in 1..=len {
                if let Ok(LuaValue::String(s)) = t.raw_get(i) {
                    if let Ok(arg) = s.to_str() {
                        apply_ext_token(&mut cfg, arg.trim());
                    }
                }
            }
        }
        _ => {}
    }
    cfg
}

/// Lua: html.markdown(text, extensions?)
fn markdown(_lua: &Lua, args: Variadic<LuaValue>) -> LuaResult<String> {
    // 1) Input validation
    let md_text = match args.get(0) {
        Some(LuaValue::String(s)) => s.to_str().map_err(LuaError::external)?.to_string(),
        Some(other) => {
            return Err(LuaError::external(format!(
                "html.markdown: first argument must be a string, got {:?}",
                other.type_name()
            )));
        }
        None => return Err(LuaError::external("html.markdown: missing first argument")),
    };

    // 2) Extension parsing
    let extensions_val = args.get(1).cloned();
    let cfg = parse_extensions(extensions_val);

    // 3) Comrak options (enable only what we need)
    use comrak::Options;
    let mut options = Options::default();

    if cfg.exts.iter().any(|e| e == "gfm") {
        // GFM implies several toggles
        options.extension.table = true;
        options.extension.strikethrough = true;
        options.extension.autolink = true;
        options.extension.tasklist = true;
        options.render.unsafe_ = true;
    }
    if cfg.exts.iter().any(|e| e == "table") {
        options.extension.table = true;
    }
    if cfg.exts.iter().any(|e| e == "strikethrough") {
        options.extension.strikethrough = true;
    }
    if cfg.exts.iter().any(|e| e == "linkify") {
        options.extension.autolink = true;
    }
    if cfg.exts.iter().any(|e| e == "footnote") {
        options.extension.footnotes = true;
    }
    if cfg.exts.iter().any(|e| e == "definitionlist") {
        options.extension.description_lists = true;
    }
    if cfg.exts.iter().any(|e| e == "footnote" || e == "footnotes") {
        options.extension.footnotes = true;
    }
    if cfg.exts.iter().any(|e| e == "typographer") {
        options.parse.smart = true; // curly quotes, en/em dashes, etc.
    }
    if cfg.exts.iter().any(|e| e == "tasklist") {
        options.extension.tasklist = true;
    }

    // 4) No highlighting → plain HTML
    if !cfg.use_highlight {
        let html = comrak::markdown_to_html(&md_text, &options);
        return Ok(html);
    }

    // 5) Syntect-based highlighting via Comrak plugin
    use comrak::{
        format_html_with_plugins, parse_document, plugins::syntect::SyntectAdapter, Arena, Plugins,
    };

    let themes = syntect::highlighting::ThemeSet::load_defaults();
    let theme_key_cow = resolve_theme_key(cfg.theme_name.as_deref(), &themes);

    let adapter = SyntectAdapter::new(Some(&theme_key_cow));
    let mut plugins = Plugins::default();
    plugins.render.codefence_syntax_highlighter = Some(&adapter);

    let arena = Arena::new();
    let root = parse_document(&arena, &md_text, &options);
    let mut out = Vec::<u8>::with_capacity(md_text.len().saturating_mul(2).max(1024));
    format_html_with_plugins(root, &options, &mut out, &plugins).map_err(LuaError::external)?;
    Ok(String::from_utf8_lossy(&out).into_owned())
}

/// Optionally generate CSS for a Syntect theme (useful if you later switch to class-based highlighting).
fn highlight_css(_lua: &Lua, theme: Option<String>) -> LuaResult<String> {
    use syntect::highlighting::ThemeSet;
    use syntect::html::ClassStyle;

    let theme_name = theme.unwrap_or_else(|| "base16-ocean.dark".to_string());
    let themes = ThemeSet::load_defaults();
    let theme = themes
        .themes
        .get(&theme_name)
        .or_else(|| themes.themes.get("base16-ocean.dark"));

    if let Some(theme) = theme {
        let css = syntect::html::css_for_theme_with_class_style(theme, ClassStyle::Spaced)
            .unwrap_or_else(|_| String::new());
        Ok(css)
    } else {
        Ok(String::new())
    }
}

// ===============================
// HTML + CSS → Lua
// ===============================

#[derive(Clone, Debug)]
struct FontFaceInfo {
    family: String,
    css: String, // full @font-face block (declarations only)
}

#[derive(Clone, Debug)]
struct PageRuleInfo {
    selector: String, // e.g. ":left", ":first"
    css: String,      // declarations as CSS text
}

// -------- Collect CSS from HTML --------

fn extract_style_blocks(html: &str) -> Vec<String> {
    // Very simple scanner: find <style>..</style> and extract inner content.
    let mut v = Vec::new();
    let lower = html.to_lowercase();
    let mut pos = 0usize;
    while let Some(start) = lower[pos..].find("<style") {
        let abs = pos + start;
        if let Some(tag_end) = lower[abs..].find('>') {
            let content_start = abs + tag_end + 1;
            if let Some(close) = lower[content_start..].find("</style>") {
                let content = &html[content_start..content_start + close];
                v.push(content.to_string());
                pos = content_start + close + 8; // len("</style>")
                continue;
            }
        }
        break;
    }
    v
}

fn extract_link_stylesheets(html: &str) -> Vec<String> {
    // Quick-n-dirty <link rel=stylesheet href=...> extractor (handles quoted and unquoted href).
    let mut v = Vec::new();
    let lower = html.to_lowercase();
    let mut pos = 0usize;
    while let Some(start) = lower[pos..].find("<link") {
        let abs = pos + start;
        if let Some(end) = lower[abs..].find('>') {
            let tag = &html[abs..abs + end + 1];
            let tl = tag.to_lowercase();
            if tl.contains("rel=\"stylesheet\"")
                || tl.contains("rel='stylesheet'")
                || tl.contains("rel=stylesheet")
            {
                if let Some(hp) = tl.find("href=") {
                    let after = &tag[hp + 5..].trim_start();
                    let quote = after.chars().next().unwrap_or('"');
                    if quote == '"' || quote == '\'' {
                        if let Some(qe) = after[1..].find(quote) {
                            v.push(after[1..1 + qe].to_string());
                        }
                    } else {
                        // unquoted href
                        let endpos = after
                            .find(|c: char| c.is_whitespace() || c == '>')
                            .unwrap_or(after.len());
                        v.push(after[..endpos].to_string());
                    }
                }
            }
            pos = abs + end + 1;
            continue;
        }
        break;
    }
    v
}

fn fetch_css(href: &str, base: Option<&Url>) -> Option<String> {
    // Load stylesheet by URL or local filesystem path.
    // For http/https you could hook up your `netfetch` module.
    if let Ok(url) = Url::parse(href) {
        if url.scheme() == "file" {
            if let Ok(p) = url.to_file_path() {
                return fs::read_to_string(p).ok();
            }
        }
        // Non-file URLs not handled here.
        return None;
    }
    // Relative to base file URL
    if let Some(base_url) = base {
        if let Ok(url) = base_url.join(href) {
            if url.scheme() == "file" {
                if let Ok(p) = url.to_file_path() {
                    return fs::read_to_string(p).ok();
                }
            } else {
                return None;
            }
        }
    }
    // Local path fallback
    fs::read_to_string(href).ok()
}

// -------- lightningcss: parse CSS and flatten rules --------

#[derive(Copy, Clone, Debug, Eq, PartialEq, Ord, PartialOrd)]
enum Origin {
    Ua,     // user agent defaults
    Author, // styles from the document
    User,   // user-provided overrides
}

#[derive(Debug)]
struct StyleRuleFlat {
    selector: String,
    decls_css: String,
    origin: Origin,
    order: u32,                   // source order for stable sorting
    specificity: (u16, u16, u16), // (IDs, classes/pseudos, type selectors)
}

/// Crude specificity estimator (sufficient for cascade sorting here).
fn estimate_specificity(sel: &str) -> (u16, u16, u16) {
    let mut a = 0;
    let mut b = 0;
    let mut c = 0;
    let s = sel.trim();
    for ch in s.chars() {
        match ch {
            '#' => a += 1,
            '.' | ':' | '[' => b += 1,
            _ => {}
        }
    }
    if let Some(first) = s.chars().find(|ch| !ch.is_whitespace()) {
        if first.is_ascii_alphabetic() {
            c += 1;
        }
    }
    (a, b, c)
}

fn extract_block(css_rule: &str) -> String {
    // Extract "{...}" block content; return empty string if malformed.
    if let (Some(open), Some(close)) = (css_rule.find('{'), css_rule.rfind('}')) {
        css_rule[open + 1..close].to_string()
    } else {
        String::new()
    }
}

fn parse_inline_style(css: &str) -> BTreeMap<String, String> {
    // Parse "a:b; c:d" into a map (lowercased keys).
    let mut m = BTreeMap::new();
    for chunk in css.split(';') {
        if let Some((k, v)) = chunk.split_once(':') {
            let key = k.trim().to_ascii_lowercase();
            let val = v.trim().to_string();
            if !key.is_empty() && !val.is_empty() {
                m.insert(key, val);
            }
        }
    }
    m
}

fn serialize_inline_style(map: &BTreeMap<String, String>) -> String {
    // Serialize map back into "a: b; c: d;" style (with spaces).
    let mut s = String::new();
    for (k, v) in map {
        if !s.is_empty() {
            s.push(' ');
        }
        s.push_str(k);
        s.push(':');
        s.push(' ');
        s.push_str(v);
        s.push(';');
    }
    s
}

fn is_dimension(tok: &str) -> bool {
    // Heuristic dimension detection (number or unit-suffixed).
    let t = tok.trim();
    if t.is_empty() {
        return false;
    }
    let has_unit = t.ends_with("px")
        || t.ends_with("pt")
        || t.ends_with("em")
        || t.ends_with("rem")
        || t.ends_with('%')
        || t.ends_with("cm")
        || t.ends_with("mm")
        || t.ends_with("in");
    let numeric = t
        .chars()
        .next()
        .map(|c| c.is_ascii_digit())
        .unwrap_or(false);
    numeric || has_unit
}

fn is_border_style(tok: &str) -> bool {
    matches!(
        tok,
        "none"
            | "hidden"
            | "dotted"
            | "dashed"
            | "solid"
            | "double"
            | "groove"
            | "ridge"
            | "inset"
            | "outset"
    )
}

fn four_values(v: &str) -> (String, String, String, String) {
    // CSS shorthands: 1 -> all; 2 -> top/bottom, left/right; 3 -> top, lr, bottom; 4 -> TRBL
    let parts: Vec<&str> = v.split_whitespace().collect();
    match parts.len() {
        0 => ("0".into(), "0".into(), "0".into(), "0".into()),
        1 => {
            let a = parts[0].to_string();
            (a.clone(), a.clone(), a.clone(), a)
        }
        2 => {
            let vert = parts[0].to_string();
            let horiz = parts[1].to_string();
            (vert.clone(), horiz.clone(), vert, horiz)
        }
        3 => (
            parts[0].to_string(),
            parts[1].to_string(),
            parts[2].to_string(),
            parts[1].to_string(),
        ),
        _ => (
            parts[0].to_string(),
            parts[1].to_string(),
            parts[2].to_string(),
            parts[3].to_string(),
        ),
    }
}

fn expand_shorthand_into(map: &mut BTreeMap<String, String>, key: &str, value: &str) {
    // Expand a subset of common CSS shorthands into longhands.
    let key = key.to_ascii_lowercase();
    match key.as_str() {
        // margin / padding
        "margin" => {
            let (t, r, b, l) = four_values(value);
            map.insert("margin-top".into(), t);
            map.insert("margin-right".into(), r);
            map.insert("margin-bottom".into(), b);
            map.insert("margin-left".into(), l);
        }
        "padding" => {
            let (t, r, b, l) = four_values(value);
            map.insert("padding-top".into(), t);
            map.insert("padding-right".into(), r);
            map.insert("padding-bottom".into(), b);
            map.insert("padding-left".into(), l);
        }

        // border (all sides)
        "border" => {
            // Reasonable defaults so "border: red" becomes visible.
            for side in ["top", "right", "bottom", "left"] {
                map.insert(format!("border-{side}-style"), "none".into());
                map.insert(format!("border-{side}-width"), "1pt".into());
                map.insert(format!("border-{side}-color"), "currentcolor".into());
            }
            // Simple tokenization; rgb()/hsl()/hex are treated as "color".
            for tok in value.split_whitespace() {
                for side in ["top", "right", "bottom", "left"] {
                    if is_border_style(tok) {
                        map.insert(format!("border-{side}-style"), tok.to_string());
                    } else if is_dimension(tok) {
                        map.insert(format!("border-{side}-width"), tok.to_string());
                    } else {
                        map.insert(format!("border-{side}-color"), tok.to_string());
                    }
                }
            }
        }

        // border-<side>
        k if k.starts_with("border-top")
            || k.starts_with("border-right")
            || k.starts_with("border-bottom")
            || k.starts_with("border-left") =>
        {
            let side = if k.contains("top") {
                "top"
            } else if k.contains("right") {
                "right"
            } else if k.contains("bottom") {
                "bottom"
            } else {
                "left"
            };
            // defaults
            map.insert(format!("border-{side}-style"), "none".into());
            map.insert(format!("border-{side}-width"), "1pt".into());
            map.insert(format!("border-{side}-color"), "currentcolor".into());
            for tok in value.split_whitespace() {
                if is_dimension(tok) {
                    map.insert(format!("border-{side}-width"), tok.to_string());
                } else if is_border_style(tok) {
                    map.insert(format!("border-{side}-style"), tok.to_string());
                } else {
                    map.insert(format!("border-{side}-color"), tok.to_string());
                }
            }
        }

        // border-color / style / width (4-value variants)
        "border-color" => {
            let (t, r, b, l) = four_values(value);
            for (side, v) in [("top", t), ("right", r), ("bottom", b), ("left", l)] {
                map.insert(format!("border-{side}-color"), v);
            }
        }
        "border-style" => {
            let (t, r, b, l) = four_values(value);
            for (side, v) in [("top", t), ("right", r), ("bottom", b), ("left", l)] {
                map.insert(format!("border-{side}-style"), v);
            }
        }
        "border-width" => {
            let (t, r, b, l) = four_values(value);
            for (side, v) in [("top", t), ("right", r), ("bottom", b), ("left", l)] {
                map.insert(format!("border-{side}-width"), v);
            }
        }

        // border-radius (simplified: apply same value to all corners)
        "border-radius" => {
            let v = value.trim().to_string();
            for (tb, lr) in [
                ("top", "left"),
                ("top", "right"),
                ("bottom", "left"),
                ("bottom", "right"),
            ] {
                map.insert(format!("border-{tb}-{lr}-radius"), v.clone());
            }
        }

        // list-style
        "list-style" => {
            for part in value.split_whitespace() {
                match part {
                    "inside" | "outside" => {
                        map.insert("list-style-position".into(), part.to_string());
                    }
                    _ => {
                        if part.starts_with("url(") {
                            map.insert("list-style-image".into(), part.to_string());
                        } else {
                            map.insert("list-style-type".into(), part.to_string());
                        }
                    }
                }
            }
        }

        // font (very rough) — enough to pull out size/family and basic style/weight
        "font" => {
            let mut font_style = "normal".to_string();
            let mut font_weight = "normal".to_string();
            let mut font_size: Option<String> = None;
            let mut font_family: Option<String> = None;

            // coarse token pass
            let fields: Vec<&str> = value.split_whitespace().collect();
            for &f in &fields {
                if f.eq_ignore_ascii_case("italic") || f.eq_ignore_ascii_case("oblique") {
                    font_style = "italic".into();
                } else if f.eq_ignore_ascii_case("bold") || f == "700" {
                    font_weight = "bold".into();
                } else if is_dimension(f) || f.ends_with('%') {
                    if font_size.is_none() {
                        font_size = Some(f.to_string());
                    }
                }
            }
            // family: everything after the font-size, trimming quotes; skip optional line-height
            if let Some(sz) = &font_size {
                if let Some(pos) = value.find(sz) {
                    let after = value[pos + sz.len()..].trim();
                    if let Some(idx) = after.find('/') {
                        // "<size>/<line-height> <family>"
                        let rest = after[idx + 1..].trim();
                        if let Some(space) = rest.find(' ') {
                            font_family = Some(
                                rest[space + 1..]
                                    .trim()
                                    .trim_matches(&['"', '\''][..])
                                    .to_string(),
                            );
                        }
                    } else {
                        let fam = after
                            .split_whitespace()
                            .skip(1)
                            .collect::<Vec<_>>()
                            .join(" ");
                        if !fam.is_empty() {
                            font_family = Some(fam.trim_matches(&['"', '\''][..]).to_string());
                        }
                    }
                }
            }

            map.insert("font-style".into(), font_style);
            map.insert("font-weight".into(), font_weight);
            if let Some(sz) = font_size {
                map.insert("font-size".into(), sz);
            }
            if let Some(fam) = font_family {
                map.insert("font-family".into(), fam);
            }
        }

        // text-decoration (simplified)
        "text-decoration" => {
            for part in value.split_whitespace() {
                match part {
                    "none" | "underline" | "overline" | "line-through" => {
                        map.insert("text-decoration-line".into(), part.to_string());
                    }
                    "solid" | "double" | "dotted" | "dashed" | "wavy" => {
                        map.insert("text-decoration-style".into(), part.to_string());
                    }
                    _ => {}
                }
            }
            if let Some(line) = map.get("text-decoration-line") {
                if line != "none" && !map.contains_key("text-decoration-style") {
                    map.insert("text-decoration-style".into(), "solid".into());
                }
            }
        }

        // background (extremely simplified)
        "background" => {
            let only = value.trim();
            if !only.is_empty() && !only.contains(|c: char| c.is_whitespace()) {
                map.insert("background-color".into(), only.to_string());
            } else if only.starts_with("rgb(") || only.starts_with("hsl(") || only.starts_with('#')
            {
                map.insert("background-color".into(), only.to_string());
            }
        }

        // default: keep as-is (lowercased key, trimmed value)
        _ => {
            map.insert(key, value.trim().to_string());
        }
    }
}

/// Minimal CSS string unescaper for string literal contents:
/// turns \XXXX (hex) into the corresponding Unicode character.
fn css_unescape_string_literal(s: &str) -> String {
    // Expect a quoted string like "\"\\2022\"" or "'\\2022'".
    let bytes = s.as_bytes();
    if bytes.len() >= 2
        && ((bytes[0] == b'"' && *bytes.last().unwrap() == b'"')
            || (bytes[0] == b'\'' && *bytes.last().unwrap() == b'\''))
    {
        let inner = &s[1..s.len() - 1];
        let mut out = String::with_capacity(inner.len());
        let mut chars = inner.chars().peekable();
        while let Some(ch) = chars.next() {
            if ch == '\\' {
                // Up to 6 hex digits per CSS spec.
                let mut hex = String::new();
                for _ in 0..6 {
                    if let Some(&c) = chars.peek() {
                        if c.is_ascii_hexdigit() {
                            hex.push(c);
                            chars.next();
                        } else {
                            break;
                        }
                    }
                }
                if !hex.is_empty() {
                    if let Ok(cp) = u32::from_str_radix(&hex, 16) {
                        if let Some(u) = char::from_u32(cp) {
                            out.push(u);
                            continue;
                        }
                    }
                }
                // Fallback: keep the backslash.
                out.push('\\');
            } else {
                out.push(ch);
            }
        }
        return format!("\"{}\"", out);
    }
    s.to_string()
}

/// Expand shorthands in a decl map; later entries override earlier ones.
fn expand_all_shorthands(input: &BTreeMap<String, String>) -> BTreeMap<String, String> {
    let mut out = BTreeMap::new();
    for (k, v) in input {
        expand_shorthand_into(&mut out, k, v);
    }
    out
}

fn parse_css_flat(
    css: &str,
    origin: Origin,
    start_order: &mut u32,
) -> (Vec<StyleRuleFlat>, Vec<FontFaceInfo>, Vec<PageRuleInfo>) {
    // Parse a stylesheet and flatten rules into a simpler representation for selection + cascade.
    let sheet = match StyleSheet::parse(css, ParserOptions::default()) {
        Ok(s) => s,
        Err(_) => return (vec![], vec![], vec![]),
    };

    let mut styles = Vec::new();
    let mut fonts = Vec::new();
    let mut pages = Vec::new();

    for rule in &sheet.rules.0 {
        match rule {
            CssRule::Style(style_rule) => {
                // Serialize declarations of the rule; selectors are handled individually.
                let decls_css = style_rule
                    .declarations
                    .to_css_string(Default::default())
                    .unwrap_or_default();

                for sel in &style_rule.selectors.0 {
                    let selector = sel.to_css_string(Default::default()).unwrap_or_default();
                    styles.push(StyleRuleFlat {
                        specificity: estimate_specificity(&selector),
                        selector,
                        decls_css: decls_css.clone(),
                        origin,
                        order: *start_order,
                    });
                    *start_order += 1;
                }
            }
            CssRule::FontFace(ff) => {
                // Keep only the declaration block for downstream parsing.
                let css_text = ff.to_css_string(Default::default()).unwrap_or_default();
                let block = extract_block(&css_text);
                let decls = parse_declarations(&block);

                let family = decls
                    .get("font-family")
                    .map(|v| v.trim_matches('"').to_string())
                    .unwrap_or_default();

                if !family.is_empty() {
                    fonts.push(FontFaceInfo { family, css: block });
                }
            }
            CssRule::Page(pg) => {
                // Collect page selector(s) and serialized declarations.
                let selector = pg
                    .selectors
                    .iter()
                    .map(|s: &PageSelector| s.to_css_string(Default::default()).unwrap_or_default())
                    .collect::<Vec<_>>()
                    .join(", ");
                let css_text = pg
                    .declarations
                    .to_css_string(Default::default())
                    .unwrap_or_default();
                pages.push(PageRuleInfo {
                    selector,
                    css: css_text,
                });
            }
            _ => {}
        }
    }
    (styles, fonts, pages)
}

fn collect_css_all(
    html: &str,
    base: Option<&Url>,
    user_css: &str,
    defaults: &str,
) -> (Vec<StyleRuleFlat>, Vec<FontFaceInfo>, Vec<PageRuleInfo>) {
    // Aggregate CSS from UA defaults, <style> blocks, <link> stylesheets, and user CSS.
    // Track source order to stabilize the cascade.
    let mut order = 0u32;
    let mut all_styles = Vec::new();
    let mut all_fonts = Vec::new();
    let mut all_pages = Vec::new();

    // UA defaults
    {
        let (s, f, p) = parse_css_flat(defaults, Origin::Ua, &mut order);
        all_styles.extend(s);
        all_fonts.extend(f);
        all_pages.extend(p);
    }

    // <style> blocks
    for block in extract_style_blocks(html) {
        let (s, f, p) = parse_css_flat(&block, Origin::Author, &mut order);
        all_styles.extend(s);
        all_fonts.extend(f);
        all_pages.extend(p);
    }

    // <link rel=stylesheet href=...>
    for href in extract_link_stylesheets(html) {
        if let Some(css) = fetch_css(&href, base) {
            let (s, f, p) = parse_css_flat(&css, Origin::Author, &mut order);
            all_styles.extend(s);
            all_fonts.extend(f);
            all_pages.extend(p);
        }
    }

    // User CSS (highest precedence origin)
    {
        let (s, f, p) = parse_css_flat(user_css, Origin::User, &mut order);
        all_styles.extend(s);
        all_fonts.extend(f);
        all_pages.extend(p);
    }

    // Cascade ordering: by origin, then specificity, then source order.
    all_styles.sort_by(|a, b| {
        a.origin
            .cmp(&b.origin)
            .then(a.specificity.cmp(&b.specificity))
            .then(a.order.cmp(&b.order))
    });

    (all_styles, all_fonts, all_pages)
}

fn normalize_zero_units_for_spacing(map: &mut BTreeMap<String, String>) {
    // Normalize bare "0" to "0pt" for spacing longhands to keep downstream code simple.
    for key in [
        "margin-top",
        "margin-right",
        "margin-bottom",
        "margin-left",
        "padding-top",
        "padding-right",
        "padding-bottom",
        "padding-left",
    ] {
        if let Some(v) = map.get_mut(key) {
            if v.trim() == "0" {
                *v = "0pt".to_string();
            }
        }
    }
}

fn apply_styles_inline(document: &kuchiki::NodeRef, rules: &[StyleRuleFlat]) {
    // Apply matched rule declarations directly into the DOM:
    // - normal rules => @style attribute
    // - ::before/::after => data-rlib-before/after (consumed later during DOM→Lua)
    for r in rules {
        // Detect pseudo-elements (both ::before/::after and legacy :before/:after).
        let mut pseudo: Option<&'static str> = None;
        let mut base_selector: std::borrow::Cow<'_, str> = std::borrow::Cow::Borrowed(&r.selector);
        if r.selector.contains("::before") || r.selector.contains(":before") {
            pseudo = Some("before");
            base_selector = std::borrow::Cow::Owned(
                r.selector
                    .replace("::before", "")
                    .replace(":before", "")
                    .trim()
                    .to_string(),
            );
        } else if r.selector.contains("::after") || r.selector.contains(":after") {
            pseudo = Some("after");
            base_selector = std::borrow::Cow::Owned(
                r.selector
                    .replace("::after", "")
                    .replace(":after", "")
                    .trim()
                    .to_string(),
            );
        }

        // Select nodes by the base selector (unchanged for normal rules).
        if let Ok(matches) = document.select(base_selector.as_ref()) {
            for m in matches {
                if let Some(el) = m.as_node().as_element() {
                    let mut attrs = el.attributes.borrow_mut();

                    // 1) Decide the target storage: @style or data-rlib-(before|after)
                    let (store_attr, existing_map_raw) = match pseudo {
                        Some("before") => {
                            let raw = attrs
                                .get("data-rlib-before")
                                .map(|s| parse_inline_style(s))
                                .unwrap_or_default();
                            ("data-rlib-before", raw)
                        }
                        Some("after") => {
                            let raw = attrs
                                .get("data-rlib-after")
                                .map(|s| parse_inline_style(s))
                                .unwrap_or_default();
                            ("data-rlib-after", raw)
                        }
                        _ => {
                            let raw = attrs
                                .get("style")
                                .map(|s| parse_inline_style(s))
                                .unwrap_or_default();
                            ("style", raw)
                        }
                    };

                    // 2) Expand/normalize existing declarations
                    let mut existing_map = expand_all_shorthands(&existing_map_raw);
                    normalize_zero_units_for_spacing(&mut existing_map);

                    // 3) Parse + expand rule declarations
                    let decls_raw = parse_inline_style(&r.decls_css);
                    let mut decls = expand_all_shorthands(&decls_raw);
                    normalize_zero_units_for_spacing(&mut decls);

                    // 4) Cascade merge: later rules override earlier ones
                    for (k, v) in decls {
                        existing_map.insert(k, v);
                    }

                    // 5) Write back into chosen attribute
                    let merged = serialize_inline_style(&existing_map);
                    attrs.insert(store_attr, merged);
                }
            }
        }
    }
}

// -------- DOM → Lua --------

fn is_inline_display_value(d: &str) -> bool {
    matches!(
        d.trim().to_ascii_lowercase().as_str(),
        "inline" | "inline-block" | "inline-table" | "inline-flex" | "inline-grid"
    )
}

fn is_inline_by_default(tag: &str) -> bool {
    // Common inline elements (not exhaustive, but practical).
    matches!(
        tag,
        "a" | "abbr"
            | "b"
            | "bdi"
            | "bdo"
            | "br"
            | "cite"
            | "code"
            | "dfn"
            | "em"
            | "i"
            | "img"
            | "kbd"
            | "label"
            | "map"
            | "mark"
            | "q"
            | "rp"
            | "rt"
            | "ruby"
            | "s"
            | "samp"
            | "small"
            | "span"
            | "strong"
            | "sub"
            | "sup"
            | "time"
            | "u"
            | "var"
            | "wbr"
            | "button"
            | "input"
            | "select"
            | "textarea"
    )
}

/// Decide if an element runs in inline direction ("→").
/// Priority:
/// 1) explicit `display` in styles
/// 2) tag default
fn is_inline_direction(tag: &str, styles: &std::collections::BTreeMap<String, String>) -> bool {
    if let Some(d) = styles.get("display") {
        return is_inline_display_value(d);
    }
    is_inline_by_default(tag)
}

fn node_to_lua(lua: &Lua, node: &NodeRef) -> LuaResult<LuaValue> {
    // Convert a DOM node into the Lua shape expected by the Go/Lua side.
    if let Some(text) = node.as_text() {
        let s = text.borrow();
        if s.trim().is_empty() {
            return Ok(LuaValue::String(lua.create_string(" ")?)); // preserve whitespace as single space
        }
        return Ok(LuaValue::String(lua.create_string(s.as_str())?));
    }
    if let Some(el) = node.as_element() {
        let mut name = el.name.local.to_string();
        if name.eq_ignore_ascii_case("x-title") {
            name = "title".to_string();
        }

        // Drop <head> entirely; only body-relevant content is exposed downstream.
        if name.eq_ignore_ascii_case("head") {
            return Ok(LuaValue::Nil);
        }

        let tbl = lua.create_table()?;
        tbl.set("elementname", name.as_str())?;

        // --- Collect styles from inline + previously inlined rules ---
        let mut kv = BTreeMap::<String, String>::new();

        // Parse @style attribute into map
        if let Some(attr) = el.attributes.borrow().get("style") {
            for (k, v) in parse_declarations(attr) {
                kv.insert(k, v);
            }
        }

        // --- Pseudo-element styles from data-rlib-before/after ---
        // We import them into 'styles' with "before::"/"after::" prefixes.
        if let Some(attr) = el.attributes.borrow().get("data-rlib-before") {
            for (k, mut v) in parse_declarations(attr) {
                if k.eq_ignore_ascii_case("content") {
                    // Unescape CSS string into real Unicode for Lua consumption.
                    v = css_unescape_string_literal(&v);
                }
                kv.insert(format!("before::{}", k), v);
            }
        }
        if let Some(attr) = el.attributes.borrow().get("data-rlib-after") {
            for (k, mut v) in parse_declarations(attr) {
                if k.eq_ignore_ascii_case("content") {
                    v = css_unescape_string_literal(&v);
                }
                kv.insert(format!("after::{}", k), v);
            }
        }

        // Build 'styles' table (quote font-family if missing quotes for deterministic downstream)
        let st_tbl = lua.create_table()?;
        for (k, v) in &kv {
            if k == "font-family" {
                let needs_quotes = !(v.starts_with('"') && v.ends_with('"'));
                if needs_quotes {
                    st_tbl.set(k.as_str(), format!("\"{}\"", v))?;
                } else {
                    st_tbl.set(k.as_str(), v.as_str())?;
                }
            } else {
                st_tbl.set(k.as_str(), v.as_str())?;
            }
        }
        if kv.contains_key("font-family") && !kv.contains_key("font-family-number") {
            st_tbl.set("font-family-number", 0)?;
        }
        st_tbl.set("has_border", false)?;
        tbl.set("styles", st_tbl)?;

        // Direction heuristic based on computed styles (or tag default).
        let is_inline = is_inline_direction(name.as_str(), &kv);
        tbl.set("direction", if is_inline { "→" } else { "↓" })?;

        // Export attributes except @style and our internal pseudo storage.
        let at_tbl = lua.create_table()?;
        for (k, v) in el.attributes.borrow().map.iter() {
            let key = k.local.to_string();
            if key.eq_ignore_ascii_case("style") {
                continue;
            }
            if key.eq_ignore_ascii_case("data-rlib-before")
                || key.eq_ignore_ascii_case("data-rlib-after")
            {
                continue;
            }
            at_tbl.set(key, v.value.to_string())?;
        }
        tbl.set("attributes", at_tbl)?;

        // Set a "block" flag for obvious block-level elements (loosely curated list).
        if matches!(
            name.as_str(),
            "body"
                | "div"
                | "p"
                | "h1"
                | "h2"
                | "h3"
                | "h4"
                | "h5"
                | "h6"
                | "ul"
                | "ol"
                | "table"
                | "thead"
                | "tbody"
                | "tfoot"
                | "tr"
                | "td"
                | "th"
                | "section"
                | "article"
                | "nav"
                | "aside"
                | "header"
                | "footer"
                | "pre"
        ) {
            tbl.set("block", true)?;
        }

        // Recurse into children; attach them directly to this table (1-based).
        let mut idx = 1i64;
        for c in node.children() {
            let v = node_to_lua(lua, &c)?;
            if !matches!(v, LuaValue::Nil) {
                tbl.raw_set(idx, v)?;
                idx += 1;
            }
        }

        return Ok(LuaValue::Table(tbl));
    }

    Ok(LuaValue::Nil)
}

fn parse_declarations(block: &str) -> BTreeMap<String, String> {
    // Split "a:b; c:d" into map (lowercase keys, trimmed values).
    let mut m = BTreeMap::new();
    for item in block.split(';') {
        if let Some((k, v)) = item.split_once(':') {
            let key = k.trim().to_ascii_lowercase();
            let val = v.trim().to_string();
            if !key.is_empty() && !val.is_empty() {
                m.insert(key, val);
            }
        }
    }
    m
}

fn first_element_child_k(node: &NodeRef) -> Option<NodeRef> {
    // Depth-first search for the first element node in the subtree.
    for child in node.children() {
        if child.as_element().is_some() {
            return Some(child);
        }
        if let Some(desc) = first_element_child_k(&child) {
            return Some(desc);
        }
    }
    None
}

fn build_lua_csshtmltree(
    lua: &Lua,
    doc: &NodeRef,
    fontfaces: &[FontFaceInfo],
    pages: &[PageRuleInfo],
) -> LuaResult<LuaTable> {
    // Build the Lua structure expected by the downstream Go/Lua pipeline.
    let out = lua.create_table()?;
    out.set("typ", "csshtmltree")?;

    // fontfamilies grouped by family and variant (regular/italic/bold/bolditalic)
    let ff_tbl = lua.create_table()?;

    fn classify_font(weight: Option<&str>, style: Option<&str>) -> &'static str {
        match (
            weight.unwrap_or("normal").to_lowercase().as_str(),
            style.unwrap_or("normal").to_lowercase().as_str(),
        ) {
            ("bold", "italic") => "bolditalic",
            ("bold", _) => "bold",
            (_, "italic") => "italic",
            _ => "regular",
        }
    }

    for ff in fontfaces {
        let family_name = ff.family.trim_matches('"').to_string();
        if family_name.is_empty() {
            continue;
        }

        // Extract weight/style/src URL from declarations block.
        let mut weight: Option<String> = None;
        let mut style: Option<String> = None;
        let mut url: Option<String> = None;

        for (k, v) in parse_declarations(&ff.css) {
            match k.as_str() {
                "font-weight" => weight = Some(v),
                "font-style" => style = Some(v),
                "src" => {
                    // First url(...) item
                    if let Some(start) = v.find("url(") {
                        let inner = &v[start + 4..];
                        if let Some(end) = inner.find(')') {
                            let raw = &inner[..end];
                            let clean = raw.trim_matches(&['"', '\''][..]).to_string();
                            url = Some(clean);
                        }
                    }
                }
                _ => {}
            }
        }

        let variant = classify_font(weight.as_deref(), style.as_deref());
        let fam_entry: Option<LuaTable> = ff_tbl.get(family_name.as_str())?;
        let family_tbl = match fam_entry {
            Some(t) => t,
            None => {
                let t = lua.create_table()?;
                ff_tbl.set(family_name.as_str(), t.clone())?;
                t
            }
        };
        for k in ["regular", "italic", "bold", "bolditalic"] {
            if !family_tbl.contains_key(k)? {
                let empty = lua.create_table()?;
                family_tbl.set(k, empty)?;
            }
        }
        let variant_tbl = lua.create_table()?;
        if let Some(u) = url {
            variant_tbl.set("url", u)?;
        }
        family_tbl.set(variant, variant_tbl)?;
    }

    out.set("fontfamilies", ff_tbl)?;

    // pages: collect selectors + declarations into a simple array
    let pages_tbl = lua.create_table()?;
    for (i, pg) in pages.iter().enumerate() {
        let t = lua.create_table()?;
        if !pg.selector.is_empty() {
            t.set("selector", pg.selector.as_str())?;
        }
        let decl_tbl = lua.create_table()?;
        for (k, v) in parse_declarations(&pg.css) {
            decl_tbl.set(k.as_str(), v.as_str())?;
        }
        t.set("declarations", decl_tbl)?;
        pages_tbl.raw_set((i + 1) as i64, t)?;
    }
    out.set("pages", pages_tbl)?;

    // Root element (typically <html>)
    if let Some(root_el) = first_element_child_k(&doc.clone()) {
        let node_tbl = node_to_lua(lua, &root_el)?;
        out.raw_set(1, node_tbl)?;
    }

    Ok(out)
}

fn protect_title_tags(src: &str) -> String {
    // Prevent <title> from being hoisted into <head> by the HTML parser.
    // Replace with <x-title> … </x-title> and normalize later.
    src.replace("<title", "<x-title")
        .replace("</title>", "</x-title>")
}

/// Lua: html.highlight_themes() -> array of available Syntect theme names
fn list_highlight_themes(_lua: &Lua, _: ()) -> LuaResult<Vec<String>> {
    let themes = syntect::highlighting::ThemeSet::load_defaults();
    let mut keys: Vec<String> = themes.themes.keys().cloned().collect();
    keys.sort_unstable();
    Ok(keys)
}

// -------- Public Lua API --------

/// parse_raw_text(html, css_text, css_defaults)
fn parse_raw_text(
    lua: &Lua,
    (html, css_text, css_defaults): (String, String, String),
) -> LuaResult<LuaValue> {
    let base = None::<Url>;

    // Protect <title> so it stays where it originally appears.
    let html_protected = protect_title_tags(&html);

    // Collect and parse CSS using the protected HTML.
    let (style_rules, fontfaces, pages) =
        collect_css_all(&html_protected, base.as_ref(), &css_text, &css_defaults);

    // Parse DOM and apply inline styles (incl. pseudo storage attributes).
    let document = parse_html().one(html_protected);
    apply_styles_inline(&document, &style_rules);

    let out = build_lua_csshtmltree(lua, &document, &fontfaces, &pages)?;
    Ok(LuaValue::Table(out))
}

/// parse_text(html_fragment_without_body, css_text, css_defaults)
fn parse_text(
    lua: &Lua,
    (frag, css_text, css_defaults): (String, String, String),
) -> LuaResult<LuaValue> {
    // Wrap fragment into <body> for consistent downstream processing.
    parse_raw_text(
        lua,
        (format!("<body>{}</body>", frag), css_text, css_defaults),
    )
}

/// parse_file(filename, css_text, css_defaults)
fn parse_file(
    lua: &Lua,
    (filename, css_text, css_defaults): (String, String, String),
) -> LuaResult<LuaValue> {
    let p = Path::new(&filename);
    if !p.exists() {
        return Err(LuaError::external(format!("File not found: {}", filename)));
    }
    let mut s = String::new();
    fs::File::open(p)
        .map_err(LuaError::external)?
        .read_to_string(&mut s)
        .map_err(LuaError::external)?;
    let s = protect_title_tags(&s);
    let base = Url::from_file_path(fs::canonicalize(p).unwrap_or_else(|_| p.to_path_buf())).ok();

    // Collect + parse CSS
    let (style_rules, fontfaces, pages) =
        collect_css_all(&s, base.as_ref(), &css_text, &css_defaults);
    let document = parse_html().one(s);
    apply_styles_inline(&document, &style_rules);

    // Build Lua tree
    let out = build_lua_csshtmltree(lua, &document, &fontfaces, &pages)?;
    Ok(LuaValue::Table(out))
}

/// Exposed Lua subtable
pub fn lua_subtable(lua: &Lua) -> LuaResult<LuaTable> {
    let tbl = lua.create_table()?;
    // Markdown
    tbl.set("markdown", lua.create_function(markdown)?)?;
    tbl.set("highlight_css", lua.create_function(highlight_css)?)?;
    tbl.set(
        "highlight_themes",
        lua.create_function(list_highlight_themes)?,
    )?;
    tbl.set("parse_raw_text", lua.create_function(parse_raw_text)?)?;
    tbl.set("parse_text", lua.create_function(parse_text)?)?;
    tbl.set("parse_file", lua.create_function(parse_file)?)?;
    Ok(tbl)
}
