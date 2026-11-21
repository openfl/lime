package lime.ui;

import haxe.io.Bytes;
import lime._internal.backend.native.NativeCFFI;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.system.CFFI;
import lime.system.ClipboardFormat;
import lime.utils.UInt8Array;

/**
	The data of a drag, in the clipboard's formats: a `String`, an
	`Array<String>` of paths for `FILE_LIST`, or an `Image`.

	A drag over a window, given to `Window.onDragEnter` and `Window.onDrop`,
	can only be read while that listener runs, as the systems only lend it
	for the event, so copy what you need before returning. Data to drag out
	of a window is made with `new DragData()` and `setData`, and passed to
	`Window.startDrag`.

	Availability: Windows, macOS and Linux on X11, through native-desktop,
	and HTML5. On HTML5 a page sees the names of files dragged in, not where
	they are, and drags out carry text, HTML and URLs only.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
class DragData
{
	/**
		Whether windows can take drags and start them on this platform. Where
		they cannot, `Window.onDropFile` still takes files dropped on desktop
		targets.
	**/
	public static var isSupported(get, never):Bool;

	/**
		The actions the drag's source allows, as `DropAction` flags. A drop
		target chooses one of them for `Window.dropAction`.
	**/
	public var allowedActions(default, null):DropAction;

	@:noCompletion private var __active:Bool;
	@:noCompletion private var __items:Map<Int, Dynamic>;
	#if (js && html5)
	@:noCompletion private var __transfer:js.html.DataTransfer;
	#end

	/**
		Makes data to drag out of a window with `Window.startDrag`.
	**/
	public function new()
	{
		allowedActions = COPY | MOVE | LINK;
		__items = new Map();
		__active = false;
	}

	/**
		The data in `format`, or `null` when the drag holds none, or when it
		is read after its event's listeners have returned.
	**/
	public function getData(format:ClipboardFormat):Dynamic
	{
		if (__items != null) return __items.get(format);
		if (!__active) return null;

		#if (lime_cffi && !macro)
		switch (format)
		{
			case FILE_LIST:
				var files:String = CFFI.stringValue(NativeCFFI.lime_drag_data_get_files());
				return files == null ? null : (files == "" ? [] : files.split("\n"));

			case IMAGE:
				var bytes:Bytes = NativeCFFI.lime_drag_data_get_image(Bytes.alloc(0));
				if (bytes == null || bytes.length < 8) return null;

				var width = bytes.getInt32(0);
				var height = bytes.getInt32(4);
				if (width <= 0 || height <= 0) return null;

				var buffer = new ImageBuffer(new UInt8Array(bytes.sub(8, width * height * 4)), width, height, 32, RGBA32);
				buffer.premultiplied = false;
				return new Image(buffer);

			default:
				return CFFI.stringValue(NativeCFFI.lime_drag_data_get_format_text(format));
		}
		#elseif (js && html5)
		return __getTransferData(format);
		#else
		return null;
		#end
	}

	/**
		Whether the drag holds data in `format`. Over a window, this can be
		read as the drag enters, while the data itself may only be given on
		drop, as on HTML5.
	**/
	public function hasFormat(format:ClipboardFormat):Bool
	{
		if (__items != null) return __items.exists(format);
		if (!__active) return false;

		#if (lime_cffi && !macro)
		return NativeCFFI.lime_drag_data_has_format(format);
		#elseif (js && html5)
		return __transfer != null && __getTransferTypes(format).length > 0;
		#else
		return false;
		#end
	}

	/**
		Puts `data` in `format`, for a drag out with `Window.startDrag`.
		Returns `false` for the data of a drag over a window, which cannot be
		changed.
	**/
	public function setData(format:ClipboardFormat, data:Dynamic):Bool
	{
		if (__items == null || data == null) return false;
		__items.set(format, data);
		return true;
	}

	@:noCompletion private static function __fromSystem(allowedActions:DropAction):DragData
	{
		var data = new DragData();
		data.allowedActions = allowedActions;
		data.__items = null;
		data.__active = true;
		return data;
	}

	#if (js && html5)
	@:noCompletion private static function __fromTransfer(transfer:js.html.DataTransfer, allowedActions:DropAction):DragData
	{
		var data = __fromSystem(allowedActions);
		data.__transfer = transfer;
		return data;
	}

	@:noCompletion private function __getTransferData(format:ClipboardFormat):Dynamic
	{
		if (__transfer == null) return null;

		switch (format)
		{
			case FILE_LIST:
				// Pages see the names of files dragged in, not where they are
				if (__transfer.files == null || __transfer.files.length == 0) return null;
				return [for (i in 0...__transfer.files.length) __transfer.files[i].name];

			case IMAGE:
				// Images only come as files, which take a while to decode
				return null;

			default:
				var types = __getTransferTypes(format);
				if (types.length == 0) return null;

				var text = __transfer.getData(types[0]);
				if (text == null || text == "") return null;

				if (format == URL)
				{
					// The first link that is not a comment
					for (line in text.split("\n"))
					{
						line = StringTools.trim(line);
						if (line != "" && line.charAt(0) != "#") return line;
					}
					return null;
				}

				return text;
		}
	}

	@:noCompletion private function __getTransferTypes(format:ClipboardFormat):Array<String>
	{
		var types:Array<String> = untyped Array.from(__transfer.types);
		var wanted = switch (format)
		{
			case TEXT: ["text/plain", "text"];
			case HTML: ["text/html"];
			case RICH_TEXT: ["text/rtf"];
			case URL: ["text/uri-list", "url"];
			case FILE_LIST: ["Files"];
			default: [];
		}

		return [for (type in wanted) if (types.indexOf(type) > -1) type];
	}
	#end

	// Get & Set Methods
	private static function get_isSupported():Bool
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_drag_drop_is_supported();
		#elseif (js && html5)
		return true;
		#else
		return false;
		#end
	}
}
