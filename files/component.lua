dofile_once("mods/hotload/files/file.lua")

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
____cached_func = function()
    for i, entity in ipairs(EntityGetInRadius(0, 0, math.huge)) do
        for i, lua in ipairs(EntityGetComponentIncludingDisabled(entity, "LuaComponent") or {}) do
            for i, script in ipairs(scripts) do
                local filename = ComponentGetValue2(lua, script)
                if not found[filename] then
                    found[filename] = true
                    make_hotload(filename)
                end
            end
        end
    end
end
____cached_func()
