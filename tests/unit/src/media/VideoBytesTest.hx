package media;

import haxe.io.Bytes;
import haxe.Timer;
import lime.media.VideoDecoder;
import lime.media.VideoFrame;
import lime.media.VideoSource;
import lime.utils.AssetLibrary;
import lime.utils.Assets;
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	Videos opened from bytes, and from an asset embedded in the application,
	which has no file of its own. Native targets write the bytes to a
	temporary file, as the platform decoders read files, and delete it when
	the video is closed. HTML5 plays them from a `blob:` URL.
**/
class VideoBytesTest extends Test
{
	private static inline var PATH = "assets/video.mp4";

	// The same video, embedded in the application by project.xml. HTML5 serves
	// it from its URL all the same.
	private static inline var EMBEDDED = "embedded/video.mp4";

	// The same video again, from a library that holds it in memory
	private static inline var MEMORY = "memory:video.mp4";

	// Opening can take seconds on a busy or cold machine, such as a CI runner
	private static inline var TIMEOUT = 15000;

	private var decoders:Array<VideoDecoder> = [];
	private var videos:Array<VideoSource> = [];

	public function new()
	{
		super();
	}

	public function setupClass(async:Async):Void
	{
		async.setTimeout(10000);

		// The tests run before the application's preloader has loaded its
		// library, which holds the embedded video
		Assets.loadLibrary("default").onComplete(function(_) async.done()).onError(function(error)
		{
			trace("Assets.loadLibrary(\"default\") failed: " + error);
			async.done();
		});
	}

	public function teardown():Void
	{
		for (decoder in decoders)
		{
			decoder.close();
		}

		for (video in videos)
		{
			video.dispose();
		}

		decoders = [];
		videos = [];

		if (Assets.hasLibrary("memory")) Assets.unloadLibrary("memory");
	}

	#if !(js && html5)
	public function testTheVideoIsEmbedded():Void
	{
		// The tests of embedded videos depend on this
		Assert.isTrue(Assets.exists(EMBEDDED), EMBEDDED + " is not an asset");
		Assert.isNull(Assets.getPath(EMBEDDED), EMBEDDED + " has a path, so it is not embedded");
	}
	#end

	public function testNothingOpensFromNoBytes():Void
	{
		var video = track(new VideoSource());
		Assert.isFalse(video.openBytes(null));
		Assert.isFalse(video.openBytes(Bytes.alloc(0)));
		Assert.isNull(VideoSource.fromBytes(Bytes.alloc(0)));
	}

	#if (sys && lime_cffi && !macro)
	public function testADecoderReadsBytesFromATemporaryFileItDeletes():Void
	{
		if (!VideoDecoder.isSupported)
		{
			Assert.pass();
			return;
		}

		var bytes = readVideo();
		var decoder = VideoDecoder.fromBytes(bytes);

		if (decoder == null)
		{
			didNotOpen();
			return;
		}

		decoders.push(decoder);

		Assert.isNull(decoder.source);
		Assert.equals(640, decoder.width);
		Assert.equals(360, decoder.height);

		var path = temporaryPath(decoder);
		Assert.notNull(path, "no temporary file was written");
		if (path == null) return;

		Assert.isTrue(sys.FileSystem.exists(path), path + " does not exist while the video is open");
		Assert.equals(bytes.length, Std.int(sys.FileSystem.stat(path).size));
		Assert.equals("lime-video", haxe.io.Path.withoutDirectory(haxe.io.Path.directory(path)));

		var frame = new VideoFrame();
		Assert.isTrue(nextFrame(decoder, frame), "no frame was read");

		decoder.close();
		Assert.isFalse(sys.FileSystem.exists(path), path + " was left behind after closing");
		Assert.isNull(temporaryPath(decoder));
	}

