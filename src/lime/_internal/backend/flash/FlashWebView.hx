package lime._internal.backend.flash;

import lime.app.Future;
import lime.app.Promise;
import lime.graphics.Image;
import lime.ui.WebView;
import lime.ui.WebViewAttributes;
import lime.ui.WebViewPDFOptions;

class FlashWebView
{
	public var height(default, null):Int;
	public var visible(default, null):Bool;
	public var width(default, null):Int;
	public var x(default, null):Int;
	public var y(default, null):Int;

	public function new(parent:WebView, attributes:WebViewAttributes)
	{
		if (attributes == null) attributes = {};
		var window = parent.window;
		x = attributes.x != null ? attributes.x : 0;
		y = attributes.y != null ? attributes.y : 0;
		width = attributes.width != null ? attributes.width : (window != null ? window.width : 0);
		height = attributes.height != null ? attributes.height : (window != null ? window.height : 0);
		visible = attributes.hidden != true;

		haxe.Timer.delay(function() parent.onError.dispatch("The view could not be created"), 0);
	}

	public function addInitScript(script:String):Void {}

	public function capture():Future<Image>
	{
		return cast Future.withError("The view is not available");
	}

	public function close():Void {}

	public function evaluateJavaScript(script:String):Future<String>
	{
		return cast Future.withError("The view is not available");
	}

	public function focus():Void {}

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
		return null;
	}

	public function getURL():String
	{
		return null;
	}

	public function goBack():Void {}

	public function goForward():Void {}

	public static function isSupported():Bool
	{
		return false;
	}

	public function load(url:String):Void {}

	public function loadHTML(html:String):Void {}

	public function postMessage(message:String):Void {}

	public function printToPDF(path:String, options:WebViewPDFOptions):Future<String>
	{
		var promise = new Promise<String>();
		promise.error("WebViews are not supported on this target");
		return promise.future;
	}

	public function reload():Void {}

	public function setBounds(x:Int, y:Int, width:Int, height:Int):Void
	{
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
	}

	public function setVisible(value:Bool):Void
	{
		visible = value;
	}

	public function stop():Void {}
}
