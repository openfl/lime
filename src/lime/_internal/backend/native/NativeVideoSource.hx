package lime._internal.backend.native;

import haxe.io.Bytes;
import haxe.Timer;
import lime.app.Future;
import lime.app.Promise;
import lime.media.AudioManager;
import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;
import lime.media.VideoDecoder;
import lime.media.VideoFrame;
import lime.media.VideoFrameFormat;
import lime.media.VideoSource;
import lime.system.System;
import lime.utils.Int16Array;
import lime.utils.UInt8Array;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime.media.VideoSource)
class NativeVideoSource
{
	private static inline var AUDIO_AHEAD_SECONDS:Float = 0.25;
	private static inline var AUDIO_BUFFER_COUNT:Int = 6;
	private static inline var AUDIO_BUFFER_SECONDS:Float = 0.04;
	private static inline var AUDIO_CHECK_SECONDS:Float = 0.5;
	private static inline var AUDIO_JUMP_SECONDS:Float = 0.25;
	private static inline var AUDIO_LEAD_SECONDS:Float = 0.1;
	private static inline var AUDIO_RETRY_SECONDS:Float = 1.0;
	private static inline var AUDIO_STEER_RATE:Float = 0.1;
	private static inline var AUDIO_STEER_SECONDS:Float = 0.5;
	private static inline var UPDATE_INTERVAL:Int = 10;

	private static var activeSources:Array<NativeVideoSource> = [];

	private var audioBuffer:Bytes;
	private var audioCheckPosition:Float;
	private var audioCheckStamp:Float;
	private var audioClockStamp:Float;
	private var audioClockTime:Float;
	private var audioData:UInt8Array;
	private var audioFormat:Int;
	private var audioLastCheck:Float;
	private var audioRetryStamp:Float;
	private var audioSamples:Int16Array;
	private var audioSkipping:Bool;
	private var audioStalled:Bool;
	private var blockAlign:Int;
	private var bufferTimes:Array<Float>;
	private var buffers:Array<ALBuffer>;
	private var bytesPerSecond:Float;
	private var clockStamp:Float;
	private var clockTime:Float;
	private var completed:Bool;
	private var decoder:VideoDecoder;
	private var freeBuffers:Array<ALBuffer>;
	private var frameEndTime:Float;
	private var gain:Float;
	private var handle:ALSource;
	private var hasFrame:Bool;
	private var loops:Int;
	private var pan:Float;
	private var parent:VideoSource;
	private var playing:Bool;
	private var timer:Timer;

	public function new(parent:VideoSource)
	{
		this.parent = parent;

		audioCheckStamp = -1;
		audioClockStamp = -1;
		audioSkipping = false;
		audioStalled = false;
		bufferTimes = [];
		clockStamp = 0;
		clockTime = 0;
		completed = false;
		frameEndTime = 0;
		gain = 1;
		hasFrame = false;
		loops = 0;
		pan = 0;
		playing = false;
	}

	public function dispose():Void
	{
		close();
	}

	public function getCurrentTime():Int
	{
		return Std.int(getTime() * 1000);
	}

	public function getGain():Float
	{
		return gain;
	}

	public function getHasAudio():Bool
	{
		return decoder != null && decoder.hasAudio;
	}

	public function getHeight():Int
	{
		return decoder != null ? decoder.height : 0;
	}

	public function getLength():Int
	{
		return decoder != null ? Std.int(decoder.duration * 1000) : 0;
	}

	public function getLoops():Int
	{
		return loops;
	}

	public function getPan():Float
	{
		return pan;
	}

	public function getPlaying():Bool
	{
		return playing;
	}

	public function getWidth():Int
	{
		return decoder != null ? decoder.width : 0;
	}

	public static function isSupported():Bool
	{
		return VideoDecoder.isSupported;
	}

	@:allow(lime.media.AudioManager)
	private static function prepareAudioContextRecovery():Void
	{
		// The OpenAL objects belong to the context being replaced, so they are
		// deleted while it is still current
		for (source in activeSources.copy())
		{
			source.deleteAudio();
		}
	}

	@:allow(lime.media.AudioManager)
	private static function restoreAudioContextRecovery():Void
	{
		for (source in activeSources.copy())
		{
			source.createAudio();
			if (source.handle != null) source.resyncAudio();
		}
	}

	public static function loadFromFile(path:String, format:VideoFrameFormat):Future<VideoSource>
	{
		var promise = new Promise<VideoSource>();

		// Opening reads the start of the file or waits for a server, so it runs
		// on a worker thread
		var future = new Future<VideoDecoder>(function()
		{
			var decoder = new VideoDecoder();
			return decoder.open(path, format) ? decoder : null;
		}, true);

		future.onComplete(function(decoder)
		{
			if (decoder == null)
			{
				promise.error("Cannot play " + path);
				return;
			}

			var source = new VideoSource();
			source.__backend.attach(decoder);
			source.source = path;
			promise.complete(source);
		});

		future.onError(promise.error);

		return promise.future;
	}

