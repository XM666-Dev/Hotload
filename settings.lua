dofile("data/scripts/lib/mod_settings.lua")

local mod_id = "hotload"
mod_settings_version = 1
mod_settings =
{
    {
        --id = "hotload_mod_id",
        --ui_name = "Hotload mod id",
        --ui_description = "For init.lua.",
        --value_default = "",
        --text_max_length = 20,
        --allowed_characters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_0123456789",
        --scope = MOD_SETTING_SCOPE_RUNTIME_RESTART,
    },
}

function ModSettingsUpdate(init_scope)
    mod_settings_update(mod_id, mod_settings, init_scope)
end

function ModSettingsGuiCount()
    return mod_settings_gui_count(mod_id, mod_settings)
end

function ModSettingsGui(gui, in_main_menu)
    mod_settings_gui(mod_id, mod_settings, gui, in_main_menu)
end
