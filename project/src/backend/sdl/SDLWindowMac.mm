#ifdef HX_MACOS

#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#include <SDL.h>
#include <SDL_syswm.h>

namespace lime {

	void SetCocoaWindowAppearance (SDL_Window* native, int appearance) {
		@autoreleasepool {
			SDL_SysWMinfo info; SDL_VERSION (&info.version);
			if (!native || !SDL_GetWindowWMInfo (native, &info) || info.subsystem != SDL_SYSWM_COCOA) return;
			if (@available(macOS 10.14, *)) {
				NSWindow* window = info.info.cocoa.window;
				window.appearance = appearance == 0 ? nil : [NSAppearance appearanceNamed:appearance == 2 ? NSAppearanceNameDarkAqua : NSAppearanceNameAqua];
			}
		}
	}

	int GetCocoaWindowAppearance (SDL_Window* native) {
		@autoreleasepool {
			SDL_SysWMinfo info; SDL_VERSION (&info.version);
			if (!native || !SDL_GetWindowWMInfo (native, &info) || info.subsystem != SDL_SYSWM_COCOA) return 0;
			if (@available(macOS 10.14, *)) {
				NSAppearance* appearance = [info.info.cocoa.window effectiveAppearance];
				NSString* match = [appearance bestMatchFromAppearancesWithNames:@[NSAppearanceNameAqua, NSAppearanceNameDarkAqua]];
				return [match isEqualToString:NSAppearanceNameDarkAqua] ? 2 : 1;
			}
			return 0;
		}
	}


	bool EnableTransparentWindow (SDL_Window* sdlWindow) {

		if (!sdlWindow) return false;

		@autoreleasepool {

			SDL_SysWMinfo wminfo;
			SDL_VERSION (&wminfo.version);
			if (SDL_GetWindowWMInfo (sdlWindow, &wminfo) != SDL_TRUE) return false;
			if (wminfo.subsystem != SDL_SYSWM_COCOA) return false;

			NSWindow* window = wminfo.info.cocoa.window;
			if (!window) return false;

			[window setOpaque:NO];
			[window setBackgroundColor:[NSColor clearColor]];

			NSView* contentView = [window contentView];
			if (contentView && [contentView layer]) {

				[[contentView layer] setOpaque:NO];
				[[contentView layer] setBackgroundColor:[[NSColor clearColor] CGColor]];

			}

			return true;

		}

	}


	void EnableTransparentOpenGLSurface () {

		@autoreleasepool {

			NSOpenGLContext* context = [NSOpenGLContext currentContext];
			if (!context) return;

			GLint opaque = 0;
			[context setValues:&opaque forParameter:NSOpenGLCPSurfaceOpacity];

		}

	}


}

#endif
