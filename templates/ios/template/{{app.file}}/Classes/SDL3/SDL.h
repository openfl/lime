/*
  Simple DirectMedia Layer
  Copyright (C) 1997-2025 Sam Lantinga <slouken@libsdl.org>

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.
*/

/**
 * Main include header for the SDL library, version 3.2.8
 *
 * It is almost always best to include just this one header instead of
 * picking out individual headers included here. There are exceptions to
 * this rule--SDL_main.h is special and not included here--but usually
 * letting SDL.h include the kitchen sink for you is the correct approach.
 */

#ifndef SDL_h_
#define SDL_h_

#include "SDL_stdinc.h"
#include "SDL_assert.h"
#include "SDL_asyncio.h"
#include "SDL_atomic.h"
#include "SDL_audio.h"
#include "SDL_bits.h"
#include "SDL_blendmode.h"
#include "SDL_camera.h"
#include "SDL_clipboard.h"
#include "SDL_cpuinfo.h"
#include "SDL_dialog.h"
#include "SDL_endian.h"
#include "SDL_error.h"
#include "SDL_events.h"
#include "SDL_filesystem.h"
#include "SDL_gamepad.h"
#include "SDL_gpu.h"
#include "SDL_guid.h"
#include "SDL_haptic.h"
#include "SDL_hidapi.h"
#include "SDL_hints.h"
#include "SDL_init.h"
#include "SDL_iostream.h"
#include "SDL_joystick.h"
#include "SDL_keyboard.h"
#include "SDL_keycode.h"
#include "SDL_loadso.h"
#include "SDL_locale.h"
#include "SDL_log.h"
#include "SDL_messagebox.h"
#include "SDL_metal.h"
#include "SDL_misc.h"
#include "SDL_mouse.h"
#include "SDL_mutex.h"
#include "SDL_pen.h"
#include "SDL_pixels.h"
#include "SDL_platform.h"
#include "SDL_power.h"
#include "SDL_process.h"
#include "SDL_properties.h"
#include "SDL_rect.h"
#include "SDL_render.h"
#include "SDL_scancode.h"
#include "SDL_sensor.h"
#include "SDL_storage.h"
#include "SDL_surface.h"
#include "SDL_system.h"
#include "SDL_thread.h"
#include "SDL_time.h"
#include "SDL_timer.h"
#include "SDL_tray.h"
#include "SDL_touch.h"
#include "SDL_version.h"
#include "SDL_video.h"
#include "SDL_oldnames.h"

#endif /* SDL_h_ */
