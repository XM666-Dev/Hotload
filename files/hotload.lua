local env
local times

local next_query_time = GameGetRealWorldTimeSinceStarted()
local g = _G
local t = setmetatable({}, {
    __index = function(t, k)
        local query_time = GameGetRealWorldTimeSinceStarted()
        if query_time > next_query_time then
            next_query_time = query_time + 1
            for filename, time in pairs(times) do
                if CrossCall("hotload.file_get_write_time", filename, time) then
                    print("Reloading %1")

                    --%3
                    --%4

                    if ____cached_func == nil then
                        local success, error = pcall(f)
                        if not success then print_error(error) end

                        do_mod_appends("%1")
                    end

                    setfenv(0, t)

                    break
                end
            end
        end
        local v = env[k]
        if type(v) == "function" then
            return function(...)
                setfenv(0, env)
                local list = { pcall(v, ...) }
                setfenv(0, t)
                if list[1] then
                    return unpack(list, 2)
                else
                    print_error(unpack(list, 2))
                end
            end
        end
        return v
    end,
    __newindex = function(t, k, v)
        env[k] = v
    end,
})

--ModTextFileSetContent("%1", %2)
--%4

local success, error = pcall(f)
if not success then print_error(error) end

setfenv(0, t)
