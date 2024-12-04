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

--dofile_once("mods/hotload/NoitaPatcher/load.lua")
--local np = require("noitapatcher")
--np.CrossCallAdd("hotload.file_get_content", file_get_content)
--np.CrossCallAdd("hotload.file_get_write_time", file_get_write_time)

local ModTextFileSetContent = ModTextFileSetContent
local function make_hotload(filename)
    ModTextFileSetContent(filename, ModTextFileGetContent("mods/hotload/files/hotload.lua")
        :gsub('"%%(%d)"', function(s) return ("%q"):format(({ filename, ModTextFileGetContent(filename) or "" })[tonumber(s)]) end)
    )
end

local write = {}
for i, mod in ipairs(ModGetActiveModIDs()) do
    local filename = ("mods/%s/init.lua"):format(mod)
    make_hotload(filename)
    if file_is_exist(filename) then
        write[filename] = file_get_write_time(filename)
    end
end
local scripts = {
    "script_collision_trigger_hit",
    "script_material_area_checker_success",
    "script_damage_received",
    "script_death",
    "script_polymorphing_to",
    "script_inhaled_material",
    "script_material_area_checker_failed",
    "script_electricity_receiver_electrified",
    "script_source_file",
    "script_biome_entered",
    "script_electricity_receiver_switched",
    "script_kick",
    "script_shot",
    "script_teleported",
    "script_collision_trigger_timer_finished",
    "script_audio_event_dead",
    "script_item_picked_up",
    "script_damage_about_to_be_received",
    "script_physics_body_modified",
    "script_portal_teleport_used",
    "script_pressure_plate_change",
    "script_interacting",
    "script_wand_fired",
    "script_enabled_changed",
    "script_throw_item",
}
local found = { [""] = true }
function OnWorldPreUpdate()
    for i, entity in ipairs(EntityGetInRadius(0, 0, math.huge)) do
        for i, lua in ipairs(EntityGetComponent(entity, "LuaComponent") or {}) do
            for i, script in ipairs(scripts) do
                local filename = ComponentGetValue2(lua, script)
                if not found[filename] then
                    found[filename] = true
                    make_hotload(filename)
                    if file_is_exist(filename) then
                        write[filename] = file_get_write_time(filename)
                    end
                end
            end
        end
    end
    for filename, previous_time in pairs(write) do
        local time = file_get_write_time(filename)
        if time ~= previous_time then
            write[filename] = time
            local content = file_get_content(filename)
            if content ~= nil then ModTextFileSetContent(filename, content) end
        end
    end
end