	public function open(path:String, format:VideoFrameFormat):Bool
	{
		close();

		var decoder = new VideoDecoder();

		if (!decoder.open(path, format))
		{
			return false;
		}

		attach(decoder);
		return true;
	}

	public function pause():Void
	{
		if (!playing) return;

		clockTime = getTime();
		clockStamp = getStamp();
		playing = false;

		if (handle != null)
		{
			AL.sourcePause(handle);
		}

		stopTimer();
	}

	public function play():Void
	{
		if (playing || decoder == null) return;

		if (completed)
		{
			seek(0);
		}

		clockStamp = getStamp();
		playing = true;

		update();

		if (timer == null)
		{
			timer = new Timer(UPDATE_INTERVAL);
			timer.run = update;
		}
	}

	public function readFrame(frame:VideoFrame):Bool
	{
		if (decoder == null || frame == null) return false;

		update();

		// The first frame after opening or seeking is shown straight away, so a
		// paused video still has a picture
		if (decoder.readFrame(frame, hasFrame ? getTime() : -1))
		{
			hasFrame = true;
			frameEndTime = frame.time + frame.duration;
			return true;
		}

		return false;
	}

	public function setCurrentTime(value:Int):Int
	{
		if (decoder != null)
		{
			seek(Math.max(0, value / 1000));
		}

		return value;
	}

	public function setGain(value:Float):Float
	{
		gain = value;

		if (handle != null)
		{
			AL.sourcef(handle, AL.GAIN, value);
		}

		return value;
	}

	public function setLoops(value:Int):Int
	{
		return loops = value;
	}

	public function setPan(value:Float):Float
	{
		pan = Math.max(-1, Math.min(1, value));

		// Stereo is balanced as it is buffered, and OpenAL places mono
		if (handle != null && decoder != null && decoder.audioChannels == 1)
		{
			AL.source3f(handle, AL.POSITION, pan, 0, -Math.sqrt(1 - pan * pan));
		}

		return pan;
	}

	public function stop():Void
	{
		pause();

		if (decoder != null)
		{
			seek(0);
		}
	}

	@:noCompletion private function attach(decoder:VideoDecoder):Void
	{
		close();

		this.decoder = decoder;

		bufferTimes = [];
		clockStamp = getStamp();
		clockTime = 0;
		completed = false;
		frameEndTime = 0;
		hasFrame = false;

		if (decoder.hasAudio)
		{
			blockAlign = decoder.audioChannels * 2;
			audioFormat = decoder.audioChannels == 1 ? AL.FORMAT_MONO16 : AL.FORMAT_STEREO16;
			audioBuffer = Bytes.alloc(Std.int(decoder.audioSampleRate * AUDIO_BUFFER_SECONDS) * blockAlign);
			audioData = UInt8Array.fromBytes(audioBuffer);
			audioSamples = Int16Array.fromBytes(audioBuffer);
			bytesPerSecond = decoder.audioSampleRate * blockAlign;

			activeSources.push(this);
			createAudio();
		}
	}

	@:noCompletion private function checkAudio():Void
	{
		var now = getStamp();

		// Only an output that has audio to play is checked. Underruns, and Lime
		// pausing the device while the window is hidden, are not stalls.
		if (!playing || isWaitingForFrame() || audioSkipping || bufferTimes.length == 0 || AudioManager.__suspended)
		{
			audioCheckStamp = -1;
			return;
		}

		var position = getAudioPosition();

		if (audioCheckStamp < 0 || now - audioLastCheck > AUDIO_CHECK_SECONDS / 2)
		{
			// Starting, or the application stopped updating for a while
			audioCheckPosition = position;
			audioCheckStamp = now;
			audioLastCheck = now;
			return;
		}

		audioLastCheck = now;

		var elapsed = now - audioCheckStamp;
		if (elapsed < AUDIO_CHECK_SECONDS) return;

		var rate = (position - audioCheckPosition) / elapsed;

		if (!audioStalled)
		{
			if (rate < 0.5 || rate > 2)
			{
				// The output stopped playing in real time, such as a sound server
				// that hangs or a device that was unplugged. The clock carries on
				// from the last time heard, and the audio is given another try.
				audioStalled = true;
				audioRetryStamp = now + AUDIO_RETRY_SECONDS;
			}
		}
		else if (rate > 0.75 && rate < 1.5 && Math.abs(position - getTime()) < 0.1)
		{
			// Playing in step again, so the audio leads the clock once more
			audioStalled = false;
		}

		audioCheckPosition = position;
		audioCheckStamp = now;
	}

