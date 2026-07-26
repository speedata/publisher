-- luacheck configuration for the speedata Publisher.
-- Run with `rake luacheck` (or directly `luacheck src/lua`).
-- LuaTeX bundles Lua 5.3.6.

-- A custom std on top of Lua 5.3 that knows about the bits LuaTeX adds.
-- LuaTeX extends some standard libraries (`os`, `string`, `table`, `math`)
-- and exposes a number of globals (`tex`, `node`, `pdf`, …) where most
-- subfields are writable. We declare them with `other_fields = true` and
-- `read_only = false` so subfield assignments don't trigger W122.
stds.luatex_ext = {
    globals = {
        -- LuaTeX core tables that the publisher legitimately mutates.
        tex        = { other_fields = true, read_only = false },
        texconfig  = { other_fields = true, read_only = false },
        pdf        = { other_fields = true, read_only = false },
        node       = { other_fields = true, read_only = false },
        nodes      = { other_fields = true, read_only = false },
        font       = { other_fields = true, read_only = false },
        fonts      = { other_fields = true, read_only = false },
        callback   = { other_fields = true, read_only = false },
        token      = { other_fields = true, read_only = false },
        tokens     = { other_fields = true, read_only = false },
        lang       = { other_fields = true, read_only = false },
        language   = { other_fields = true, read_only = false },
        texio      = { other_fields = true, read_only = false },
        status     = { other_fields = true, read_only = false },
        img        = { other_fields = true, read_only = false },
        mp         = { other_fields = true, read_only = false },
        mplib      = { other_fields = true, read_only = false },
        epdf       = { other_fields = true, read_only = false },
        pdfe       = { other_fields = true, read_only = false },
        luatexbase = { other_fields = true, read_only = false },
        fontloader = { other_fields = true, read_only = false },
        -- spinit.lua and fonts.lua extend the stdlib tables
        -- (table.find, table.sum, math.round, ...). Allow writes.
        os         = { other_fields = true, read_only = false },
        string     = { other_fields = true, read_only = false },
        table      = { other_fields = true, read_only = false },
        math       = { other_fields = true, read_only = false },
    },
    read_globals = {
        -- Pure read-only externals
        utf8       = { other_fields = true },
        bit32      = { other_fields = true },
        lfs        = { other_fields = true },
        fio        = { other_fields = true },
        unicode    = { other_fields = true },
        oslibext   = { other_fields = true },
        sha2       = { other_fields = true },
        md5        = { other_fields = true },
        lua        = { other_fields = true },
        luaharfbuzz = { other_fields = true },
        harfbuzz   = { other_fields = true },
        luaglue    = { other_fields = true },
    },
}

std = "lua53+luatex_ext"

-- The Publisher relies heavily on top-level globals (publisher.lua, sdini.lua,
-- spinit.lua, commands.lua, ...). Allow definitions without requiring every
-- single one to be listed below.
allow_defined_top = true

-- Many functions are wired up as TeX/Lua callbacks; their arguments are
-- prescribed by the API even if unused in the body.
unused_args = false

-- TeX code tends to be wide; don't fail on long lines.
max_line_length = false

codes = true

-- Stylistic warnings that are noisy without flagging real bugs:
-- W411 / W412: redefining a local / shadowing an argument
-- W421 / W422 / W423: shadowing inner / outer / loop scopes
-- W431 / W432: shadowing upvalue / upvalue argument
-- W542: empty if branch — the codebase commonly uses `if X then -- ignore
-- elseif … else … end` as a deliberate no-op stub (often with an
-- explanatory comment); flagging those is just noise.
-- A common Lua idiom is `local x = x or default`, which trips W411/W412.
-- W211 unused locals stay enabled — those tend to surface real dead code.
-- Exception: a leading underscore marks a local as intentionally unused
-- (same convention as diagnostics.unusedLocalExclude for lua-language-server).
ignore = {
    "411", "412", "421", "422", "423", "431", "432",
    "542",
    "21/_.*",
}

