local __modified = {}
local g = {}
for k, v in pairs(_G) do
    g[k] = v
end
local function newenv()
    local env = {}
    for k, v in pairs(g) do
        if type(v) == "table" then
            local t = v
            v = {}
            for key, value in pairs(t) do
                v[key] = value
            end
        end
        env[k] = v
    end
    setfenv(function()
        function loadfile(...)
            __modified[...] = g.CrossCall("hotload.file_get_write_time", ...)
            return g.setfenv(g.loadfile(...), env)
        end

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
    end, env)()
    return env
end
local env
local function reload()
    env = newenv()
    local filename = "%s"
    ModTextFileSetContent(filename, CrossCall("hotload.file_get_content", filename))
    __modified[filename] = CrossCall("hotload.file_get_write_time", filename)
    env.__loaded[filename] = setfenv(loadfile(filename), env)
    env.dofile(filename)
end
reload()
setmetatable(_G, {
    __index = function(t, k)
        local modified = false
        for filename, previous_time in pairs(__modified) do
            local time = CrossCall("hotload.file_get_write_time", filename)
            if time ~= previous_time then
                __modified[filename] = time
                modified = true
            end
        end
        if modified then
            reload()
            print("HOTLOADED!")
        end
        return env[k]
    end,
})
--to do: io & do_mod_appends
