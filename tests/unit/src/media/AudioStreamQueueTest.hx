package media;

#if (lime_cffi && !macro && lime_sdl_sound && lime_audio_test_hooks)
import haxe.Timer;
import haxe.io.Bytes;
import lime.media.AudioBuffer;
import lime.media.AudioSource;
import lime.media.openal.AL;
import lime.media.openal.ALC;
import lime.media.openal.ALSource;
import sys.thread.Mutex;
#end
import utest.Assert;
import utest.Test;

/**
	What a stream decodes and queues when it is stopped, disposed, paused, resumed and sought, read
	through the hook `lime_audio_test_hooks` adds, which reports each buffer a stream queues, the stream
	time of its first frame and whether the queue was emptied before it.

	A stream decodes on the calling thread whenever its queue is emptied and filled again, and for an MP3
	that can mean decoding the file from its start. Stopping or disposing a stream, and resuming one that
	was paused, shouldn't do that: nothing it decodes then is ever played. Where a stream plays from, and
	what it plays, must stay as it is.
**/
class AudioStreamQueueTest extends Test
{
	#if (lime_cffi && !macro && lime_sdl_sound && lime_audio_test_hooks)
	private static inline var SAMPLE_RATE = 22050;

	private var mutex:Mutex;
	private var queued:Array<QueuedBuffer>;
	private var watched:AudioSource;
	#end

	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro && lime_sdl_sound && lime_audio_test_hooks)
	public function setup():Void
	{
		mutex = new Mutex();
		queued = [];
		watched = null;

		@:privateAccess lime._internal.backend.native.NativeAudioSource.onTestQueue = function(source:AudioSource, bytes:Bytes, time:Float, emptied:Bool)
		{
			mutex.acquire();
			if (source == watched) queued.push(new QueuedBuffer(time, emptied, bytes.length));
			mutex.release();
		};
	}

	public function teardown():Void
	{
		@:privateAccess lime._internal.backend.native.NativeAudioSource.onTestQueue = null;
	}

	@Ignored("Waiting on #2224")
	public function testStoppingAStreamDecodesNothing():Void
	{
		var source = playingStream();
		if (source == null) return;

		var during = record(function() source.stop());
		Assert.equals(0, refills(during), "stop() emptied the queue and filled it again: " + during.join(", "));

		source.dispose();
	}

	@Ignored("Waiting on #2224")
	public function testDisposingAPlayingStreamDecodesNothing():Void
	{
		var source = playingStream();
		if (source == null) return;

		var during = record(function() source.dispose());
		Assert.equals(0, refills(during), "dispose() emptied the queue and filled it again: " + during.join(", "));
	}

	@Ignored("Waiting on #2224")
	public function testSeekingAStoppedStreamDecodesNothingUntilItPlays():Void
	{
		var source = playingStream();
		if (source == null) return;

		source.stop();
		var during = record(function() source.currentTime = 1500);
		Assert.equals(0, during.length, "seeking a stopped stream queued " + during.join(", "));

		source.dispose();
	}

	public function testAStoppedStreamPlaysAgainFromItsStart():Void
	{
		var source = playingStream();
		if (source == null) return;

		source.stop();
		var during = record(function() source.play());
		Assert.equals(0.0, firstRefillTime(during), "the stream played again from " + during.join(", "));

		source.dispose();
	}

	public function testAStoppedStreamIsAtItsStart():Void
	{
		var source = playingStream();
		if (source == null) return;

		Assert.isTrue(source.currentTime > 0, "the stream had not played");
		source.stop();
		Assert.equals(0, source.currentTime);
		Assert.isTrue(stateOf(source) != AL.PLAYING, "the stream is still playing");

		// And stays there until it plays again
		Sys.sleep(0.2);
		Assert.equals(0, source.currentTime);
		source.dispose();
	}

	public function testAStoppedSoundIsAtItsStart():Void
	{
		// A sound decoded whole, for comparison with a stream
		if (!hasOutput()) return;

		var source = new AudioSource(AudioBuffer.fromBytes(AudioBufferTest.createWAV(AudioBufferTest.tone(SAMPLE_RATE * 3))));
		source.play();
		var end = Timer.stamp() + 5;
		while (source.currentTime < 300 && Timer.stamp() < end)
		{
			Sys.sleep(0.01);
		}

		source.stop();
		Assert.equals(0, source.currentTime);
		source.dispose();
	}

	public function testAStreamSoughtWhileStoppedPlaysFromThere():Void
	{
		var source = playingStream();
		if (source == null) return;

		source.stop();
		source.currentTime = 1500;
		Assert.equals(1500, source.currentTime);

		var during = record(function() source.play());
		assertNear(1.5, firstRefillTime(during), "the stream played from " + during.join(", "));
		assertPlaysFrom(source, 1500);

		source.dispose();
	}

	@Ignored("Waiting on #2225")
	public function testResumingAPausedStreamKeepsItsQueue():Void
	{
		var source = playingStream();
		if (source == null) return;

		source.pause();
		var during = record(function() source.play());
		Assert.equals(0, refills(during), "resuming emptied the queue and filled it again: " + during.join(", "));

		source.dispose();
	}

	public function testAPausedStreamHoldsItsTimeAndResumesFromIt():Void
	{
		var source = playingStream();
		if (source == null) return;

		source.pause();
		var paused = source.currentTime;
		Assert.isTrue(paused > 0, "the stream had not played before it was paused");
		Sys.sleep(0.2);
		Assert.equals(paused, source.currentTime, "the time moved while the stream was paused");
		Assert.equals(AL.PAUSED, stateOf(source));

		source.play();
		assertPlaysFrom(source, paused);

		source.dispose();
	}

	public function testAStreamSoughtWhilePausedPlaysFromThere():Void
	{
		var source = playingStream();
		if (source == null) return;

		source.pause();
		source.currentTime = 3000;
		Assert.equals(3000, source.currentTime);

		var during = record(function() source.play());
		var all = during.concat(record(function() Sys.sleep(0.05)));
		assertNear(3.0, firstRefillTime(all), "the stream played from " + all.join(", "));
		assertPlaysFrom(source, 3000);

		source.dispose();
	}

	public function testAStreamResumedAfterAPauseQueuesTheRestOfItsSound():Void
	{
		// Paused and resumed twice, a short stream still gets to its end, each buffer queued once and in order
		if (!hasOutput()) return;

		var source = new AudioSource(AudioBuffer.fromBytesStream(AudioBufferTest.createWAV(AudioBufferTest.tone(SAMPLE_RATE * 5))));
		watched = source;
		source.play();
		Sys.sleep(0.3);
		source.pause();
		source.play();
		Sys.sleep(0.3);
		source.pause();
		source.play();

		var end = Timer.stamp() + 10;
		while (stateOf(source) == AL.PLAYING && Timer.stamp() < end)
		{
			Sys.sleep(0.05);
		}

		var all = take();
		Assert.isTrue(stateOf(source) != AL.PLAYING, "the stream did not finish");
		Assert.isTrue(all.length > 0, "nothing was queued");
		if (all.length == 0) return;

		// The last buffer queued ends where the sound does
		var last = all[all.length - 1];
		assertNear(5.0, last.time + last.length / (SAMPLE_RATE * 2), "the last buffer queued was " + last + ", of " + all.join(", "));

		source.dispose();
	}

	// Helpers

	/** A 10 second stream, playing, with a buffer or more played **/
	private function playingStream():AudioSource
	{
		if (!hasOutput()) return null;

		var source = new AudioSource(AudioBuffer.fromBytesStream(AudioBufferTest.createWAV(AudioBufferTest.tone(SAMPLE_RATE * 10))));
		watched = source;
		source.play();

		var end = Timer.stamp() + 5;
		while (source.currentTime < 300 && Timer.stamp() < end)
		{
			Sys.sleep(0.01);
		}

		take();
		return source;
	}

	private function record(action:Void->Void):Array<QueuedBuffer>
	{
		take();
		action();
		return take();
	}

	private function take():Array<QueuedBuffer>
	{
		mutex.acquire();
		var result = queued;
		queued = [];
		mutex.release();
		return result;
	}

	private static function refills(buffers:Array<QueuedBuffer>):Int
	{
		var count = 0;
		for (buffer in buffers)
		{
			if (buffer.emptied) count++;
		}
		return count;
	}

	private static function firstRefillTime(buffers:Array<QueuedBuffer>):Float
	{
		for (buffer in buffers)
		{
			if (buffer.emptied) return buffer.time;
		}
		return -1;
	}

	private static function assertNear(expected:Float, actual:Float, message:String, ?pos:haxe.PosInfos):Void
	{
		Assert.isTrue(Math.abs(expected - actual) < 0.01, message, pos);
	}

	/** The stream's time, once it is playing again, is at or a little past `time` **/
	private static function assertPlaysFrom(source:AudioSource, time:Int, ?pos:haxe.PosInfos):Void
	{
		Assert.equals(AL.PLAYING, stateOf(source), "the stream is not playing", pos);
		var now = source.currentTime;
		Assert.isTrue(now >= time - 1 && now < time + 500, "the stream is at " + now + " ms, having been asked to play from " + time, pos);
	}

	private static function hasOutput():Bool
	{
		if (ALC.getCurrentContext() == null)
		{
			// utest takes a warning as a failure, so the test passes, saying why
			trace("There is no audio output here, so streams were not played");
			Assert.pass();
			return false;
		}

		return true;
	}

	private static function stateOf(source:AudioSource):Int
	{
		var handle:ALSource = @:privateAccess source.__backend.handle;
		return handle == null ? 0 : AL.getSourcei(handle, AL.SOURCE_STATE);
	}
	#end
}

#if (lime_cffi && !macro && lime_sdl_sound && lime_audio_test_hooks)
private class QueuedBuffer
{
	public var time:Float;
	public var emptied:Bool;
	public var length:Int;

	public function new(time:Float, emptied:Bool, length:Int)
	{
		this.time = time;
		this.emptied = emptied;
		this.length = length;
	}

	public function toString():String
	{
		return (emptied ? "emptied, then " : "") + length + " bytes at " + (Math.round(time * 1000) / 1000) + " s";
	}
}
#end
