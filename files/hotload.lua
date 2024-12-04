local env
local written_time
local raw_filename = "%1"
local g = {}
for k, v in pairs(_G) do
    g[k] = v
end
local function load()
    env = {}
    for k, v in pairs(g) do
        env[k] = v
    end
    return setfenv(function()
        written_time = {}
        loadfile = function(...)
            local time = g.CrossCall("hotload.file_get_write_time", ...)
            if time ~= "0" then written_time[...] = time end
            local f = g.loadfile(...)
            if f ~= nil then return g.setfenv(f, env) end
        end
        __loadonce = {}
        dofile_once = function(filename)
            local result = nil
            local cached = __loadonce[filename]
            if cached ~= nil then
                result = cached[1]
            else
                local f, err = loadfile(filename)
                if f == nil then return f, err end
                result = f()
                __loadonce[filename] = { result }
                do_mod_appends(filename)
            end
            return result
        end
        __loaded = {}
        dofile = function(filename)
            local f = __loaded[filename]
            if f == nil then
                f, err = loadfile(filename)
                if f == nil then return f, err end
                __loaded[filename] = f
            end
            local result = f()
            do_mod_appends(filename)
            return result
        end
        _G = env
        local success, f = pcall(loadfile, raw_filename)
        if not success then f = nil end
        if g.____cached_func ~= nil then ____cached_func = f end
        return f
    end, env)()
end
ModTextFileSetContent(raw_filename, "%2")
local success, error = pcall(load())
if not success then print_error(error) end
setmetatable(_G, {
    __index = function(t, k)
        local written = false
        for filename, previous_time in pairs(written_time) do
            local time = CrossCall("hotload.file_get_write_time", filename)
            if time ~= previous_time then
                written = true
                if filename == raw_filename then
                    local content = CrossCall("hotload.file_get_content", filename)
                    if content ~= nil then g.ModTextFileSetContent(filename, content) end
                end
            end
        end
        if written then
            print("Reloading " .. raw_filename)
            if g.____cached_func ~= nil then
                load()
            else
                local success, error = pcall(load())
                if not success then print_error(error) end
                do_mod_appends(raw_filename)
            end
        end
        return env[k]
    end,
})
____cached_func = nil
dofile = nil
