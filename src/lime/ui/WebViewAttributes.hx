package lime.ui;

/**
	What a `WebView` is created with. Everything is optional.
**/
typedef WebViewAttributes =
{
	/**
		Whether media plays without waiting for a user action. `false` by default.
		Applied on macOS, iOS, Android and AIR.
	**/
	@:optional public var autoplay:Bool;

	/**
		Whether the user can open the page's context menu. `true` by default.
	**/
	@:optional public var contextMenu:Bool;

	/**
		Whether the engine's developer tools are available: `true` in debug builds,
		and `false` otherwise.
	**/
	@:optional public var devTools:Bool;

	/**
		The view's height, in window coordinates. The window's height by default.
	**/
	@:optional public var height:Int;

	/**
		Whether the view starts out hidden, until `visible` is set. `false` by default.
	**/
	@:optional public var hidden:Bool;

	/**
		Whether browser shortcuts, such as the one to print, work. `true` by default.
	**/
	@:optional public var keyboardShortcuts:Bool;

	/**
		Whether the status bar shows, as it does over a link. `true` by default.
	**/
	@:optional public var statusBar:Bool;

	/**
		What the view says it is, in place of the engine's own user agent.
	**/
	@:optional public var userAgent:String;

	/**
		The view's width, in window coordinates. The window's width by default.
	**/
	@:optional public var width:Int;

	/**
		The view's horizontal position in its window. `0` by default.
	**/
	@:optional public var x:Int;

	/**
		The view's vertical position in its window. `0` by default.
	**/
	@:optional public var y:Int;

	/**
		Whether the user can zoom the page. `true` by default.
	**/
	@:optional public var zoom:Bool;
}
