#include <SDL.h>
#include <windows.h>
#include <stdio.h>

#ifdef __WINRT__

// --- SDL Joystick Stubs ---
SDL_bool SDL_XINPUT_Enabled(void) { return SDL_FALSE; }
SDL_bool SDL_DINPUT_JoystickPresent(Uint16 vendor, Uint16 product, Uint16 version) { return SDL_FALSE; }

// --- Cairo / Win32 API Stubs ---
// Using __cdecl (default) to match what Cairo expects in this build configuration.

HANDLE CreateFileW_WinRT(
    LPCWSTR lpFileName,
    DWORD dwDesiredAccess,
    DWORD dwShareMode,
    LPSECURITY_ATTRIBUTES lpSecurityAttributes,
    DWORD dwCreationDisposition,
    DWORD dwFlagsAndAttributes,
    HANDLE hTemplateFile
) {
    CREATEFILE2_EXTENDED_PARAMETERS params;
    params.dwSize = sizeof(params);
    params.dwFileAttributes = dwFlagsAndAttributes & 0x0000FFFF;
    params.dwFileFlags = dwFlagsAndAttributes & 0xFFFF0000;
    params.dwSecurityQosFlags = 0;
    params.lpSecurityAttributes = lpSecurityAttributes;
    params.hTemplateFile = hTemplateFile;
    return CreateFile2(lpFileName, dwDesiredAccess, dwShareMode, dwCreationDisposition, &params);
}

UINT GetTempFileNameW_WinRT(
    LPCWSTR lpPathName,
    LPCWSTR lpPrefixString,
    UINT uUnique,
    LPWSTR lpTempFileName
) {
    static UINT counter = 0;
    if (uUnique == 0) uUnique = GetTickCount() + (++counter);
    swprintf(lpTempFileName, MAX_PATH, L"%s\\%s%x.tmp", lpPathName, lpPrefixString, uUnique);
    return uUnique;
}

// --- SDL Generic Condition Variable Stubs ---
// These are referenced by SDL_syscond_cv.c but the generic implementation 
// is excluded from the WinRT build. Since we use the native CV implementation,
// these will never be called.
void *SDL_CreateCond_generic(void) { return NULL; }
void SDL_DestroyCond_generic(void *cond) {}
int SDL_CondSignal_generic(void *cond) { return 0; }
int SDL_CondBroadcast_generic(void *cond) { return 0; }
int SDL_CondWait_generic(void *cond, void *mutex) { return 0; }
int SDL_CondWaitTimeout_generic(void *cond, void *mutex, Uint32 ms) { return 0; }

// --- COM / IUnknown Fix ---
// Some SDL modules reference this symbol as an external instead of inlining it.
#include <unknwn.h>
#ifdef __cplusplus
extern "C" {
#endif

// Providing a direct implementation for the linker
ULONG STDMETHODCALLTYPE IUnknown_Release(IUnknown* This) {
    return This->lpVtbl->Release(This);
}

#ifdef _WIN32
#pragma comment(lib, "dxguid.lib")
#pragma comment(lib, "uuid.lib")
#endif

#ifdef __cplusplus
}
#endif

#endif
