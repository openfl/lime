#include "SDLMenu.h"

#ifdef LIME_SDL_MENU_COCOA

// Native menus and tray icons for macOS

#import <Cocoa/Cocoa.h>
#include "SDLTrayIcon.h"
#include <ui/TrayIconEvent.h>
#include <SDL_syswm.h>
#include <string.h>

#if __has_feature(objc_arc)
#define LIME_AUTORELEASE(object) (object)
#define LIME_RETAIN(object) (object)
#define LIME_BRIDGE(type, pointer) ((__bridge type)(pointer))
#define LIME_BRIDGE_RETAIN(object) ((void*)CFBridgingRetain (object))
#define LIME_BRIDGE_RELEASE(pointer) CFRelease ((CFTypeRef)(pointer))
#else
#define LIME_AUTORELEASE(object) [(object) autorelease]
#define LIME_RETAIN(object) [(object) retain]
#define LIME_BRIDGE(type, pointer) ((type)(pointer))
#define LIME_BRIDGE_RETAIN(object) ((void*)[(object) retain])
#define LIME_BRIDGE_RELEASE(pointer) [(NSObject*)(pointer) release]
#endif


@interface LimeMenuTarget : NSObject <NSMenuDelegate> {

	@public
	NSInteger highlightedTag;
	NSInteger popupSelection;

}

- (void)clickTrayIcon:(id)sender;
- (void)selectApplicationMenuItem:(NSMenuItem*)sender;
- (void)selectPopupMenuItem:(NSMenuItem*)sender;
- (void)selectTrayIconMenuItem:(NSMenuItem*)sender;

@end


@implementation LimeMenuTarget

- (void)clickTrayIcon:(id)sender {

	NSEvent* event = [NSApp currentEvent];
	bool rightClick = event && ([event type] == NSEventTypeRightMouseUp || ([event modifierFlags] & NSEventModifierFlagControl));

	lime::SDLMenu::PushTrayIconEvent ((int)[sender tag], rightClick ? lime::TRAY_ICON_RIGHT_CLICK : lime::TRAY_ICON_CLICK, 0);

}

- (void)selectApplicationMenuItem:(NSMenuItem*)sender {

	// Called while SDL pumps Cocoa events, so queue the selection for SDLApplication
	lime::SDLMenu::PushSelection (0, (int)[sender tag]);

}

- (void)selectPopupMenuItem:(NSMenuItem*)sender {

	popupSelection = [sender tag];

}

- (void)selectTrayIconMenuItem:(NSMenuItem*)sender {

	// Tray icon menu items carry the tray icon ID in the high 32 bits of their tag
	NSInteger tag = [sender tag];
	lime::SDLMenu::PushTrayIconEvent ((int)(tag >> 32), lime::TRAY_ICON_MENU_SELECT, (int)(tag & 0xFFFFFFFF));

}

- (void)menu:(NSMenu*)menu willHighlightItem:(NSMenuItem*)item {

	highlightedTag = (item && [item action] == @selector(selectPopupMenuItem:)) ? [item tag] : 0;

}

@end


namespace lime {


	// Cocoa has a single menu bar for the application, which SDL fills with a
	// default application menu. The first item of a Lime menu becomes the
	// application menu, as on other macOS applications.

	static NSMenu* defaultApplicationMenu = nil;
	static bool defaultApplicationMenuSaved = false;
	static LimeMenuTarget* menuTarget = nil;


	static LimeMenuTarget* GetMenuTarget () {

		if (!menuTarget) menuTarget = [[LimeMenuTarget alloc] init];
		return menuTarget;

	}


	static NSWindow* GetNSWindow (SDL_Window* window) {

		if (!window) return nil;

		SDL_SysWMinfo info;
		SDL_VERSION (&info.version);

		if (!SDL_GetWindowWMInfo (window, &info) || info.subsystem != SDL_SYSWM_COCOA) return nil;

		return info.info.cocoa.window;

	}


	static NSString* GetString (const std::string& text) {

		NSString* result = [[NSString alloc] initWithBytes:text.data () length:text.size () encoding:NSUTF8StringEncoding];
		return result ? LIME_AUTORELEASE (result) : @"";

	}


