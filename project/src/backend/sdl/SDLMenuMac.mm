#include "SDLMenu.h"

#ifdef LIME_SDL_MENU_COCOA

#import <Cocoa/Cocoa.h>
#include <SDL_syswm.h>

#if __has_feature(objc_arc)
#define LIME_AUTORELEASE(object) (object)
#define LIME_RETAIN(object) (object)
#else
#define LIME_AUTORELEASE(object) [(object) autorelease]
#define LIME_RETAIN(object) [(object) retain]
#endif


@interface LimeMenuTarget : NSObject <NSMenuDelegate> {

	@public
	NSInteger highlightedTag;
	NSInteger popupSelection;

}

- (void)selectApplicationMenuItem:(NSMenuItem*)sender;
- (void)selectPopupMenuItem:(NSMenuItem*)sender;

@end


@implementation LimeMenuTarget

- (void)selectApplicationMenuItem:(NSMenuItem*)sender {

	// Called while SDL pumps Cocoa events, so queue the selection for SDLApplication
	lime::SDLMenu::PushSelection (0, (int)[sender tag]);

}

- (void)selectPopupMenuItem:(NSMenuItem*)sender {

	popupSelection = [sender tag];

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


	static void AppendMenuItems (NSMenu* menu, const std::vector<SDLMenuItem>& items, SEL action) {

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

			[menuItem setTag:item.id];
			[menuItem setTarget:GetMenuTarget ()];
			[menuItem setEnabled:(item.flags & MENU_ITEM_ENABLED) != 0];
			[menuItem setState:(item.flags & MENU_ITEM_CHECKED) ? NSControlStateValueOn : NSControlStateValueOff];

			if (hasSubmenu) {

				NSMenu* submenu = CreateMenu (title);
				AppendMenuItems (submenu, item.submenu, action);
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
			AppendMenuItems (menu, items, @selector(selectPopupMenuItem:));

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
			AppendMenuItems (menu, items, @selector(selectApplicationMenuItem:));

			[NSApp setMainMenu:menu];
			return true;

		}

	}


	bool SDLMenu::SetWindowMenu (SDL_Window* window, const unsigned char* data, int length) {

		// macOS windows do not have menu bars, use the application menu instead
		return false;

	}


}


#endif
