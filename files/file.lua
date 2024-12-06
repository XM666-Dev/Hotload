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
                return ("%q"):format(ModTextFileGetContent(filename))
            elseif file_is_exist(filename) then
                return ([[
                    if CrossCall("hotload.file_get_write_time", "%s") ~= times["%s"] then
                        local content = CrossCall("hotload.file_get_content", "%s")
                        --当返回空字符串时，如果文件被清空，也清空文件，无需特化。如果文件读取失败，跳过热重载，等待下一次热重载。
                        ModTextFileSetContent("%s", content)
                    end
                ]]):format(filename, filename, filename, filename)
            end
            return ""
        end)
    )
end
