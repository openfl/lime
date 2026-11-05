package lime.ui;

/**
	What a `WebView` is created with. Everything is optional.
**/
typedef WebViewAttributes =
{
	/**
		Whether the user can open the page's context menu. `true` by default.
	**/
	@:optional var contextMenu:Bool;

	/**
		Whether the engine's developer tools are available: `true` in debug builds,
		and `false` otherwise.
	**/
	@:optional var devTools:Bool;

	/**
		The view's height, in window coordinates. `0` by default.
	**/
	@:optional var height:Int;

	/**
		Whether browser shortcuts, such as the one to print, work. `true` by default.
	**/
	@:optional var keyboardShortcuts:Bool;

	/**
		Whether media waits for a user action before it plays. `true` by default.
		Applied on macOS, iOS and Android.
	**/
	@:optional var mediaNeedsUserAction:Bool;

	/**
		Whether the status bar shows, as it does over a link. `true` by default.
	**/
	@:optional var statusBar:Bool;

	/**
		What the view says it is, in place of the engine's own user agent.
	**/
	@:optional var userAgent:String;

	/**
		The view's width, in window coordinates. `0` by default.
	**/
	@:optional var width:Int;

	/**
		The view's horizontal position in its window. `0` by default.
	**/
	@:optional var x:Int;

	/**
		The view's vertical position in its window. `0` by default.
	**/
	@:optional var y:Int;

	/**
		Whether the user can zoom the page. `true` by default.
	**/
	@:optional var zoom:Bool;
}