	public function testOpeningOtherBytesDeletesTheFirstFile():Void
	{
		if (!VideoDecoder.isSupported)
		{
			Assert.pass();
			return;
		}

		var bytes = readVideo();
		var decoder = new VideoDecoder();
		decoders.push(decoder);

		if (!decoder.openBytes(bytes))
		{
			didNotOpen();
			return;
		}

		var first = temporaryPath(decoder);
		Assert.isTrue(decoder.openBytes(bytes), "the bytes did not open again");
		var second = temporaryPath(decoder);

		Assert.notEquals(first, second);
		Assert.isFalse(sys.FileSystem.exists(first), "the first file was left behind");
		Assert.isTrue(sys.FileSystem.exists(second), "the second file does not exist");

		// Opening a path after bytes deletes their file too
		Assert.isTrue(decoder.open(PATH));
		Assert.isFalse(sys.FileSystem.exists(second), "the file was left behind after opening a path");
		Assert.isNull(temporaryPath(decoder));
	}

	public function testBytesThatAreNotAVideoLeaveNothingBehind():Void
	{
		if (!VideoDecoder.isSupported)
		{
			Assert.pass();
			return;
		}

		var garbage = Bytes.alloc(64 * 1024);
		for (i in 0...garbage.length)
		{
			garbage.set(i, (i * 31 + 7) & 0xFF);
		}

		var before = temporaryFiles();
		var decoder = new VideoDecoder();
		decoders.push(decoder);

		Assert.isFalse(decoder.openBytes(garbage), "bytes that are not a video opened");
		Assert.isNull(temporaryPath(decoder));
		Assert.isNull(VideoDecoder.fromBytes(garbage));
		Assert.isNull(VideoSource.fromBytes(garbage));

		var left = [for (file in temporaryFiles()) if (before.indexOf(file) < 0) file];
		Assert.same([], left, "files were left behind");
	}

	public function testADecoderOpensAnEmbeddedAssetByItsID():Void
	{
		if (!VideoDecoder.isSupported)
		{
			Assert.pass();
			return;
		}

		var decoder = new VideoDecoder();
		decoders.push(decoder);

		if (!decoder.open(EMBEDDED))
		{
			// Only a failure where the same video opens from its file
			if (decoder.open(PATH)) Assert.fail(EMBEDDED + " did not open, where " + PATH + " does");
			else cannotDecode();
			return;
		}

		Assert.equals(EMBEDDED, decoder.source);
		Assert.equals(640, decoder.width);

		var path = temporaryPath(decoder);
		Assert.notNull(path, "the embedded asset was not written to a file");

		var frame = new VideoFrame();
		Assert.isTrue(nextFrame(decoder, frame), "no frame was read");

		decoder.close();
		if (path != null) Assert.isFalse(sys.FileSystem.exists(path), path + " was left behind after closing");
	}

	@:timeout(20000)
	public function testAVideoSourcePlaysBytes(async:Async):Void
	{
		var bytes = readVideo();
		var video = VideoSource.fromBytes(bytes);

		if (video == null)
		{
			didNotOpen();
			async.done();
			return;
		}

		track(video);
		Assert.isNull(video.source);

		var path = temporaryPath(@:privateAccess video.__backend.decoder);
		Assert.notNull(path, "no temporary file was written");

		var ready = false;
		video.onReady.add(function() ready = true);

		waitUntil(function() return ready, TIMEOUT, function(_)
		{
			Assert.isTrue(ready, "onReady was not dispatched");
			Assert.equals(640, video.width);
			Assert.isTrue(Math.abs(video.length - 2000) <= 100, "length " + video.length);
			Assert.equals(bytes.length * 1.0, video.bytesTotal);
			Assert.equals(bytes.length * 1.0, video.bytesLoaded);

			playUntil(video, 500, function(reached)
			{
				Assert.isTrue(reached, "the video did not play, at " + video.currentTime + " ms");

				video.dispose();
				if (path != null) Assert.isFalse(sys.FileSystem.exists(path), path + " was left behind after disposing");
				async.done();
			});
		});
	}

