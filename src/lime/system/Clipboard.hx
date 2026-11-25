package lime.system;

import lime._internal.backend.native.NativeCFFI;
import lime.app.Application;
import haxe.io.Bytes;
import lime.app.Event;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.system.CFFI;
import lime.utils.UInt8Array;
#if flash
import flash.desktop.Clipboard as FlashClipboard;
#elseif (js && html5)
import lime._internal.backend.html5.HTML5Clipboard;
import lime._internal.backend.html5.HTML5Window;
#end

/**
	Reads and writes the system clipboard: its text, and with `hasFormat`,
	`getData` and `setData` its HTML, rich text, URL, files and images.

	Availability of the other formats: Windows, macOS, and Linux with GTK 3,
	through native-desktop. HTML5 writes text, HTML and images with the
	browser's Clipboard API, which needs a secure context and a user action,
	and reads what the last paste into the page held, as browsers only give
	pages the clipboard then; `onUpdate` is dispatched once a pasted image
	is ready. Other targets only have text.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.ui.Window)
class Clipboard
{
	/**
		Dispatched when the clipboard text changes.
	**/
	public static var onUpdate = new Event<Void->Void>();

	/**
		The text currently stored in the clipboard.
	**/
	public static var text(get, set):String;

	private static var _text:String;

	// What setData has set since the last clear, which is all written at once, as the systems replace the
	// whole clipboard when it is set
	@:noCompletion private static var __items:Map<Int, Dynamic> = new Map();
	@:noCompletion private static var __updated = false;

	private static function __update():Void
	{
		var cacheText = _text;
		_text = null;

		#if (lime_cffi && !macro)
		_text = CFFI.stringValue(NativeCFFI.lime_clipboard_get_text());
		#elseif flash
		if (FlashClipboard.generalClipboard.hasFormat(TEXT_FORMAT))
		{
			_text = FlashClipboard.generalClipboard.getData(TEXT_FORMAT);
		}
		#elseif (js || html5)
		_text = cacheText;
		#end
		__updated = true;

		if (_text != cacheText)
		{
			onUpdate.dispatch();
		}
	}

	/**
		Empties the clipboard, and forgets what `setData` set.
	**/
	public static function clear():Void
	{
		__items = new Map();

		#if (lime_cffi && !macro)
		if (!NativeCFFI.lime_clipboard_set_items(__encodeItems(__items)))
		{
			NativeCFFI.lime_clipboard_set_text("");
		}
		#elseif (js && html5)
		HTML5Clipboard.write(__items);
		#elseif flash
		FlashClipboard.generalClipboard.clear();
		#end

		__update();
	}

	/**
		The clipboard's data in `format`, or `null` when it holds none: a
		`String`, an `Array<String>` of paths for `FILE_LIST`, or an `Image`.
	**/
	public static function getData(format:ClipboardFormat):Dynamic
	{
		if (format == TEXT) return text;

		#if (lime_cffi && !macro)
		switch (format)
		{
			case FILE_LIST:
				var files:String = CFFI.stringValue(NativeCFFI.lime_clipboard_get_files());
				return files == null ? null : (files == "" ? [] : files.split("\n"));

			case IMAGE:
				var bytes:Bytes = NativeCFFI.lime_clipboard_get_image(Bytes.alloc(0));
				if (bytes == null || bytes.length < 8) return null;

				var width = bytes.getInt32(0);
				var height = bytes.getInt32(4);
				if (width <= 0 || height <= 0) return null;

				var buffer = new ImageBuffer(new UInt8Array(bytes.sub(8, width * height * 4)), width, height, 32, RGBA32);
				buffer.premultiplied = false;
				return new Image(buffer);

			default:
				return CFFI.stringValue(NativeCFFI.lime_clipboard_get_format_text(format));
		}
		#elseif (js && html5)
		return HTML5Clipboard.getData(format);
		#else
		return null;
		#end
	}

	/**
		Whether the clipboard holds data in `format`.
	**/
	public static function hasFormat(format:ClipboardFormat):Bool
	{
		#if (lime_cffi && !macro)
		if (format == TEXT) return text != null;
		return NativeCFFI.lime_clipboard_has_format(format);
		#elseif (js && html5)
		return HTML5Clipboard.hasFormat(format);
		#else
		return format == TEXT && text != null;
		#end
	}

	/**
		Puts `data` on the clipboard in `format`, beside what `setData` set
		since the last `clear`, which is written again with it. Setting `text`
		replaces it all. Returns whether the system took it.
	**/
	public static function setData(format:ClipboardFormat, data:Dynamic):Bool
	{
		if (data == null) return false;

		__items.set(format, data);

		#if (lime_cffi && !macro)
		var result = NativeCFFI.lime_clipboard_set_items(__encodeItems(__items));

		// Where only text is supported, as on mobile
		if (!result && format == TEXT) NativeCFFI.lime_clipboard_set_text(data);
		#elseif (js && html5)
		var result = HTML5Clipboard.write(__items);
		#else
		var result = false;
		if (format == TEXT)
		{
			text = data;
			result = true;
		}
		#end

		__update();
		return result || format == TEXT;
	}

	// Little-endian Int32 values: count, then for each item its format and its data, as lime::Clipboard::SetItems and
	// lime::DragDrop::StartDrag read them
	@:noCompletion private static function __encodeItems(items:Map<Int, Dynamic>):Bytes
	{
		var output = new haxe.io.BytesOutput();
		output.bigEndian = false;

		var count = 0;
		for (format in items.keys()) count++;
		output.writeInt32(count);

		for (format in items.keys())
		{
			var data:Dynamic = items.get(format);
			output.writeInt32(format);

			switch ((format : ClipboardFormat))
			{
				case FILE_LIST:
					var files:Array<String> = data;
					output.writeInt32(files.length);

					for (file in files)
					{
						var bytes = Bytes.ofString(file);
						output.writeInt32(bytes.length);
						output.write(bytes);
					}

				case IMAGE:
					var image:Image = data;
					var pixels = image.getPixels(image.rect, RGBA32);
					output.writeInt32(image.width);
					output.writeInt32(image.height);
					output.write(pixels);

				default:
					var bytes = Bytes.ofString(Std.string(data));
					output.writeInt32(bytes.length);
					output.write(bytes);
			}
		}

		return output.getBytes();
	}

	// Get & Set Methods
	private static function get_text():String
	{
		// On some native platforms, __update() is called automatically when the
		// native clipboard changes. On others, __update() needs to be called
		// manually.
		#if (flash || js || html5 || ios || tvos || android)
		__update();
		#elseif linux
		// Xorg won't call __update until we call set_text at least once.
		// Details: SDL_x11clipboard.c calls X11_XSetSelectionOwner,
		// registering this app to receive clipboard events.
		if (_text == null)
		{
			__update();

			// Call set_text while changing as little as possible. (Rich text
			// formatting will unavoidably be lost.)
			set_text(_text);
		}
		#elseif (windows || mac)
		if (!__updated)
		{
			// Lime listens for clipboard updates automatically, but if the
			// clipboard has never been updated since before the app started,
			// we need to populate the initial contents manually
			__update();
		}
		#end

		return _text;
	}

	private static function set_text(value:String):String
	{
		var cacheText = _text;
		_text = value;

		// Setting the text replaces the clipboard, and what setData set with it
		__items = new Map();
		if (value != null) __items.set(ClipboardFormat.TEXT, value);

		#if (lime_cffi && !macro)
		NativeCFFI.lime_clipboard_set_text(value);
		#elseif flash
		FlashClipboard.generalClipboard.setData(TEXT_FORMAT, value);
		#elseif (js && html5)
		var window = Application.current.window;
		if (window != null)
		{
			window.__backend.setClipboard(value);
		}
		#end

		if (_text != cacheText)
		{
			onUpdate.dispatch();
		}

		return value;
	}
}
