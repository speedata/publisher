use crate::html_to_xml::convert_html_to_xml;
use anyhow::{anyhow, bail, Context, Result};
use mlua::prelude::*;
use std::collections::BTreeMap;
use std::path::{Path, PathBuf};
use xmlparser::{ElementEnd, Token, Tokenizer};

const XI_NS: &str = "http://www.w3.org/2001/XInclude";
const MAX_INCLUDE_DEPTH: usize = 32;

/// Convert byte offset to (line, col) — both 1-based.
/// Simple but correct (for large files you could optimize later using `memchr`).
fn offset_to_line_col(src: &str, offset: usize) -> (u32, u32) {
    let bytes = src.as_bytes();
    let mut line: u32 = 1;
    let mut last_nl: usize = 0;
    let mut i = 0;
    while i < offset && i < bytes.len() {
        if bytes[i] == b'\n' {
            line += 1;
            last_nl = i + 1;
        }
        i += 1;
    }
    let col = (offset - last_nl) as u32 + 1;
    (line, col)
}

/// Simple helper to resolve a namespace prefix by walking the namespace stack.
fn lookup_ns(stack: &Vec<BTreeMap<String, String>>, prefix: Option<&str>) -> Option<String> {
    let key = prefix.unwrap_or("").to_string();
    for m in stack.iter().rev() {
        if let Some(uri) = m.get(&key) {
            return Some(uri.clone());
        }
    }
    None
}

/// Qualified name: prefix, local part, and resolved namespace URI (if any)
#[derive(Clone)]
struct QName {
    prefix: Option<String>,
    local: String,
    ns_uri: Option<String>,
}

/// Internal tree node used while parsing.
struct ElementNode {
    id: u64,
    qname: QName,
    attrs: BTreeMap<String, String>,
    nsmap: BTreeMap<String, String>, // visible namespaces at this element ("" = default)
    file: String,
    line: u32,
    col: u32,
    children: Vec<Child>, // elements and text nodes, in order
}

/// Either text or element node
enum Child {
    Text(String),
    Elem(Box<ElementNode>),
}

/// Expose Lua functions under `rlib.xml`
pub fn lua_subtable(lua: &Lua) -> LuaResult<LuaTable> {
    let t = lua.create_table()?;

    // rlib.xml.parse("somefile.xml") — parses and expands XInclude
    t.set(
        "parse",
        lua.create_function(|lua, path: String| {
            let root =
                parse_entrypoint_with_xinclude(Path::new(&path)).map_err(LuaError::external)?;
            to_lua_document(lua, &root)
        })?,
    )?;

    t.set(
        "parse_string",
        lua.create_function(|lua, (text, name): (String, Option<String>)| {
            // Use "<memory>" as pseudo filename if none given
            let name = name.unwrap_or_else(|| "<memory>".to_string());
            let root =
                parse_string_with_xinclude(&text, Path::new(&name)).map_err(LuaError::external)?;
            to_lua_document(lua, &root)
        })?,
    )?;
    // rlib.xml.html_to_xml("…") → XML-String
    t.set(
        "html_to_xml",
        lua.create_function(|_, text: String| {
            convert_html_to_xml(&text).map_err(LuaError::external)
        })?,
    )?;
    Ok(t)
}

/// Public entry for file paths: parse + expand xi:include.
fn parse_entrypoint_with_xinclude(path: &Path) -> Result<ElementNode> {
    let content =
        std::fs::read_to_string(path).with_context(|| format!("reading {}", path.display()))?;
    let mut root = parse_with_positions(&content, &path.display().to_string())?;
    let basedir = path.parent().unwrap_or(Path::new(".")).to_path_buf();
    expand_xinclude_in_place(&mut root, &basedir, 0)?;
    Ok(root)
}

/// Public entry for string input: parse + expand xi:include using the directory of `name_path` as base.
fn parse_string_with_xinclude(src: &str, name_path: &Path) -> Result<ElementNode> {
    let mut root = parse_with_positions(src, &name_path.display().to_string())?;
    let basedir = name_path.parent().unwrap_or(Path::new(".")).to_path_buf();
    expand_xinclude_in_place(&mut root, &basedir, 0)?;
    Ok(root)
}

