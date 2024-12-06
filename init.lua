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
function OnWorldInitialized()
    EntityAddComponent2(EntityCreateNew(), "LuaComponent", { script_source_file = "mods/hotload/files/component.lua" })
end

local ModTextFileSetContent = ModTextFileSetContent
function OnWorldPreUpdate()
end
