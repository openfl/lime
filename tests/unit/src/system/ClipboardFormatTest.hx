package system;

import lime.graphics.Image;
import lime.system.Clipboard;
import lime.system.ClipboardFormat;
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	`Clipboard.setData`, `getData`, `hasFormat` and `clear` for each format.

	Native tests replace what the system clipboard holds, so they only run
	where `LIME_TEST_CLIPBOARD` is `1`, as on CI, and put its text back after.
	HTML5 reads what a paste into the page held, which the tests dispatch, so
	those always run.
**/
class ClipboardFormatTest extends Test
{
	public function new()
	{
		super();
	}

	public function testFormatsHaveTheirValues():Void
	{
		Assert.equals(0, (ClipboardFormat.TEXT : Int));
		Assert.equals(1, (ClipboardFormat.HTML : Int));
		Assert.equals(2, (ClipboardFormat.RICH_TEXT : Int));
		Assert.equals(3, (ClipboardFormat.URL : Int));
		Assert.equals(4, (ClipboardFormat.FILE_LIST : Int));
		Assert.equals(5, (ClipboardFormat.IMAGE : Int));
	}

	public function testNothingIsSetFromNull():Void
	{
		Assert.isFalse(Clipboard.setData(HTML, null));
	}

	#if (lime_cffi && !macro && (windows || mac || linux))
	private static var savedText:String;
	private static var enabled:Bool;

	public function setupClass():Void
	{
		enabled = Sys.getEnv("LIME_TEST_CLIPBOARD") == "1";
		if (enabled) savedText = Clipboard.text;
	}

	public function teardownClass():Void
	{
		if (enabled) Clipboard.text = savedText;
	}

	public function testTextAndHTMLAreSetTogether():Void
	{
		if (!canRun()) return;

		Clipboard.clear();
		Assert.isTrue(Clipboard.setData(TEXT, "café 漢"));
		if (!formatsAreSupported(Clipboard.setData(HTML, "<b>café</b> 漢"))) return;

		Assert.isTrue(Clipboard.hasFormat(TEXT));
		Assert.isTrue(Clipboard.hasFormat(HTML));
		Assert.equals("café 漢", Clipboard.getData(TEXT));
		Assert.equals("café 漢", Clipboard.text);
		Assert.equals("<b>café</b> 漢", Clipboard.getData(HTML));
		Assert.isFalse(Clipboard.hasFormat(IMAGE));
	}

	public function testRichTextAndAURL():Void
	{
		if (!canRun()) return;

		var rtf = "{\\rtf1\\ansi {\\b bold} text}";
		var url = "https://example.com/path?a=1&b=caf%C3%A9";

		Clipboard.clear();
		if (!formatsAreSupported(Clipboard.setData(RICH_TEXT, rtf))) return;
		Assert.isTrue(Clipboard.setData(URL, url));

		Assert.isTrue(Clipboard.hasFormat(RICH_TEXT));
		Assert.isTrue(Clipboard.hasFormat(URL));
		Assert.equals(rtf, Clipboard.getData(RICH_TEXT));
		Assert.equals(url, Clipboard.getData(URL));
	}

