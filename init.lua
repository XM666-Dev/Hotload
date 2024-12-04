dofile_once("mods/hotload/NoitaPatcher/load.lua")
local np = require("noitapatcher")
local nxml = dofile_once("mods/hotload/files/nxml.lua")
local ffi = require("ffi")

ffi.cdef [[
typedef unsigned long DWORD;
typedef void* HANDLE;
typedef int BOOL;
typedef struct _FILETIME {
    DWORD dwLowDateTime;
    DWORD dwHighDateTime;
} FILETIME, *PFILETIME, *LPFILETIME;

HANDLE CreateFileA(
    const char* lpFileName,
    DWORD dwDesiredAccess,
    DWORD dwShareMode,
    void* lpSecurityAttributes,
    DWORD dwCreationDisposition,
    DWORD dwFlagsAndAttributes,
    HANDLE hTemplateFile
);

BOOL GetFileTime(
    HANDLE hFile,
    LPFILETIME lpCreationTime,
    LPFILETIME lpLastAccessTime,
    LPFILETIME lpLastWriteTime
);

BOOL CloseHandle(HANDLE hObject);
]]

local function file_get_content(filename)
    local file = io.open(filename, "r")
    if file == nil then return end
    local content = file:read "*a"
    file:close()
    return content
end
local function file_set_content(filename, content)
    local file = io.open(filename, "w")
    if file == nil then return end
    file:write(content)
    file:close()
end

np.CrossCallAdd("hotload.file_get_write_time", function(filename)
    local OPEN_EXISTING = 3
    local handle = ffi.C.CreateFileA(filename, 0, 0, nil, OPEN_EXISTING, 0, nil)
    local write_time = ffi.new("FILETIME[1]")
    ffi.C.GetFileTime(handle, nil, nil, write_time)
    ffi.C.CloseHandle(handle)
    return tostring(ffi.cast("long long*", write_time)[0]):sub(1, -3)
end)
np.CrossCallAdd("hotload.file_get_content", file_get_content)

local content = file_get_content("save00/mod_config.xml")
local xml = nxml.parse(content)
for mod in xml:each_child() do
    if mod.attr.name == "hotload" then
        xml:remove_child(mod)
        table.insert(xml.children, 1, mod)
        break
    end
end
file_set_content("save00/mod_config.xml", tostring(xml))

local ModTextFileSetContent = ModTextFileSetContent
local function make_hotload(filename)
    ModTextFileSetContent(filename, ModTextFileGetContent("mods/hotload/files/hotload.lua")
        :gsub('"%%(%d)"', function(s) return ("%q"):format(({ filename, ModTextFileGetContent(filename) or "" })[tonumber(s)]) end)
    )
end

make_hotload(("mods/%s/init.lua"):format(ModSettingGet("hotload.hotload_mod_id")))

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
                end
            end
        end
    end
end