	static NSString* GetKeyEquivalent (int keyCode) {

		unichar character = 0;

		// Use lowercase characters, since an uppercase key equivalent implies Shift
		if (keyCode >= 0x20 && keyCode < 0x7F) {

			character = (unichar)keyCode;

		} else if (keyCode >= SDLK_F1 && keyCode <= SDLK_F12) {

			character = (unichar)(NSF1FunctionKey + (keyCode - SDLK_F1));

		} else if (keyCode >= SDLK_F13 && keyCode <= SDLK_F24) {

			character = (unichar)(NSF13FunctionKey + (keyCode - SDLK_F13));

		} else {

			switch (keyCode) {

				case SDLK_BACKSPACE: character = NSBackspaceCharacter; break;
				case SDLK_TAB: character = NSTabCharacter; break;
				case SDLK_RETURN: character = NSCarriageReturnCharacter; break;
				case SDLK_ESCAPE: character = 0x1B; break;
				case SDLK_DELETE: character = NSDeleteFunctionKey; break;
				case SDLK_HOME: character = NSHomeFunctionKey; break;
				case SDLK_END: character = NSEndFunctionKey; break;
				case SDLK_PAGEUP: character = NSPageUpFunctionKey; break;
				case SDLK_PAGEDOWN: character = NSPageDownFunctionKey; break;
				case SDLK_INSERT: character = NSInsertFunctionKey; break;
				case SDLK_LEFT: character = NSLeftArrowFunctionKey; break;
				case SDLK_RIGHT: character = NSRightArrowFunctionKey; break;
				case SDLK_UP: character = NSUpArrowFunctionKey; break;
				case SDLK_DOWN: character = NSDownArrowFunctionKey; break;
				default: break;

			}

		}

		return character ? [NSString stringWithCharacters:&character length:1] : @"";

	}


	static NSUInteger GetModifierMask (int keyModifiers) {

		NSUInteger mask = 0;

		if (keyModifiers & KMOD_GUI) mask |= NSEventModifierFlagCommand;
		if (keyModifiers & KMOD_SHIFT) mask |= NSEventModifierFlagShift;
		if (keyModifiers & KMOD_ALT) mask |= NSEventModifierFlagOption;
		if (keyModifiers & KMOD_CTRL) mask |= NSEventModifierFlagControl;

		return mask;

	}


	static NSMenu* CreateMenu (NSString* title) {

		NSMenu* menu = LIME_AUTORELEASE ([[NSMenu alloc] initWithTitle:title]);

		// Use the enabled state from Lime instead of validating against the responder chain
		[menu setAutoenablesItems:NO];
		[menu setDelegate:GetMenuTarget ()];

		return menu;

	}


	static void AppendMenuItems (NSMenu* menu, const std::vector<SDLMenuItem>& items, SEL action, NSInteger tagBase) {

		for (size_t i = 0; i < items.size (); i++) {

			const SDLMenuItem& item = items[i];
			bool hasSubmenu = (item.flags & MENU_ITEM_SUBMENU) != 0;

			if ((item.flags & MENU_ITEM_SEPARATOR) && !hasSubmenu) {

				[menu addItem:[NSMenuItem separatorItem]];
				continue;

			}

			// macOS menus do not use mnemonics
			NSString* title = GetString (SDLMenu::GetLabel (item.label, 0));
			NSString* keyEquivalent = (!hasSubmenu && item.keyCode != 0) ? GetKeyEquivalent (item.keyCode) : @"";

			NSMenuItem* menuItem = LIME_AUTORELEASE ([[NSMenuItem alloc] initWithTitle:title action:(hasSubmenu ? NULL : action) keyEquivalent:keyEquivalent]);

			if ([keyEquivalent length] > 0) {

				[menuItem setKeyEquivalentModifierMask:GetModifierMask (item.keyModifiers)];

			}

			[menuItem setTag:(tagBase | item.id)];
			[menuItem setTarget:GetMenuTarget ()];
			[menuItem setEnabled:(item.flags & MENU_ITEM_ENABLED) != 0];
			[menuItem setState:(item.flags & MENU_ITEM_CHECKED) ? NSControlStateValueOn : NSControlStateValueOff];

			if (hasSubmenu) {

				NSMenu* submenu = CreateMenu (title);
				AppendMenuItems (submenu, item.submenu, action, tagBase);
				[menuItem setSubmenu:submenu];

			}

			[menu addItem:menuItem];

		}

	}


