package graphics;

#if ((cpp || hl) && lime_cffi && !macro)
import haxe.Timer;
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.Path;
import haxe.zip.Compress;
import lime.app.Application;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.graphics.ImageFileFormat;
import lime.system.System;
import lime.utils.UInt8Array;
import sys.FileSystem;
import sys.io.File;
import system.CollectorWait;
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	Decoding and encoding large images away from the main thread, on C++ and HashLink.

	An image loaded in the background shouldn't hold the main thread up: a collection on the main thread
	shouldn't have to wait for a worker's decode to finish, and `Image.loadFromFile` shouldn't decode on
	the main thread at all. Encoding already lets the collector run, so the encoding tests show that
	`CollectorWait` can tell.

	The image is 2048x2048 pixels of noise, so that each decode takes a good deal longer than a
	collection, and its pixels are pinned here as well, as a large image decoded in one go.
**/
class ImageWorkerTest extends Test
{
	#if ((cpp || hl) && lime_cffi && !macro)
	private static inline var SIZE = 2048;

	// The noise encoded as a JPEG at quality 90, and that decoded
	private static inline var JPEG_BYTES = "2814117 bytes, crc 39E63697";
	private static inline var JPEG_PIXELS = "2048x2048, crc 69A49371";

	private static var noise:Image;
	private static var png:Bytes;
	private static var jpeg:Bytes;
	#end

	public function new()
	{
		super();
	}

	#if ((cpp || hl) && lime_cffi && !macro)
	public function testTheCollectorRunsWhileAWorkerEncodesAPNG():Void
	{
		// A quarter of the noise, since libpng's compression is slow on noise
		var image = noiseImage().clone();
		image.resize(SIZE >> 1, SIZE >> 1);
		var result = CollectorWait.collectDuring(function()
		{
			image.encode(PNG);
		});

		Assert.isFalse(result.waited, "Encoding a PNG on a worker: " + result);
	}

	public function testTheCollectorRunsWhileAWorkerEncodesAJPEG():Void
	{
		var image = noiseImage();
		var result = CollectorWait.collectDuring(function()
		{
			image.encode(JPEG, 90);
		});

		Assert.isFalse(result.waited, "Encoding a JPEG on a worker: " + result);
	}

	public function testTheCollectorRunsWhileAWorkerDecodesAPNG():Void
	{
		var bytes = pngBytes();
		var decoded:Image = null;
		var result = CollectorWait.collectDuring(function()
		{
			decoded = Image.fromBytes(bytes);
		});

		Assert.isFalse(result.waited, "Decoding a PNG on a worker: " + result);
		Assert.equals(checksum(noiseImage()), checksum(decoded));
	}

	public function testTheCollectorRunsWhileAWorkerDecodesAJPEG():Void
	{
		var bytes = jpegBytes();
		var decoded:Image = null;
		var result = CollectorWait.collectDuring(function()
		{
			decoded = Image.fromBytes(bytes);
		});

		Assert.isFalse(result.waited, "Decoding a JPEG on a worker: " + result);
		Assert.notNull(decoded);
	}

	public function testALargePNGDecodesToThePixelsItWasEncodedFrom():Void
	{
		var decoded = Image.fromBytes(pngBytes());

		Assert.notNull(decoded);
		if (decoded == null) return;

		Assert.equals(SIZE, decoded.width);
		Assert.equals(SIZE, decoded.height);
		Assert.equals(checksum(noiseImage()), checksum(decoded));
	}

	public function testALargeJPEGKeepsItsEncodedBytesAndDecodedPixels():Void
	{
		// Both come from Lime's own libjpeg-turbo, so they are the same on every platform
		var bytes = jpegBytes().length + " bytes, crc " + crc(jpegBytes());
		Assert.equals(JPEG_BYTES, bytes, "the JPEG encoded from the noise is " + bytes + ", pinned " + JPEG_BYTES);

		var decoded = Image.fromBytes(jpegBytes());
		Assert.notNull(decoded);
		if (decoded == null) return;

		var pixels = decoded.width + "x" + decoded.height + ", crc " + checksum(decoded);
		Assert.equals(JPEG_PIXELS, pixels, "the JPEG's decoded pixels are " + pixels + ", pinned " + JPEG_PIXELS);
	}