/// Return a char for common (X)HTML entities.
/// Extend this match as needed.
fn named_html_entity(name: &str) -> Option<char> {
    match name {
        // XML core (redundant, aber ok)
        "amp" => Some('&'),
        "lt" => Some('<'),
        "gt" => Some('>'),
        "quot" => Some('"'),
        "apos" => Some('\''),

        // Whitespace / spaces
        "nbsp" => Some('\u{00A0}'), // no-break space
        "ensp" => Some('\u{2002}'),
        "emsp" => Some('\u{2003}'),
        "thinsp" => Some('\u{2009}'),
        "hairsp" => Some('\u{200A}'),
        "shy" => Some('\u{00AD}'), // soft hyphen

        // Dashes, quotes, ellipsis
        "ndash" => Some('\u{2013}'),
        "mdash" => Some('\u{2014}'),
        "hellip" => Some('\u{2026}'),
        "lsquo" => Some('\u{2018}'),
        "rsquo" => Some('\u{2019}'),
        "ldquo" => Some('\u{201C}'),
        "rdquo" => Some('\u{201D}'),
        "laquo" => Some('\u{00AB}'),
        "raquo" => Some('\u{00BB}'),

        // Symbols
        "copy" => Some('\u{00A9}'),
        "reg" => Some('\u{00AE}'),
        "trade" => Some('\u{2122}'),
        "euro" => Some('\u{20AC}'),
        "pound" => Some('\u{00A3}'),
        "yen" => Some('\u{00A5}'),
        "sect" => Some('\u{00A7}'),
        "para" => Some('\u{00B6}'),
        "middot" => Some('\u{00B7}'),
        "bull" => Some('\u{2022}'),

        // Comparison/math basics
        "ne" => Some('\u{2260}'),
        "le" => Some('\u{2264}'),
        "ge" => Some('\u{2265}'),
        "times" => Some('\u{00D7}'),
        "divide" => Some('\u{00F7}'),

        _ => None,
    }
}

fn decode_xml_entities(input: &str) -> String {
    if !input.as_bytes().contains(&b'&') {
        return input.to_string();
    }

    let mut out = String::with_capacity(input.len());
    let mut i = 0;

    while i < input.len() {
        if let Some(rel_amp) = input[i..].find('&') {
            let amp = i + rel_amp;
            out.push_str(&input[i..amp]);

            if let Some(rel_semi) = input[amp + 1..].find(';') {
                let semi = amp + 1 + rel_semi;
                let entity = &input[amp + 1..semi];

                // 1) Numeric?
                let decoded_num = if let Some(num) = entity.strip_prefix('#') {
                    let cp = if let Some(hex) = num.strip_prefix(['x', 'X']) {
                        u32::from_str_radix(hex, 16).ok()
                    } else {
                        u32::from_str_radix(num, 10).ok()
                    };
                    cp.and_then(|cp| {
                        if (cp <= 0x10FFFF) && !(0xD800..=0xDFFF).contains(&cp) {
                            char::from_u32(cp)
                        } else {
                            None
                        }
                    })
                } else {
                    None
                };

                if let Some(ch) = decoded_num {
                    out.push(ch);
                    i = semi + 1;
                    continue;
                }

                // 2) Named? (first check our HTML map)
                if let Some(ch) = named_html_entity(entity) {
                    out.push(ch);
                    i = semi + 1;
                    continue;
                }

                // 3) Unbekannt: gib '&' wörtlich aus und scanne weiter
                out.push('&');
                i = amp + 1;
                continue;
            } else {
                out.push_str(&input[amp..]);
                break;
            }
        } else {
            out.push_str(&input[i..]);
            break;
        }
    }

    out
}

