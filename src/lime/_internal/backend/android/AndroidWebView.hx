package lime._internal.backend.android;

#if android
import haxe.crypto.Base64;
import haxe.Json;
import lime._internal.backend.native.NativeApplication;
import lime.app.Future;
import lime.app.Promise;
import lime.graphics.Image;
import lime.system.JNI;
import lime.ui.WebView;
import lime.ui.WebViewAttributes;
import lime.ui.WebViewPDFOptions;

/**
	Drives StageWebView's Java host, which keeps an `android.webkit.WebView` for
	each view. Calls go out over JNI and return at once, and what happens comes
	back through `pollEvents`, once a frame.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeApplication)
class AndroidWebView
{
	private static inline var HOST:String = "org/dimensionscape/stagewebview/StageWebViewHost";

	private static inline var RECORD_SEPARATOR:String = "\x1E";
	private static inline var FIELD_SEPARATOR:String = "\x1F";
	private static inline var PART_SEPARATOR:String = "\x1D";

	private static var methods = new Map<String, Dynamic>();
	private static var views = new Map<Int, AndroidWebView>();

	public var height(default, null):Int;
	public var visible(default, null):Bool;
	public var width(default, null):Int;
	public var x(default, null):Int;
	public var y(default, null):Int;

	private var container:Int;
	private var id:Int;
	private var nextToken:Int;
	private var parent:WebView;
	private var printing:Map<Int, Promise<String>>;
	private var printPaths:Map<Int, String>;

	public function new(parent:WebView, attributes:WebViewAttributes)
	{
		this.parent = parent;

		if (attributes == null) attributes = {};
		x = attributes.x != null ? attributes.x : 0;
		y = attributes.y != null ? attributes.y : 0;
		width = attributes.width != null ? attributes.width : 0;
		height = attributes.height != null ? attributes.height : 0;
		visible = true;
		container = -1;
		nextToken = 1;
		printing = new Map();
		printPaths = new Map();

		if (parent.window != null)
		{
			container = method("createContainer", "(IIII)I")(x, y, width, height);
			method("setContainerVisible", "(IZ)V")(container, true);
			parent.window.onClose.add(close);
		}

		var devTools = attributes.devTools == true #if debug || attributes.devTools == null #end;
		var mediaNeedsUserAction = attributes.mediaNeedsUserAction != false ? 1 : 0;

		// The host keeps its own bridge script when it is not given one
		id = method("create", "(IZLjava/lang/String;ILjava/lang/String;)I")(container, devTools, attributes.userAgent, mediaNeedsUserAction, null);

		if (id > 0)
		{
			views.set(id, this);
			NativeApplication.__updateWebViews = update;
			method("setInterceptNavigation", "(IZ)V")(id, true);
		}
	}

	public function addInitScript(script:String):Void
	{
		if (id > 0) method("addInitScript", "(ILjava/lang/String;)V")(id, script);
	}

	public function capture():Image
	{
		if (id > 0)
		{
			var base64:String = method("capture", "(II)Ljava/lang/String;")(id, 0);
			if (base64 != null && base64 != "") return Image.fromBytes(Base64.decode(base64));
		}

		return null;
	}

	public function close():Void
	{
		if (id > 0)
		{
			if (parent.window != null) parent.window.onClose.remove(close);

			method("destroy", "(I)V")(id);
			views.remove(id);
			id = -1;

			if (container > 0)
			{
				method("destroyContainer", "(I)V")(container);
				container = -1;
			}

			for (token in printing.keys())
			{
				printing.get(token).error("The view has closed");
			}

			printing = new Map();
		}
	}

	public function evaluateJavaScript(script:String):Void
	{
		if (id > 0) method("evaluate", "(ILjava/lang/String;)V")(id, script);
	}

	public function focus():Void
	{
		command("focus");
	}

	public function getCanGoBack():Bool
	{
		return id > 0 && method("canGoBack", "(I)Z")(id);
	}

	public function getCanGoForward():Bool
	{
		return id > 0 && method("canGoForward", "(I)Z")(id);
	}

	public function getTitle():String
	{
		return id > 0 ? method("getTitle", "(I)Ljava/lang/String;")(id) : null;
	}

	public function getURL():String
	{
		return id > 0 ? method("getLocation", "(I)Ljava/lang/String;")(id) : null;
	}

	public function goBack():Void
	{
		command("back");
	}

	public function goForward():Void
	{
		command("forward");
	}

	public static function isSupported():Bool
	{
		return true;
	}

	public function load(url:String):Void
	{
		if (id > 0) method("loadUrl", "(ILjava/lang/String;)V")(id, url);
	}

	public function loadHTML(html:String):Void
	{
		if (id > 0) method("loadHtml", "(ILjava/lang/String;)V")(id, html);
	}

	public function postMessage(message:String):Void
	{
		evaluateJavaScript("window.chrome && window.chrome.webview && window.chrome.webview.__stagewebviewDispatch(" + Json.stringify(message) + ");");
	}

	public function printToPDF(path:String, options:WebViewPDFOptions):Future<String>
	{
		var promise = new Promise<String>();

		if (id > 0)
		{
			// A missing folder fails the same way everywhere
			var target = sys.FileSystem.absolutePath(path);
			var directory = haxe.io.Path.directory(target);

			if (directory != "" && !sys.FileSystem.exists(directory))
			{
				promise.error("The folder does not exist: " + directory);
				return promise.future;
			}

			if (options == null) options = {};

			var token = nextToken++;
			printing.set(token, promise);
			printPaths.set(token, path);

			// Chromium repeats a table's header by itself, and Android's print attributes have no scale or background option
			method("printToPdf", "(IILjava/lang/String;DDDDDDZ)V")(id, token, target, options.pageWidth != null ? options.pageWidth : 8.5,
				options.pageHeight != null ? options.pageHeight : 11, options.marginTop != null ? options.marginTop : 0.4,
				options.marginRight != null ? options.marginRight : 0.4, options.marginBottom != null ? options.marginBottom : 0.4,
				options.marginLeft != null ? options.marginLeft : 0.4, options.landscape == true);

			return promise.future;
		}

		promise.error("The view is not available");
		return promise.future;
	}

	public function reload():Void
	{
		command("reload");
	}

	public function setBounds(x:Int, y:Int, width:Int, height:Int):Void
	{
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;

		if (container > 0) method("moveContainer", "(IIIII)V")(container, x, y, width, height);
	}

	public function setVisible(value:Bool):Void
	{
		visible = value;

		if (container > 0) method("setContainerVisible", "(IZ)V")(container, value);
	}

	public function stop():Void
	{
		command("stop");
	}

	private function command(name:String):Void
	{
		if (id > 0) method("command", "(ILjava/lang/String;)V")(id, name);
	}

	private function dispatch(type:String, payload:String):Void
	{
		switch (type)
		{
			case "changing":
				// A token of 0 only tells of a navigation that is already going ahead
				var separator = payload.indexOf(PART_SEPARATOR);
				var token = Std.parseInt(payload.substring(0, separator));
				var event = parent.onNavigate;
				event.dispatch(payload.substring(separator + 1));

				if (token != null && token > 0)
				{
					method("resolveNavigation", "(IZ)V")(token, event.canceled);
				}

			case "complete":
				parent.onLoad.dispatch();

			case "error":
				parent.onError.dispatch(payload);

			case "focusIn":
				parent.onFocusIn.dispatch();

			case "focusOut":
				parent.onFocusOut.dispatch();

			case "location":
				parent.onURLChange.dispatch(payload);

			case "message":
				parent.onMessage.dispatch(payload);

			case "pdf":
				var parts = payload.split(PART_SEPARATOR);
				var token = Std.parseInt(parts[0]);
				var promise = printing.get(token);
				var path = printPaths.get(token);
				printing.remove(token);
				printPaths.remove(token);

				if (promise != null)
				{
					if (parts[1] == "1")
					{
						promise.complete(path);
					}
					else
					{
						promise.error(parts.slice(2).join(PART_SEPARATOR));
					}
				}

			default:
		}
	}

	private static function method(name:String, signature:String):Dynamic
	{
		var value = methods.get(name);

		if (value == null)
		{
			value = JNI.createStaticMethod(HOST, name, signature);
			methods.set(name, value);
		}

		return value;
	}

	private static function update():Void
	{
		var events:String = method("pollEvents", "()Ljava/lang/String;")();
		if (events == null || events == "") return;

		for (record in events.split(RECORD_SEPARATOR))
		{
			var first = record.indexOf(FIELD_SEPARATOR);
			var second = first >= 0 ? record.indexOf(FIELD_SEPARATOR, first + 1) : -1;
			if (second < 0) continue;

			var view = views.get(Std.parseInt(record.substring(0, first)));
			if (view != null) view.dispatch(record.substring(first + 1, second), record.substring(second + 1));
		}
	}
}
#end
