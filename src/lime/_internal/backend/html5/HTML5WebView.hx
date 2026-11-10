package lime._internal.backend.html5;

import js.html.Element;
import js.html.Event;
import js.html.IFrameElement;
import js.html.MessageEvent;
import js.Browser;
import lime.app.Future;
import lime.graphics.Image;
import lime.ui.WebView;
import lime.ui.WebViewAttributes;
import lime.ui.WebViewPDFOptions;

/**
	An `<iframe>` over the window. The browser keeps other sites to themselves, so
	for a page from elsewhere `title` and `url` say what they can, and scripts and
	the bridge only reach pages from `loadHTML` or the application's own site.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class HTML5WebView
{
	private static inline var BRIDGE:String = "<script>(function () {
	var listeners = [];
	var bridge = {
		postMessage: function (message) {
			parent.postMessage({limeWebView: typeof message === 'string' ? message : JSON.stringify(message)}, '*');
		},
		addEventListener: function (type, listener) {
			if (type === 'message' && typeof listener === 'function' && listeners.indexOf(listener) < 0) { listeners.push(listener); }
		},
		removeEventListener: function (type, listener) {
			var index = listeners.indexOf(listener);
			if (type === 'message' && index >= 0) { listeners.splice(index, 1); }
		}
	};
	window.addEventListener('message', function (event) {
		if (event.source !== parent) { return; }
		var message = { data: event.data, source: bridge };
		listeners.slice().forEach(function (listener) { listener.call(bridge, message); });
	});
	window.chrome = window.chrome || {};
	window.chrome.webview = bridge;
})();</script>";

	// After what might cancel the close, and just before the application lets the window go
	private static inline var WINDOW_CLOSE_PRIORITY:Int = -9999;

	private static var listening:Bool = false;
	private static var views:Array<HTML5WebView> = [];

	public var height(default, null):Int;
	public var visible(default, null):Bool;
	public var width(default, null):Int;
	public var x(default, null):Int;
	public var y(default, null):Int;

	private var frame:IFrameElement;
	private var initScripts:Array<String>;
	private var lastURL:String;
	private var parent:WebView;

	public function new(parent:WebView, attributes:WebViewAttributes)
	{
		this.parent = parent;

		if (attributes == null) attributes = {};
		var window = parent.window;
		x = attributes.x != null ? attributes.x : 0;
		y = attributes.y != null ? attributes.y : 0;
		width = attributes.width != null ? attributes.width : (window != null ? window.width : 0);
		height = attributes.height != null ? attributes.height : (window != null ? window.height : 0);
		visible = attributes.hidden != true;
		initScripts = [];

		frame = cast Browser.document.createElement("iframe");
		frame.style.border = "0";
		frame.style.position = "absolute";
		frame.addEventListener("load", onFrameLoad);
		frame.addEventListener("focus", function(_) parent.onFocusIn.dispatch());
		frame.addEventListener("blur", function(_) parent.onFocusOut.dispatch());

		var container:Element = window != null ? window.element : Browser.document.body;
		if (container == null) container = Browser.document.body;
		container.appendChild(frame);

		updateFrame();
		views.push(this);

		if (window != null) window.onClose.add(close, false, WINDOW_CLOSE_PRIORITY);

		if (!listening)
		{
			listening = true;
			Browser.window.addEventListener("message", onWindowMessage);
		}
	}

	public function addInitScript(script:String):Void
	{
		initScripts.push(script);
	}

	public function capture():Future<Image>
	{
		return cast Future.withError("A browser cannot capture a page");
	}

	public function close():Void
	{
		if (frame != null)
		{
			if (parent.window != null) parent.window.onClose.remove(close);

			if (frame.parentNode != null) frame.parentNode.removeChild(frame);
			frame = null;
			views.remove(this);

			parent.onClose.dispatch();
		}
	}

	public function evaluateJavaScript(script:String):Future<String>
	{
		if (frame == null) return cast Future.withError("The view is not available");

		try
		{
			var json:String = (cast Browser.window).JSON.stringify((cast frame.contentWindow).eval(script));
			return Future.withValue(json != null ? json : "null");
		}
		catch (error:Dynamic)
		{
			return cast Future.withError(Std.string(error));
		}
	}

	public function focus():Void
	{
		if (frame != null) frame.focus();
	}

	public function getCanGoBack():Bool
	{
		return false;
	}

	public function getCanGoForward():Bool
	{
		return false;
	}

	public function getTitle():String
	{
		if (frame == null) return null;

		try
		{
			return frame.contentDocument.title;
		}
		catch (error:Dynamic)
		{
			return null;
		}
	}

	public function getURL():String
	{
		if (frame == null) return null;

		try
		{
			var url = frame.contentWindow.location.href;
			return url == "about:srcdoc" ? "about:blank" : url;
		}
		catch (error:Dynamic)
		{
			return lastURL;
		}
	}

	public function goBack():Void
	{
		history(-1);
	}

	public function goForward():Void
	{
		history(1);
	}

	public static function isSupported():Bool
	{
		return true;
	}

	public function load(url:String):Void
	{
		if (frame == null) return;

		var event = parent.onNavigate;
		event.dispatch(url);

		if (!event.canceled)
		{
			lastURL = url;
			frame.removeAttribute("srcdoc");
			frame.src = url;
		}
	}

	public function loadHTML(html:String):Void
	{
		if (frame == null) return;

		var scripts = BRIDGE;

		for (script in initScripts)
		{
			scripts += "<script>" + script + "</script>";
		}

		// At the start of the document, ahead of the page's own scripts
		var head = ~/<head[^>]*>/i;
		var root = ~/<html[^>]*>/i;

		if (head.match(html))
		{
			html = head.matchedLeft() + head.matched(0) + scripts + head.matchedRight();
		}
		else if (root.match(html))
		{
			html = root.matchedLeft() + root.matched(0) + scripts + root.matchedRight();
		}
		else
		{
			html = scripts + html;
		}

		frame.srcdoc = html;
	}

	public function postMessage(message:String):Void
	{
		if (frame != null) frame.contentWindow.postMessage(message, "*");
	}

	public function printToPDF(path:String, options:WebViewPDFOptions):Future<String>
	{
		return cast Future.withError("A browser cannot save a page as a PDF");
	}

	public function reload():Void
	{
		if (frame == null) return;

		try
		{
			frame.contentWindow.location.reload();
		}
		catch (error:Dynamic)
		{
			frame.src = frame.src;
		}
	}

	public function setBounds(x:Int, y:Int, width:Int, height:Int):Void
	{
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		updateFrame();
	}

	public function setVisible(value:Bool):Void
	{
		visible = value;
		updateFrame();
	}

	public function stop():Void
	{
		if (frame == null) return;

		try
		{
			frame.contentWindow.stop();
		}
		catch (error:Dynamic) {}
	}

	private function history(delta:Int):Void
	{
		if (frame == null) return;

		try
		{
			frame.contentWindow.history.go(delta);
		}
		catch (error:Dynamic) {}
	}

	private function onFrameLoad(_:Event):Void
	{
		var url = getURL();

		if (url != null && url != lastURL)
		{
			lastURL = url;
			parent.onURLChange.dispatch(url);
		}

		parent.onLoad.dispatch();
	}

	private static function onWindowMessage(event:MessageEvent):Void
	{
		var data:Dynamic = event.data;
		if (data == null || data.limeWebView == null) return;

		for (view in views)
		{
			if (view.frame != null && view.frame.contentWindow == event.source)
			{
				view.parent.onMessage.dispatch(data.limeWebView);
				return;
			}
		}
	}

	private function updateFrame():Void
	{
		if (frame == null) return;

		frame.style.left = x + "px";
		frame.style.top = y + "px";
		frame.style.width = width + "px";
		frame.style.height = height + "px";
		frame.style.display = visible && parent.window != null ? "block" : "none";
	}
}
