if require ~= nil then
    function file_get_content(filename)
        local file = io.open(filename)
        if file == nil then return end
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
        typedef void* HANDLE;
        typedef const char* LPCSTR;
        typedef unsigned long DWORD;
        typedef void* LPVOID;
        typedef int BOOL;
        typedef struct {
            DWORD dwLowDateTime;
            DWORD dwHighDateTime;
        } FILETIME, *PFILETIME, *LPFILETIME;
        HANDLE CreateFileA(
            LPCSTR lpFileName,
            DWORD dwDesiredAccess,
            DWORD dwShareMode,
            LPVOID lpSecurityAttributes,
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
    local OPEN_EXISTING = 3
    function file_get_write_time(filename, previous_time)
        local handle = ffi.C.CreateFileA(filename, 0, 0, nil, OPEN_EXISTING, 0, nil)
        local write_time = ffi.new("FILETIME[1]")
        ffi.C.GetFileTime(handle, nil, nil, write_time)
        ffi.C.CloseHandle(handle)
        if ffi.cast("uint64_t*", write_time)[0] ~= tointeger(previous_time) then return ffi.cast("double*", write_time)[0] end
    end

    ffi.cdef [[
        typedef void* HANDLE;
        typedef const char* LPCSTR;
        typedef unsigned long DWORD;
        typedef void* LPVOID;
        typedef DWORD* LPDWORD;
        typedef int BOOL;
        HANDLE CreateFileA(
            LPCSTR lpFileName,
            DWORD dwDesiredAccess,
            DWORD dwShareMode,
            LPVOID lpSecurityAttributes,
            DWORD dwCreationDisposition,
            DWORD dwFlagsAndAttributes,
            HANDLE hTemplateFile
        );
        DWORD GetFileSize(
            HANDLE hFile,
            LPDWORD lpFileSizeHigh
        );
        BOOL ReadFile(
            HANDLE hFile,
            LPVOID lpBuffer,
            DWORD nNumberOfBytesToRead,
            DWORD* lpNumberOfBytesRead,
            LPVOID lpOverlapped
        );
        BOOL CloseHandle(HANDLE hObject);
    ]]
    local GENERIC_READ = 0x80000000
    local FILE_SHARE_READ = 0x00000001
    local FILE_SHARE_WRITE = 0x00000002
    local ModTextFileSetContent = ModTextFileSetContent
    function file_update(filename, previous_time)
        local handle = ffi.C.CreateFileA(filename, GENERIC_READ, FILE_SHARE_READ + FILE_SHARE_WRITE, nil, OPEN_EXISTING, 0, nil)

        local write_time = ffi.new("FILETIME[1]")
        ffi.C.GetFileTime(handle, nil, nil, write_time)
        if ffi.cast("uint64_t*", write_time)[0] == tointeger(previous_time) then
            ffi.C.CloseHandle(handle)
            return
        end

        local size
        for i = 1, 512 do
            size = ffi.C.GetFileSize(handle, nil)
            if size > 0 then
                break
            end
        end
        if size == 0xffffffff then size = 0 end
        local buffer = ffi.new("char[?]", size)

        ffi.C.ReadFile(handle, buffer, size, nil, nil)
        ffi.C.CloseHandle(handle)
        ModTextFileSetContent(filename, ffi.string(buffer, size))
    end

    function tointeger(n)
        return ffi.cast("uint64_t*", ffi.new("double[1]", n))[0]
    end
else
    function file_is_exist(filename)
        return CrossCall("hotload.file_is_exist", filename)
    end
end

function make_hotload(filename)
    ModTextFileSetContent(filename, ModTextFileGetContent("mods/hotload/files/hotload.lua")
        :gsub("%-%-", "")
        :gsub("%%(%d)", function(s)
            if s == "1" then
                return filename
            elseif s == "2" then
                if file_is_exist(filename) then
                    return ('CrossCall("hotload.file_get_content", "%s")'):format(filename)
                end
                local content = ModTextFileGetContent(filename)
                if content == nil then content = "" end
                return ("%q"):format(content)
            elseif file_is_exist(filename) then
                return ('CrossCall("hotload.file_update", "%s", times["%s"])'):format(filename, filename)
            end
            return ""
        end)
    )
end
