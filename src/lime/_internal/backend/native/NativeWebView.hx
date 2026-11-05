package lime._internal.backend.native;

import haxe.crypto.Base64;
import lime.app.Future;
import lime.app.Promise;
import lime.graphics.Image;
import lime.system.CFFI;
import lime.ui.MouseButton;
import lime.ui.WebView;
import lime.ui.WebViewAttributes;
import lime.ui.WebViewPDFOptions;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeApplication)
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.ui.Window)
class NativeWebView
{
	// See project/include/ui/WebView.h
	private static inline var FLAG_CONTEXT_MENU:Int = 0x01;
	private static inline var FLAG_KEYBOARD_SHORTCUTS:Int = 0x02;
	private static inline var FLAG_DEV_TOOLS:Int = 0x04;
	private static inline var FLAG_STATUS_BAR:Int = 0x08;
	private static inline var FLAG_ZOOM:Int = 0x10;
	private static inline var FLAG_MEDIA_NEEDS_USER_ACTION:Int = 0x20;

	private static inline var RECORD_SEPARATOR:String = "\x1E";
	private static inline var FIELD_SEPARATOR:String = "\x1F";
	private static inline var PART_SEPARATOR:String = "\x1D";

	private static var views = new Map<Int, NativeWebView>();

	public var height(default, null):Int;
	public var visible(default, null):Bool;
	public var width(default, null):Int;
	public var x(default, null):Int;
	public var y(default, null):Int;

	private var handle:Dynamic;
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
		id = -1;
		nextToken = 1;
		printing = new Map();
		printPaths = new Map();

		#if (!macro && lime_cffi)
		var flags = 0;
		if (attributes.contextMenu != false) flags |= FLAG_CONTEXT_MENU;
		if (attributes.keyboardShortcuts != false) flags |= FLAG_KEYBOARD_SHORTCUTS;
		if (attributes.devTools == true #if debug || attributes.devTools == null #end) flags |= FLAG_DEV_TOOLS;
		if (attributes.statusBar != false) flags |= FLAG_STATUS_BAR;
		if (attributes.zoom != false) flags |= FLAG_ZOOM;
		if (attributes.mediaNeedsUserAction != false) flags |= FLAG_MEDIA_NEEDS_USER_ACTION;

		if (isSupported())
		{
			if (Lambda.count(views) == 0) register();

			var window = parent.window;
			var windowHandle:Dynamic = window != null ? window.__backend.handle : null;
			var scale = hostScale();

			handle = NativeCFFI.lime_web_view_create(windowHandle, Std.int(x * scale), Std.int(y * scale), Std.int(width * scale), Std.int(height * scale),
				flags, attributes.userAgent);

			if (handle != null)
			{
				id = NativeCFFI.lime_web_view_get_id(handle);
				views.set(id, this);

				if (window != null)
				{
					window.onClose.add(close);
					window.onMouseDown.add(onWindowMouseDown);
				}
			}
		}
		#end
	}

	public function addInitScript(script:String):Void
	{
		#if (!macro && lime_cffi)
		if (handle != null) NativeCFFI.lime_web_view_add_init_script(handle, script);
		#end
	}

	public function capture():Image
	{
		#if (!macro && lime_cffi)
		if (handle != null)
		{
			var base64:String = CFFI.stringValue(NativeCFFI.lime_web_view_capture(handle));
			if (base64 != null) return Image.fromBytes(Base64.decode(base64));
		}
		#end

		return null;
	}

	public function close():Void
	{
		if (handle != null)
		{
			var window = parent.window;

			if (window != null)
			{
				window.onClose.remove(close);
				window.onMouseDown.remove(onWindowMouseDown);
			}

			#if (!macro && lime_cffi)
			NativeCFFI.lime_web_view_close(handle);
			#end

			views.remove(id);
			handle = null;

			for (token in printing.keys())
			{
				printing.get(token).error("The view has closed");
			}

			printing = new Map();
		}
	}

	public function evaluateJavaScript(script:String):Void
	{
		#if (!macro && lime_cffi)
		if (handle != null) NativeCFFI.lime_web_view_evaluate_java_script(handle, script);
		#end
	}

	public function focus():Void
	{
		#if (!macro && lime_cffi)
		if (handle != null) NativeCFFI.lime_web_view_focus(handle);
		#end
	}

	public function getCanGoBack():Bool
	{
		#if (!macro && lime_cffi)
		if (handle != null) return NativeCFFI.lime_web_view_get_can_go_back(handle);
		#end

		return false;
	}

	public function getCanGoForward():Bool
	{
		#if (!macro && lime_cffi)
		if (handle != null) return NativeCFFI.lime_web_view_get_can_go_forward(handle);
		#end

		return false;
	}

	public function getTitle():String
	{
		#if (!macro && lime_cffi)
		if (handle != null) return CFFI.stringValue(NativeCFFI.lime_web_view_get_title(handle));
		#end

		return null;
	}

	public function getURL():String
	{
		#if (!macro && lime_cffi)
		if (handle != null) return CFFI.stringValue(NativeCFFI.lime_web_view_get_url(handle));
		#end

		return null;
	}

