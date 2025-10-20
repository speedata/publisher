use mlua::prelude::*;
use unicode_bidi::{bidi_class, BidiClass, BidiInfo, Level};

/// Lua: segments = rlib.text.segmentize_text(str, dir)
/// dir: 0 = neutral/auto, 1 = LTR, 2 = RTL
/// Returns: { {dir_flag, text}, ... } where dir_flag: 0 = LTR, 1 = RTL
fn lua_segmentize_text(lua: &Lua, (s, dir_opt): (String, Option<i64>)) -> LuaResult<LuaTable> {
    let default_level = match dir_opt.unwrap_or(0) {
        1 => Some(Level::ltr()),
        2 => Some(Level::rtl()),
        _ => None,
    };
    if s.is_empty() {
        return lua.create_table();
    }

    // 1) Analyze original text and pick the first paragraph.
    let info = BidiInfo::new(&s, default_level);
    let para = &info.paragraphs[0];
    let line_range = para.range.clone();

    // 2) Visual runs over ORIGINAL text (ranges index into `s`).
    let (run_levels, run_ranges) = info.visual_runs(para, line_range);

    // 3) Reading order: reverse for RTL base paragraphs.
    let rtl_base = para.level.is_rtl();
    let indices: Box<dyn Iterator<Item = usize>> = if rtl_base {
        Box::new((0..run_ranges.len()).rev())
    } else {
        Box::new(0..run_ranges.len())
    };

    // Helper: determine direction flag for a run by scanning the first meaningful char.
    let run_dir_flag = |text: &str| -> Option<i32> {
        for ch in text.chars() {
            match bidi_class(ch) {
                BidiClass::L => return Some(0),                 // strong L
                BidiClass::R | BidiClass::AL => return Some(1), // strong R/AL
                BidiClass::EN => return Some(0),                // European Number -> LTR
                // Arabic Number (AN) is tricky; if you need it, decide policy:
                // Here we leave AN to fallback (context), or uncomment: `BidiClass::AN => return Some(1),`
                _ => continue, // neutrals/formatting; keep scanning
            }
        }
        None // no decisive char found in this run
    };

    // 4) Build Lua table.
    let tbl = lua.create_table_with_capacity(run_ranges.len(), 0)?;
    let mut out_i = 1usize;
    for i in indices {
        let range = &run_ranges[i];
        let slice = &s[range.clone()];

        // Prefer a per-run decision from first meaningful codepoint; else fallback to run level parity.
        let dir_flag = match run_dir_flag(slice) {
            Some(d) => d,
            None => {
                if run_levels[i].is_rtl() {
                    1
                } else {
                    0
                }
            }
        };

        let sub = lua.create_table_with_capacity(2, 0)?;
        sub.set(1, dir_flag)?; // 0 = LTR, 1 = RTL
        sub.set(2, slice)?;
        tbl.set(out_i, sub)?;
        out_i += 1;
    }

    Ok(tbl)
}

pub fn lua_subtable(lua: &Lua) -> LuaResult<LuaTable> {
    let t = lua.create_table()?;
    t.set("segmentize_text", lua.create_function(lua_segmentize_text)?)?;
    Ok(t)
}