	bool SDLMenu::GetPlatformSelection (SDL_Event* event, Uint32* windowID, int* id) {

		return false;

	}


	int SDLMenu::GetSupport () {

		return MENU_SUPPORT_POPUP | MENU_SUPPORT_APPLICATION;

	}


	int SDLMenu::Popup (SDL_Window* window, const unsigned char* data, int length, int x, int y, bool atCursor) {

		@autoreleasepool {

			NSWindow* nsWindow = GetNSWindow (window);
			std::vector<SDLMenuItem> items;

			if (!nsWindow || !Parse (data, length, &items)) return 0;

			LimeMenuTarget* target = GetMenuTarget ();
			NSMenu* menu = CreateMenu (@"");
			AppendMenuItems (menu, items, @selector(selectPopupMenuItem:), 0);

			NSView* view = [nsWindow contentView];
			NSPoint location;

			if (atCursor || !view) {

				// Screen coordinates, used when no view is given
				location = [NSEvent mouseLocation];
				view = nil;

			} else {

				// SDL window coordinates start at the top-left of the content view
				location = NSMakePoint (x, [view isFlipped] ? y : NSHeight ([view bounds]) - y);

			}

			target->popupSelection = 0;
			target->highlightedTag = 0;

			BOOL selected = [menu popUpMenuPositioningItem:nil atLocation:location inView:view];

			// The action is normally sent before tracking ends, the highlighted item is a fallback
			int result = (int)target->popupSelection;
			if (result == 0 && selected) result = (int)target->highlightedTag;

			return result;

		}

	}


	void SDLMenu::Remove (SDL_Window* window) {}


	bool SDLMenu::SetApplicationMenu (const unsigned char* data, int length) {

		@autoreleasepool {

			if (!NSApp) return false;

			if (!defaultApplicationMenuSaved) {

				defaultApplicationMenu = LIME_RETAIN ([NSApp mainMenu]);
				defaultApplicationMenuSaved = true;

			}

			if (!data || length <= 0) {

				[NSApp setMainMenu:defaultApplicationMenu];
				return true;

			}

			std::vector<SDLMenuItem> items;

			if (!Parse (data, length, &items)) return false;

			NSMenu* menu = CreateMenu (@"MainMenu");
			AppendMenuItems (menu, items, @selector(selectApplicationMenuItem:), 0);

			[NSApp setMainMenu:menu];
			return true;

		}

	}


	bool SDLMenu::SetWindowMenu (SDL_Window* window, const unsigned char* data, int length) {

		// macOS windows do not have menu bars, use the application menu instead
		return false;

	}


	// Tray icons use NSStatusItem. When an icon has a menu, macOS shows it when the icon is
	// clicked, otherwise clicks are reported through the button action.

	static int nextTrayIconID = 0;


	static NSStatusItem* GetStatusItem (SDLTrayIcon* trayIcon) {

		return trayIcon->platform ? LIME_BRIDGE (NSStatusItem*, trayIcon->platform) : nil;

	}


	static NSImage* GetTrayImage (NSImage* image) {

		if (!image) return nil;

		CGFloat size = [[NSStatusBar systemStatusBar] thickness] - 4.0;
		if (size < 16.0) size = 16.0;

		NSImage* copy = LIME_AUTORELEASE ([image copy]);
		NSSize imageSize = [copy size];

		if (imageSize.width > 0 && imageSize.height > 0) {

			[copy setSize:NSMakeSize (size * imageSize.width / imageSize.height, size)];

		}

		return copy;

	}


	bool TrayIcon::IsSupported () {

		return NSApp != nil;

	}