	public function goBack():Void
	{
		#if (!macro && lime_cffi)
		if (handle != null) NativeCFFI.lime_web_view_go_back(handle);
		#end
	}

	public function goForward():Void
	{
		#if (!macro && lime_cffi)
		if (handle != null) NativeCFFI.lime_web_view_go_forward(handle);
		#end
	}

	public static function isSupported():Bool
	{
		#if (!macro && lime_cffi)
		return NativeCFFI.lime_web_view_is_supported();
		#else
		return false;
		#end
	}

	public function load(url:String):Void
	{
		#if (!macro && lime_cffi)
		if (handle != null) NativeCFFI.lime_web_view_load(handle, url);
		#end
	}

	public function loadHTML(html:String):Void
	{
		#if (!macro && lime_cffi)
		if (handle != null) NativeCFFI.lime_web_view_load_html(handle, html);
		#end
	}

	public function postMessage(message:String):Void
	{
		#if (!macro && lime_cffi)
		if (handle != null) NativeCFFI.lime_web_view_post_message(handle, message);
		#end
	}

	public function printToPDF(path:String, options:WebViewPDFOptions):Future<String>
	{
		var promise = new Promise<String>();

		#if (!macro && lime_cffi)
		if (handle != null)
		{
			// A missing folder fails the same way everywhere, and macOS's engine would never answer
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

			NativeCFFI.lime_web_view_print_to_pdf(handle, target, {
				pageWidth: options.pageWidth != null ? options.pageWidth : 8.5,
				pageHeight: options.pageHeight != null ? options.pageHeight : 11,
				marginTop: options.marginTop != null ? options.marginTop : 0.4,
				marginRight: options.marginRight != null ? options.marginRight : 0.4,
				marginBottom: options.marginBottom != null ? options.marginBottom : 0.4,
				marginLeft: options.marginLeft != null ? options.marginLeft : 0.4,
				scale: options.scale != null ? options.scale : 1.0,
				landscape: options.landscape == true,
				printBackground: options.printBackground != false,
				repeatTableHeaders: options.repeatTableHeaders != false
			}, token);

			return promise.future;
		}
		#end

		promise.error("The view is not available");
		return promise.future;
	}

	public function reload():Void
	{
		#if (!macro && lime_cffi)
		if (handle != null) NativeCFFI.lime_web_view_reload(handle);
		#end
	}

	public function setBounds(x:Int, y:Int, width:Int, height:Int):Void
	{
		this.x = x;
		this.y = y;
		this.width = width;
		this.height = height;

		#if (!macro && lime_cffi)
		if (handle != null)
		{
			var scale = hostScale();
			NativeCFFI.lime_web_view_set_bounds(handle, Std.int(x * scale), Std.int(y * scale), Std.int(width * scale), Std.int(height * scale));
		}
		#end
	}

	public function setVisible(value:Bool):Void
	{
		visible = value;

		#if (!macro && lime_cffi)
		if (handle != null) NativeCFFI.lime_web_view_set_visible(handle, value);
		#end
	}

	public function stop():Void
	{
		#if (!macro && lime_cffi)
		if (handle != null) NativeCFFI.lime_web_view_stop(handle);
		#end
	}

	private function dispatch(type:String, payload:String):Void
	{
		switch (type)
		{
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

	// Host windows are in pixels on Windows, where a window's own coordinates are not
	private function hostScale():Float
	{
		#if windows
		var window = parent.window;
		return window != null && window.scale > 0 ? window.scale : 1;
		#else
		return 1;
		#end
	}

	private function onWindowMouseDown(_:Float, _:Float, _:MouseButton):Void
	{
		// A click on the window's own content takes the focus back from the view
		#if (!macro && lime_cffi)
		if (handle != null) NativeCFFI.lime_web_view_release_focus(handle);
		#end
	}

	private static function register():Void
	{
		#if (!macro && lime_cffi)
		NativeApplication.__updateWebViews = update;

		NativeCFFI.lime_web_view_set_navigation_callback(onNavigate);
		#end
	}

	private static function onNavigate():Void
	{
		#if (!macro && lime_cffi)
		var navigation:String = CFFI.stringValue(NativeCFFI.lime_web_view_get_navigation());
		var separator = navigation.indexOf(FIELD_SEPARATOR);
		var view = views.get(Std.parseInt(navigation.substring(0, separator)));

		if (view != null)
		{
			var event = view.parent.onNavigate;
			event.dispatch(navigation.substring(separator + 1));
			if (event.canceled) NativeCFFI.lime_web_view_cancel_navigation();
		}
		#end
	}

	private static function update():Void
	{
		#if (!macro && lime_cffi)
		var events:String = CFFI.stringValue(NativeCFFI.lime_web_view_poll_events());
		if (events == null) return;

		for (record in events.split(RECORD_SEPARATOR))
		{
			var first = record.indexOf(FIELD_SEPARATOR);
			var second = first >= 0 ? record.indexOf(FIELD_SEPARATOR, first + 1) : -1;
			if (second < 0) continue;

			var view = views.get(Std.parseInt(record.substring(0, first)));
			if (view != null) view.dispatch(record.substring(first + 1, second), record.substring(second + 1));
		}
		#end
	}
}
