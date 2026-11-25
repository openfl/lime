package ui;

#if (js && html5)
import haxe.io.Bytes;
import js.Browser;
import js.html.InputElement;
import lime.ui.FileDialog;
import lime.utils.Resource;
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	`FileDialog` where it can be tried without a person to pick a file.

	On HTML5, `open()` shows the browser's file picker through an `<input type="file">`, and gives
	the chosen file's bytes to `onOpen`, or calls `onCancel` when the picker closes without one
	(#963). A browser only shows the picker from a user input handler, so these tests find the input
	`open()` put in the page and do what the browser does once a person has chosen: give the input a
	file and fire `change`, or fire `cancel` (HTML's "cancel" event for file inputs).
**/
class FileDialogTest extends Test
{
	#if (js && html5)
	private var inputsBefore:Array<InputElement>;
	#end

	public function new()
	{
		super();
	}

	#if (js && html5)
	public function setup():Void
	{
		inputsBefore = fileInputs();
	}

	public function teardown():Void
	{
		// Pickers a test left open leave the page with it
		for (input in fileInputs())
		{
			if (inputsBefore.indexOf(input) == -1 && input.parentNode != null) input.parentNode.removeChild(input);
		}
	}

	public function testOpenIsSupported():Void
	{
		var dialog = new FileDialog();
		var canceled = 0;
		dialog.onCancel.add(function() canceled++);

		Assert.isTrue(dialog.open(), "open() says it is not supported");
		Assert.equals(0, canceled, "onCancel was dispatched as soon as the picker opened");
		Assert.notNull(newInput(), "no file input was added to the page");
	}

	public function testTheFilterBecomesTheInputsAccept():Void
	{
		// Bare extensions and wildcard patterns become ".ext" entries, a MIME type is kept as it is,
		// and a filter that allows every file sets no accept at all
		var filters:Array<Array<String>> = [
			["png,jpg", ".png,.jpg"],
			["*.png", ".png"],
			["*.png,*.jpg", ".png,.jpg"],
			["*.png, *.jpg", ".png,.jpg"],
			[".gif", ".gif"],
			["image/*", "image/*"],
			// A pattern that is more than an extension can't be an accept entry, and is left out
			["png, *.jpg, .gif, image/*, slide*.json", ".png,.jpg,.gif,image/*"],
			[null, ""],
			["*", ""],
			["*.*", ""]
		];

		for (filter in filters)
		{
			var dialog = new FileDialog();
			dialog.open(filter[0]);

			var input = newInput();
			Assert.notNull(input, "no file input for " + filter[0]);
			if (input == null) continue;

			Assert.equals(filter[1], input.accept, "the accept for " + filter[0]);
			Assert.equals("file", input.type);
			Assert.isFalse(input.multiple, "a picker for one file lets several be chosen, for " + filter[0]);

			input.parentNode.removeChild(input);
		}
	}

	@:timeout(5000)
	public function testChoosingAFileDispatchesOnOpenWithItsBytes(async:Async):Void
	{
		// Every byte value, so a file read as text would not come back the same
		var content = Bytes.alloc(256 + 3);
		for (i in 0...content.length)
		{
			content.set(i, (i * 7 + 3) & 0xFF);
		}

		var input:InputElement = null;
		var finish = once(async);
		var dialog = new FileDialog();
		dialog.onCancel.add(function()
		{
			Assert.fail("onCancel was dispatched for a chosen file");
			finish();
		});
		dialog.onOpen.add(function(resource:Resource)
		{
			var bytes:Bytes = resource;
			Assert.notNull(bytes, "onOpen gave null");

			if (bytes != null)
			{
				Assert.equals(content.length, bytes.length, "the file's length");
				Assert.equals(0, content.compare(bytes), "the file's bytes differ from byte " + firstDifference(content, bytes));
			}

			Assert.isNull(input.parentNode, "the file input is still in the page");
			finish();
		});

		Assert.isTrue(dialog.open("bin"), "open() says it is not supported");
		input = newInput();
		if (input == null)
		{
			Assert.fail("no file input was added to the page");
			finish();
			return;
		}

		choose(input, [new js.html.File([content.getData()], "test.bin")]);
	}

	@:timeout(5000)
	public function testClosingThePickerWithoutAFileDispatchesOnCancel(async:Async):Void
	{
		var dialog = new FileDialog();
		var canceled = 0;
		dialog.onOpen.add(function(resource) Assert.fail("onOpen was dispatched without a file"));
		dialog.onCancel.add(function() canceled++);

		Assert.isTrue(dialog.open());
		var input = newInput();
		if (input == null)
		{
			Assert.fail("no file input was added to the page");
			async.done();
			return;
		}

		input.dispatchEvent(new js.html.Event("cancel", {bubbles: true}));

		// A FileReader would answer on a later task, so give one the time
		haxe.Timer.delay(function()
		{
			Assert.equals(1, canceled, "onCancel dispatches");
			Assert.isNull(input.parentNode, "the file input is still in the page");
			async.done();
		}, 100);
	}

	@:timeout(5000)
	public function testAChangeWithoutAFileDispatchesOnCancel(async:Async):Void
	{
		// A browser without the cancel event fires change with no file when an earlier choice is undone
		var dialog = new FileDialog();
		var canceled = 0;
		dialog.onOpen.add(function(resource) Assert.fail("onOpen was dispatched without a file"));
		dialog.onCancel.add(function() canceled++);

		Assert.isTrue(dialog.open());
		var input = newInput();
		if (input == null)
		{
			Assert.fail("no file input was added to the page");
			async.done();
			return;
		}

		choose(input, []);

		haxe.Timer.delay(function()
		{
			Assert.equals(1, canceled, "onCancel dispatches");
			async.done();
		}, 100);
	}

	public function testBrowseIsStillUnsupported():Void
	{
		// A browser gives no file paths
		var dialog = new FileDialog();
		var canceled = 0;
		dialog.onCancel.add(function() canceled++);

		Assert.isFalse(dialog.browse(lime.ui.FileDialogType.OPEN));
		Assert.equals(1, canceled, "onCancel dispatches");
		Assert.isNull(newInput(), "browse() added a file input to the page");
	}

	/** Ends an async test the first time it is called, whichever of the listeners gets there **/
	private static function once(async:Async):Void->Void
	{
		var done = false;
		return function()
		{
			if (done) return;
			done = true;
			async.done();
		};
	}

	private function newInput():InputElement
	{
		var added = [for (input in fileInputs()) if (inputsBefore.indexOf(input) == -1) input];
		return added.length > 0 ? added[added.length - 1] : null;
	}

	private static function fileInputs():Array<InputElement>
	{
		var list = Browser.document.querySelectorAll("input[type=file]");
		return [for (i in 0...list.length) cast list.item(i)];
	}

	/** What the browser does when a person picks `files` and closes the picker **/
	private static function choose(input:InputElement, files:Array<js.html.File>):Void
	{
		var transfer = new js.html.DataTransfer();
		for (file in files)
		{
			transfer.items.add(file);
		}

		input.files = transfer.files;
		input.dispatchEvent(new js.html.Event("input", {bubbles: true}));
		input.dispatchEvent(new js.html.Event("change", {bubbles: true}));
	}

	private static function firstDifference(expected:Bytes, actual:Bytes):Int
	{
		for (i in 0...Std.int(Math.min(expected.length, actual.length)))
		{
			if (expected.get(i) != actual.get(i)) return i;
		}

		return (expected.length == actual.length ? -1 : Std.int(Math.min(expected.length, actual.length)));
	}
	#end
}
