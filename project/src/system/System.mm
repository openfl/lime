#ifdef IPHONE
#import <UIKit/UIKit.h>
#endif

#import <sys/utsname.h>
#include <system/System.h>
#include <system/OrientationEvent.h>


#ifdef IPHONE
@interface OrientationObserver: NSObject
- (id) init;
- (void) dealloc;
- (void) dispatchEventForDevice:(UIDevice *) device;
- (void) orientationChanged:(NSNotification *) notification;
@end

@implementation OrientationObserver {
}

- (void) dealloc
{

	UIDevice * device = [UIDevice currentDevice];
	// [device endGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	[super dealloc];

}

- (id) init
{

	self = [super init];
	if (!self)
	{
		return nil;
	}

	UIDevice * device = [UIDevice currentDevice];
	// [device beginGeneratingDeviceOrientationNotifications];
	[[NSNotificationCenter defaultCenter]
		addObserver:self selector:@selector(orientationChanged:)
		name:UIDeviceOrientationDidChangeNotification
		object:device];

	return self;

}

- (void) dispatchEventForCurrentDevice
{

	UIDevice * device = [UIDevice currentDevice];
	[self dispatchEventForDevice:device];

}

- (void) dispatchEventForDevice:(UIDevice *) device
{

	int orientation = 0; // SDL_ORIENTATION_UNKNOWN
	switch (device.orientation)
	{

		case UIDeviceOrientationLandscapeLeft:

			orientation = 1; // SDL_ORIENTATION_LANDSCAPE
			break;

		case UIDeviceOrientationLandscapeRight:

			orientation = 2; // SDL_ORIENTATION_LANDSCAPE_FLIPPED
			break;

		case UIDeviceOrientationPortrait:

			orientation = 3; // SDL_ORIENTATION_PORTRAIT
			break;

		case UIDeviceOrientationPortraitUpsideDown:

			orientation = 4; // SDL_ORIENTATION_PORTRAIT_FLIPPED
			break;

		default:

			break;
	};

	lime::OrientationEvent event;
	event.orientation = orientation;
	event.display = -1;
	event.type = lime::DEVICE_ORIENTATION_CHANGE;
	lime::OrientationEvent::Dispatch(&event);

}

- (void) orientationChanged:(NSNotification *) notification
{

	UIDevice * device = notification.object;
	[self dispatchEventForDevice:device];

}
@end
#endif

namespace lime {

	OrientationObserver* orientationObserver;

	void System::GCEnterBlocking () {

		// if (!_isHL) {

			gc_enter_blocking ();

		// }

	}


	void System::GCExitBlocking () {

		// if (!_isHL) {

			gc_exit_blocking ();

		// }

	}


	std::wstring* System::GetIOSDirectory (SystemDirectory type) {

		#ifndef OBJC_ARC
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		#endif

		NSSearchPathDirectory searchType = NSDocumentDirectory;

		switch (type) {

			case DESKTOP:

				searchType = NSDesktopDirectory;
				break;

			case USER:

				//searchType = NSUserDirectory;
				searchType = NSDocumentDirectory;
				break;

			default: break;

		}

		std::wstring* result = 0;

		NSArray* paths = NSSearchPathForDirectoriesInDomains (searchType, NSUserDomainMask, YES);

		if (paths && [paths count] > 0) {

			NSString* basePath = paths.firstObject;
			std::string path = std::string ([basePath UTF8String]);
			result = new std::wstring (path.begin (), path.end ());

		}

		#ifndef OBJC_ARC
		[pool drain];
		#endif

		return result;

	}


	bool System::GetIOSTablet () {

		return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) ? 1 : 0;

	}


	int System::GetDeviceOrientation () {

		UIDevice * device = [UIDevice currentDevice];

		int orientation = 0; // SDL_ORIENTATION_UNKNOWN
		switch (device.orientation)
		{

			case UIDeviceOrientationLandscapeLeft:

				orientation = 1; // SDL_ORIENTATION_LANDSCAPE
				break;

			case UIDeviceOrientationLandscapeRight:

				orientation = 2; // SDL_ORIENTATION_LANDSCAPE_FLIPPED
				break;

			case UIDeviceOrientationPortrait:

				orientation = 3; // SDL_ORIENTATION_PORTRAIT
				break;

			case UIDeviceOrientationPortraitUpsideDown:

				orientation = 4; // SDL_ORIENTATION_PORTRAIT_FLIPPED
				break;

			default:

				break;
		};

		return orientation;

	}


	std::wstring* System::GetDeviceModel () {

		#ifdef IPHONE
		struct utsname systemInfo;
		uname (&systemInfo);

		std::string model = std::string (systemInfo.machine);
		return new std::wstring (model.begin (), model.end ());
		#else
		return NULL;
		#endif

	}


	std::wstring* System::GetDeviceVendor () {

		return NULL;

	}


	std::wstring* System::GetPlatformLabel () {

		return NULL;

	}


	std::wstring* System::GetPlatformName () {

		return NULL;

	}


	std::wstring* System::GetPlatformVersion () {

		#ifdef IPHONE
		NSString *versionString = [[UIDevice currentDevice] systemVersion];
		std::string result = std::string ([versionString UTF8String]);
		return new std::wstring (result.begin (), result.end ());
		#else
		return NULL;
		#endif

	}


	void System::EnableDeviceOrientationChange (bool enable) {

		#ifdef IPHONE
		if (enable && !orientationObserver)
		{

			orientationObserver = [[OrientationObserver alloc] init];
			// SDL forces dispatch of a display orientation event immediately.
			// for consistency, we should dispatch one for device orientation.
			[orientationObserver dispatchEventForCurrentDevice];

		}
		else if (!enable && orientationObserver)
		{

			orientationObserver = nil;

		}
		#endif

	}


	void System::OpenFile (const char* path) {

		OpenURL (path, NULL);

	}


	void System::OpenURL (const char* url, const char* target) {

		#ifndef OBJC_ARC
		NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
		#endif

		UIApplication *application = [UIApplication sharedApplication];
		NSString *str = [[NSString alloc] initWithUTF8String: url];
		NSURL *_url = [NSURL URLWithString: str];

		if ([[UIApplication sharedApplication] canOpenURL: _url]) {

			if ([application respondsToSelector: @selector (openURL:options:completionHandler:)]) {

				[application openURL: _url options: @{}
					completionHandler:^(BOOL success) {
						//NSLog(@"Open %@: %d", _url, success);
					}
				];

			} else {

				BOOL success = [application openURL: _url];
				//NSLog(@"Open %@: %d",scheme,success);

			}

		}

		#ifndef OBJC_ARC
		[str release];
		[pool drain];
		#endif

	}


}