	public function testLoadFromFileGivesTheSamePixelsAsFromBytesForALargeImage(async:Async):Void
	{
		async.setTimeout(30000);

		var path = writeFile("large.png", pngBytes());
		var expected = checksum(noiseImage());

		Image.loadFromFile(path).onComplete(function(image)
		{
			Assert.notNull(image);
			if (image != null) Assert.equals(expected, checksum(image));
			async.done();
		}).onError(function(error)
		{
			Assert.fail(path + " did not load: " + error);
			async.done();
		});
	}

	@Ignored("Waiting on #2232")
	public function testLoadFromFileDecodesOffTheMainThread(async:Async):Void
	{
		async.setTimeout(30000);

		var bytes = pngBytes();
		var path = writeFile("large.png", bytes);

		// How long a decode takes here, on this thread. A frame can still wait on the worker's decode while
		// the main thread collects, until decoding lets the collector run (#2125).
		var start = Timer.stamp();
		Image.fromBytes(bytes);
		var decode = Timer.stamp() - start;

		var last = Timer.stamp();
		var longest = 0.0;
		var update = function(_:Int)
		{
			var now = Timer.stamp();
			if (now - last > longest) longest = now - last;
			last = now;
		};

		Application.current.onUpdate.add(update);

		Image.loadFromFile(path).onComplete(function(image)
		{
			var now = Timer.stamp();
			if (now - last > longest) longest = now - last;
			Application.current.onUpdate.remove(update);

			Assert.notNull(image);
			// A frame that took as long as the decode did is a frame the decode ran in
			Assert.isTrue(longest < decode / 2,
				"the longest gap between frames while the image loaded was " + ms(longest) + ", and a decode takes " + ms(decode));
			async.done();
		}).onError(function(error)
		{
			Application.current.onUpdate.remove(update);
			Assert.fail(path + " did not load: " + error);
			async.done();
		});
	}

	// Helpers

	/** Opaque noise from a 32-bit xorshift, seven bits a channel, so zlib codes it rather than storing it **/
	private static function noiseImage():Image
	{
		if (noise == null)
		{
			var bytes = Bytes.alloc(SIZE * SIZE * 4);
			var state = 0x2545F491;

			for (i in 0...SIZE * SIZE)
			{
				state ^= state << 13;
				state ^= state >>> 17;
				state ^= state << 5;
				bytes.setInt32(i * 4, (state & 0x7F7F7F) | 0xFF000000);
			}

			var buffer = new ImageBuffer(UInt8Array.fromBytes(bytes), SIZE, SIZE, 32, RGBA32);
			buffer.transparent = false;
			noise = new Image(buffer, 0, 0, SIZE, SIZE, null, DATA);
		}

		return noise;
	}

	/**
		The noise as a PNG, written here with zlib at its fastest setting, since libpng's own encoder takes
		seconds over noise. Each scanline has filter type 0, so the decoder inflates every byte.
	**/
	private static function pngBytes():Bytes
	{
		if (png == null)
		{
			var pixels = noiseImage().buffer.data.toBytes();
			var raw = Bytes.alloc((SIZE * 4 + 1) * SIZE);

			for (y in 0...SIZE)
			{
				raw.set(y * (SIZE * 4 + 1), 0);
				raw.blit(y * (SIZE * 4 + 1) + 1, pixels, y * SIZE * 4, SIZE * 4);
			}

			var out = new BytesBuffer();
			out.add(PNGFile.signature());
			out.add(PNGFile.chunk("IHDR", PNGFile.header(SIZE, SIZE, 8, PNGFile.TRUECOLOUR_ALPHA, false)));
			out.add(PNGFile.chunk("IDAT", Compress.run(raw, 1)));
			out.add(PNGFile.chunk("IEND", Bytes.alloc(0)));
			png = out.getBytes();
		}

		return png;
	}

	private static function jpegBytes():Bytes
	{
		if (jpeg == null) jpeg = noiseImage().encode(JPEG, 90);
		return jpeg;
	}

	private static function writeFile(name:String, bytes:Bytes):String
	{
		var directory = System.applicationStorageDirectory + "image-worker-test";
		if (!FileSystem.exists(directory)) FileSystem.createDirectory(directory);

		var path = Path.join([directory, name]);
		File.saveBytes(path, bytes);
		return path;
	}

	private static function checksum(image:Image):String
	{
		if (image == null) return "null";

		var data = image.buffer.data;
		return crc(data.toBytes().sub(data.byteOffset, data.byteLength));
	}

	private static function crc(bytes:Bytes):String
	{
		return bytes == null ? "null" : StringTools.hex(Crc32.make(bytes), 8);
	}

	private static function ms(seconds:Float):String
	{
		return Math.round(seconds * 1000) + " ms";
	}
	#end
}
