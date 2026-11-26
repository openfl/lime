/* Lime: the window scene and interface orientation of the UIScene life cycle, after SDL 3.4
 * (libsdl-org/SDL b46e26e65aac and 114aca1727c7). They are in a header of their own because SDL's
 * headers include SDL_uikitvideo.h from SDL's folder, so a patched copy of it could be skipped. */
#ifndef SDL_uikitscene_h_
#define SDL_uikitscene_h_

#ifdef __OBJC__

#import <UIKit/UIKit.h>

/* The window scene the application's windows go in, or nil before iOS 13 */
UIWindowScene *UIKit_GetActiveWindowScene(void) API_AVAILABLE(ios(13.0), tvos(13.0));

#if !TARGET_OS_TV
/* The interface's orientation, from its window scene where there is one, as the status bar's
 * orientation is deprecated and reads nothing on iOS 27 */
UIInterfaceOrientation UIKit_GetInterfaceOrientation(void);
#endif

#endif /* __OBJC__ */

#endif /* SDL_uikitscene_h_ */
