--- This is the location for file related callbacks.
-- TeX uses the kpathsea library, which I disable right away (`texconfig.kpse_init=false` in sdini.lua).
-- We still use the namespace kpse.
--
--  sd-callbacks.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.

-- This file is loaded from sdini.lua, which runs before publisher.lua
-- and before spinit.lua finishes wiring up tex.sp etc. So we cannot
-- `require("publisher")` here at module-load time — the require would
-- recursively load publisher.lua too early. The callbacks themselves
-- only fire at typesetting time (long after publisher.lua has loaded),
-- so they require it lazily on first invocation.
local publisher

-- necessary callbacks if we want to use LuaTeX without kpathsea

local function reader(asked_name)
    return {
        file = io.open(asked_name, "rb"),
        reader = function(t)
            local f = t.file
            return f:read("*l")
        end,
        close = function(t)
            t.file:close()
        end,
    }
end

local function find_generic_file(asked_name)
    local file = kpse.find_file(asked_name)
    return file
end

local function return_asked_name(asked_name)
    return asked_name
end

local function read_font_file(name)
    local f = io.open(name, "rb")
    local buf = f:read("*all")
    f:close()
    return true, buf, buf:len()
end

local function find_read_file(id_number, asked_name)
    local file = kpse.find_file(asked_name)
    return file
end
function find_write_file(id_number, asked_name)
    return asked_name
end
local function read_other_file(name)
    return true, "", 0
end

callback.register("page_order_index", function(pagenum)
    publisher = publisher or require("publisher")
    local ppt = publisher.pagenum_tbl
    return ppt[pagenum]
end)

callback.register("open_read_file", reader)

callback.register("find_opentype_file", return_asked_name)
callback.register("find_type1_file", return_asked_name)
callback.register("find_output_file", return_asked_name)

callback.register("read_opentype_file", read_font_file)
callback.register("read_type1_file", read_font_file)

callback.register("find_write_file", find_write_file)

callback.register("find_read_file", find_read_file)

for _, t in ipairs({
    "find_font_file",
    "find_vf_file",
    "find_format_file",
    "find_map_file",
    "find_enc_file",
    "find_sfd_file",
    "find_pk_file",
    "find_data_file",
    "find_image_file",
    "find_truetype_file",
}) do
    callback.register(t, find_generic_file)
end
for _, t in ipairs({
    "read_vf_file",
    "read_sdf_file",
    "read_pk_file",
    "read_data_file",
    "read_font_file",
    "read_map_file",
}) do
    callback.register(t, read_other_file)
end

local show_progress = os.getenv("SP_PROGRESS") == "1" and os.getenv("SP_VERBOSITY") == nil
local progress_start_time = os.clock()

local function format_duration(seconds)
    local m = math.floor(seconds / 60)
    local s = math.floor(seconds % 60)
    return string.format("%d:%02d", m, s)
end

function print_page_number()
    publisher = publisher or require("publisher")
    main.log("info", "Shipout page", "page", tostring(publisher.current_pagenumber))
    if show_progress then
        local page = publisher.current_pagenumber
        local elapsed = os.clock() - progress_start_time
        local line
        if publisher.expected_pages and publisher.expected_pages > 0 then
            local pct = math.floor(page / publisher.expected_pages * 100)
            if pct > 100 then
                pct = 100
            end
            line = string.format(
                "\rPage %d/%d (%d%%) -- %s",
                page,
                publisher.expected_pages,
                pct,
                format_duration(elapsed)
            )
            if publisher.previous_duration then
                line = line .. "/" .. format_duration(publisher.previous_duration)
            end
        else
            line = string.format("\rPage %d -- %s", page, format_duration(elapsed))
        end
        -- pad with spaces to clear previous longer line
        io.write(line .. "          ")
        io.flush()
    end
end

function pluralize(what, count)
    if count ~= 1 then
        what = what .. "s"
    end
    return string.format("%d %s", count, what)
end

function stop_run_cb()
    if show_progress then
        -- clear the progress line
        io.write("\r                                                            \r")
        io.flush()
    end
    print(
        string.format(
            "Finished with %s and %s",
            pluralize("error", errcount or 0),
            pluralize("warning", warncount or 0)
        )
    )
    if not status.output_file_name then
        print("No output written")
    else
        print(
            string.format(
                "Output written on %s (%d pages, %d bytes)",
                status.output_file_name,
                status.total_pages,
                status.pdf_gone
            )
        )
    end
    print(string.format("Transcript written to %s-protocol.xml", tex.jobname))
end

callback.register("start_page_number", print_page_number)
callback.register("stop_page_number", false)
callback.register("stop_run", stop_run_cb)
