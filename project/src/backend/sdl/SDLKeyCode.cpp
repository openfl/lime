#include <SDL.h>
#include <ui/KeyCode.h>


namespace lime {


	int32_t KeyCode::FromScanCode (int32_t scanCode) {

		return SDL_GetKeyFromScancode ((SDL_Scancode)scanCode);

	}


	int32_t KeyCode::ToScanCode (int32_t keyCode) {

		return SDL_GetScancodeFromKey ((SDL_Keycode)keyCode);

	}


}