package lime._internal.backend.html5;

import haxe.io.Bytes;
import js.Browser;
import js.html.CanvasElement;
import lime.graphics.Image;
import lime.system.Clipboard;
import lime.system.ClipboardFormat;

/**
	The clipboard formats beyond text on HTML5. Browsers only give a page
	what the clipboard holds as something is pasted into it, so what the last
	paste held is kept, and writing goes through the asynchronous Clipboard
	API, which takes text, HTML and PNG images.
**/
@:access(lime.system.Clipboard)
class HTML5Clipboard
{
	private static var data:Map<Int, Dynamic> = new Map();
	private static var listening:Bool = false;

	public static function getData(format:ClipboardFormat):Dynamic
	{
		listen();
		return data.get(format);
	}

	public static function hasFormat(format:ClipboardFormat):Bool
	{
		listen();
		return data.exists(format);
	}

	public static function write(items:Map<Int, Dynamic>):Bool
	{
		listen();

		var clipboard:Dynamic = untyped Browser.navigator.clipboard;
		var itemClass:Dynamic = untyped window.ClipboardItem;
		if (clipboard == null || clipboard.write == null || itemClass == null) return false;

		var types:Dynamic = {};
		var count = 0;

		for (format in items.keys())
		{
			var value:Dynamic = items.get(format);

			switch ((format : ClipboardFormat))
			{
				case TEXT:
					Reflect.setField(types, "text/plain", new js.html.Blob([Std.string(value)], {type: "text/plain"}));
					count++;

				case HTML:
					Reflect.setField(types, "text/html", new js.html.Blob([Std.string(value)], {type: "text/html"}));
					count++;

				case IMAGE:
					// The PNG is made as the browser asks for it
					var image:Image = value;
					Reflect.setField(types, "image/png", new #if haxe4 js.lib.Promise #else js.Promise #end(function(resolve, reject)
					{
						var canvas:CanvasElement = cast Browser.document.createElement("canvas");
						canvas.width = image.width;
						canvas.height = image.height;
						var pixels = image.getPixels(image.rect, RGBA32);
						var imageData = canvas.getContext2d().createImageData(image.width, image.height);
						imageData.data.set(cast pixels.getData());
						canvas.getContext2d().putImageData(imageData, 0, 0);
						canvas.toBlob(function(blob) blob != null ? resolve(blob) : reject("No PNG"), "image/png");
					}));
					count++;

				default:
					// Browsers take no rich text, URLs or files from a page
			}
		}

		var known = new Map<Int, Dynamic>();
		for (format in items.keys()) known.set(format, items.get(format));

		if (count == 0)
		{
			// Clearing writes an empty text
			if (Lambda.count(items) == 0) clipboard.writeText("");
			data = known;
			return Lambda.count(items) == 0;
		}

		var promise:Dynamic = clipboard.write([#if haxe4 js.Syntax.construct(itemClass, types) #else untyped __new__(itemClass, types) #end]);

		promise.then(function(_)
		{
			// What was written is what a paste in the page would read
			data = known;
		}, function(_) {});

		return true;
	}

	private static function listen():Void
	{
		if (listening) return;
		listening = true;

		Browser.window.addEventListener("paste", function(event:Dynamic)
		{
			var transfer:Dynamic = event.clipboardData;
			if (transfer == null) return;

			var pasted = new Map<Int, Dynamic>();
			var types:Array<String> = untyped Array.from(transfer.types);

			if (types.indexOf("text/plain") > -1)
			{
				// Clipboard.text reads what was last pasted too
				pasted.set(TEXT, transfer.getData("text/plain"));
				Clipboard._text = transfer.getData("text/plain");
			}
			if (types.indexOf("text/html") > -1) pasted.set(HTML, fragment(transfer.getData("text/html")));
			if (types.indexOf("text/rtf") > -1) pasted.set(RICH_TEXT, transfer.getData("text/rtf"));
			if (types.indexOf("text/uri-list") > -1) pasted.set(URL, StringTools.trim(transfer.getData("text/uri-list").split("\n")[0]));

			// Pages see the names of pasted files, not where they are
			var files:Array<String> = [];
			var imageFile:Dynamic = null;

			for (i in 0...Std.int(transfer.files.length))
			{
				var file:Dynamic = transfer.files[i];
				files.push(file.name);
				if (imageFile == null && StringTools.startsWith(file.type, "image/")) imageFile = file;
			}

			if (files.length > 0) pasted.set(FILE_LIST, files);
			data = pasted;
			Clipboard.onUpdate.dispatch();

			if (imageFile != null)
			{
				// Decoded in the background, and announced again once it can be read
				imageFile.arrayBuffer().then(function(buffer)
				{
					Image.loadFromBytes(Bytes.ofData(buffer)).onComplete(function(image)
					{
						if (data != pasted) return;
						pasted.set(IMAGE, image);
						Clipboard.onUpdate.dispatch();
					});
				});
			}
		}, true);
	}

	// Browsers wrap copied HTML in a document, with the selection between these comments
	private static function fragment(html:String):String
	{
		if (html == null) return null;

		var start = html.indexOf("<!--StartFragment-->");
		var end = html.indexOf("<!--EndFragment-->");
		if (start > -1 && end > start) return html.substring(start + 20, end);
		return html;
	}
}