	@:noCompletion private function clearBuffers():Void
	{
		// Rewinding stops the source in any state and leaves it initial, where no
		// buffer counts as played, as a stopped source would count them all. An
		// initial source cannot unqueue buffers, but removing its buffer releases
		// the whole queue.
		AL.sourceRewind(handle);
		AL.sourcei(handle, AL.BUFFER, null);

		audioClockStamp = -1;
		bufferTimes = [];
		freeBuffers = buffers != null ? buffers.copy() : [];
	}

	@:noCompletion private function close():Void
	{
		stopTimer();
		playing = false;

		activeSources.remove(this);
		deleteAudio();

		audioCheckStamp = -1;
		audioSkipping = false;
		audioStalled = false;

		if (decoder != null)
		{
			decoder.close();
			decoder = null;
		}

		audioBuffer = null;
		audioData = null;
		audioSamples = null;
		bufferTimes = [];
	}

	@:noCompletion private function complete():Void
	{
		if (loops > 0)
		{
			loops--;
			seek(0);
			return;
		}

		pause();
		completed = true;
		parent.onComplete.dispatch();
	}

	@:noCompletion private function createAudio():Void
	{
		handle = AL.createSource();
		if (handle == null) return;

		AL.sourcef(handle, AL.GAIN, gain);

		if (decoder.audioChannels == 1)
		{
			// Panned mono is placed around the listener, wherever it is
			AL.sourcei(handle, AL.SOURCE_RELATIVE, AL.TRUE);
			setPan(pan);
		}

		buffers = AL.genBuffers(AUDIO_BUFFER_COUNT);
		freeBuffers = buffers.copy();
		bufferTimes = [];
	}

	@:noCompletion private function deleteAudio():Void
	{
		if (handle != null)
		{
			clearBuffers();
			AL.deleteSource(handle);
			handle = null;
		}

		if (buffers != null)
		{
			AL.deleteBuffers(buffers);
			buffers = null;
			freeBuffers = null;
		}

		bufferTimes = [];
	}

	@:noCompletion private function fillBuffers():Void
	{
		// A stalled output is only given audio up to a little past the clock, so
		// one that drops what it is given does not drain the decoder
		var limit = audioStalled ? getTime() + AUDIO_AHEAD_SECONDS : Math.POSITIVE_INFINITY;

		while (freeBuffers.length > 0 && !decoder.audioComplete && decoder.audioTime < limit)
		{
			var length = decoder.readAudio(audioBuffer, 0, audioBuffer.length);
			if (length <= 0) break;

			if (pan != 0 && decoder.audioChannels == 2)
			{
				panBuffer(length);
			}

			var buffer = freeBuffers.pop();
			AL.bufferData(buffer, audioFormat, audioData, length, decoder.audioSampleRate);
			AL.sourceQueueBuffer(handle, buffer);
			bufferTimes.push(decoder.audioTime - length / bytesPerSecond);
		}
	}

	@:noCompletion private function followAudio(position:Float):Float
	{
		// The audio position only moves when the output mixes, every 20 to 60 ms
		// or more, and frames timed by it would arrive in uneven bursts. The clock
		// runs on monotonic time instead, a little faster or slower to stay with
		// the audio. It holds while the source or Lime's audio is paused, and
		// does not run far ahead of an output that stops taking audio.
		var now = getStamp();
		var running = playing && !AudioManager.__suspended && AL.getSourcei(handle, AL.SOURCE_STATE) == AL.PLAYING;
		var elapsed = running ? now - clockStamp : 0;
		var time = clockTime + elapsed;
		var error = position - time;

		if (Math.abs(error) > AUDIO_JUMP_SECONDS)
		{
			// Starting, or the audio moved on without the clock
			time = position;
		}
		else
		{
			time += Math.max(-AUDIO_STEER_RATE, Math.min(AUDIO_STEER_RATE, error / AUDIO_STEER_SECONDS)) * elapsed;
			time = Math.max(clockTime, Math.min(time, position + AUDIO_LEAD_SECONDS));
		}

		clockTime = time;
		clockStamp = now;
		return time;
	}

	@:noCompletion private function getAudioPosition():Float
	{
		// The time of the sample being heard. Rounding can put the start of the
		// first buffer just below zero, which readFrame would take as no time at
		// all.
		var offset:Int = AL.getSourcei(handle, AL.SAMPLE_OFFSET);
		return Math.max(0, bufferTimes[0] + offset / decoder.audioSampleRate);
	}

	@:noCompletion private static inline function getStamp():Float
	{
		// Timer.stamp follows the wall clock on Linux and macOS, which can step
		return System.getTimer() / 1000;
	}