-- Cross-file project globals (read AND written somewhere in the tree).
globals = {
    -- Conventional throwaway name
    "_",
    -- Core modules / shared state
    "publisher", "main", "css", "par", "xpath", "newxpath",
    "splib", "kpse", "barcodes",
    -- Logging / dispatch helpers (defined in spinit.lua, used everywhere)
    "warning", "warningonce", "err", "log", "dbg", "info", "call",
    -- Debug printf-style helper from common/sd-debug.lua
    "w",
    -- Command table (defined in publisher/commands.lua, read across the tree)
    "commands",
    -- Optional library probes set in publisher.lua before the _ENV trick
    -- (so they land in _G, not in M).
    "hasharfbuzz", "harfbuzz", "hasharfbuzzsubset", "harfbuzzsubset",
    -- File / module loading helpers
    "do_luafile", "file_start", "file_end",
    -- Frequently shared state and tunables
    "options", "modes", "pages", "pages_shippedout", "pagestore",
    "pagelabels", "pagenum_tbl", "matters", "masterpages",
    "current_pagenumber", "current_layout_file", "current_layout_line",
    "current_data_line", "current_grid", "current_group",
    "current_fontfamily", "current_fgcolor",
    "default_area", "default_areaname", "defaultlanguage",
    "defaultcolorstack",
    "expected_pages", "previous_duration",
    "errorcode", "compatibility", "viewerpreferences",
    "nextpage", "skippages", "total_inserted_pages",
    "visible_pagenumbers", "forward_pagestore",
    "alternating", "alternating_value",
    "data_dispatcher", "data_dispatcher_patterns",
    "intextblockcontext", "imagehandler", "resizehandler",
    "filespecnumbers", "fontaliases", "fontgroup", "groups",
    "borderattributes", "languages", "languages_id_lang",
    "language_filename", "language_mapping",
    "leftskip", "rightskip", "lowercase", "maxdimen", "shape",
    "marker", "markers", "markercount", "marker_id_value",
    "marker_max", "marker_min",
    "metapostcolors", "metapostcolorwarnings",
    "metapostgraphics", "metapostvariables",
    "puastart", "rolecounter", "roles_a",
    "structElements", "struct_root_numtree",
    "textformats", "user_defined_functions",
    "bookmarks",
    "env_publisherversion", "utf8_to_utf16_string_pdf",
    "has_pro_error", "pro",
    "os_separator",
    "loglevel", "loglevel_str",
    -- Attributes registered globally
    "attributes", "attribute_name_number", "attribute_number_name",
    "att_rows", "att_shift_left", "att_shift_up", "att_tie_glue",
    "att_space_prio", "att_space_amount",
    "att_break_below_forbidden", "att_break_above",
    "att_omit_at_top", "att_use_as_head", "att_dont_format",
    "att_margin_newcolumn", "att_margin_top_boxstart",
    "att_ignore_orphan_widowsetting",
    "att_margin_top", "att_margin_bottom", "att_break_before",
    "att_is_table_row", "att_tr_dynamic_data", "att_tr_shift_up",
    "att_lineheight", "att_dontadjustlineheight", "att_keep",
    "att_leaderwd", "att_tablenewpage", "att_newline", "att_role",
    -- Whatsits / node ids
    "user_defined_addtolist", "user_defined_bookmark",
    "user_defined_mark", "user_defined_marker",
    "user_defined_mark_append", "user_defined_whatsit",
    "pdf_refximage_whatsit", "pdf_action_whatsit", "pdf_dest_whatsit",
    "pdf_start_link_whatsit", "pdf_literal_whatsit",
    "action_node", "disc_node", "dir_node",
    "glue_node", "glue_spec_node", "glyph_node",
    "hlist_node", "kern_node", "penalty_node",
    "rule_node", "vlist_node", "whatsit_node",
    -- Unit constants computed in publisher.lua
    "factor", "maxframes",
    "tenpoint_sp", "twelvepoint_sp",
    "tenmm_sp", "onemm_sp", "onein_sp",
    "onept_sp", "onepc_sp", "onepp_sp",
    "onedd_sp", "onecc_sp", "onecm_sp",
    "glue_stretch2",
    -- Helper hooks
    "htmlbox", "dothings", "initialize_luatex_and_generate_pdf",
    "define_image_callback",
    "get_ps_name", "get_extension", "get_lineheight",
    "get_argument_number", "get_colorprofile",
    "register_colorprofile", "set_colorprofile", "set_colorprofile_filename",
    "write_colorprofile", "use_color", "getresource",
    "round_half_even",
    -- Debug helpers used cross-file
    "tracetable", "showattributes", "sp_to_pt", "sp_suppressinfo",
    -- spinit.lua exports
    "escape_lua_pattern", "sp_to_bp", "bp_to_sp", "table_textvalue",
    "set_glue", "set_glue_values", "get_glue_value",
    "exit", "quit", "main_loop", "starttime",
    "prohibited_at_end", "prohibited_at_beginning",
    "luatex_version", "errcount", "warncount",
    -- sd-callbacks.lua hooks
    "stop_run_cb",
    -- sd-callbacks / sd-debug helpers (also cross-file)
    "save_color",
}

