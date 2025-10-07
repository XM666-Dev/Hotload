env = {}
times = {}
for k, v in pairs(_G) do env[k] = v end
setfenv(1, env)

__loadonce = {}
dofile_once = function(filename)
    local result = nil
    local cached = __loadonce[filename]
    if cached ~= nil then
        result = cached[1]
    else
        times[filename] = CrossCall("hotload.file_get_write_time", filename, 0)
        local f, err = loadfile(filename)
        if f == nil then return f, err end
        result = f()
        __loadonce[filename] = {result}
        do_mod_appends(filename)
    end
    return result
end
__loaded = {}
dofile = function(filename)
    local f = __loaded[filename]
    if f == nil then
        times[filename] = CrossCall("hotload.file_get_write_time", filename, 0)
        f, err = loadfile(filename)
        if f == nil then return f, err end
        __loaded[filename] = f
    end
    local result = f()
    do_mod_appends(filename)
    return result
end
_G = env
times["%1"] = CrossCall("hotload.file_get_write_time", "%1", 0)
setfenv(0, env)
local success, f = pcall(loadfile, "%1")
if not success then f = nil end
if ____cached_func ~= nil then ____cached_func = f end

setfenv(1, g)
