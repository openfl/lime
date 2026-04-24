#ifndef CAIRO_WINRT_STUBS_H
#define CAIRO_WINRT_STUBS_H

#ifdef __WINRT__
#include <windows.h>

#ifdef __cplusplus
extern "C" {
#endif

HANDLE CreateFileW_WinRT(
    LPCWSTR lpFileName,
    DWORD dwDesiredAccess,
    DWORD dwShareMode,
    LPSECURITY_ATTRIBUTES lpSecurityAttributes,
    DWORD dwCreationDisposition,
    DWORD dwFlagsAndAttributes,
    HANDLE hTemplateFile
);

UINT GetTempFileNameW_WinRT(
    LPCWSTR lpPathName,
    LPCWSTR lpPrefixString,
    UINT uUnique,
    LPWSTR lpTempFileName
);

#ifdef __cplusplus
}
#endif

#undef CreateFileW
#define CreateFileW CreateFileW_WinRT

#undef GetTempFileNameW
#define GetTempFileNameW GetTempFileNameW_WinRT

#endif

#endif
