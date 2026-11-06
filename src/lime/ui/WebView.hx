package lime.ui;

import lime.app.Event;
import lime.app.Future;
import lime.graphics.Image;

/**
	A web page in a `Window`, drawn by the system's own engine: WebView2 on
	Windows, WebKitGTK on Linux, WKWebView on macOS and iOS,
	`android.webkit.WebView` on Android, and an `<iframe>` in a browser. It is a
	native view above the window's content, so it moves and resizes, but it does
	not take part in rendering. Without a window it is never shown, which suits
	work like `printToPDF`.

	The engines are StageWebView's, a library other frameworks share.

	Pages talk to the application through `window.chrome.webview`, on every
	engine:

	```js
	window.chrome.webview.addEventListener("message", function (event) {
		console.log(event.data);
	});
	window.chrome.webview.postMessage("ready");
	```

	Example usage:
	```haxe
	var view = new WebView(window);
	window.onResize.add(view.resize);
	view.onLoad.add(function() view.postMessage("hello"));
	view.onMessage.add(function(message) trace(message));
	view.onNavigate.add(function(url) if (url.indexOf("https:") != 0) view.onNavigate.cancel());
	view.load("https://lime.openfl.org");
	```

	Events are dispatched on the main thread. `isSupported` is true on Windows
	with the WebView2 Runtime installed, on x86-64 and ARM64 Linux with WebKitGTK
	4.1 installed and a display, on macOS, iOS and Android, and in browsers, which
	keep other sites' pages to themselves: there, `title` and
	the bridge only reach pages from `loadHTML` or the application's own site, and
	`onNavigate` only sees `load`. On AIR, where it is `StageWebView.isSupported`,
	there is no bridge, and `evaluateJavaScript` cannot read what a script gives.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class WebView
{
	/**
		Whether a webview can be created here. Applications built with the `no-webview`
		define leave out the engine, so it is false on native targets and Android.
	**/
	public static var isSupported(get, never):Bool;

	/**
		Whether there is a page to go back to.
	**/
	public var canGoBack(get, never):Bool;

	/**
		Whether there is a page to go forward to.
	**/
	public var canGoForward(get, never):Bool;

	/**
		The view's height, in window coordinates.
	**/
	public var height(get, set):Int;

	/**
		The title of the current page.
	**/
	public var title(get, never):String;

	/**
		The URL of the current page, which is `about:blank` for a page from `loadHTML`.
	**/
	public var url(get, never):String;

	/**
		Whether the view shows.
	**/
	public var visible(get, set):Bool;

	/**
		The view's width, in window coordinates.
	**/
	public var width(get, set):Int;

	/**
		The window the view is in, or `null` for one that is never shown.
	**/
	public var window(default, null):Window;

	/**
		The view's horizontal position in its window.
	**/
	public var x(get, set):Int;

	/**
		The view's vertical position in its window.
	**/
	public var y(get, set):Int;

	/**
		Dispatched when the view has closed, by `close` or with its window.
	**/
	public var onClose(default, null) = new Event<Void->Void>();

	/**
		Dispatched when a page could not be loaded, the view could not be created, or
		the engine reports an error.
	**/
	public var onError(default, null) = new Event<String->Void>();

	/**
		Dispatched when the view takes the focus.
	**/
	public var onFocusIn(default, null) = new Event<Void->Void>();

	/**
		Dispatched when the view loses the focus.
	**/
	public var onFocusOut(default, null) = new Event<Void->Void>();

	/**
		Dispatched when a page has finished loading.
	**/
	public var onLoad(default, null) = new Event<Void->Void>();

	/**
		Dispatched for each message the page posted.
	**/
	public var onMessage(default, null) = new Event<String->Void>();

	/**
		Dispatched before the view goes to a URL, while the engine waits, for `load`
		and for the page's own navigations. Calling `cancel()` on the event stops it
		from going there. A page from `loadHTML` goes nowhere, so it does not dispatch
		this.
	**/
	public var onNavigate(default, null) = new Event<String->Void>();

	/**
		Dispatched after the view went to a URL.
	**/
	public var onURLChange(default, null) = new Event<String->Void>();

	@:noCompletion private var __backend:WebViewBackend;

	/**
		Creates a view in `window`, or with `null`, one that is never shown. Where
		it cannot be created, as `isSupported` says, `onError` is dispatched, and what
		is asked of it does nothing.
	**/
	public function new(window:Window = null, attributes:WebViewAttributes = null)
	{
		this.window = window;
		__backend = new WebViewBackend(this, attributes);
	}

	/**
		Runs `script` in each page from now on, before the page's own scripts.
	**/
	public function addInitScript(script:String):Void
	{
		__backend.addInitScript(script);
	}

	/**
		Takes a picture of what the view shows. The future fails if the engine cannot
		say.
	**/
	public function capture():Future<Image>
	{
		return __backend.capture();
	}

	/**
		Closes the view. It closes with its window, too, unless that close is
		cancelled.
	**/
	public function close():Void
	{
		__backend.close();
	}

	/**
		Runs `script` in the page. The future completes with the value of its last
		statement, as JSON for `haxe.Json.parse`, or fails if the script threw. Where
		an engine does not say that it threw, on Android and older WebView2 Runtimes,
		that is `null`. `undefined` is `null` as well, a promise is not waited for,
		and what a value JSON has no form for gives depends on the engine.
	**/
	public function evaluateJavaScript(script:String):Future<String>
	{
		return __backend.evaluateJavaScript(script);
	}

	/**
		Gives the view the focus.
	**/
	public function focus():Void
	{
		__backend.focus();
	}

	/**
		Goes back to the previous page, if there is one.
	**/
	public function goBack():Void
	{
		__backend.goBack();
	}

	/**
		Goes forward to the next page, if there is one.
	**/
	public function goForward():Void
	{
		__backend.goForward();
	}

	/**
		Goes to `url`.
	**/
	public function load(url:String):Void
	{
		__backend.load(url);
	}

	/**
		Shows `html` as a page of its own.
	**/
	public function loadHTML(html:String):Void
	{
		__backend.loadHTML(html);
	}

	/**
		Moves the view in its window.
	**/
	public function move(x:Int, y:Int):Void
	{
		__backend.setBounds(x, y, __backend.width, __backend.height);
	}

	/**
		Sends `message` to the page, as a `message` event on
		`window.chrome.webview`.
	**/
	public function postMessage(message:String):Void
	{
		__backend.postMessage(message);
	}

	/**
		Saves the current page to `path` as a paginated PDF, with the system's own
		print engine. The future completes with `path`, or fails with why not.
		The folder must exist.
	**/
	public function printToPDF(path:String, options:WebViewPDFOptions = null):Future<String>
	{
		return __backend.printToPDF(path, options);
	}

	/**
		Loads the current page again.
	**/
	public function reload():Void
	{
		__backend.reload();
	}

	/**
		Resizes the view. It does not follow its window by itself, but
		`window.onResize.add(view.resize)` makes it.
	**/
	public function resize(width:Int, height:Int):Void
	{
		__backend.setBounds(__backend.x, __backend.y, width, height);
	}

	/**
		Stops loading the current page.
	**/
	public function stop():Void
	{
		__backend.stop();
	}

	// Get & Set Methods
	@:noCompletion private function get_canGoBack():Bool
	{
		return __backend.getCanGoBack();
	}

	@:noCompletion private function get_canGoForward():Bool
	{
		return __backend.getCanGoForward();
	}

	@:noCompletion private function get_height():Int
	{
		return __backend.height;
	}

	@:noCompletion private function set_height(value:Int):Int
	{
		__backend.setBounds(__backend.x, __backend.y, __backend.width, value);
		return value;
	}

	@:noCompletion private static function get_isSupported():Bool
	{
		return WebViewBackend.isSupported();
	}

	@:noCompletion private function get_title():String
	{
		return __backend.getTitle();
	}

	@:noCompletion private function get_url():String
	{
		return __backend.getURL();
	}

	@:noCompletion private function get_visible():Bool
	{
		return __backend.visible;
	}

	@:noCompletion private function set_visible(value:Bool):Bool
	{
		__backend.setVisible(value);
		return value;
	}

	@:noCompletion private function get_width():Int
	{
		return __backend.width;
	}

	@:noCompletion private function set_width(value:Int):Int
	{
		__backend.setBounds(__backend.x, __backend.y, value, __backend.height);
		return value;
	}

	@:noCompletion private function get_x():Int
	{
		return __backend.x;
	}

	@:noCompletion private function set_x(value:Int):Int
	{
		__backend.setBounds(value, __backend.y, __backend.width, __backend.height);
		return value;
	}

	@:noCompletion private function get_y():Int
	{
		return __backend.y;
	}

	@:noCompletion private function set_y(value:Int):Int
	{
		__backend.setBounds(__backend.x, value, __backend.width, __backend.height);
		return value;
	}
}

#if air
@:noCompletion private typedef WebViewBackend = lime._internal.backend.air.AIRWebView;
#elseif flash
@:noCompletion private typedef WebViewBackend = lime._internal.backend.flash.FlashWebView;
#elseif (js && html5)
@:noCompletion private typedef WebViewBackend = lime._internal.backend.html5.HTML5WebView;
#elseif android
@:noCompletion private typedef WebViewBackend = lime._internal.backend.android.AndroidWebView;
#else
@:noCompletion private typedef WebViewBackend = lime._internal.backend.native.NativeWebView;
#end
