function file_get_content(filename)
    local file = io.open(filename)
    if file == nil then return nil end
    local content = file:read "*a"
    file:close()
    return content
end

function file_set_content(filename, content)
    local file = io.open(filename, "w")
    if file == nil then return end
    file:write(content)
    file:close()
end

function file_is_exist(filename)
    local file = io.open(filename)
    if file == nil then return false end
    file:close()
    return true
end

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
function file_get_write_time(filename)
    local OPEN_EXISTING = 3
    local handle = ffi.C.CreateFileA(filename, 0, 0, nil, OPEN_EXISTING, 0, nil)
    local write_time = ffi.new("FILETIME[1]")
    ffi.C.GetFileTime(handle, nil, nil, write_time)
    ffi.C.CloseHandle(handle)
    return tostring(ffi.cast("long long*", write_time)[0]):sub(1, -3)
end