	public function testFilesAreListedByTheirPaths():Void
	{
		if (!canRun()) return;

		var folder = haxe.io.Path.join([temporaryFolder(), "lime-test-clipboard-" + Std.random(0x3FFFFFFF)]);
		sys.FileSystem.createDirectory(folder);
		var files = [haxe.io.Path.join([folder, "one.txt"]), haxe.io.Path.join([folder, #if neko "two.txt" #else "café 漢.txt" #end])];
		for (file in files)
		{
			sys.io.File.saveContent(file, "text");
		}

		Clipboard.clear();
		var set = Clipboard.setData(FILE_LIST, files);

		if (formatsAreSupported(set))
		{
			Assert.isTrue(Clipboard.hasFormat(FILE_LIST));
			var listed:Array<String> = Clipboard.getData(FILE_LIST);
			Assert.same([for (file in files) normalize(file)], listed == null ? null : [for (file in listed) normalize(file)]);
		}

		for (file in files)
		{
			sys.FileSystem.deleteFile(file);
		}
		sys.FileSystem.deleteDirectory(folder);
	}

	public function testAnImageKeepsItsPixels():Void
	{
		if (!canRun()) return;

		// Opaque, as systems store images without alpha or premultiplied
		var image = new Image(null, 0, 0, 3, 2, 0x000000FF);
		var colors = [0xFF0000FF, 0x00FF00FF, 0x0000FFFF, 0x102030FF, 0xFFFFFFFF, 0x808080FF];
		for (i in 0...colors.length)
		{
			image.setPixel32(i % 3, Std.int(i / 3), colors[i], RGBA32);
		}

		Clipboard.clear();
		if (!formatsAreSupported(Clipboard.setData(IMAGE, image))) return;

		Assert.isTrue(Clipboard.hasFormat(IMAGE));
		var copied:Image = Clipboard.getData(IMAGE);
		Assert.notNull(copied, "no image was read back");
		if (copied == null) return;

		Assert.equals(3, copied.width);
		Assert.equals(2, copied.height);
		Assert.same([for (color in colors) StringTools.hex(color, 8)],
			[for (i in 0...colors.length) StringTools.hex(copied.getPixel32(i % 3, Std.int(i / 3), RGBA32), 8)]);
	}

	public function testSettingTheTextReplacesEverything():Void
	{
		if (!canRun()) return;

		Clipboard.clear();
		if (!formatsAreSupported(Clipboard.setData(HTML, "<i>html</i>"))) return;
		Assert.isTrue(Clipboard.hasFormat(HTML));

		Clipboard.text = "only text";
		Assert.isFalse(Clipboard.hasFormat(HTML), "setting the text kept the HTML");
		Assert.equals("only text", Clipboard.getData(TEXT));

		// And setData after it adds to the text alone
		Assert.isTrue(Clipboard.setData(URL, "https://example.com/"));
		Assert.isFalse(Clipboard.hasFormat(HTML));
		Assert.isTrue(Clipboard.hasFormat(URL));
	}

	public function testClearingEmptiesIt():Void
	{
		if (!canRun()) return;

		Clipboard.setData(TEXT, "text");
		var supported = Clipboard.setData(HTML, "<i>html</i>");
		Clipboard.clear();

		Assert.isFalse(Clipboard.hasFormat(HTML));
		Assert.isFalse(Clipboard.hasFormat(URL));
		Assert.isFalse(Clipboard.hasFormat(IMAGE));
		Assert.isFalse(Clipboard.hasFormat(FILE_LIST));
		var text = Clipboard.text;
		Assert.isTrue(text == null || text == "", "the text after clearing was " + text);
		if (!supported) formatsAreSupported(false);
	}

	private static function canRun():Bool
	{
		if (enabled) return true;

		// utest takes a warning as a failure, so the test passes, saying why
		trace("LIME_TEST_CLIPBOARD is not 1, so the clipboard was left alone");
		Assert.pass();
		return false;
	}

	/**
		Whether formats other than text are supported, from whether one was
		set. They need native-desktop 1.2.0, and on Linux GTK.
	**/
	private static function formatsAreSupported(set:Bool):Bool
	{
		if (set) return true;

		#if (native_desktop >= "1.2.0" && !linux)
		Assert.fail("the clipboard did not take a format other than text");
		#else
		trace("native-desktop " + haxe.macro.Compiler.getDefine("native-desktop") + " has no clipboard formats here, so only text was tested");
		Assert.pass();
		#end
		return false;
	}

	private static function normalize(path:String):String
	{
		#if windows
		return path.split("/").join("\\").toLowerCase();
		#else
		return path;
		#end
	}

	private static function temporaryFolder():String
	{
		for (name in ["TEMP", "TMPDIR", "TMP"])
		{
			var value = Sys.getEnv(name);
			if (value != null && value != "") return value;
		}

		return "/tmp";
	}
	#end

	#if (js && html5)
	@:timeout(10000)
	public function testAPasteIsReadInEachFormat(async:Async):Void
	{
		// A 2x1 PNG, red then green, made by a canvas
		var canvas:js.html.CanvasElement = cast js.Browser.document.createElement("canvas");
		canvas.width = 2;
		canvas.height = 1;
		var context = canvas.getContext2d();
		context.fillStyle = "#FF0000";
		context.fillRect(0, 0, 1, 1);
		context.fillStyle = "#00FF00";
		context.fillRect(1, 0, 1, 1);

		canvas.toBlob(function(blob)
		{
			var transfer = new js.html.DataTransfer();
			transfer.setData("text/plain", "café 漢");
			transfer.setData("text/html", "<html><body><!--StartFragment--><b>café</b><!--EndFragment--></body></html>");
			transfer.setData("text/rtf", "{\\rtf1 text}");
			transfer.setData("text/uri-list", "https://example.com/a\r\nhttps://example.com/b");
			transfer.items.add(new js.html.File([blob], "picture.png", {type: "image/png"}));

			var updates = 0;
			var listener = function() updates++;
			Clipboard.onUpdate.add(listener);

			// Listening starts once the clipboard is asked
			Clipboard.hasFormat(TEXT);
			js.Browser.window.dispatchEvent(paste(transfer));

			Assert.equals(1, updates, "onUpdate was not dispatched for the paste");
			Assert.equals("café 漢", Clipboard.getData(TEXT));
			Assert.equals("café 漢", Clipboard.text);
			Assert.equals("<b>café</b>", Clipboard.getData(HTML));
			Assert.equals("{\\rtf1 text}", Clipboard.getData(RICH_TEXT));
			Assert.equals("https://example.com/a", Clipboard.getData(URL));
			Assert.same(["picture.png"], Clipboard.getData(FILE_LIST));
			Assert.isFalse(Clipboard.hasFormat(IMAGE), "the image was there before it was decoded");

			var timer = new haxe.Timer(10);
			var end = haxe.Timer.stamp() + 5;
			var ended = false;
			timer.run = function()
			{
				// A run already queued can come after stop()
				if (ended || (updates < 2 && haxe.Timer.stamp() < end)) return;
				ended = true;
				timer.stop();
				Clipboard.onUpdate.remove(listener);

				Assert.equals(2, updates, "onUpdate was not dispatched for the decoded image");
				var image:Image = Clipboard.getData(IMAGE);
				Assert.notNull(image, "the pasted image was not decoded");

				if (image != null)
				{
					Assert.equals(2, image.width);
					Assert.equals(1, image.height);
					Assert.equals("FF0000FF", StringTools.hex(image.getPixel32(0, 0, RGBA32), 8));
					Assert.equals("00FF00FF", StringTools.hex(image.getPixel32(1, 0, RGBA32), 8));
				}

				async.done();
			};
		}, "image/png");
	}

	public function testAPasteOfTextAloneHasNoOtherFormats():Void
	{
		var transfer = new js.html.DataTransfer();
		transfer.setData("text/plain", "plain");

		Clipboard.hasFormat(TEXT);
		js.Browser.window.dispatchEvent(paste(transfer));

		Assert.equals("plain", Clipboard.getData(TEXT));
		for (format in [HTML, RICH_TEXT, URL, FILE_LIST, IMAGE])
		{
			Assert.isFalse(Clipboard.hasFormat(format), "format " + format + " was kept from an earlier paste");
		}
	}

	private static function paste(transfer:js.html.DataTransfer):js.html.Event
	{
		// The externs leave clipboardData out of the event's options
		var init:Dynamic = {clipboardData: transfer, bubbles: true, cancelable: true};
		return new js.html.ClipboardEvent("paste", init);
	}
	#end
}
