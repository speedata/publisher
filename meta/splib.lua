---@meta
-- Type definitions for the `splib` global, exposed by `luaglue.so` (see src/c/luaglue.c)
-- and implemented in src/go/splib/splib.go. This file is annotation-only and is not
-- loaded at runtime; lua-language-server picks it up via .luarc.json's workspace.library.

---@class splib
---@field markdownextensions? string[]  Configured markdown extensions; set by Layout `LoadFontfile`/`LoadMarkdown`-style commands.
splib = {}

---Append a directory to the file-lookup search path.
---@param dirname string
function splib.add_dir(dirname) end

---Re-scan all configured directories and (re)build the internal file list.
---Reads PUBLISHER_BASE_PATH, SP_FONT_PATH and SP_EXTRA_DIRS from the environment.
function splib.buildfilelist() end

---Test whether `haystack` contains `needle` (plain substring match, no regex).
---@param haystack string
---@param needle string
---@return boolean
function splib.contains(haystack, needle) end

---Convert an SVG image to a usable form and return the (possibly cached) output path.
---@param filename string
---@return string? converted Output path on success.
function splib.convert_svg_image(filename) end

---Convert string `contents` via the named handler and return the conversion result.
---@param contents string
---@param handler string
---@return string converted
function splib.convertcontents(contents, handler) end

---Convert an image file via the named handler and return the (cached) output path.
---@param filename string
---@param handler string
---@return string? converted
function splib.convertimage(filename, handler) end

---Number of errors logged so far in this run.
---@return integer
function splib.errcount() end

---Log an error and increment the error counter. Extra varargs are key/value pairs
---that get included in the structured log record.
---@param message string
---@param ... any
function splib.error(message, ...) end

---Convert HTML-style markup to well-formed XML by passing through Go's encoding/xml
---in non-strict, HTML-auto-close mode.
---@param input string
---@return string? xml
function splib.htmltoxml(input) end

---Return the list of font filenames known to the file-lookup system.
---@return string[]
function splib.listfonts() end

---Read an XML file and return it parsed as a nested Lua table. Tags become numerically
---indexed children; attributes are stored as string-keyed entries on the node.
---@param filename string
---@param filetype? string  Free-text label used in log output, e.g. `"layout instructions"` or `"data"`.
---@param ignoreeol? string Pass `"true"` to drop EOL whitespace.
---@return table? root
function splib.load_xmlfile(filename, filetype, ignoreeol) end

---Parse an XML string and return the resulting node tree.
---@param xml string
---@return table? root
function splib.loadxmlstring(xml) end

---Structured logging entry point. Levels: `"message"`/`"notice"`, `"info"`, `"debug"`,
---`"warning"`/`"warn"`, `"error"`. Extra varargs are key/value pairs.
---@param level "message"|"notice"|"info"|"debug"|"warning"|"warn"|"error"
---@param message string
---@param ... any
function splib.log(level, message, ...) end

---Lower-case `text` using the Unicode full case mappings.
---@param text string
---@return string? lowercased
function splib.lowercase(text) end

---Resolve a logical filename through the file-lookup system to its absolute path,
---or `nil` if not found.
---@param filename string
---@return string? fullpath
function splib.lookupfile(filename) end

---Render Markdown text to HTML, honouring `splib.markdownextensions` for the
---enabled goldmark extensions and highlighting options.
---@param md string
---@return string? html
function splib.markdown(md) end

---Test whether `text` matches the Go regular expression `pattern`.
---@param text string
---@param pattern string  Go-flavoured regexp.
---@return boolean
function splib.matches(text, pattern) end

---Parse an HTML fragment plus CSS and emit it as a nested Lua table tree
---(no surrounding `<body>` wrapping).
---@param html string
---@param css string
---@return table? tree
function splib.parse_raw_html_text(html, css) end

---Like `parse_raw_html_text`, but wraps the input in `<body>…</body>` first.
---@param html string
---@param css string
---@return table? tree
function splib.parse_html_text(html, css) end

---@class SplibReloadImageArgs
---@field filename string
---@field width integer
---@field height integer
---@field imagetype string
---@field resizehandler? string

---Resize/convert an existing image and return the new filename.
---@param args SplibReloadImageArgs
---@return string? newfilename
function splib.reloadimage(args) end

---Replace all matches of the Go regexp `pattern` in `text` with `replacement`.
---Backreferences use `$1`, `$2`, … (numeric, like Go's regexp package).
---@param text string
---@param pattern string
---@param replacement string
---@return string? result
function splib.replace(text, pattern, replacement) end

---Apply Unicode bidi segmentation to `text`. Returns an array of `{direction, run}`
---pairs where `direction` is `0` (LTR) or `1` (RTL) and `run` is the substring.
---@param text string
---@param dir? 0|1|2  Default direction hint: 0=neutral, 1=LTR, 2=RTL.
---@return [0|1, string][]? runs
function splib.segmentize_text(text, dir) end

---Release native resources held by splib (called at shutdown).
function splib.teardown() end

---Split `text` at every match of the Go regexp `pattern`, returning the surrounding
---segments. The matches themselves are dropped.
---@param text string
---@param pattern string  Go-flavoured regexp.
---@return string[] segments
function splib.tokenize(text, pattern) end

---Upper-case `text` using the Unicode full case mappings (Straße -> STRASSE).
---@param text string
---@return string? uppercased
function splib.uppercase(text) end

---Number of warnings logged so far in this run.
---@return integer
function splib.warncount() end
