package lime.ui;

/**
	The windowing system a `WindowHandle` belongs to, which says what its
	`window` and `display` are.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract WindowHandleType(Int) from Int to Int
{
	/**
		`window` is the `HWND`.
	**/
	var WINDOWS = 1;

	/**
		`window` is the `NSWindow*`.
	**/
	var COCOA = 2;

	/**
		`window` is the X11 `Window`, and `display` the `Display*`.
	**/
	var X11 = 3;

	/**
		`window` is the `wl_surface*`, and `display` the `wl_display*`.
	**/
	var WAYLAND = 4;

	/**
		`window` is the `UIWindow*`.
	**/
	var UIKIT = 5;

	/**
		`window` is the `ANativeWindow*`.
	**/
	var ANDROID = 6;
}
