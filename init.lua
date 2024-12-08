dofile_once("mods/hotload/files/file.lua")

local content = file_get_content("save00/mod_config.xml")
local xml = dofile_once("mods/hotload/files/nxml.lua").parse(content)
for mod in xml:each_child() do
    if mod.attr.name == "hotload" then
        xml:remove_child(mod)
        table.insert(xml.children, 1, mod)
        break
    end
end
file_set_content("save00/mod_config.xml", tostring(xml))

for i, mod in ipairs(ModGetActiveModIDs()) do
    local filename = ("mods/%s/init.lua"):format(mod)
    if ModDoesFileExist(filename) then make_hotload(filename) end
end

dofile_once("mods/hotload/NoitaPatcher/load.lua")
local np = require("noitapatcher")
np.CrossCallAdd("hotload.file_get_content", file_get_content)
np.CrossCallAdd("hotload.file_is_exist", file_is_exist)
np.CrossCallAdd("hotload.file_get_write_time", file_get_write_time)
np.CrossCallAdd("hotload.file_update", file_update)
function OnWorldInitialized()
    EntityAddComponent2(EntityCreateNew(), "LuaComponent", { script_source_file = "mods/hotload/files/component.lua" })
end

local g = {}
for k, v in pairs(_G) do
    g[k] = v
    if type(v) == "function" then pcall(setfenv, v, g) end
end
setfenv(1, g)
for k in pairs(g) do
    _G[k] = nil
end
local env = {}
local previous_time = file_get_write_time("mods/hotload/terminal.lua", 0)
setmetatable(_G, {
    __index = function(t, k)
        local time = file_get_write_time("mods/hotload/terminal.lua", previous_time)
        if time ~= nil then
            previous_time = time
            env = setmetatable({}, { __index = g })
            local f = loadfile("mods/hotload/terminal.lua")
            if f ~= nil then setfenv(f, env)() end
        end
        return function(...)
            local f = env[k]
            if f ~= nil then f(...) end
            return g[k](...)
        end
    end,
})