-- publisher.lua uses `local _ENV = setmetatable(M, {__index = _G})`, so
-- references such as `getprop`, `pdf_lineto`, `xml_escape` resolve to entries
-- on M that are merged in from publisher/*.lua submodules at the bottom of
-- the file (see the `for _, modname in ipairs({...})` loop). luacheck has no
-- way to follow that, so we declare the merged exports as readable globals
-- only inside publisher.lua.
-- qrencode.lua exposes its internal helpers when the global `testing` is
-- set — that's a deliberate hook used by the upstream luaqrcode test suite.
files["src/lua/barcodes/qrencode.lua"] = {
    read_globals = { "testing" },
}

-- barcodes.lua mixes tabs and spaces in its indentation — purely cosmetic.
files["src/lua/barcodes/barcodes.lua"] = {
    ignore = { "621" },
}

-- fnDimexpr in layout_functions_lxpath.lua loads `value = <expr>` via
-- `load(...)` and then reads the global `value`. luacheck cannot see that
-- write, so just declare it as a read global for this file.
files["src/lua/publisher/layout_functions_lxpath.lua"] = {
    read_globals = { "value" },
}
-- Same trick exists in the legacy layout_functions.lua. `csshtmltree` is
-- a similar load()-side-effect global produced by an embedded Lua snippet.
files["src/lua/publisher/layout_functions.lua"] = {
    read_globals = { "value", "csshtmltree" },
}

-- spinit.lua defines a number of cross-file globals (set_glue, exit, quit,
-- prohibited_at_end, ...). luacheck flags them as W131 ("unused global")
-- because they're declared but never read in this file.
files["src/lua/publisher/spinit.lua"] = {
    ignore = { "131" },
}

-- sd-debug.lua exists to hand out cross-file debug helpers (`w`,
-- `tracetable`, `showattributes`, …) — none are read in this file by design.
files["src/lua/common/sd-debug.lua"] = {
    ignore = { "131" },
}

files["src/lua/publisher.lua"] = {
    -- Most "unused implicit global" warnings in this file are project-globals
    -- (factor, tenpoint_sp, att_*, *_node, ...) that are read by other files
    -- but not by publisher.lua itself, so suppress W131 here.
    ignore = { "131" },
    -- `data` is the xpath context built in initialize_luatex_and_generate_pdf.
    -- It's read in this file *and* in submodules via `publisher.data`. We
    -- need write access to its sub-fields (data.xmldoc, data.vars, ...).
    globals = {
        data = { other_fields = true, read_only = false },
        -- ExtGState object refs are initialized here and only read elsewhere,
        -- but they're declared as readonly project-globals; allow writing.
        "GS_State_OP_On", "GS_State_OP_Off",
    },
    read_globals = {
        -- publisher.utilities
        "deepcopy", "copy_table_from_defaults", "insertion_sort",
        "merge", "merge_sort", "stable_sort",
        "flush_table", "flush_variable", "string_random",
        -- publisher.xml_helpers
        "xml_escape", "xml_to_string_newxpath", "xml_to_string",
        "xml_stringvalue", "fixup_xmlfile", "load_xml",
        "calculate_md5sum", "elementname", "element_contents",
        -- publisher.images
        "set_image_length", "calculate_image_width_height", "reload_image",
        "new_image", "validateimagetype", "get_fallback_image_name",
        "imageinfo",
        -- publisher.language
        "get_language", "get_languagecode", "set_mainlanguage",
        "get_languages_used",
        -- publisher.attributes
        "read_attribute", "get_attributes", "get_attribute",
        "set_attribute", "clear_attribute", "set_attributes",
        "set_attribute_recurse", "setprop", "getprop", "clearprop",
        -- publisher.structure_tree
        "bookmarkstotex", "get_action_node", "get_rolenum",
        "sort_struct_tree_by_page_order", "dump_struct_tree_xml",
        "writeStructElements", "get_page_labels_str",
        "mknumdest", "mkstringdest", "mkbookmarknodes",
        -- publisher.drawing
        "pdf_draw_pos", "pdf_circle_pos", "pdf_circle_pos_big",
        "pdf_curveto", "pdf_moveto", "pdf_lineto",
        "pdf_draw_pos_bp", "pdf_circle_pos_bp", "pdf_circle_pos_big_bp",
        "pdf_curveto_bp", "pdf_moveto_bp", "pdf_lineto_bp",
        "transparentcolorstack", "concat_transformation",
        "bgtext", "background", "frame", "clip",
        "circle_pdfstring", "circle_pdfstring_bp", "circle",
        "do_metapostimage", "mpbox", "box", "addhrule", "boxit",
        "colorbar", "montage", "matrix",
        "rotate", "rotateTd", "rotate_textblock",
        -- publisher.fontfamilies
        "get_fontname", "define_fontfamily", "define_default_fontfamily",
        -- publisher.dispatch
        "compile_match_pattern", "convert_pattern_to_selftest",
        "find_matching_pattern", "new_textformat", "dispatch",
        -- publisher.pages
        "page_initialized_p", "shipout", "output_absolute_position",
        "output_at", "place_at", "detect_pagetype", "initialize_page",
        "setup_page", "next_area", "new_page", "clearpage",
        "setpageresources", "dothingsbeforeoutput", "dothingsafteroutput",
        "set_pageformat", "get_remaining_height", "next_row",
        "empty_block", "emergency_block", "getheight",
        "less_or_equal_than_n_lines", "join_table_to_box", "vsplit",
        -- publisher.nodes
        "parse_html", "insert_nonmoving_whatsits", "bigger_glue_spec",
        "short_newline", "newline",
        "remove_first_whitespace", "remove_last_whitespace",
        "addstrut", "getfallbacks", "hbglyphlist", "getinstancename",
        "mknodes", "setsegmentdir", "add_rule",
        "bullet_hbox", "number_hbox", "whatever_hbox",
        "get_glue_size", "add_glue", "hss_glue", "make_glue",
        "finish_par", "hbkern", "fix_justification", "do_linebreak",
        "create_empty_vbox_width_width_height",
        "create_empty_hbox_with_width",
        "set_color_if_necessary", "set_fontfamily_if_necessary",
        "break_url",
        -- additional helpers used inside publisher.lua via _ENV
        "exit", "sp_to_bp",
        -- M-fields set by other modules (publisher/commands.lua etc.)
        "current_pagestore_name",
        -- ExtGState object refs initialized in publisher.lua, read in pages.lua
        "GS_State_OP_On", "GS_State_OP_Off",
    },
}

-- Files that are vendored / third-party — don't lint them.
exclude_files = {
    "src/lua/luxor.lua",
    "src/lua/socket_url.lua",
    "src/lua/ProFi.lua",
    "src/lua/uuid.lua",
    "src/lua/sampler.lua",
    "src/lua/nodetree.lua",
    "src/lua/shalocal.lua",
    -- generated / build artefacts
    "build/**",
    "lib/**",
    ".git/**",
}