	@:noCompletion private function getTime():Float
	{
		if (decoder == null) return 0;

		if (isWaitingForFrame())
		{
			return clockTime;
		}

		// The audio leads the clock while its output plays
		if (handle != null && !audioStalled)
		{
			if (bufferTimes.length > 0)
			{
				var position = getAudioPosition();
				if (isAudioPositionValid(position)) return followAudio(position);
			}
			else if (!decoder.audioComplete)
			{
				// Waiting for audio, so hold the picture too
				return clockTime;
			}
		}

		return playing ? clockTime + (getStamp() - clockStamp) : clockTime;
	}

	@:noCompletion private function isAudioPositionValid(position:Float):Bool
	{
		// OpenAL can report nonsense, such as for a source whose device went away.
		// A position that jumps rather than following real time is not used, and
		// the clock carries on from the last one that was, as for a stall.
		var now = getStamp();

		if (audioClockStamp >= 0)
		{
			var change = position - audioClockTime;

			if (change < -AUDIO_JUMP_SECONDS || change > (now - audioClockStamp) * 2 + AUDIO_JUMP_SECONDS)
			{
				audioStalled = true;
				audioRetryStamp = now + AUDIO_RETRY_SECONDS;
				return false;
			}
		}

		audioClockStamp = now;
		audioClockTime = position;
		return true;
	}

	@:noCompletion private inline function isWaitingForFrame():Bool
	{
		// After opening or seeking, the sound and the clock wait for the first
		// frame, which takes longer to decode, so both start together
		return !hasFrame && decoder.hasVideo && !decoder.videoComplete;
	}

	@:noCompletion private function panBuffer(length:Int):Void
	{
		// OpenAL only places mono sources, so stereo is balanced here by turning
		// down the channel opposite the pan
		var left = pan > 0 ? 1 - pan : 1;
		var right = pan < 0 ? 1 + pan : 1;
		var count = length >> 1;
		var i = 0;

		while (i < count)
		{
			audioSamples[i] = Std.int(audioSamples[i] * left);
			audioSamples[i + 1] = Std.int(audioSamples[i + 1] * right);
			i += 2;
		}
	}

	@:noCompletion private function resyncAudio():Void
	{
		// Drops the queued audio and the decoded audio before the clock, so the
		// sound starts again in step with the picture
		clearBuffers();
		audioCheckStamp = -1;
		audioSkipping = true;
	}

	@:noCompletion private function seek(time:Float):Void
	{
		decoder.seek(time, true);

		if (handle != null)
		{
			clearBuffers();
		}

		audioCheckStamp = -1;
		audioSkipping = false;
		clockStamp = getStamp();
		clockTime = time;
		completed = false;
		frameEndTime = 0;
		hasFrame = false;

		update();
	}

	@:noCompletion private function skipAudio(time:Float):Void
	{
		while (!decoder.audioComplete)
		{
			var length = Std.int((time - decoder.audioTime) * bytesPerSecond);
			length -= length % blockAlign;

			if (length <= 0) break;

			// Without more audio decoded yet, skipping carries on next update
			if (decoder.readAudio(audioBuffer, 0, Std.int(Math.min(length, audioBuffer.length))) <= 0) return;
		}

		audioSkipping = false;
	}

	@:noCompletion private function stopTimer():Void
	{
		if (timer != null)
		{
			timer.stop();
			timer = null;
		}
	}

	@:noCompletion private function unqueueBuffers(count:Int):Void
	{
		if (count <= 0) return;

		for (buffer in AL.sourceUnqueueBuffers(handle, count))
		{
			freeBuffers.push(buffer);
			bufferTimes.shift();
		}
	}

	@:noCompletion private function update():Void
	{
		if (decoder == null) return;

		if (handle != null)
		{
			unqueueBuffers(AL.getSourcei(handle, AL.BUFFERS_PROCESSED));

			if (audioStalled && playing && getStamp() >= audioRetryStamp)
			{
				audioRetryStamp = getStamp() + AUDIO_RETRY_SECONDS;
				resyncAudio();
			}

			if (audioSkipping)
			{
				skipAudio(getTime());
			}

			if (!audioSkipping)
			{
				fillBuffers();
			}

			if (playing && bufferTimes.length > 0 && !isWaitingForFrame() && AL.getSourcei(handle, AL.SOURCE_STATE) != AL.PLAYING)
			{
				AL.sourcePlay(handle);
			}

			checkAudio();
		}

		var time = getTime();

		if (playing && !completed)
		{
			// Keep the clock current so it carries on smoothly when the audio ends
			clockTime = time;
			clockStamp = getStamp();

			var audioDone = handle == null || audioStalled || (decoder.audioComplete && bufferTimes.length == 0);
			var videoDone = !decoder.hasVideo || (decoder.videoComplete && time >= frameEndTime)
				|| (decoder.duration > 0 && time >= decoder.duration);

			if (audioDone && videoDone)
			{
				complete();
			}
		}
	}
}
