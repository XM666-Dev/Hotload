dofile_once("mods/hotload/NoitaPatcher/load.lua")

local np = require("noitapatcher")
local ffi = require("ffi")

ffi.cdef [[
typedef unsigned long DWORD;
typedef void* HANDLE;
typedef int BOOL;
typedef struct _FILETIME {
    DWORD dwLowDateTime;
    DWORD dwHighDateTime;
} FILETIME, *PFILETIME, *LPFILETIME;
typedef struct _SYSTEMTIME {
    unsigned short wYear;
    unsigned short wMonth;
    unsigned short wDayOfWeek;
    unsigned short wDay;
    unsigned short wHour;
    unsigned short wMinute;
    unsigned short wSecond;
    unsigned short wMilliseconds;
} SYSTEMTIME, *PSYSTEMTIME, *LPSYSTEMTIME;

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

BOOL FileTimeToSystemTime(
    const FILETIME* lpFileTime,
    LPSYSTEMTIME lpSystemTime
);

BOOL CloseHandle(HANDLE hObject);
]]

local GENERIC_READ = 0x80000000
local FILE_SHARE_READ = 0x00000001
local OPEN_EXISTING = 3

local function get_file_modification_time(file_path)
    local handle = ffi.C.CreateFileA(file_path, GENERIC_READ, FILE_SHARE_READ, nil, OPEN_EXISTING, 0, nil)
    if handle == ffi.cast("HANDLE", -1) then
        return nil, "无法打开文件"
    end

    local write_time = ffi.new("FILETIME[1]")
    if ffi.C.GetFileTime(handle, nil, nil, write_time) == 0 then
        ffi.C.CloseHandle(handle)
        return nil, "无法获取文件时间"
    end

    ffi.C.CloseHandle(handle)

    local system_time = ffi.new("SYSTEMTIME")
    if ffi.C.FileTimeToSystemTime(write_time, system_time) == 0 then
        return nil, "无法转换文件时间"
    end

    return string.format(
        "%04d-%02d-%02d %02d:%02d:%02d",
        system_time.wYear,
        system_time.wMonth,
        system_time.wDay,
        system_time.wHour,
        system_time.wMinute,
        system_time.wSecond
    )
end

np.CrossCallAdd("hotload.file_get_write_time", function(filename)
    local handle = ffi.C.CreateFileA(filename, 0, 0, nil, OPEN_EXISTING, 0, nil)
    local write_time = ffi.new("FILETIME[1]")
    ffi.C.GetFileTime(handle, nil, nil, write_time)
    ffi.C.CloseHandle(handle)
    return tonumber(ffi.cast("long long*", write_time)[0])
end)
np.CrossCallAdd("hotload.file_get_content", function(filename)
    io.input(filename)
    local content = io.read "*a"
    io.input():close()
    return content
end)
function make_hotload(filename)
    ModTextFileSetContent(filename, ModTextFileGetContent("mods/hotload/files/hotload.lua"):format(filename))
end

make_hotload("mods/hotloadtest/init.lua")
make_hotload("mods/hotloadtest/files/test.lua")
