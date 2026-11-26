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
#ifndef SDL_uikitvideo_h_
#define SDL_uikitvideo_h_

#include "../SDL_sysvideo.h"

#ifdef __OBJC__

#include <UIKit/UIKit.h>

@interface SDL_VideoData : NSObject

@property (nonatomic, assign) id pasteboardObserver;

@end

CGRect UIKit_ComputeViewFrame(SDL_Window *window, UIScreen *screen);

/* The window scene the application's windows go in, or nil before iOS 13 */
UIWindowScene *UIKit_GetActiveWindowScene(void) API_AVAILABLE(ios(13.0), tvos(13.0));

#if !TARGET_OS_TV
/* The interface's orientation, from its window scene where there is one, as the status bar's
 * orientation is deprecated and reads nothing on iOS 27 */
UIInterfaceOrientation UIKit_GetInterfaceOrientation(void);
#endif

#endif /* __OBJC__ */

void UIKit_SuspendScreenSaver(_THIS);

void UIKit_ForceUpdateHomeIndicator(void);

SDL_bool UIKit_IsSystemVersionAtLeast(double version);

#endif /* SDL_uikitvideo_h_ */

/* vi: set ts=4 sw=4 expandtab: */