	@:timeout(20000)
	public function testAVideoSourceOpensAnEmbeddedAsset(async:Async):Void
	{
		var video = track(new VideoSource());

		if (!video.open(EMBEDDED))
		{
			if (video.open(PATH)) Assert.fail(EMBEDDED + " did not open, where " + PATH + " does");
			else cannotDecode();
			async.done();
			return;
		}

		Assert.equals(EMBEDDED, video.source);
		var path = temporaryPath(@:privateAccess video.__backend.decoder);

		var ready = false;
		video.onReady.add(function() ready = true);

		waitUntil(function() return ready, TIMEOUT, function(_)
		{
			Assert.isTrue(ready, "onReady was not dispatched");
			Assert.equals(readVideo().length * 1.0, video.bytesTotal);

			playUntil(video, 500, function(reached)
			{
				Assert.isTrue(reached, "the video did not play, at " + video.currentTime + " ms");

				video.dispose();
				if (path != null) Assert.isFalse(sys.FileSystem.exists(path), path + " was left behind after disposing");
				async.done();
			});
		});
	}

	public function testAnAssetWithNoPathOpensFromItsBytes():Void
	{
		var bytes = readVideo();
		Assets.registerLibrary("memory", new MemoryLibrary("video.mp4", bytes));

		var video = track(new VideoSource());

		if (!video.open(MEMORY))
		{
			if (new VideoSource().open(PATH)) Assert.fail(MEMORY + " did not open, where " + PATH + " does");
			else cannotDecode();
			return;
		}

		Assert.equals(MEMORY, video.source);
		var path = temporaryPath(@:privateAccess video.__backend.decoder);
		Assert.notNull(path, "the asset was not written to a file");
		if (path != null) Assert.equals(bytes.length, Std.int(sys.FileSystem.stat(path).size));

		video.dispose();
		if (path != null) Assert.isFalse(sys.FileSystem.exists(path), path + " was left behind after disposing");
	}

	@:timeout(30000)
	public function testABytesVideoLoopsOnItsTemporaryFile(async:Async):Void
	{
		var video = VideoSource.fromBytes(readVideo());

		if (video == null)
		{
			didNotOpen();
			async.done();
			return;
		}

		track(video);

		var path = temporaryPath(@:privateAccess video.__backend.decoder);
		var completed = 0;
		var furthest = 0;
		var wrapped = false;
		video.onComplete.add(function() completed++);
		video.loops = 1;
		video.gain = 0;
		video.play();

		var frame = new VideoFrame();

		waitUntil(function()
		{
			video.readFrame(frame);
			var time = video.currentTime;
			if (time < furthest - 1000) wrapped = true;
			if (time > furthest) furthest = time;
			return completed > 0;
		}, TIMEOUT * 2, function(done)
		{
			Assert.isTrue(done, "the video did not complete, at " + video.currentTime + " ms");
			Assert.isTrue(wrapped, "the video did not play again from the start");

			// Ownership passes to the decoder of the second loop, which still holds it
			var current = temporaryPath(@:privateAccess video.__backend.decoder);
			Assert.equals(path, current, "the second loop did not play the same file");

			Timer.delay(function()
			{
				Assert.equals(1, completed, "onComplete was dispatched " + completed + " times");

				video.dispose();
				if (path != null) Assert.isFalse(sys.FileSystem.exists(path), path + " was left behind after disposing");
				async.done();
			}, 300);
		});
	}

	private static function nextFrame(decoder:VideoDecoder, frame:VideoFrame):Bool
	{
		var end = Timer.stamp() + TIMEOUT / 1000;

		while (!decoder.readFrame(frame))
		{
			if (decoder.videoComplete || Timer.stamp() > end) return false;
			Sys.sleep(0.001);
		}

		return true;
	}

	private static function didNotOpen():Void
	{
		// Only a failure where the same video opens from its file
		var decoder = new VideoDecoder();

		if (decoder.open(PATH))
		{
			Assert.fail("the bytes of " + PATH + " did not open, where the file does");
			decoder.close();
		}
		else
		{
			cannotDecode();
		}
	}

	private static function readVideo():Bytes
	{
		return sys.io.File.getBytes(@:privateAccess VideoDecoder.__resolvePath(PATH));
	}

	private static function temporaryFiles():Array<String>
	{
		var directory = @:privateAccess VideoDecoder.__getTemporaryDirectory();
		return directory != null && sys.FileSystem.exists(directory) ? sys.FileSystem.readDirectory(directory) : [];
	}

