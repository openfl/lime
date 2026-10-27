package media;

import haxe.io.Bytes;
import haxe.Timer;
import lime.media.VideoDecoder;
import lime.media.VideoFrame;
import utest.Assert;
import utest.Test;
#if (sys && target.threaded)
import sys.net.Host;
import sys.net.Socket;
import sys.thread.Thread;
#end

/**
	Reads video over HTTP from a server in the test that stops sending partway,
	as connections do in production, and checks that seeking and closing do not
	wait for the connection to give up. Media Foundation, MediaCodec and
	GStreamer read URLs. AVFoundation's reader only reads local files.
**/
class VideoNetworkTest extends Test
{
	private static inline var PATH = "assets/video.mp4";

	// Android reads a URL 64 KB at a time, and none of a piece that stalls, so
	// the chunks of media are spread out, and those before a stall are read
	private static inline var CHUNK_SPACING = 64 * 1024;

	// Android reads up to 20 MB ahead, on a single thread that reads nothing
	// else while it waits on a stalled connection, and opening reads the first
	// half of the test video, so the stall is further than that past it
	private static inline var STALL_SPACING = 24 * 1024 * 1024;

	// Android reads the end of the file when opening it, which it asks a server
	// for separately once that is more than 256 KB past what it has read
	private static inline var MEDIA_PADDING = 512 * 1024;

	// Longer than any pause in a healthy local connection
	private static inline var STALL_SECONDS = 1.0;

	private static inline var TIMEOUT = 15;

	public function new()
	{
		super();
	}

	#if (sys && target.threaded)
	private var deadline:sys.thread.Lock;
	private var phase:String;

	public function setup():Void
	{
		phase = "opening the stream";
		deadline = new sys.thread.Lock();
		var finished = deadline;
		Thread.create(function()
		{
			// Polling deadlines cannot interrupt a blocked native open, seek or close.
			if (finished.wait(TIMEOUT * 4)) return;
			Sys.stderr().writeString("VideoNetworkTest timed out while " + phase + "\n");
			Sys.stderr().flush();
			Sys.exit(1);
		});
	}

	public function teardown():Void
	{
		deadline.release();
	}

	private function entering(phase:String):Void
	{
		this.phase = phase;
		Sys.println("VideoNetworkTest: " + phase);
		Sys.stdout().flush();
	}

	public function testSeekingAStalledStreamDoesNotWait():Void
	{
		entering("opening the stream");
		var server = new StallingServer(streamable(readAsset(PATH)));
		var decoder = open(server);

		if (decoder == null)
		{
			server.stop();
			return;
		}

		var frame = new VideoFrame();
		entering("waiting for the stream to stall");
		var stalledAt = readUntilStalled(decoder, frame);
		Assert.isTrue(stalledAt >= 0 && stalledAt < decoder.duration - 0.2, "the stream did not stall partway, but at " + stalledAt);

		// The connection that stalled stays stalled, and new ones are answered,
		// as when a player seeks to get going again
		server.stalls = false;

		entering("seeking the stalled stream");
		var start = Timer.stamp();
		var moved = decoder.seek(0);
		var took = Timer.stamp() - start;

		Assert.isTrue(moved, "the stalled stream did not seek");
		Assert.isTrue(took < 1, "seeking the stalled stream took " + took + " s");

		entering("reading after seeking");
		var resumed = nextFrame(decoder, frame);
		Assert.isTrue(resumed, "no frame came after seeking");
		if (resumed) Assert.isTrue(frame.time < 0.5, "the first frame after seeking to the start was at " + frame.time);

		entering("closing after seeking");
		start = Timer.stamp();
		decoder.close();
		took = Timer.stamp() - start;
		server.stop();

		Assert.isTrue(took < 1, "closing took " + took + " s");
	}

