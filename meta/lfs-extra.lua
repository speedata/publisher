---@meta
-- LuaTeX extends the stock LuaFileSystem library with two convenience
-- functions (LuaTeX manual, "The lfs library"). The TeXLuaCATS library
-- does not declare them. Worth a PR upstream. This file is
-- annotation-only and never loaded at runtime.

-- Returns true if the given path exists and is a directory.
---@param filename string
---@return boolean
function lfs.isdir(filename) end

-- Returns true if the given path exists and is a file.
---@param filename string
---@return boolean
function lfs.isfile(filename) end