	private static function temporaryPath(decoder:VideoDecoder):String
	{
		return decoder != null ? @:privateAccess decoder.__temporaryPath : null;
	}
	#end

	#if (js && html5)
	@:timeout(20000)
	public function testBytesPlayFromABlobURLThatIsRevoked(async:Async):Void
	{
		Assets.loadBytes(PATH).onComplete(function(bytes)
		{
			var video = track(new VideoSource());
			Assert.isTrue(video.openBytes(bytes), "the bytes did not open");
			Assert.isNull(video.source);

			var element:js.html.VideoElement = @:privateAccess video.__backend.element;
			var url = element.src;
			Assert.isTrue(StringTools.startsWith(url, "blob:"), "the video plays from " + url);

			var ready = false;
			var failed = null;
			video.onReady.add(function() ready = true);
			video.onError.add(function(message) failed = message);

			waitUntil(function() return ready || failed != null, TIMEOUT, function(_)
			{
				if (failed != null)
				{
					// utest takes a warning as a failure, so the test passes, saying why
					trace("This browser cannot play " + PATH + " (" + failed + "), so only opening was tested");
					Assert.pass();
				}
				else
				{
					Assert.isTrue(ready, "onReady was not dispatched");
					Assert.equals(640, video.width);
				}

				video.dispose();

				// A revoked URL can no longer be read
				js.Browser.window.fetch(url).then(function(_)
				{
					Assert.fail(url + " was not revoked");
					async.done();
				}, function(_)
				{
					Assert.pass();
					async.done();
				});
			});
		}).onError(function(error)
		{
			Assert.fail("cannot load " + PATH + ": " + error);
			async.done();
		});
	}

	@:timeout(20000)
	public function testAnAssetWithNoPathPlaysFromABlobURL(async:Async):Void
	{
		Assets.loadBytes(PATH).onComplete(function(bytes)
		{
			Assets.registerLibrary("memory", new MemoryLibrary("video.mp4", bytes));

			var video = track(new VideoSource());
			Assert.isTrue(video.open(MEMORY), MEMORY + " did not open");
			Assert.equals(MEMORY, video.source);

			var element:js.html.VideoElement = @:privateAccess video.__backend.element;
			Assert.isTrue(element != null && StringTools.startsWith(element.src, "blob:"), "the video plays from " + (element != null ? element.src : null));
			async.done();
		}).onError(function(error)
		{
			Assert.fail("cannot load " + PATH + ": " + error);
			async.done();
		});
	}
	#end

	#if (sys || (js && html5))
	private static function cannotDecode():Void
	{
		// utest takes a warning as a failure, so the test passes, saying why
		trace("Cannot decode H.264 and AAC here, so videos from bytes were not tested");
		Assert.pass();
	}

	private static function playUntil(video:VideoSource, time:Int, then:Bool->Void):Void
	{
		var frame = new VideoFrame();
		video.gain = 0;
		video.play();

		waitUntil(function()
		{
			video.readFrame(frame);
			return video.currentTime >= time;
		}, TIMEOUT, then);
	}

	private static function waitUntil(condition:Void->Bool, timeout:Int, then:Bool->Void):Void
	{
		var end = Timer.stamp() + timeout / 1000;
		var timer = new Timer(10);
		timer.run = function()
		{
			var met = condition();

			if (met || Timer.stamp() > end)
			{
				timer.stop();
				then(met);
			}
		};
	}
	#end

	private function track(video:VideoSource):VideoSource
	{
		videos.push(video);
		return video;
	}
}

/**
	Holds one asset in memory, with no path, as an embedded asset is.
**/
private class MemoryLibrary extends AssetLibrary
{
	private var bytes:Bytes;
	private var name:String;

	public function new(name:String, bytes:Bytes)
	{
		super();
		this.name = name;
		this.bytes = bytes;
	}

	public override function exists(id:String, type:String):Bool
	{
		return id == name;
	}

	public override function getBytes(id:String):Bytes
	{
		return id == name ? bytes : null;
	}

	public override function getPath(id:String):String
	{
		return null;
	}

	public override function isLocal(id:String, type:String):Bool
	{
		return id == name;
	}
}
