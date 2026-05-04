-- Sampling-based Lua profiler for LuaTeX (Lua 5.3)
-- Uses debug.sethook with instruction counting for low overhead.
--
-- Usage:
--   sampler = require "sampler"
--   sampler.start()       -- default: sample every 10000 VM instructions
--   ... code to profile ...
--   sampler.stop()
--   sampler.report("profile.txt")

---@class sampler_module
local sampler = {}

---@type table<string, integer>
local samples_by_func = {}
---@type table<string, integer>
local samples_by_line = {}
---@type integer
local total_samples = 0
---@type number
local start_time

local getinfo = debug.getinfo

-- Debug hook installed by `start`: bumps the per-function and per-line
-- sample counters for the function currently on the stack.
---@return nil
local function hook()
    local info = getinfo(2, "Sln")
    if not info then return end
    local src = info.short_src or "?"
    local name = info.name or ("anon:" .. (info.linedefined or 0))
    local line = info.currentline or 0

    local fkey = src .. " :: " .. name
    samples_by_func[fkey] = (samples_by_func[fkey] or 0) + 1

    local lkey = src .. ":" .. line
    samples_by_line[lkey] = (samples_by_line[lkey] or 0) + 1

    total_samples = total_samples + 1
end

-- Starts sampling: installs the debug hook to fire every `interval` VM
-- instructions and resets the counters.
---@param interval? integer VM instructions between samples (default 10000).
---@return nil
function sampler.start(interval)
    interval = interval or 10000
    samples_by_func = {}
    samples_by_line = {}
    total_samples = 0
    start_time = os.clock()
    debug.sethook(hook, "", interval)
end

-- Stops sampling and returns the elapsed wall-clock time in seconds.
---@return number elapsed
function sampler.stop()
    debug.sethook()
    return os.clock() - start_time
end

-- Returns the entries of `tbl` as an array sorted by descending count.
---@param tbl table<string, integer>
---@return { key: string, count: integer }[]
local function sorted_entries(tbl)
    local entries = {}
    for k, v in pairs(tbl) do
        entries[#entries + 1] = { key = k, count = v }
    end
    table.sort(entries, function(a, b) return a.count > b.count end)
    return entries
end

-- Writes a human-readable profile report (top functions and top lines)
-- to `filename`.
---@param filename? string Output file path; defaults to `"profile.txt"`.
---@param limit? integer Maximum entries per section; defaults to 40.
---@return nil
function sampler.report(filename, limit)
    limit = limit or 40
    filename = filename or "profile.txt"
    local elapsed = os.clock() - start_time

    local file, err = io.open(filename, "w")
    if not file then
        print("[sampler] Cannot open " .. filename .. ": " .. (err or ""))
        return
    end

    file:write(string.format("Sampling profiler report  --  %d samples in %.2fs\n", total_samples, elapsed))
    file:write(string.format("Estimated sample interval: %.1f us\n\n", elapsed / total_samples * 1e6))

    -- By function
    file:write("=== Top functions by sample count ===\n")
    file:write(string.format("%-6s  %-6s  %s\n", "pct", "count", "function"))
    file:write(string.rep("-", 90) .. "\n")
    local funcs = sorted_entries(samples_by_func)
    for i = 1, math.min(limit, #funcs) do
        local e = funcs[i]
        file:write(string.format("%5.1f%%  %6d  %s\n", e.count / total_samples * 100, e.count, e.key))
    end

    -- By line
    file:write("\n=== Top lines by sample count ===\n")
    file:write(string.format("%-6s  %-6s  %s\n", "pct", "count", "location"))
    file:write(string.rep("-", 90) .. "\n")
    local lines = sorted_entries(samples_by_line)
    for i = 1, math.min(limit, #lines) do
        local e = lines[i]
        file:write(string.format("%5.1f%%  %6d  %s\n", e.count / total_samples * 100, e.count, e.key))
    end

    file:close()
    print(string.format("[sampler] %d samples, report written to %s", total_samples, filename))
end

return sampler
