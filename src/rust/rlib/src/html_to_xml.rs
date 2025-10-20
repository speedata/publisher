use anyhow::{anyhow, Result};
use html5ever::driver::ParseOpts;
use html5ever::parse_document;
use html5ever::tendril::TendrilSink;
use markup5ever_rcdom::{Handle, NodeData, RcDom};
use mlua::prelude::*;

// ---- public API -------------------------------------------------------------

/// Core function: parse HTML and serialize it as **well-formed XML** (returned as String).
/// Notes:
/// - We wrap the input in a synthetic element so html5ever can repair top-level structure.
/// - Only Element/Text nodes are serialized (like the Go version); Doctype/Comments/etc. are skipped.
/// - Empty elements are emitted as self-closing tags (`<tag/>`).
pub fn convert_html_to_xml(input: &str) -> Result<String> {
    // Synthetic wrapper to collect top-level nodes deterministically (mirrors Go behavior).
    const WRAP: &str = "toplevel·toplevel";
    let wrapped = format!("<{WRAP}>{}</{WRAP}>", input);

    // Robust HTML parsing; html5ever handles tag autoclose, entity handling, etc.
    let dom = parse_document(RcDom::default(), ParseOpts::default())
        .from_utf8()
        .read_from(&mut wrapped.as_bytes())
        .map_err(|e| anyhow!("html parsing failed: {e}"))?;

    // Find the wrapper and serialize its children. If not found (very unlikely), fall back
    // to serializing document children.
    let mut out = String::new();
    let mut found_wrapper = false;
    for child in dom.document.children.borrow().iter() {
        if let NodeData::Element { ref name, .. } = child.data {
            if name.local.as_ref() == "toplevel·toplevel" {
                found_wrapper = true;
                for n in child.children.borrow().iter() {
                    write_node_as_xml(n, &mut out)?;
                }
            }
        }
    }
    if !found_wrapper {
        // Fallback: serialize all top-level children of the document.
        for n in dom.document.children.borrow().iter() {
            write_node_as_xml(n, &mut out)?;
        }
    }
    Ok(out)
}

/// mlua binding: `html_to_xml(text) -> xml_string`
/// Returns a Lua error string on failure (keeps API simple on the Lua side).
pub fn sd_html_to_xml(lua: &Lua) -> LuaResult<LuaFunction> {
    lua.create_function(|_, input: String| match convert_html_to_xml(&input) {
        Ok(s) => Ok(s),
        Err(e) => Err(LuaError::RuntimeError(format!("html to xml failed: {e}"))),
    })
}

// ---- helpers ----------------------------------------------------------------

/// Depth-first serialization of a DOM node into well-formed XML.
/// Keeps output minimal and Go-compatible: skips Doctype/Comments/PI, etc.
fn write_node_as_xml(n: &Handle, out: &mut String) -> Result<()> {
    match &n.data {
        NodeData::Document => {
            // Recurse into children; document node itself is not serialized.
            for c in n.children.borrow().iter() {
                write_node_as_xml(c, out)?;
            }
        }
        NodeData::Doctype { .. } => {
            // Not serialized to align with the Go behavior.
        }
        NodeData::Text { contents } => {
            // Escape text content as XML character data.
            let text = contents.borrow();
            escape_text(&text, out)?;
        }
        NodeData::Comment { .. } => {
            // Skip comments to match the Go variant’s “default only” handling.
        }
        NodeData::Element { name, attrs, .. } => {
            // Serialize element: open tag + attributes, then children, then close tag.
            // If no children, emit a self-closing form.
            let tag = name.local.as_ref();

            // Skip the synthetic wrapper itself; only serialize its children.
            if tag == "toplevel·toplevel" {
                for c in n.children.borrow().iter() {
                    write_node_as_xml(c, out)?;
                }
                return Ok(());
            }

            out.push('<');
            out.push_str(tag);

            // Attributes: write in parser order; escape values.
            for attr in attrs.borrow().iter() {
                out.push(' ');
                out.push_str(attr.name.local.as_ref());
                out.push_str("=\"");
                escape_attr(&attr.value, out)?;
                out.push('"');
            }

            // Children vs. self-closing
            let has_children = !n.children.borrow().is_empty();
            if has_children {
                out.push('>');
                for c in n.children.borrow().iter() {
                    write_node_as_xml(c, out)?;
                }
                out.push_str("</");
                out.push_str(tag);
                out.push('>');
            } else {
                out.push_str("/>");
            }
        }
        _ => {
            // Ignore other node kinds (ProcessingInstruction, etc.) for parity with the Go version.
        }
    }
    Ok(())
}

#[inline]
fn escape_text(text: &str, out: &mut String) -> Result<()> {
    // Minimal XML character data escaping.
    for ch in text.chars() {
        match ch {
            '&' => out.push_str("&amp;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            _ => out.push(ch),
        }
    }
    Ok(())
}

#[inline]
fn escape_attr(value: &str, out: &mut String) -> Result<()> {
    // Attribute value escaping (includes double quote).
    for ch in value.chars() {
        match ch {
            '&' => out.push_str("&amp;"),
            '<' => out.push_str("&lt;"),
            '>' => out.push_str("&gt;"),
            '"' => out.push_str("&quot;"),
            _ => out.push(ch),
        }
    }
    Ok(())
}
