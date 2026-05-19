#include <SDL.h>

#ifdef __WINRT__

// Stubs for functions typically provided by Win32-only joystick backends (DInput/XInput)
// which are disabled in WinRT builds to avoid Win32 API dependency violations.
// Since these backends are disabled, these functions should always return SDL_FALSE.

SDL_bool SDL_XINPUT_Enabled(void) {
    return SDL_FALSE;
}

SDL_bool SDL_DINPUT_JoystickPresent(Uint16 vendor, Uint16 product, Uint16 version) {
    return SDL_FALSE;
}

#endif