	SDLTrayIcon::SDLTrayIcon () {

		id = ++nextTrayIconID;
		platform = NULL;

		@autoreleasepool {

			NSStatusItem* statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];

			if (!statusItem) return;

			NSStatusBarButton* button = [statusItem button];
			[button setImage:GetTrayImage ([NSApp applicationIconImage])];
			[button setTarget:GetMenuTarget ()];
			[button setAction:@selector(clickTrayIcon:)];
			[button setTag:id];
			[button sendActionOn:(NSEventMaskLeftMouseUp | NSEventMaskRightMouseUp)];

			// The status bar does not keep the item alive
			platform = LIME_BRIDGE_RETAIN (statusItem);

		}

	}


	SDLTrayIcon::~SDLTrayIcon () {

		Close ();

	}


	void SDLTrayIcon::Close () {

		if (!platform) return;

		@autoreleasepool {

			[[NSStatusBar systemStatusBar] removeStatusItem:GetStatusItem (this)];

		}

		LIME_BRIDGE_RELEASE (platform);
		platform = NULL;

	}


	int SDLTrayIcon::PopupMenu (const unsigned char* data, int length) {

		if (!platform) return 0;

		@autoreleasepool {

			std::vector<SDLMenuItem> items;

			if (!SDLMenu::Parse (data, length, &items)) return 0;

			LimeMenuTarget* target = GetMenuTarget ();
			NSMenu* menu = CreateMenu (@"");
			AppendMenuItems (menu, items, @selector(selectPopupMenuItem:), 0);

			NSStatusBarButton* button = [GetStatusItem (this) button];
			NSPoint location = NSMakePoint (0, [button isFlipped] ? NSHeight ([button bounds]) + 4.0 : -4.0);

			target->popupSelection = 0;
			target->highlightedTag = 0;

			BOOL selected = [menu popUpMenuPositioningItem:nil atLocation:location inView:button];

			int result = (int)target->popupSelection;
			if (result == 0 && selected) result = (int)target->highlightedTag;

			return result;

		}

	}


	void SDLTrayIcon::SetIcon (ImageBuffer* imageBuffer) {

		if (!platform || !imageBuffer || !imageBuffer->data || !imageBuffer->data->buffer || imageBuffer->width <= 0 || imageBuffer->height <= 0 || imageBuffer->bitsPerPixel != 32) {

			return;

		}

		@autoreleasepool {

			int width = imageBuffer->width;
			int height = imageBuffer->height;

			if (imageBuffer->data->buffer->length < imageBuffer->Stride () * height) return;

			NSBitmapImageRep* bitmap = LIME_AUTORELEASE ([[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:width pixelsHigh:height bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO colorSpaceName:NSDeviceRGBColorSpace bitmapFormat:NSBitmapFormatAlphaNonpremultiplied bytesPerRow:width * 4 bitsPerPixel:32]);

			if (!bitmap) return;

			const unsigned char* source = imageBuffer->data->buffer->b;
			unsigned char* dest = [bitmap bitmapData];
			int stride = imageBuffer->Stride ();

			for (int y = 0; y < height; y++) {

				memcpy (dest + y * width * 4, source + y * stride, width * 4);

			}

			NSImage* image = LIME_AUTORELEASE ([[NSImage alloc] initWithSize:NSMakeSize (width, height)]);
			[image addRepresentation:bitmap];

			[[GetStatusItem (this) button] setImage:GetTrayImage (image)];

		}

	}


	bool SDLTrayIcon::SetMenu (const unsigned char* data, int length) {

		if (!platform) return false;

		@autoreleasepool {

			NSStatusItem* statusItem = GetStatusItem (this);
			std::vector<SDLMenuItem> items;

			if (!data || length <= 0 || !SDLMenu::Parse (data, length, &items)) {

				[statusItem setMenu:nil];
				return false;

			}

			NSMenu* menu = CreateMenu (@"");
			AppendMenuItems (menu, items, @selector(selectTrayIconMenuItem:), (NSInteger)id << 32);

			[statusItem setMenu:menu];
			return true;

		}

	}


	void SDLTrayIcon::SetTooltip (const char* tooltip) {

		if (!platform) return;

		@autoreleasepool {

			[[GetStatusItem (this) button] setToolTip:GetString (tooltip ? std::string (tooltip) : std::string ())];

		}

	}


	void SDLTrayIcon::Update () {}


}


#endif