/// Parse XML string into our internal tree representation, keeping line/column/file info.
fn parse_with_positions(src: &str, filename: &str) -> Result<ElementNode> {
    let mut toks = Tokenizer::from(src);

    // Namespace stack: each level = prefix -> URI map; "" = default namespace
    let mut ns_stack: Vec<BTreeMap<String, String>> = vec![BTreeMap::new()];

    // Node stack for building the tree
    let mut node_stack: Vec<ElementNode> = Vec::new();

    // Running ID counter
    let mut idctr: u64 = 0;

    // Iterate over tokens produced by xmlparser
    while let Some(res) = toks.next() {
        let token = res?;
        match token {
            // Start of an element (e.g. <tag>)
            Token::ElementStart {
                local,
                prefix,
                span,
                ..
            } => {
                // Push a new namespace level (copy of parent)
                ns_stack.push(ns_stack.last().cloned().unwrap_or_default());

                idctr += 1;
                let (line, col) = offset_to_line_col(src, span.start());

                // Determine prefix (empty = None)
                let pre: Option<String> = {
                    let p = prefix.as_str();
                    if p.is_empty() {
                        None
                    } else {
                        Some(p.to_string())
                    }
                };

                let loc = local.as_str().to_string();

                // Namespace URI will be filled later (after xmlns attributes are processed)
                let elem = ElementNode {
                    id: idctr,
                    qname: QName {
                        prefix: pre.clone(),
                        local: loc,
                        ns_uri: None,
                    },
                    attrs: BTreeMap::new(),
                    nsmap: ns_stack.last().cloned().unwrap_or_default(),
                    file: filename.to_string(),
                    line,
                    col,
                    children: Vec::new(),
                };
                node_stack.push(elem);
            }

            // Attribute (prefix is a StrSpan, empty if none)
            Token::Attribute {
                local,
                prefix,
                value,
                ..
            } => {
                let pfx = prefix.as_str();
                let name = if pfx.is_empty() {
                    local.as_str().to_string()
                } else {
                    format!("{}:{}", pfx, local.as_str())
                };

                // Namespace declarations
                if name == "xmlns" {
                    if let Some(last) = ns_stack.last_mut() {
                        last.insert("".into(), value.as_str().to_string());
                    }
                } else if pfx == "xmlns" {
                    if let Some(last) = ns_stack.last_mut() {
                        last.insert(local.as_str().to_string(), value.as_str().to_string());
                    }
                } else if let Some(last) = node_stack.last_mut() {
                    // Regular attribute
                    last.attrs.insert(name, decode_xml_entities(value.as_str()));
                }
            }

            // Text content between tags
            Token::Text { text } => {
                if let Some(last) = node_stack.last_mut() {
                    last.children
                        .push(Child::Text(decode_xml_entities(text.as_str())));
                }
            }

            Token::Cdata { text, .. } => {
                if let Some(last) = node_stack.last_mut() {
                    last.children.push(Child::Text(text.as_str().to_string()));
                }
            }

            // End of an element (</tag> or empty <tag/>)
            Token::ElementEnd { end, .. } => {
                // Update namespace map + namespace URI now that xmlns attributes are known
                if let Some(cur) = node_stack.last_mut() {
                    cur.nsmap = ns_stack.last().cloned().unwrap_or_default();
                    cur.qname.ns_uri = lookup_ns(&ns_stack, cur.qname.prefix.as_deref());
                }

                match end {
                    ElementEnd::Open => {
                        // <tag> — children will follow
                    }
                    ElementEnd::Close(_, _) | ElementEnd::Empty => {
                        if let Some(finished) = node_stack.pop() {
                            if let Some(parent) = node_stack.last_mut() {
                                parent.children.push(Child::Elem(Box::new(finished)));
                            } else {
                                // Root element finished
                                return Ok(finished);
                            }
                        }
                        // Pop one namespace level
                        let _ = ns_stack.pop();
                    }
                }
            }

            // Ignore comments, DTDs, and processing instructions for now
            Token::DtdStart { .. }
            | Token::DtdEnd { .. }
            | Token::Comment { .. }
            | Token::ProcessingInstruction { .. } => {}

            _ => {}
        }
    }

    bail!("no root element found")
}

