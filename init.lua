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

np.CrossCallAdd("hotload.file_get_write_time", function(filename)
    local OPEN_EXISTING = 3
    local handle = ffi.C.CreateFileA(filename, 0, 0, nil, OPEN_EXISTING, 0, nil)
    local write_time = ffi.new("FILETIME[1]")
    ffi.C.GetFileTime(handle, nil, nil, write_time)
    ffi.C.CloseHandle(handle)
    return tostring(ffi.cast("long long*", write_time)[0])
end)
np.CrossCallAdd("hotload.file_get_content", function(filename)
    if io.open(filename) == nil then return "" end
    local content = io.input(filename):read "*a"
    io.input():close()
    return content
end)

local content = io.input("save00/mod_config.xml"):read "*a"
io.input():close()
local xml = nxml.parse(content)
for mod in xml:each_child() do
    if mod.attr.name == "hotload" then
        xml:remove_child(mod)
        table.insert(xml.children, 1, mod)
        break
    end
end
io.output("save00/mod_config.xml"):write(tostring(xml))
io.output():close()

local function make_hotload(filename)
    ModTextFileSetContent(filename, ModTextFileGetContent("mods/hotload/files/hotload.lua"):format(filename, filename))
end

local mods = { "120fps", "test" }
for i, mod in ipairs(mods) do
    make_hotload(("mods/%s/init.lua"):format(mod))
    make_hotload(("mods/%s/settings.lua"):format(mod))
end

function OnWorldPreUpdate()
    for i, entity in ipairs(EntityGetInRadius(0, 0, math.huge)) do
        for i, lua in ipairs(EntityGetComponent(entity, "LuaComponent") or {}) do
            for k, v in ipairs(ComponentGetMembers(lua) or {}) do
                for i, mod in ipairs(mods) do
                    if k:find("script_") and (v:find(("mods/%s/"):format(mod)) or ModDoesFileExist(("mods/%s/%s"):format(mod, v))) then
                        make_hotload(v)
                    end
                end
            end
        end
    end
end
