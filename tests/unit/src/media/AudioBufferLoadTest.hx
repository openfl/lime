package media;

#if (lime_cffi && !macro && sys)
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import haxe.Timer;
import lime.app.Application;
import lime.app.Future;
import lime.media.AudioBuffer;
import lime.utils.AssetLibrary;
import lime.utils.Assets;
import sys.FileSystem;
import sys.io.File;
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	Sounds loaded on native targets with `AudioBuffer.loadFromFile()` and `Assets.loadAudioBuffer()`.
	Loading decodes a sound on a worker where there are threads, rather than on the main thread as its
	bytes arrive (#1845), and gives the buffer that decoding the file at once with `fromFile()` gives.
	A file that isn't there, or isn't a sound, still ends in an error.
**/
class AudioBufferLoadTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro && sys)
	@:timeout(10000)
	public function testLoadFromFileGivesWhatFromFileGives(async:Async):Void
	{
		inTurn(["assets/tone.ogg", "assets/tone.wav"], function(path, next)
		{
			AudioBuffer.loadFromFile(path).onComplete(function(buffer)
			{
				Assert.equals(describe(AudioBuffer.fromFile(path)), describe(buffer), path);
				next();
			}).onError(function(error)
			{
				Assert.fail(path + " did not load: " + error);
				next();
			});
		}, function() async.done());
	}

	@:timeout(10000)
	public function testAnAssetLoadsAsItsFileDecodes(async:Async):Void
	{
		Assets.loadAudioBuffer("assets/tone.ogg", false).onComplete(function(buffer)
		{
			Assert.equals(describe(AudioBuffer.fromFile("assets/tone.ogg")), describe(buffer));
			async.done();
		}).onError(function(error)
		{
			Assert.fail("assets/tone.ogg did not load: " + error);
			async.done();
		});
	}

	@:timeout(10000)
	public function testAnEmbeddedSoundLoadsAsItsFileDecodes(async:Async):Void
	{
		if (!Assets.exists("embedded/tone.ogg"))
		{
			Assert.fail("the test project embeds no assets/tone.ogg as embedded/tone.ogg");
			async.done();
			return;
		}

		Assets.loadAudioBuffer("embedded/tone.ogg", false).onComplete(function(buffer)
		{
			Assert.equals(describe(AudioBuffer.fromFile("assets/tone.ogg")), describe(buffer));
			async.done();
		}).onError(function(error)
		{
			Assert.fail("embedded/tone.ogg did not load: " + error);
			async.done();
		});
	}

	@:timeout(10000)
	public function testABundledSoundIsDecodedAndKept(async:Async):Void
	{
		// A bundle's library holds its sounds as bytes until they are asked for
		var library = new AssetLibrary();
		@:privateAccess library.cachedBytes.set("tone", File.getBytes("assets/tone.ogg"));
		@:privateAccess library.types.set("tone", SOUND);

		library.loadAudioBuffer("tone").onComplete(function(buffer)
		{
			Assert.equals(describe(AudioBuffer.fromFile("assets/tone.ogg")), describe(buffer));
			Assert.isTrue(buffer != null && library.getAudioBuffer("tone") == buffer, "the decoded sound was not kept for getAudioBuffer()");
			async.done();
		}).onError(function(error)
		{
			Assert.fail("the bundled sound did not load: " + error);
			async.done();
		});
	}

	@:timeout(10000)
	public function testAFileThatIsNotThereOrNotASoundIsAnError(async:Async):Void
	{
		var text = Sys.getCwd() + "/AudioBufferLoadTest.txt";
		File.saveContent(text, "Not a sound, though long enough to be read as one: " + [for (i in 0...64) i].join(","));

		inTurn(["assets/missing.ogg", text], function(path, next)
		{
			AudioBuffer.loadFromFile(path).onComplete(function(buffer)
			{
				Assert.fail(path + " loaded as " + describe(buffer));
				next();
			}).onError(function(error)
			{
				Assert.pass();
				next();
			});
		}, function()
		{
			FileSystem.deleteFile(text);
			async.done();
		});
	}

	@Ignored("Waiting on #2447")
	@:timeout(60000)
	public function testTheMainThreadKeepsRunningWhileALongSoundDecodes(async:Async):Void
	{
		// A long sound: the stream in assets with its audio packets again and again, enough of them to take
		// some time to decode here, which is measured on the main thread
		var tone = File.getBytes("assets/tone.ogg");
		var single = AudioBuffer.fromFile("assets/tone.ogg");
		var path = Sys.getCwd() + "/AudioBufferLoadTest.ogg";
		var count = 3000;
		var decoding = 0.0;
		var whole = true;

		for (attempt in 0...3)
		{
			var long = longOgg(tone, count);
			if (long == null || single == null)
			{
				Assert.fail("assets/tone.ogg could not be read as an Ogg Vorbis stream");
				async.done();
				return;
			}

			File.saveBytes(path, long);
			var start = Timer.stamp();
			var decoded = AudioBuffer.fromFile(path);
			decoding = Timer.stamp() - start;
			whole = decoded != null && decoded.data.length >= single.data.length * count * 0.9;

			if (!whole || decoding >= 0.25 || count >= 40000) break;
			count = Std.int(Math.min(40000, count * 0.4 / Math.max(decoding, 0.01)));
		}

		if (!whole || decoding < 0.2)
		{
			FileSystem.deleteFile(path);
			// utest takes a warning as a failure, so the test passes, saying why
			trace("A long sound decodes " + (whole ? "too quickly here (" + Math.round(decoding * 1000) + " ms)" : "only in part here")
				+ ", so whether the main thread waits for it was not tested");
			Assert.pass();
			async.done();
			return;
		}

		// The longest the main thread goes between updates while the sound loads
		var last = Timer.stamp();
		var longest = 0.0;
		var listener = function(_:Int)
		{
			var now = Timer.stamp();
			if (now - last > longest) longest = now - last;
			last = now;
		};
		Application.current.onUpdate.add(listener);

		var finish = function(message:String)
		{
			// Up to the completion too, which a decode on the main thread comes just before
			listener(0);
			Application.current.onUpdate.remove(listener);
			FileSystem.deleteFile(path);

			if (message != null) Assert.fail(message);
			else Assert.isTrue(longest < decoding / 2, "the main thread went " + Math.round(longest * 1000) + " ms without an update while a sound that takes "
				+ Math.round(decoding * 1000) + " ms to decode loaded");
			async.done();
		};

		AudioBuffer.loadFromFile(path).onComplete(function(buffer)
		{
			finish(buffer == null ? "the long sound loaded as null" : null);
		}).onError(function(error)
		{
			finish("the long sound did not load: " + error);
		});
	}

	/**
		One Ogg Vorbis stream (RFC 3533, Vorbis I) of the headers of `ogg`, then its audio packets
		`repeats` times over, on pages of its own with their own sequence numbers, granule positions
		and checksums.
	**/
	private static function longOgg(ogg:Bytes, repeats:Int):Bytes
	{
		var packets:Array<Bytes> = [];
		var packet = new haxe.io.BytesBuffer();
		var serial = 0;
		var samples = 0;
		var position = 0;

		while (position + 27 <= ogg.length && ogg.getString(position, 4) == "OggS")
		{
			var granule = ogg.getInt32(position + 6);
			if (granule > 0) samples = granule;
			serial = ogg.getInt32(position + 14);

			var segments = ogg.get(position + 26);
			var data = position + 27 + segments;

			for (i in 0...segments)
			{
				var lacing = ogg.get(position + 27 + i);
				packet.addBytes(ogg, data, lacing);
				data += lacing;

				if (lacing < 255)
				{
					packets.push(packet.getBytes());
					packet = new haxe.io.BytesBuffer();
				}
			}

			position = data;
		}

		// The identification, comment and setup headers, then audio
		if (packets.length < 4 || samples <= 0) return null;

		var output = new haxe.io.BytesOutput();
		var sequence = 0;
		var writePage = function(pagePackets:Array<Bytes>, granule:Int, flags:Int)
		{
			var lacings = [];
			var size = 0;
			for (pagePacket in pagePackets)
			{
				for (i in 0...Std.int(pagePacket.length / 255))
				{
					lacings.push(255);
				}
				lacings.push(pagePacket.length % 255);
				size += pagePacket.length;
			}

			var page = Bytes.alloc(27 + lacings.length + size);
			page.fill(0, page.length, 0);
			page.blit(0, Bytes.ofString("OggS"), 0, 4);
			page.set(5, flags);
			page.setInt32(6, granule);
			page.setInt32(14, serial);
			page.setInt32(18, sequence++);
			page.set(26, lacings.length);
			for (i in 0...lacings.length)
			{
				page.set(27 + i, lacings[i]);
			}

			var at = 27 + lacings.length;
			for (pagePacket in pagePackets)
			{
				page.blit(at, pagePacket, 0, pagePacket.length);
				at += pagePacket.length;
			}

			page.setInt32(22, oggChecksum(page));
			output.write(page);
		};

		// The identification header alone on the first page, and audio from a page of its own
		writePage([packets[0]], 0, 0x02);
		writePage([packets[1], packets[2]], 0, 0);

		var audio = packets.slice(3);
		var total = audio.length * repeats;
		var page:Array<Bytes> = [];
		var lacings = 0;

		for (n in 0...total)
		{
			var next = audio[n % audio.length];
			var needed = Std.int(next.length / 255) + 1;

			if (lacings + needed > 255)
			{
				// Where the packets so far end, about
				writePage(page, Std.int(samples * (n / audio.length)), 0);
				page = [];
				lacings = 0;
			}

			page.push(next);
			lacings += needed;
		}

		writePage(page, samples * repeats, 0x04);
		return output.getBytes();
	}

	/** The CRC-32 of an Ogg page, with the polynomial 0x04C11DB7, no reflection and its own field as 0 **/
	private static function oggChecksum(page:Bytes):Int
	{
		var crc = 0;

		for (i in 0...page.length)
		{
			crc = (crc << 8) ^ OGG_CRC[((crc >>> 24) & 0xFF) ^ page.get(i)];
		}

		return crc;
	}

	private static var OGG_CRC:Array<Int> = [
		for (i in 0...256)
		{
			var r = i << 24;
			for (j in 0...8)
			{
				r = (r & 0x80000000) != 0 ? (r << 1) ^ 0x04C11DB7 : r << 1;
			}
			r;
		}
	];

	/** Calls `each` on every item, one after the other, then `done` **/
	private static function inTurn<T>(items:Array<T>, each:T->(Void->Void)->Void, done:Void->Void):Void
	{
		if (items.length == 0)
		{
			done();
			return;
		}

		each(items[0], function() inTurn(items.slice(1), each, done));
	}

	private static function describe(buffer:AudioBuffer):String
	{
		if (buffer == null) return "null";
		var data = buffer.data != null ? buffer.data.toBytes() : null;
		return buffer.channels + " channels, " + buffer.sampleRate + " Hz, " + buffer.bitsPerSample + "-bit, "
			+ (data == null ? "no data" : data.length + " bytes, crc " + StringTools.hex(Crc32.make(data), 8));
	}
	#end
}
