-- User defined callbacks, loaded from the file given with the `luafile`
-- option (publisher.cfg or --luafile on the command line).
--
--  usercallbacks.lua
--  speedata publisher
--
--  For a list of authors see `git blame'
--  See file COPYING in the root directory for license info.
--
-- The file is loaded in a restricted environment: it only sees the functions
-- listed in make_env() below, most importantly register_callback(). This is a
-- contract, not a security boundary: everything in the environment is official
-- API, everything else is invisible and thus visibly unsupported.
--
-- Only plain values (strings, numbers, flat tables of those) cross the
-- boundary between the publisher and the user callbacks, so the callbacks
-- stay decoupled from the publisher internals.

file_start("usercallbacks.lua")

---@class usercallbacks_module
local M = {}

-- The version of the callback API, exposed to the user file as api.version.
M.apiversion = 1

-- Registered callbacks, name → function.
---@type table<string, function>
M.callbacks = {}

-- Path of the loaded user callback file (for error messages).
local hooksfilename

-- First hex digits of the md5 sum of the user callback file. Mixed into the
-- image cache file names, so a changed callback file invalidates the cache.
local hookshash = ""

local allowed_callbacks = {
    lookup_file = true,
    image_handler = true,
    resize_handler = true,
}

---@class UserImageJob
---@field input string Full path of the file to convert.
---@field extension string Lowercased file name extension, `""` if none.
---@field outputbase string Path in the image cache (without extension) reserved for the output file.
---@field imagetype string? Image type (embedded image contents and resize_handler).
---@field width integer? Target width in pixels (resize_handler only).
---@field height integer? Target height in pixels (resize_handler only).

---@class UserImageJobResult
---@field command (string|number)[]? The command and its arguments, one entry each.
---@field output string The file that the command creates (or an existing file when `command` is absent).

-- Registers the function fn for the callback name. Called by the user file.
---@param name string
---@param fn function
local function register_callback(name, fn)
    if not allowed_callbacks[name] then
        main.log("error", string.format("register_callback: unknown callback name %q", tostring(name)))
        return
    end
    if type(fn) ~= "function" then
        main.log("error", string.format("register_callback: second argument for %q must be a function", name))
        return
    end
    M.callbacks[name] = fn
end

-- The environment the user callback file runs in. No _G, no require, no
-- publisher internals.
local function make_env()
    return {
        register_callback = register_callback,
        log = function(...)
            main.log(...)
        end,
        api = { version = M.apiversion },
        string = string,
        table = table,
        math = math,
        tonumber = tonumber,
        tostring = tostring,
        error = error,
        assert = assert,
        pcall = pcall,
        pairs = pairs,
        ipairs = ipairs,
        next = next,
        type = type,
        select = select,
        io = { open = io.open, lines = io.lines },
        os = { getenv = os.getenv },
    }
end

-- Returns the registered callback function or nil.
---@param name string
---@return function?
function M.get(name)
    return M.callbacks[name]
end

-- Calls the registered callback name (if any) in protected mode. An error
-- inside the callback is reported with the file name and yields nil.
---@param name string
---@return any
function M.call(name, ...)
    local fn = M.callbacks[name]
    if not fn then
        return nil
    end
    local ok, ret = pcall(fn, ...)
    if not ok then
        main.log(
            "error",
            string.format("Error in user callback %q (%s): %s", name, hooksfilename or "?", tostring(ret))
        )
        return nil
    end
    return ret
end

-- Wraps kpse.find_file so that the lookup_file callback can rewrite the
-- requested file name before the regular lookup runs. The callback result is
-- memoized, since the same name is often requested several times.
local function install_lookup_file()
    local original_find_file = kpse.find_file
    local memo = {}
    kpse.find_file = function(filename)
        local newname = memo[filename]
        if newname == nil then
            newname = M.call("lookup_file", filename)
            if type(newname) ~= "string" or newname == "" then
                newname = false
            end
            memo[filename] = newname
        end
        return original_find_file(newname or filename)
    end
end

-- Loads the user callback file in the restricted environment.
---@param filename string
---@return boolean success
function M.load(filename)
    local path = kpse.find_file(filename)
    if not path then
        main.log("error", string.format("Cannot find the callback file %q (luafile option)", filename))
        return false
    end
    local f, msg = io.open(path, "rb")
    if not f then
        main.log("error", msg or string.format("Cannot open the callback file %q", path))
        return false
    end
    local contents = f:read("*a")
    f:close()
    hooksfilename = path
    hookshash = md5.sumhexa(contents):sub(1, 8)
    local chunk, errmsg = load(contents, "@" .. path, "t", make_env())
    if not chunk then
        main.log("error", string.format("Cannot load the callback file: %s", errmsg))
        return false
    end
    local ok, callerr = pcall(chunk)
    if not ok then
        main.log("error", string.format("Error while running the callback file %q: %s", path, tostring(callerr)))
        return false
    end
    main.log("info", "Loaded user callbacks", "filename", path)
    if M.callbacks.lookup_file then
        install_lookup_file()
    end
    return true
end

-- Creates the directory path (and its parents) if necessary.
---@param path string
local function mkdirp(path)
    if lfs.attributes(path, "mode") == "directory" then
        return
    end
    local parent = path:match("^(.*)[/\\][^/\\]+$")
    if parent and parent ~= "" and parent ~= path then
        mkdirp(parent)
    end
    lfs.mkdir(path)
end

-- Builds the path (without extension) in the image cache that a conversion
-- job may write its output to. The name contains a hash over the full input
-- path, all extra parameters and the user callback file, so different
-- conversions never collide and a changed callback file invalidates the
-- cache.
---@param input string Full path of the input file.
---@return string outputbase
function M.outputbase(input, ...)
    local imgcache = os.getenv("IMGCACHE") or "imagecache"
    local parts = { hookshash, input, ... }
    for i = 1, #parts do
        parts[i] = tostring(parts[i])
    end
    local hash = md5.sumhexa(table.concat(parts, "\0")):sub(1, 8)
    local basename = input:match("([^/\\]+)$") or input
    basename = basename:match("^(.+)%.[^.]+$") or basename
    return imgcache .. "/" .. basename .. "-" .. hash
end

-- Validates the table an image_handler/resize_handler callback returned and
-- runs the command (with caching and error reporting on the Go side).
-- Returns the name of the converted file or nil.
---@param name string Callback name, for error messages.
---@param res any Return value of the callback.
---@return string? filename
function M.run_imagejob(name, res)
    if type(res) ~= "table" then
        main.log("error", string.format("The %q callback must return a table (or nil)", name))
        return nil
    end
    local output = res.output
    if type(output) ~= "string" or output == "" then
        main.log("error", string.format("The %q callback must return the output file name in `output`", name))
        return nil
    end
    if res.command == nil then
        -- No command: use the (existing) file as it is.
        if lfs.attributes(output, "mode") ~= "file" then
            main.log("error", string.format("The %q callback returned the non-existing file %q", name, output))
            return nil
        end
        return output
    end
    if type(res.command) ~= "table" or #res.command == 0 then
        main.log("error", string.format("`command` returned by the %q callback must be a non-empty table", name))
        return nil
    end
    local argv = {}
    for i, v in ipairs(res.command) do
        if type(v) == "number" then
            v = tostring(v)
        end
        if type(v) ~= "string" then
            main.log(
                "error",
                string.format("Entry %d of `command` returned by the %q callback must be a string", i, name)
            )
            return nil
        end
        argv[i] = v
    end
    return splib.runimagecommand(output, table.unpack(argv))
end

-- Asks the image_handler callback to convert embedded image contents. The
-- contents are written to a file in the image cache first, which is passed to
-- the callback as job.input. The second return value tells the caller whether
-- the callback handled the job at all (false: fall back to the imagehandler
-- configuration).
---@param contents string The embedded image contents.
---@param imagetype string The image type given in the layout.
---@return string? filename
---@return boolean handled
function M.convert_contents(contents, imagetype)
    if not M.callbacks.image_handler or type(contents) ~= "string" then
        return nil, false
    end
    local imgcache = os.getenv("IMGCACHE") or "imagecache"
    local hash = md5.sumhexa(table.concat({ hookshash, imagetype, contents }, "\0")):sub(1, 16)
    local outputbase = imgcache .. "/embedded-" .. hash
    local inputfile = outputbase .. ".input"
    mkdirp(imgcache)
    local f, msg = io.open(inputfile, "wb")
    if not f then
        main.log("error", msg or string.format("Cannot write embedded image contents to %q", inputfile))
        return nil, true
    end
    f:write(contents)
    f:close()
    local job = {
        input = inputfile,
        extension = "",
        imagetype = imagetype,
        outputbase = outputbase,
    }
    local res = M.call("image_handler", job)
    if res == nil then
        return nil, false
    end
    return M.run_imagejob("image_handler", res), true
end

file_end("usercallbacks.lua")

return M
