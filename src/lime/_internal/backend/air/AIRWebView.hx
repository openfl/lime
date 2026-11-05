package lime._internal.backend.air;

import flash.display.BitmapData;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.LocationChangeEvent;
import flash.geom.Rectangle;
import flash.media.StageWebView;
import lime.app.Future;
import lime.graphics.Image;
import lime.ui.WebView;
import lime.ui.WebViewAttributes;
import lime.ui.WebViewPDFOptions;

/**
	AIR's own `StageWebView`, which has no bridge between the page and the
	application, and no way to read what a script gives.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class AIRWebView
{
	private static inline var WINDOW_CLOSE_PRIORITY:Int = -9999;

	public var height(default, null):Int;
	public var visible(default, null):Bool;
	public var width(default, null):Int;
	public var x(default, null):Int;
	public var y(default, null):Int;

	private var initScripts:Array<String>;
	private var parent:WebView;
	private var view:StageWebView;

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

		if (!isSupported())
		{
			haxe.Timer.delay(function() parent.onError.dispatch("The view could not be created"), 0);
			return;
		}

		view = new StageWebView();
		view.mediaPlaybackRequiresUserAction = attributes.autoplay != true;
		view.addEventListener(Event.COMPLETE, onComplete);
		view.addEventListener(ErrorEvent.ERROR, onError);
		view.addEventListener(FocusEvent.FOCUS_IN, onFocusIn);
		view.addEventListener(FocusEvent.FOCUS_OUT, onFocusOut);
		view.addEventListener(LocationChangeEvent.LOCATION_CHANGE, onLocationChange);
		view.addEventListener(LocationChangeEvent.LOCATION_CHANGING, onLocationChanging);

		if (window != null) window.onClose.add(close, false, WINDOW_CLOSE_PRIORITY);

		updateView();
	}

	public function addInitScript(script:String):Void
	{
		initScripts.push(script);
	}

	public function capture():Future<Image>
	{
		if (view == null || view.stage == null || width <= 0 || height <= 0)
		{
			return cast Future.withError("The view does not show");
		}

		var bitmapData = new BitmapData(width, height);
		view.drawViewPortToBitmapData(bitmapData);
		return Future.withValue(Image.fromBitmapData(bitmapData));
	}

	public function close():Void
	{
		if (view != null)
		{
			if (parent.window != null) parent.window.onClose.remove(close);

			view.dispose();
			view = null;

			parent.onClose.dispatch();
		}
	}

	public function evaluateJavaScript(script:String):Future<String>
	{
		if (view == null) return cast Future.withError("The view is not available");

		view.loadURL("javascript:" + StringTools.urlEncode(script));
		return Future.withValue("null");
	}

	public function focus():Void
	{
		if (view != null) view.assignFocus();
	}

	public function getCanGoBack():Bool
	{
		return view != null && view.isHistoryBackEnabled;
	}

	public function getCanGoForward():Bool
	{
		return view != null && view.isHistoryForwardEnabled;
	}

	public function getTitle():String
	{
		return view != null ? view.title : null;
	}

	public function getURL():String
	{
		return view != null ? view.location : null;
	}

	public function goBack():Void
	{
		if (view != null) view.historyBack();
	}

	public function goForward():Void
	{
		if (view != null) view.historyForward();
	}

	public static function isSupported():Bool
	{
		return StageWebView.isSupported;
	}

	public function load(url:String):Void
	{
		if (view != null) view.loadURL(url);
	}

	public function loadHTML(html:String):Void
	{
		if (view == null) return;

		var scripts = "";

		for (script in initScripts)
		{
			scripts += "<script>" + script + "</script>";
		}

		// At the start of the document, ahead of the page's own scripts
		var head = ~/<head[^>]*>/i;
		view.loadString(head.match(html) ? head.matchedLeft() + head.matched(0) + scripts + head.matchedRight() : scripts + html, "text/html");
	}

	public function postMessage(message:String):Void {}

	public function printToPDF(path:String, options:WebViewPDFOptions):Future<String>
	{
		return cast Future.withError("AIR cannot save a page as a PDF");
	}

	public function reload():Void
	{
		if (view != null) view.reload();
	}

	public function setBounds(x:Int, y:Int, width:Int, height:Int):Void
	{
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;
		updateView();
	}

	public function setVisible(value:Bool):Void
	{
		visible = value;
		updateView();
	}

	public function stop():Void
	{
		if (view != null) view.stop();
	}

	private function onComplete(_:Event):Void
	{
		parent.onLoad.dispatch();
	}

	private function onError(event:ErrorEvent):Void
	{
		parent.onError.dispatch(event.text);
	}

	private function onFocusIn(_:FocusEvent):Void
	{
		parent.onFocusIn.dispatch();
	}

	private function onFocusOut(_:FocusEvent):Void
	{
		parent.onFocusOut.dispatch();
	}

	private function onLocationChange(event:LocationChangeEvent):Void
	{
		parent.onURLChange.dispatch(event.location);
	}

	private function onLocationChanging(event:LocationChangeEvent):Void
	{
		parent.onNavigate.dispatch(event.location);
		if (parent.onNavigate.canceled) event.preventDefault();
	}

	private function updateView():Void
	{
		if (view == null) return;

		// A view port must have a size, and a view leaves the screen by leaving the stage
		var window = parent.window;
		view.viewPort = new Rectangle(x, y, width > 0 ? width : 1, height > 0 ? height : 1);
		view.stage = window != null && visible && width > 0 && height > 0 ? window.stage : null;
	}
}
