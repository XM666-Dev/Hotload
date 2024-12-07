local g = {}
for k, v in pairs(_G) do
    g[k] = v
end
setfenv(1, g)
for k in pairs(g) do
    _G[k] = nil
end

local env
local times
local f = loadfile
function loadfile(...)
    local time = CrossCall("hotload.file_get_write_time", ...)
    if CrossCall("hotload.not_equal", time, 0) then times[...] = time end
    local f = f(...)
    if f ~= nil then return setfenv(f, env) end
end

local function load()
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
    local success, f = pcall(loadfile, "%1")
    if not success then f = nil end
    if ____cached_func ~= nil then ____cached_func = f end
    return f
end

--ModTextFileSetContent("%1", %2)

env = {}
times = {}
for k, v in pairs(g) do env[k] = v end
local f = setfenv(load, env)()

local success, error = pcall(f)
if not success then print_error(error) end

setmetatable(_G, {
    __index = function(t, k)
        for filename, previous_time in pairs(times) do
            local time = CrossCall("hotload.file_get_write_time", filename)
            if CrossCall("hotload.not_equal", time, previous_time) then
                --%3

                print("Reloading %1")

                env = {}
                times = {}
                for k, v in pairs(g) do env[k] = v end
                local f = setfenv(load, env)()

                if ____cached_func == nil then
                    local success, error = pcall(f)
                    if not success then print_error(error) end

                    do_mod_appends("%1")
                end

                break
            end
        end
        return env[k]
    end,
})