	public function testSeekingWhileTheServerIsDownDoesNotWait():Void
	{
		entering("opening the stream");
		var server = new StallingServer(streamable(readAsset(PATH)));
		var decoder = open(server);

		if (decoder == null)
		{
			server.stop();
			return;
		}

		var frame = new VideoFrame();
		entering("waiting for the stream to stall");
		var stalledAt = readUntilStalled(decoder, frame);
		Assert.isTrue(stalledAt >= 0 && stalledAt < decoder.duration - 0.2, "the stream did not stall partway, but at " + stalledAt);

		// The server takes no more requests, as when the network goes down, so
		// the stream cannot be read again
		server.down = true;

		for (time in [0.0, 0.5, 1.0])
		{
			entering("seeking while the server is down to " + time);
			var start = Timer.stamp();
			decoder.seek(time);
			var took = Timer.stamp() - start;
			Assert.isTrue(took < 1, "seeking to " + time + " s while the server is down took " + took + " s");

			// A moment for the stream to try again
			pause(0.3);
		}

		entering("reading while the server is down");
		Assert.isFalse(decoder.readFrame(frame), "a frame came from a server that is down");

		entering("closing while the server is down");
		var start = Timer.stamp();
		decoder.close();
		var took = Timer.stamp() - start;
		server.stop();

		Assert.isTrue(took < 1, "closing took " + took + " s");
	}

	public function testClosingAStalledStreamDoesNotWait():Void
	{
		entering("opening the stream");
		var server = new StallingServer(streamable(readAsset(PATH)));
		var decoder = open(server);

		if (decoder == null)
		{
			server.stop();
			return;
		}

		entering("waiting for the stream to stall");
		var stalledAt = readUntilStalled(decoder, new VideoFrame());
		Assert.isTrue(stalledAt >= 0 && stalledAt < decoder.duration - 0.2, "the stream did not stall partway, but at " + stalledAt);

		entering("closing the stalled stream");
		var start = Timer.stamp();
		decoder.close();
		var took = Timer.stamp() - start;
		server.stop();

		Assert.isTrue(took < 1, "closing the stalled stream took " + took + " s");
	}

	private static function findChunkOffsets(data:Bytes, start:Int, end:Int, entries:Array<Int>):Void
	{
		// Where each chunk offset is in the index
		var position = start;

		while (position + 8 <= end)
		{
			var size = readUInt32(data, position);
			if (size < 8 || position + size > end) return;

			switch (data.getString(position + 4, 4))
			{
				case "moov", "trak", "mdia", "minf", "stbl":
					findChunkOffsets(data, position + 8, position + size, entries);

				case "stco":
					for (i in 0...readUInt32(data, position + 12))
					{
						entries.push(position + 16 + i * 4);
					}

				default:
			}

			position += size;
		}
	}

	private static function nextFrame(decoder:VideoDecoder, frame:VideoFrame):Bool
	{
		var end = Timer.stamp() + TIMEOUT;

		while (!decoder.readFrame(frame))
		{
			if (decoder.videoComplete || Timer.stamp() > end) return false;
			Sys.sleep(0.001);
		}

		return true;
	}

	private static function open(server:StallingServer):VideoDecoder
	{
		if (!VideoDecoder.isSupported)
		{
			Assert.pass();
			return null;
		}

		var decoder = new VideoDecoder();

		if (!decoder.open(server.url))
		{
			#if (mac || ios)
			// Only local files are read here
			Assert.pass();
			#else
			Assert.fail("Cannot open " + server.url);
			#end
			return null;
		}

		return decoder;
	}

	private static function pause(seconds:Float):Void
	{
		var end = Timer.stamp() + seconds;
		while (Timer.stamp() < end) Sys.sleep(0.01);
	}

	private static function readAsset(path:String):Bytes
	{
		// Where the decoder finds it, which tests can read before assets load,
		// including from inside an Android package
		var resolved = @:privateAccess VideoDecoder.__resolvePath(path);
		var bytes:Bytes = lime.utils.Bytes.fromFile(resolved);
		return bytes != null ? bytes : sys.io.File.getBytes(resolved);
	}

