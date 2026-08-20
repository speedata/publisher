-- This file runs in the restricted user callback environment, where
-- register_callback is provided as a global.
---@diagnostic disable: undefined-global
register_callback("lookup_file", function(name)
    if name == "REWRITTEN-BY-CALLBACK.pdf" then
        return "_samplea.pdf"
    end
end)
