package utils;

#if (js && html5)
import lime.app.Application;
import lime.graphics.Image;
import lime.media.AudioBuffer;
import lime.utils.Assets;
import lime.utils.Bytes;
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	Images and sounds made from bytes in a browser.

	`Image.fromBytes()` and `AudioBuffer.fromBytes()` hand the browser the file as a Base64 `data:` URI,
	which it decodes straight back, and Howler keeps the text for as long as the sound. A Blob URL hands
	over the bytes as they are, as `Image.loadFromBytes()` already does. The image has to come out as
	it does through `loadFromBytes()`, and the sound has to load.

	These run only in a browser, which CI doesn't run the unit tests in.
**/
class HTML5BytesTest extends Test
{
	public function new()
	{
		super();
	}

	#if (js && html5)
	@:timeout(20000)
	public function setupClass(async:Async):Void
	{
		// The tests start before the application has loaded its assets
		Assets.loadLibrary("default").onComplete(function(_) async.done()).onError(function(_) async.done());
	}

	@:timeout(10000)
	public function testAnImageFromBytesHasThePixelsOfOneLoadedFromBytes(async:Async):Void
	{
		fixture("assets/image-palette.png", function(bytes)
		{
			if (bytes == null)
			{
				async.done();
				return;
			}

			imageMatches(bytes, async);
		});
	}

	private static function imageMatches(bytes:Bytes, async:Async):Void
	{
		var image = Image.fromBytes(bytes);
		Image.loadFromBytes(bytes).onComplete(function(loaded)
		{
			whenLoaded(image, function()
			{
				Assert.equals(loaded.width + "x" + loaded.height, image.width + "x" + image.height);
				var differ = 0;
				for (y in 0...image.height)
				{
					for (x in 0...image.width)
					{
						if (image.getPixel32(x, y) != loaded.getPixel32(x, y)) differ++;
					}
				}
				Assert.equals(0, differ, differ + " pixels differ");
				async.done();
			});
		});
	}

	@Ignored("Waiting on #2244")
	@:timeout(10000)
	public function testAnImageFromBytesIsNotADataURI(async:Async):Void
	{
		fixture("assets/image-420.jpg", function(bytes)
		{
			if (bytes != null)
			{
				var sources = spyOnImageSources();
				Image.fromBytes(bytes);
				var set = sources();

				Assert.isTrue(set.length > 0, "no image source was set");
				for (source in set)
				{
					Assert.isFalse(StringTools.startsWith(source, "data:"), "the image's source was " + source.substr(0, 40) + "...");
				}
			}

			async.done();
		});
	}

	#if lime_howlerjs
	@:timeout(10000)
	public function testASoundFromBytesLoads(async:Async):Void
	{
		fixture("assets/tone.wav", function(bytes)
		{
			if (bytes == null)
			{
				async.done();
				return;
			}

			soundLoads(bytes, async);
		});
	}

	private static function soundLoads(bytes:Bytes, async:Async):Void
	{
		var buffer = AudioBuffer.fromBytes(bytes);
		Assert.notNull(buffer);
		var howl:Dynamic = buffer.src;
		var check = function()
		{
			Assert.equals("loaded", howl.state());
			Assert.isTrue(Math.abs(howl.duration() - 0.1) < 0.02, "the sound lasts " + howl.duration() + " s");
			async.done();
		};

		if (howl.state() == "loaded") check();
		else
		{
			howl.once("load", check);
			howl.once("loaderror", function(_, error) {
				Assert.fail("the sound did not load: " + error);
				async.done();
			});
		}
	}

	@Ignored("Waiting on #2244")
	@:timeout(10000)
	public function testASoundFromBytesIsNotADataURI(async:Async):Void
	{
		fixture("assets/tone.wav", function(bytes)
		{
			if (bytes != null)
			{
				var howl:Dynamic = AudioBuffer.fromBytes(bytes).src;
				var sources:Array<String> = Std.isOfType(howl._src, Array) ? howl._src : [howl._src];

				for (source in sources)
				{
					Assert.isFalse(StringTools.startsWith(source, "data:"), "Howler was given " + source.substr(0, 40) + "...");
				}
			}

			async.done();
		});
	}
	#end

	// Helpers

	private static function fixture(path:String, done:Bytes->Void):Void
	{
		Assets.loadBytes(path).onComplete(done).onError(function(error)
		{
			Assert.fail(path + " did not load: " + error);
			done(null);
		});
	}

	private static function whenLoaded(image:Image, done:Void->Void):Void
	{
		var frames = 0;
		var listener:Int->Void = null;
		listener = function(_:Int)
		{
			if ((image.buffer != null && image.width > 0) || ++frames > 300)
			{
				Application.current.onUpdate.remove(listener);
				done();
			}
		};
		Application.current.onUpdate.add(listener);
	}

	/** Records each source an image element is given until the returned function is called **/
	private static function spyOnImageSources():Void->Array<String>
	{
		var set:Array<String> = [];
		var record = function(value:String) set.push(value);
		js.Syntax.code("var original = Object.getOwnPropertyDescriptor(HTMLImageElement.prototype, 'src');
			window.__limeTestImageSrc = original;
			Object.defineProperty(HTMLImageElement.prototype, 'src', { configurable: true, get: original.get,
				set: function (value) { {0}(String(value)); original.set.call(this, value); } });", record);

		return function()
		{
			js.Syntax.code("Object.defineProperty(HTMLImageElement.prototype, 'src', window.__limeTestImageSrc);");
			return set;
		};
	}
	#end
}
