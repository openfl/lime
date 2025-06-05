#ifdef HX_MACOS
#import <Cocoa/Cocoa.h>
#else
#import <UIKit/UIKit.h>
#endif

#include <system/Display.h>
#include <math/Rectangle.h>


namespace lime {


	void Display::GetSafeAreaInsets (int displayIndex, Rectangle * rect) {

		#ifdef HX_MACOS

		if (@available(macOS 12, *)) {

			NSScreen * screen = [[NSScreen screens] objectAtIndex: displayIndex];
			NSEdgeInsets safeAreaInsets = [screen safeAreaInsets];
			rect->SetTo(safeAreaInsets.left,
					safeAreaInsets.top,
					safeAreaInsets.right,
					safeAreaInsets.bottom);
			return;

		}

		#endif

		#ifdef IPHONE

		if (@available(iOS 11, *)) {

			UIWindow * window = [[UIApplication sharedApplication] keyWindow];
			UIEdgeInsets safeAreaInsets = [window safeAreaInsets];
			rect->SetTo(safeAreaInsets.left,
					safeAreaInsets.top,
					safeAreaInsets.right,
					safeAreaInsets.bottom);
			return;

		}

		#endif

		rect->SetTo(0.0, 0.0, 0.0, 0.0);

	}

}