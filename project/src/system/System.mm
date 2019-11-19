#ifdef IPHONE
#import <UIKit/UIKit.h>
#endif

#import <sys/utsname.h>
#include <system/System.h>


namespace lime {


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