	private static function readUInt32(data:Bytes, position:Int):Int
	{
		return (data.get(position) << 24) | (data.get(position + 1) << 16) | (data.get(position + 2) << 8) | data.get(position + 3);
	}

	private static function readUntilStalled(decoder:VideoDecoder, frame:VideoFrame):Float
	{
		// Reads frames and sound as they come, until none have come for a while,
		// and returns the time of the last frame, or -1 when the video ended
		var audio = Bytes.alloc(16384);
		var lastTime = 0.0;
		var lastProgress = Timer.stamp();
		var end = lastProgress + TIMEOUT;

		while (Timer.stamp() < end)
		{
			if (decoder.videoComplete) return -1;

			var progressed = false;

			if (decoder.readFrame(frame))
			{
				lastTime = frame.time;
				progressed = true;
			}

			if (decoder.readAudio(audio, 0, audio.length) > 0) progressed = true;

			if (progressed)
			{
				lastProgress = Timer.stamp();
			}
			else if (Timer.stamp() - lastProgress > STALL_SECONDS)
			{
				return lastTime;
			}
			else
			{
				Sys.sleep(0.001);
			}
		}

		return -1;
	}

	private static function streamable(data:Bytes):ServedFile
	{
		// Files made for streaming have their index before the media, which
		// players need before they can read it, so the index of the test video
		// is moved to the front. Its chunks of media are spread out, and the
		// media box carries on past them. The space between is never sent as
		// part of the file, only zeros in its place.
		var media = -1;
		var index = -1;
		var position = 0;

		while (position + 8 <= data.length)
		{
			var size = readUInt32(data, position);
			var type = data.getString(position + 4, 4);
			if (type == "mdat") media = position;
			if (type == "moov") index = position;
			position += size;
		}

		var mediaEnd = media + readUInt32(data, media);
		var moved = data.sub(index, readUInt32(data, index));
		var header = Bytes.alloc(8);
		header.blit(4, Bytes.ofString("mdat"), 0, 4);

		var file = new ServedFile();
		file.add(data, 0, media);
		file.add(moved, 0, moved.length);
		var mediaStart = file.length;
		file.add(header, 0, 8);

		var entries = [];
		findChunkOffsets(moved, 0, moved.length, entries);

		var chunks = [];

		for (entry in entries)
		{
			var offset = readUInt32(moved, entry);
			if (chunks.indexOf(offset) < 0) chunks.push(offset);
		}

		chunks.sort(function(a, b) return a - b);

		// Reading stalls three quarters of the way through the media
		var stallChunk = Std.int(chunks.length * 3 / 4);
		var movedTo = new Map<Int, Int>();
		file.add(data, media + 8, chunks[0] - media - 8);

		for (i in 0...chunks.length)
		{
			var next = i + 1 < chunks.length ? chunks[i + 1] : mediaEnd;
			file.add(null, 0, i == stallChunk ? STALL_SPACING : CHUNK_SPACING);
			if (i == stallChunk) file.stallAt = file.length;
			movedTo.set(chunks[i], file.length);
			file.add(data, chunks[i], next - chunks[i]);
		}

		file.add(null, 0, MEDIA_PADDING);

		for (entry in entries)
		{
			writeUInt32(moved, entry, movedTo.get(readUInt32(moved, entry)));
		}

		writeUInt32(header, 0, file.length - mediaStart);
		return file;
	}

	private static function writeUInt32(data:Bytes, position:Int, value:Int):Void
	{
		data.set(position, value >>> 24);
		data.set(position + 1, value >>> 16);
		data.set(position + 2, value >>> 8);
		data.set(position + 3, value);
	}
	#end
}

#if (sys && target.threaded)
/**
	A file made of pieces of other data and runs of zeros.
**/
private class ServedFile
{
	public var length(default, null):Int = 0;
	public var stallAt:Int;

	private var pieces:Array<{data:Bytes, length:Int, offset:Int, start:Int}> = [];

	public function new() {}

