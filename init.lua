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

local ffi = require("ffi")
local GENERIC_READ = 0x80000000
local FILE_SHARE_READ_WRITE = 0x00000003
local CREATE_ALWAYS = 2
local FILE_FLAG_DELETE_ON_CLOSE = 0x04000000
local handle = ffi.C.CreateFileA("terminal.lua", GENERIC_READ, FILE_SHARE_READ_WRITE, nil, CREATE_ALWAYS, FILE_FLAG_DELETE_ON_CLOSE, nil)
local previous_open_time = 0
dofile_once("data/scripts/debug/keycodes.lua")
ffi.cdef [[
    typedef long LONG;
    typedef LONG* PLONG;
    DWORD SetFilePointer(
        HANDLE hFile,
        LONG lDistanceToMove,
        PLONG lpDistanceToMoveHigh,
        DWORD dwMoveMethod
    );
]]
local FILE_BEGIN = 0

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
local previous_write_time = file_get_write_time("terminal.lua", 0)
setmetatable(_G, {
    __index = function(t, k)
        local open_time = GameGetRealWorldTimeSinceStarted()
        if InputIsKeyJustDown(Key_GRAVE) and open_time > previous_open_time then
            previous_open_time = open_time + 1
            io.popen("terminal.lua")
        end
        local write_time = file_get_write_time("terminal.lua", previous_write_time)
        if write_time ~= nil then
            previous_write_time = write_time
            env = setmetatable({}, { __index = g })

            local size
            for i = 1, 512 do
                size = ffi.C.GetFileSize(handle, nil)
                if size > 0 then
                    break
                end
            end
            if size == 0xffffffff then size = 0 end
            local buffer = ffi.new("char[?]", size)
            ffi.C.SetFilePointer(handle, 0, nil, FILE_BEGIN)
            ffi.C.ReadFile(handle, buffer, size, nil, nil)
            ModTextFileSetContent("mods/hotload/terminal.lua", ffi.string(buffer, size))

            local f = loadfile("mods/hotload/terminal.lua")
            if f ~= nil then setfenv(f, env)() end
        end
        return function(...)
            local f = env[k]
            if f ~= nil then f(...) end
            f = g[k]
            if f ~= nil then return f(...) end
        end
    end,
})