/// Expand <xi:include> elements in-place.
/// Replacement policy: the xi:include node is replaced by the **children of the included document's root element**.
/// This "flattens" typical patterns like including a small <Layout> file whose children you want at the call site.
fn expand_xinclude_in_place(root: &mut ElementNode, base_dir: &Path, depth: usize) -> Result<()> {
    if depth > MAX_INCLUDE_DEPTH {
        bail!("maximum XInclude depth ({MAX_INCLUDE_DEPTH}) exceeded");
    }

    // We rebuild the children vector to make splicing easy.
    let mut new_children: Vec<Child> = Vec::new();

    for child in std::mem::take(&mut root.children) {
        match child {
            Child::Text(t) => {
                new_children.push(Child::Text(t));
            }
            Child::Elem(mut boxed) => {
                let is_xi_include =
                    boxed.qname.ns_uri.as_deref() == Some(XI_NS) && boxed.qname.local == "include";

                if is_xi_include {
                    // 1) Read href
                    let href = boxed.attrs.get("href").cloned().ok_or_else(|| {
                        anyhow!(
                            "xi:include missing required @href at {}:{}:{}",
                            boxed.file,
                            boxed.line,
                            boxed.col
                        )
                    })?;

                    // 2) Resolve path relative to the file where <xi:include> appears
                    //    Use the *actual file* recorded on the xi node as base (correct for nested includes).
                    let xi_file_dir: PathBuf = Path::new(&boxed.file)
                        .parent()
                        .unwrap_or(Path::new("."))
                        .to_path_buf();
                    let resolved = xi_file_dir.join(&href);

                    // 3) Parse included document (with correct positions/file names)
                    let content = std::fs::read_to_string(&resolved)
                        .with_context(|| format!("reading included file {}", resolved.display()))?;

                    let mut included_root =
                        parse_with_positions(&content, &resolved.display().to_string())?;

                    // 4) Recursively expand includes inside the included document
                    let sub_base = resolved.parent().unwrap_or(Path::new(".")).to_path_buf();
                    expand_xinclude_in_place(&mut included_root, &sub_base, depth + 1)?;

                    // 5) Splice **children of included root** (flattening)
                    for grandchild in included_root.children.into_iter() {
                        new_children.push(grandchild);
                    }
                } else {
                    // Regular element: recurse
                    // Compute new base: for normal elements it doesn't matter,
                    // but we keep it conceptually as the directory of this element's file.
                    let child_base = Path::new(&boxed.file)
                        .parent()
                        .unwrap_or(base_dir)
                        .to_path_buf();
                    expand_xinclude_in_place(&mut boxed, &child_base, depth)?;
                    new_children.push(Child::Elem(boxed));
                }
            }
        }
    }

    root.children = new_children;
    Ok(())
}

/// Convert the internal ElementNode tree to a Lua table in the expected format.
fn to_lua_document(lua: &Lua, root: &ElementNode) -> LuaResult<LuaTable> {
    let doc = lua.create_table()?;
    doc.set(".__type", "document")?;
    let root_tbl = element_to_lua(lua, root)?;
    doc.set(1, root_tbl)?;
    Ok(doc)
}

/// Recursively convert an ElementNode (and its children) to a Lua table.
fn element_to_lua(lua: &Lua, el: &ElementNode) -> LuaResult<LuaTable> {
    let t = lua.create_table()?;

    t.set(".__type", "element")?;
    t.set(".__id", el.id)?;
    t.set(".__file", el.file.as_str())?;
    t.set(".__line", el.line)?;
    t.set(".__col", el.col)?;

    // Element name and namespace
    let local = &el.qname.local;
    let name = if let Some(p) = &el.qname.prefix {
        format!("{p}:{local}")
    } else {
        local.clone()
    };
    t.set(".__name", name)?;
    t.set(".__local_name", local.as_str())?;
    if let Some(ns) = &el.qname.ns_uri {
        t.set(".__namespace", ns.as_str())?;
    }

    // Namespace table (visible at this element)
    let ns_tbl = lua.create_table()?;
    for (k, v) in &el.nsmap {
        ns_tbl.set(k.as_str(), v.as_str())?;
    }
    t.set(".__ns", ns_tbl)?;

    // Attributes
    let at = lua.create_table()?;
    for (k, v) in &el.attrs {
        at.set(k.as_str(), v.as_str())?;
    }
    t.set(".__attributes", at)?;

    // Child nodes (text or nested elements)
    let mut idx = 1;
    for ch in &el.children {
        match ch {
            Child::Text(s) => t.set(idx, s.as_str())?,
            Child::Elem(e) => t.set(idx, element_to_lua(lua, e)?)?,
        }
        idx += 1;
    }

    Ok(t)
}