	/**
		Adds `length` bytes of `data` from `offset`, or zeros when `data` is null.
	**/
	public function add(data:Bytes, offset:Int, length:Int):Void
	{
		if (length <= 0) return;

		pieces.push({data: data, length: length, offset: offset, start: this.length});
		this.length += length;
	}

	/**
		Writes up to `length` bytes from `position`, and returns how many.
	**/
	public function write(output:haxe.io.Output, position:Int, length:Int, zeros:Bytes):Int
	{
		for (piece in pieces)
		{
			if (position >= piece.start + piece.length) continue;

			var count = Std.int(Math.min(length, Math.min(zeros.length, piece.start + piece.length - position)));

			if (piece.data == null)
			{
				output.writeFullBytes(zeros, 0, count);
			}
			else
			{
				output.writeFullBytes(piece.data, piece.offset + position - piece.start, count);
			}

			return count;
		}

		return 0;
	}
}

/**
	Serves a file over HTTP on a local port. Requests from before a point in
	the file stop sending there, and hold the connection open, as a stalled
	connection does. Requests from after it are sent in full.
**/
private class StallingServer
{
	/**
		Whether requests are held without an answer, as when the network is down.
	**/
	public var down:Bool;

	/**
		Whether requests from before the stall point stop there.
	**/
	public var stalls:Bool = true;

	public var url(default, null):String;

	private var file:ServedFile;
	private var listener:Socket;
	private var stopped:Bool;
	private var zeros:Bytes;

	public function new(file:ServedFile)
	{
		this.file = file;

		zeros = Bytes.alloc(64 * 1024);
		zeros.fill(0, zeros.length, 0);

		listener = new Socket();
		listener.bind(new Host("127.0.0.1"), 0);
		listener.listen(8);
		url = "http://127.0.0.1:" + listener.host().port + "/video.mp4";

		Thread.create(acceptConnections);
	}

	public function stop():Void
	{
		stopped = true;
	}

	private function acceptConnections():Void
	{
		while (!stopped)
		{
			// Waits briefly, so stopping is seen
			if (Socket.select([listener], [], [], 0.05).read.length == 0) continue;

			var connection = listener.accept();
			Thread.create(function() serve(connection));
		}

		listener.close();
	}

	private function hold():Void
	{
		// The connection stays open without sending anything
		while (!stopped)
		{
			Sys.sleep(0.05);
		}
	}

	private function serve(connection:Socket):Void
	{
		try
		{
			var ranged = false;
			var start = 0;
			var end = file.length - 1;
			var range = ~/^range: *bytes=(\d+)-(\d*)/i;
			var line = connection.input.readLine();
			var head = StringTools.startsWith(line, "HEAD ");

			while ((line = connection.input.readLine()) != "")
			{
				if (range.match(line))
				{
					ranged = true;
					start = Std.parseInt(range.matched(1));
					if (range.matched(2) != "") end = Std.int(Math.min(Std.parseInt(range.matched(2)), file.length - 1));
				}
			}

			if (down)
			{
				hold();
			}
			else
			{
				var response = (ranged ? "HTTP/1.1 206 Partial Content\r\n" : "HTTP/1.1 200 OK\r\n")
					+ "Content-Type: video/mp4\r\nAccept-Ranges: bytes\r\nConnection: close\r\n"
					+ "Content-Length: " + (end - start + 1) + "\r\n"
					+ (ranged ? "Content-Range: bytes " + start + "-" + end + "/" + file.length + "\r\n" : "")
					+ "\r\n";

				connection.output.writeString(response);

				var limit = stalls && start < file.stallAt ? file.stallAt : file.length;
				var position = start;

				while (!head && position <= end)
				{
					if (position >= limit)
					{
						connection.output.flush();
						hold();
						break;
					}

					position += file.write(connection.output, position, Std.int(Math.min(end + 1, limit)) - position, zeros);
				}

				connection.output.flush();
			}
		}
		catch (e:Dynamic) {}

		try
		{
			connection.close();
		}
		catch (e:Dynamic) {}
	}
}
#end
