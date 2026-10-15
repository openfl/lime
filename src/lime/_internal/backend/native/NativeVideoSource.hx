package lime._internal.backend.native;

import haxe.io.Bytes;
import haxe.Timer;
import lime.app.Future;
import lime.app.Promise;
import lime.media.AudioManager;
import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALC;
import lime.media.openal.ALSource;
import lime.media.VideoClockMode;
import lime.media.VideoDecoder;
import lime.media.VideoFrame;
import lime.media.VideoFrameFormat;
import lime.media.VideoSource;
import lime.system.System;
#if (lime_threads && !html5)
#if target.threaded
import sys.thread.Mutex;
import sys.thread.Thread;
#elseif cpp
import cpp.vm.Mutex;
import cpp.vm.Thread;
#else
import neko.vm.Mutex;
import neko.vm.Thread;
#end
#end
import lime.utils.Int16Array;
import lime.utils.UInt8Array;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime.media.VideoSource)
@:access(lime.system.System)
class NativeVideoSource
{
	private static inline var AUDIO_AHEAD_SECONDS:Float = 0.25;
	// Half a second of sound is queued, so it plays on through pauses in the
	// application's updates, such as garbage collection or a blocking load
	private static inline var AUDIO_BUFFER_COUNT:Int = 12;
	private static inline var AUDIO_BUFFER_SECONDS:Float = 0.04;
	private static inline var AUDIO_CHECK_SECONDS:Float = 0.5;
	private static inline var AUDIO_DRIFT_SECONDS:Float = 0.1;
	private static inline var AUDIO_DRIFT_WAIT_SECONDS:Float = 0.25;
	private static inline var AUDIO_FEED_SECONDS:Float = 0.02;
	private static inline var AUDIO_JUMP_SECONDS:Float = 0.25;
	private static inline var AUDIO_LEAD_SECONDS:Float = 0.2;
	private static inline var AUDIO_LEARN_SECONDS:Float = 1.0;
	private static inline var AUDIO_MIX_SECONDS:Float = 0.0001;
	private static inline var AUDIO_READ_SECONDS:Float = 0.05;
	private static inline var AUDIO_RETRY_SECONDS:Float = 1.0;
	private static inline var AUDIO_STEER_RATE:Float = 0.1;
	private static inline var AUDIO_STEER_SECONDS:Float = 0.5;
	// A looping video opens its next loop this long before the end
	private static inline var LOOP_OPEN_SECONDS:Float = 2.0;
	private static inline var LOOP_POLL_SECONDS:Float = 0.05;
	private static inline var UPDATE_INTERVAL:Int = 10;
	private static inline var VIDEO_BEHIND_SECONDS:Float = 1.0;

	private static var activeSources:Array<NativeVideoSource> = [];
	#if (lime_threads && !html5)
	private static var activeSourcesMutex:Mutex = new Mutex();
	private static var feeding:Bool = false;
	private static var loopRequests:Array<LoopRequest> = [];
	private static var loopRequestsMutex:Mutex = new Mutex();
	private static var loopThreadStarted:Bool = false;
	private static var retiredDecoders:Array<VideoDecoder> = [];
	#end
	private static var latencyExtension:Null<Bool>;
	private static var timerDrift:Float = 0;

	private var audioBuffer:Bytes;
	private var audioCheckPosition:Float;
	private var audioCheckStamp:Float;
	private var audioClockStamp:Float;
	private var audioClockTime:Float;
	private var audioData:UInt8Array;
	private var audioDecoder:VideoDecoder;
	private var audioDriftStamp:Float;
	private var audioFormat:Int;
	private var audioLastCheck:Float;
	private var audioLatencyBelow:Float;
	private var audioLatencyMeasured:Bool;
	private var audioLatencyMost:Float;
	private var audioMixPosition:Float;
	private var audioOffset:Float;
	#if (lime_threads && !html5)
	private var audioMutex:Mutex;
	#end
	private var audioPeriod:Float;
	private var audioRateCount:Int;
	private var audioRatePosition:Float;
	private var audioRateStamp:Float;
	private var audioRateSums:Array<Float>;
	private var audioReadPosition:Float;
	private var audioReadStamp:Float;
	private var audioRetryStamp:Float;
	private var audioSamples:Int16Array;
	private var audioSkipping:Bool;
	private var audioStalled:Bool;
	private var audioStarting:Bool;
	private var blockAlign:Int;
	private var bufferTimes:Array<Float>;

	/**
		The stereo sound in each queued buffer as it was before it was panned, so
		that what is left of the queue can be panned again. Null for mono.
	**/
	private var bufferSounds:Array<QueuedSound>;
	private var buffers:Array<ALBuffer>;
	private var bytesPerSecond:Float;
	private var clockMode:VideoClockMode;
	private var clockRate:Float;
	private var clockStamp:Float;
	private var clockTime:Float;
	private var completed:Bool;
	private var decoder:VideoDecoder;
	private var droppedBefore:Int;
	private var dropLateFrames:Bool;
	private var failed:Bool;
	private var freeBuffers:Array<ALBuffer>;
	private var freeSounds:Array<Bytes>;
	private var frameDuration:Float;
	private var frameEndTime:Float;
	private var gain:Float;
	private var handle:ALSource;
	private var hasFrame:Bool;
	private var loopDecoder:VideoDecoder;
	private var loopOffset:Float;
	private var loopOpening:Bool;
	private var loopToken:Int;
	private var loops:Int;
	private var pan:Float;
	private var parent:VideoSource;
	private var playing:Bool;
	private var retiredDecoder:VideoDecoder;
	private var timer:Timer;

	public function new(parent:VideoSource)
	{
		this.parent = parent;

		#if (lime_threads && !html5)
		audioMutex = new Mutex();
		#end

		audioCheckStamp = -1;
		audioClockStamp = -1;
		audioDriftStamp = -1;
		audioLatencyBelow = 0;
		audioLatencyMeasured = false;
		audioLatencyMost = 0;
		audioMixPosition = 0;
		audioOffset = 0;
		audioPeriod = 0;
		audioRateCount = 0;
		audioRatePosition = 0;
		audioRateStamp = -1;
		audioRateSums = [0, 0, 0, 0];
		audioReadPosition = 0;
		audioReadStamp = -1;
		audioSkipping = false;
		audioStalled = false;
		audioStarting = false;
		bufferTimes = [];
		bufferSounds = [];
		clockMode = SMOOTH;
		clockRate = 1;
		clockStamp = 0;
		clockTime = 0;
		completed = false;
		droppedBefore = 0;
		dropLateFrames = true;
		failed = false;
		frameDuration = 0;
		frameEndTime = 0;
		gain = 1;
		hasFrame = false;
		loopOffset = 0;
		loopOpening = false;
		loopToken = 0;
		loops = 0;
		pan = 0;
		playing = false;
	}

	public function dispose():Void
	{
		close();
	}

	public function getClockMode():VideoClockMode
	{
		return clockMode;
	}

	public function getCurrentTime():Int
	{
		// The clock runs on across loops, and the time is within the loop playing
		var time = getTime() - loopOffset;
		if (decoder != null && decoder.duration > 0) time = Math.min(time, decoder.duration);
		return Std.int(time * 1000);
	}

	public function getDisplayHeight():Int
	{
		return decoder != null ? decoder.displayHeight : 0;
	}

	public function getDisplayWidth():Int
	{
		return decoder != null ? decoder.displayWidth : 0;
	}

	public function getDroppedFrames():Int
	{
		return decoder != null ? droppedBefore + decoder.droppedFrames : 0;
	}

	public function getDropLateFrames():Bool
	{
		return dropLateFrames;
	}

	public function getGain():Float
	{
		return gain;
	}

	public function getHasAudio():Bool
	{
		return decoder != null && decoder.hasAudio;
	}

	public function getHasVideo():Bool
	{
		return decoder != null && decoder.hasVideo;
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

	public function getPixelAspectRatio():Float
	{
		return decoder != null ? decoder.pixelAspectRatio : 1;
	}

	public function getPlaying():Bool
	{
		return playing;
	}

	public function getRotation():Int
	{
		return decoder != null ? decoder.rotation : 0;
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
		for (source in getActiveSources())
		{
			source.deleteAudio();
		}
	}

	@:allow(lime.media.AudioManager)
	private static function restoreAudioContextRecovery():Void
	{
		// A new output runs at its own rate
		timerDrift = 0;

		for (source in getActiveSources())
		{
			source.lockAudio();
			source.createAudio();
			if (source.handle != null) source.resyncAudio();
			source.unlockAudio();
		}
	}

	public static function loadFromFile(path:String, format:VideoFrameFormat):Future<VideoSource>
	{
		var promise = new Promise<VideoSource>();

		openDecoder(path, format, true, function(decoder) completeLoad(decoder, path, promise));
		return promise.future;
	}

	@:noCompletion private static function openDecoder(path:String, format:VideoFrameFormat, hardwareDecoding:Bool, callback:VideoDecoder->Void):Void
	{
		#if (lime_threads && !html5)
		// Opening reads the start of the file or waits for a server, so each
		// video opens on a thread of its own, where a slow server holds up
		// nothing else. The callback runs on the main thread, as promises do,
		// with null when the video cannot be opened.
		Thread.create(function()
		{
			var decoder = new VideoDecoder();
			decoder.hardwareDecoding = hardwareDecoding;
			var opened = false;

			// An error while opening is reported as a video that cannot be opened,
			// rather than leaving the callback waiting
			try
			{
				opened = decoder.open(path, format);
			}
			catch (e:Dynamic) {}

			haxe.MainLoop.runInMainThread(callback.bind(opened ? decoder : null));
		});
		#else
		var decoder = new VideoDecoder();
		decoder.hardwareDecoding = hardwareDecoding;
		callback(decoder.open(path, format) ? decoder : null);
		#end
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
		lockAudio();
		pauseUnlocked();
		unlockAudio();
	}

	@:noCompletion private function pauseUnlocked():Void
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

		// A video that has ended, or that was moved to its end, plays again from
		// the start, unless its next loop is ready to follow on. The end is
		// compared in the milliseconds of currentTime and length.
		if (completed
			|| (loopDecoder == null && decoder.duration > 0 && Std.int((clockTime - loopOffset) * 1000) >= Std.int(decoder.duration * 1000)))
		{
			seek(0);
		}
		else if (failed && !seek(clockTime - loopOffset))
		{
			// Playing again after an error tries again from where it stopped
			return;
		}

		// Seeking updates, where a handler can dispose of the source
		if (decoder == null) return;

		clockStamp = getStamp();
		playing = true;

		// The timer starts first, so an update that completes playback, or a
		// handler that disposes of the source, stops it
		if (timer == null)
		{
			timer = new Timer(UPDATE_INTERVAL);
			timer.run = update;
		}

		update();
	}

	public function readFrame(frame:VideoFrame):Bool
	{
		if (decoder == null || frame == null) return false;

		update();

		// Updating can complete playback, and the handler can dispose of the source
		if (decoder == null) return false;

		// The first frame after opening or seeking is shown straight away, so a
		// paused video still has a picture
		if (decoder.readFrame(frame, hasFrame ? getTime() - loopOffset : -1))
		{
			hasFrame = true;
			frameDuration = frame.duration;
			frameEndTime = frame.time + frame.duration + loopOffset;

			// The last loop's frames, and its textures, are kept until the next
			// loop's first frame replaces them
			closeRetiredDecoder();
			return true;
		}

		return false;
	}

	public function setClockMode(value:VideoClockMode):VideoClockMode
	{
		if (value != clockMode)
		{
			// The new mode carries on from the current time
			clockTime = getTime();
			clockStamp = getStamp();
			clockRate = 1;
			audioDriftStamp = -1;
			audioRateStamp = -1;
			audioReadStamp = -1;
			audioStarting = false;
			clockMode = value;
		}

		return value;
	}

	public function setCurrentTime(value:Int):Int
	{
		if (decoder != null)
		{
			seek(value / 1000);
		}

		return value;
	}

	public function setDropLateFrames(value:Bool):Bool
	{
		if (decoder != null) decoder.dropLateFrames = value;
		if (loopDecoder != null) loopDecoder.dropLateFrames = value;
		return dropLateFrames = value;
	}

	public function setGain(value:Float):Float
	{
		gain = value;
		lockAudio();

		if (handle != null)
		{
			AL.sourcef(handle, AL.GAIN, value);
		}

		unlockAudio();
		return value;
	}

	public function setLoops(value:Int):Int
	{
		return loops = value;
	}

	public function setPan(value:Float):Float
	{
		value = Math.max(-1, Math.min(1, value));
		lockAudio();

		var changed = value != pan;
		pan = value;

		// OpenAL places mono, and stereo is balanced as it is buffered
		if (handle != null && decoder != null)
		{
			if (decoder.audioChannels == 1)
			{
				AL.source3f(handle, AL.POSITION, pan, 0, -Math.sqrt(1 - pan * pan));
			}
			else if (changed && audioDecoder != null && audioDecoder.audioChannels == 2)
			{
				panQueue();
			}
		}

		unlockAudio();
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
		lockAudio();
		attachUnlocked(decoder);
		unlockAudio();
	}

	@:noCompletion private function attachUnlocked(decoder:VideoDecoder):Void
	{
		close();

		this.decoder = decoder;
		decoder.dropLateFrames = dropLateFrames;

		audioDecoder = decoder;
		audioOffset = 0;
		droppedBefore = 0;
		loopOffset = 0;
		loopOpening = false;
		loopToken++;
		failed = false;
		audioDriftStamp = -1;
		audioRateStamp = -1;
		audioReadStamp = -1;
		audioStarting = decoder.hasAudio;
		bufferTimes = [];
		bufferSounds = [];
		clockRate = 1;
		clockStamp = getStamp();
		clockTime = 0;
		completed = false;
		frameDuration = 0;
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

			createAudio();
			addActiveSource(this);
		}
	}

	@:noCompletion private function checkAudio():Void
	{
		var now = getStamp();

		// Only an output that has audio to play is checked. Underruns, sound that
		// has not started yet, and Lime pausing the device while the window is
		// hidden, are not stalls.
		if (!playing || isWaitingForFrame() || audioSkipping || bufferTimes.length == 0 || AudioManager.__suspended
			|| AL.getSourcei(handle, AL.SOURCE_STATE) == AL.INITIAL)
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

	@:noCompletion private function checkDrift():Void
	{
		// A clock that runs on the timer alone moves the sound to it once they
		// have been more than a tenth of a second apart for a quarter of a
		// second while the sound plays
		if (!playing || audioSkipping || bufferTimes.length == 0 || AudioManager.__suspended
			|| AL.getSourcei(handle, AL.SOURCE_STATE) != AL.PLAYING
			|| Math.abs(getAudioPosition() - getTime()) <= AUDIO_DRIFT_SECONDS)
		{
			audioDriftStamp = -1;
			return;
		}

		var now = getStamp();

		if (audioDriftStamp < 0)
		{
			audioDriftStamp = now;
		}
		else if (now - audioDriftStamp >= AUDIO_DRIFT_WAIT_SECONDS)
		{
			audioDriftStamp = -1;
			resyncAudio();
		}
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
		recycleSounds(bufferSounds);
		bufferTimes = [];
		bufferSounds = [];
		freeBuffers = buffers != null ? buffers.copy() : [];
	}

	@:noCompletion private function close():Void
	{
		lockAudio();
		closeUnlocked();
		unlockAudio();
	}

	@:noCompletion private function closeUnlocked():Void
	{
		stopTimer();
		playing = false;

		removeActiveSource(this);
		deleteAudio();

		audioCheckStamp = -1;
		audioSkipping = false;
		audioStalled = false;
		audioStarting = false;

		closeLoops();

		if (decoder != null)
		{
			decoder.close();
			decoder = null;
		}

		audioDecoder = null;
		audioBuffer = null;
		audioData = null;
		audioSamples = null;
		bufferTimes = [];
		bufferSounds = [];
	}

	@:noCompletion private function closeLoops():Void
	{
		// Loops being opened are dropped when they arrive
		loopToken++;
		loopOpening = false;

		if (loopDecoder != null)
		{
			closeDecoderLater(loopDecoder);
			loopDecoder = null;
		}

		closeRetiredDecoder();
		audioDecoder = decoder;
		audioOffset = loopOffset;
	}

	@:noCompletion private static function closeDecoderLater(decoder:VideoDecoder):Void
	{
		#if (lime_threads && !html5)
		// Closing waits for the decoder's threads and releases its device, which
		// would hold up the frames at each loop, so it happens on the loop thread.
		// Texture output is closed where its textures were made.
		if (decoder.format != TEXTURE)
		{
			loopRequestsMutex.acquire();
			retiredDecoders.push(decoder);
			startLoopThread();
			loopRequestsMutex.release();
			return;
		}
		#end

		decoder.close();
	}

	@:noCompletion private function closeRetiredDecoder():Void
	{
		if (retiredDecoder != null)
		{
			closeDecoderLater(retiredDecoder);
			retiredDecoder = null;
		}
	}

	@:noCompletion private function complete():Void
	{
		// A video that cannot seek, such as a live stream, cannot loop
		if (loops > 0 && seek(0))
		{
			loops--;
			return;
		}

		pause();
		completed = true;
		parent.onComplete.dispatch();
	}

	@:noCompletion private static function completeLoad(decoder:VideoDecoder, path:String, promise:Promise<VideoSource>):Void
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
	}

	@:noCompletion private function createAudio():Void
	{
		lockAudio();
		createAudioUnlocked();
		unlockAudio();
	}

	@:noCompletion private function createAudioUnlocked():Void
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
		freeSounds = [];
		bufferTimes = [];
		bufferSounds = [];

		// The output mixes once a period, and until its latency is seen changing,
		// it is taken as a fixed estimate
		var context = ALC.getCurrentContext();
		var device = context != null ? ALC.getContextsDevice(context) : null;
		var refresh = device != null ? ALC.getIntegerv(device, ALC.REFRESH, 1)[0] : 0;
		audioLatencyBelow = 0;
		audioLatencyMeasured = false;
		audioLatencyMost = 0;
		audioPeriod = refresh > 0 ? 1 / refresh : 0;
	}

	@:noCompletion private function deleteAudio():Void
	{
		lockAudio();
		deleteAudioUnlocked();
		unlockAudio();
	}

	@:noCompletion private function deleteAudioUnlocked():Void
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
		bufferSounds = [];
	}

	@:noCompletion private function fillBuffers():Void
	{
		// A stalled output is only given audio up to a little past the clock, so
		// one that drops what it is given does not drain the decoder
		var limit = audioStalled ? getTime() + AUDIO_AHEAD_SECONDS : Math.POSITIVE_INFINITY;

		while (freeBuffers.length > 0 && audioDecoder.audioTime + audioOffset < limit)
		{
			var length = audioDecoder.audioComplete ? 0 : audioDecoder.readAudio(audioBuffer, 0, audioBuffer.length);

			if (length <= 0)
			{
				// The next loop's sound follows straight on, once it is open
				if (audioDecoder.audioComplete && startLoopAudio()) continue;
				break;
			}

			queueSound(length, audioDecoder.audioTime + audioOffset - length / bytesPerSecond);
		}
	}

	@:noCompletion private function queueSound(length:Int, time:Float):Void
	{
		// Queues the sound in audioBuffer, which starts at the given time, keeping
		// stereo as it was so that it can be panned again
		var sound:QueuedSound = null;

		if (audioDecoder.audioChannels == 2)
		{
			var data = freeSounds.length > 0 ? freeSounds.pop() : Bytes.alloc(audioBuffer.length);
			data.blit(0, audioBuffer, 0, length);
			sound = {data: data, length: length};

			if (pan != 0)
			{
				panBuffer(length);
			}
		}

		var buffer = freeBuffers.pop();
		AL.bufferData(buffer, audioFormat, audioData, length, audioDecoder.audioSampleRate);
		AL.sourceQueueBuffer(handle, buffer);
		bufferTimes.push(time);
		bufferSounds.push(sound);
	}

	@:noCompletion private function panQueue():Void
	{
		// Stereo is balanced as it is buffered, so what the output has yet to play
		// is queued again with the new balance, from the sample it is at
		unqueueBuffers(AL.getSourcei(handle, AL.BUFFERS_PROCESSED));
		if (bufferTimes.length == 0 || bufferSounds[0] == null) return;

		var playing = AL.getSourcei(handle, AL.SOURCE_STATE) == AL.PLAYING;
		var skip = AL.getSourcei(handle, AL.SAMPLE_OFFSET) * blockAlign;
		var times = bufferTimes;
		var sounds = bufferSounds;

		bufferSounds = [];
		clearBuffers();

		for (i in 0...sounds.length)
		{
			var sound = sounds[i];
			var start = i == 0 ? Std.int(Math.min(skip, sound.length)) : 0;

			if (start < sound.length)
			{
				audioBuffer.blit(0, sound.data, start, sound.length - start);
				freeSounds.push(sound.data);
				queueSound(sound.length - start, times[i] + start / bytesPerSecond);
			}
			else
			{
				freeSounds.push(sound.data);
			}
		}

		if (playing && bufferTimes.length > 0)
		{
			AL.sourcePlay(handle);
		}
	}

	@:noCompletion private function recycleSounds(sounds:Array<QueuedSound>):Void
	{
		if (sounds == null || freeSounds == null) return;

		for (sound in sounds)
		{
			if (sound != null) freeSounds.push(sound.data);
		}
	}

	@:noCompletion private function followAudio(position:Float):Float
	{
		var now = getStamp();
		var running = playing && !AudioManager.__suspended && AL.getSourcei(handle, AL.SOURCE_STATE) == AL.PLAYING;

		// The audio position moves each time the output mixes, at some point since
		// the clock last read it, taken as halfway. Reads further apart cannot
		// place the mix, so the position is used as it is. Unqueueing a played
		// buffer can move it by a rounding error, which is not a mix.
		var moved = Math.abs(audioMixPosition - audioReadPosition) > AUDIO_MIX_SECONDS;
		var timed = moved && audioReadStamp >= 0 && now - audioReadStamp <= AUDIO_READ_SECONDS;
		var heard = position + (timed ? (now - audioReadStamp) / 2 : 0);
		audioReadPosition = audioMixPosition;
		audioReadStamp = now;

		var time = running ? clockTime + (now - clockStamp) * clockRate : clockTime;

		if (audioStarting)
		{
			// After opening or seeking, the clock waits for the sound to be heard,
			// and starts at a mix, where the position is freshest, unless reads are
			// too far apart to see one
			if (position <= clockTime || (!timed && position <= clockTime + AUDIO_LEAD_SECONDS))
			{
				clockStamp = now;
				return clockTime;
			}

			audioStarting = false;
			clockRate = 1 + timerDrift;
			time = clockMode == AUDIO || !timed ? position : heard;
		}
		else
		{
			switch (clockMode)
			{
				case AUDIO:
					time = position;

				case INTERPOLATED:
					// Runs on the timer between mixes, and is set back to the sound
					// each time it moves
					if (running && moved) time = heard;

				default:
					var gap = heard - time;

					if (Math.abs(gap) > AUDIO_JUMP_SECONDS)
					{
						// The sound moved on without the clock
						time = heard;
						clockRate = 1 + timerDrift;
						audioRateStamp = -1;
					}
					else
					{
						// Each mix sets how much faster or slower the clock runs until
						// the next, closing the gap without jumping. Outputs and the
						// timer run at slightly different rates, several percent apart
						// in some virtual machines, so the sound's rate against the
						// timer is fitted to every mix since the clock last held or
						// jumped, once that is a second ago, and kept for every video.
						// The clock never goes back, or far ahead of an output that
						// stops taking audio.
						if (timed && running)
						{
							if (audioRateStamp < 0)
							{
								audioRateCount = 0;
								audioRatePosition = heard;
								audioRateStamp = now;
								audioRateSums = [0, 0, 0, 0];
							}

							var t = now - audioRateStamp;
							var h = heard - audioRatePosition;
							audioRateCount++;
							audioRateSums[0] += t;
							audioRateSums[1] += h;
							audioRateSums[2] += t * t;
							audioRateSums[3] += t * h;

							var spread = audioRateCount * audioRateSums[2] - audioRateSums[0] * audioRateSums[0];

							if (t >= AUDIO_LEARN_SECONDS && spread > 0)
							{
								var rate = (audioRateCount * audioRateSums[3] - audioRateSums[0] * audioRateSums[1]) / spread;
								timerDrift = Math.max(-AUDIO_STEER_RATE, Math.min(AUDIO_STEER_RATE, rate - 1));
							}

							clockRate = 1 + timerDrift + Math.max(-AUDIO_STEER_RATE, Math.min(AUDIO_STEER_RATE, gap / AUDIO_STEER_SECONDS));
						}
						else if (!running)
						{
							audioRateStamp = -1;
						}

						time = Math.max(clockTime, Math.min(time, position + AUDIO_LEAD_SECONDS));
					}
			}
		}

		clockTime = time;
		clockStamp = now;
		return time;
	}

	@:noCompletion private function getAudioLatency():Float
	{
		// How long the output takes to play what it has mixed, where OpenAL Soft
		// reports it
		#if lime_openalsoft
		if (hasLatency()) return getHeardLatency(AL.getSourcedvSOFT(handle, AL.SEC_OFFSET_LATENCY_SOFT, 2)[1]);
		#end
		return 0;
	}

	@:noCompletion private function getAudioPosition():Float
	{
		// The time of the sample being heard: how far the output has mixed into
		// the queue, less its latency where OpenAL Soft reports it. Rounding can
		// put the start of the first buffer just below zero, which readFrame
		// would take as no time at all.
		var offset:Float;
		var latency = 0.0;

		#if lime_openalsoft
		if (hasLatency())
		{
			var values = AL.getSourcedvSOFT(handle, AL.SEC_OFFSET_LATENCY_SOFT, 2);
			offset = values[0];
			latency = getHeardLatency(values[1]);
		}
		else
		#end
		{
			offset = AL.getSourcei(handle, AL.SAMPLE_OFFSET) / decoder.audioSampleRate;
		}

		audioMixPosition = bufferTimes[0] + offset;
		return Math.max(0, audioMixPosition - latency);
	}

	@:noCompletion private function getHeardLatency(reported:Float):Float
	{
		// Outputs that measure their latency report it falling as they play and
		// rising as they mix, so most readings are below the most seen, and the
		// position they give when they mix is what is heard then. The rest report
		// a fixed estimate of all but one period, right just before each mix but
		// a period short when the position moves, so what is heard then is a
		// period further back. OpenAL Soft also takes up to a period off when a
		// mix lands while it reads, which leaves an estimate below the most seen
		// now and then. So the latency is taken as an estimate, and the most seen
		// used, until a third of the readings fall below it.
		audioLatencyMost = Math.max(audioLatencyMost, reported);
		var below = reported < audioLatencyMost - AUDIO_MIX_SECONDS ? 1 : 0;
		audioLatencyBelow += (below - audioLatencyBelow) * 0.05;
		if (audioLatencyBelow > 0.3) audioLatencyMeasured = true;

		return audioLatencyMeasured ? reported : audioLatencyMost + audioPeriod;
	}

	@:noCompletion private static inline function getStamp():Float
	{
		// SDL's monotonic ticks, read as a Float, since System.getTimer wraps
		// after 24.8 days
		return System.__getTimer() / 1000;
	}

	@:noCompletion private function getTime():Float
	{
		lockAudio();
		var time = getTimeUnlocked();
		unlockAudio();
		return time;
	}

	@:noCompletion private function getTimeUnlocked():Float
	{
		if (decoder == null) return 0;

		// The clock is carried on from the time and stamp it last had, both set
		// from the same reading of the timer, so no time is lost between reads
		var now = getStamp();

		if (isWaitingForFrame())
		{
			clockStamp = now;
			return clockTime;
		}

		// The audio leads the clock while its output plays, unless the clock runs
		// on the timer alone
		if (handle != null && !audioStalled && clockMode != MONOTONIC)
		{
			if (bufferTimes.length > 0)
			{
				var position = getAudioPosition();
				if (isAudioPositionValid(position)) return followAudio(position);
			}
			else if (!audioDecoder.audioComplete)
			{
				// Waiting for audio, so hold the picture too
				clockStamp = now;
				return clockTime;
			}
		}

		// Lime pauses the sound while the application is in the background or its
		// window is inactive, so a clock on the timer alone holds then too
		if (playing && !AudioManager.__suspended)
		{
			clockTime += now - clockStamp;
		}

		clockStamp = now;
		return clockTime;
	}

	@:noCompletion private static function hasLatency():Bool
	{
		if (latencyExtension == null) latencyExtension = AL.isExtensionPresent("AL_SOFT_source_latency");
		return latencyExtension;
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

	@:noCompletion private function openLoop():Void
	{
		// The next loop opens ahead of the end, so its sound and frames follow on
		// without the pause of seeking back to the start
		var token = ++loopToken;
		loopOpening = true;

		#if (lime_threads && !html5)
		// Opening reads the file or waits for a server, so it happens on a thread
		// of its own, which hands the decoder over under the source's lock
		loopRequestsMutex.acquire();
		loopRequests.push({format: decoder.format, hardwareDecoding: decoder.hardwareDecoding, path: parent.source, source: this, token: token});
		startLoopThread();
		loopRequestsMutex.release();
		#else
		var next = new VideoDecoder();
		next.hardwareDecoding = decoder.hardwareDecoding;
		finishLoop(token, next.open(parent.source, decoder.format) ? next : null);
		#end
	}

	@:noCompletion private function finishLoop(token:Int, next:VideoDecoder):Void
	{
		lockAudio();

		if (token == loopToken && decoder != null && next != null)
		{
			next.dropLateFrames = dropLateFrames;
			loopDecoder = next;
		}
		else if (next != null)
		{
			next.close();
		}

		// A loop that cannot open is not tried again until the next seek
		unlockAudio();
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

	@:noCompletion private function seek(time:Float):Bool
	{
		lockAudio();
		var moved = seekUnlocked(time);
		unlockAudio();
		return moved;
	}

	@:noCompletion private function seekUnlocked(time:Float):Bool
	{
		time = Math.max(0, time);
		if (decoder.duration > 0) time = Math.min(time, decoder.duration);

		// A video that cannot seek carries on as it was
		if (!decoder.seek(time, true)) return false;

		// Seeking starts the timeline again from the loop playing
		loopOffset = 0;
		closeLoops();

		if (handle != null)
		{
			clearBuffers();
		}

		audioCheckStamp = -1;
		audioDriftStamp = -1;
		audioRateStamp = -1;
		audioReadStamp = -1;
		audioSkipping = false;
		audioStarting = handle != null;
		clockRate = 1;
		clockStamp = getStamp();
		clockTime = time;
		completed = false;
		failed = false;
		frameDuration = 0;
		frameEndTime = 0;
		hasFrame = false;

		update();
		return true;
	}

	@:noCompletion private function skipAudio(time:Float):Void
	{
		while (!audioDecoder.audioComplete)
		{
			var length = Std.int((time - audioOffset - audioDecoder.audioTime) * bytesPerSecond);
			length -= length % blockAlign;

			if (length <= 0) break;

			// Without more audio decoded yet, skipping carries on next update
			if (audioDecoder.readAudio(audioBuffer, 0, Std.int(Math.min(length, audioBuffer.length))) <= 0) return;
		}

		audioSkipping = false;
	}

	@:noCompletion private function startLoopAudio():Bool
	{
		if (loops <= 0 || loopDecoder == null || audioDecoder != decoder || audioDecoder.error || !loopDecoder.hasAudio) return false;

		audioDecoder = loopDecoder;
		audioOffset = loopOffset + decoder.duration;
		return true;
	}

	@:noCompletion private function startLoop():Void
	{
		// The next loop takes over the picture once the last frame of this one has
		// been shown, after its sound took over the queue. The clock runs on.
		var previous = decoder;
		droppedBefore += previous.droppedFrames;
		loopOffset += previous.duration;
		decoder = loopDecoder;
		loopDecoder = null;
		loopOpening = false;
		loops--;

		if (audioDecoder == previous)
		{
			audioDecoder = decoder;
			audioOffset = loopOffset;
		}

		closeRetiredDecoder();

		if (hasFrame && previous.hasVideo)
		{
			retiredDecoder = previous;
		}
		else
		{
			closeDecoderLater(previous);
		}
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

			var sound = bufferSounds.shift();
			if (sound != null && freeSounds != null) freeSounds.push(sound.data);
		}
	}

	@:noCompletion private function update():Void
	{
		lockAudio();
		updateUnlocked();
		unlockAudio();
	}

	@:noCompletion private function updateUnlocked():Void
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
				// Far enough ahead that the sound is heard when the clock gets there
				skipAudio(getTime() + getAudioLatency());
			}

			if (!audioSkipping)
			{
				fillBuffers();
			}

			if (playing && bufferTimes.length > 0 && !isWaitingForFrame())
			{
				var state = AL.getSourcei(handle, AL.SOURCE_STATE);
				var start = true;

				if (state == AL.INITIAL && clockMode == MONOTONIC)
				{
					// The clock does not wait for the sound, which would be late by the
					// output's latency, so it starts that much further in. Sound that
					// starts ahead of the clock, as after moving the sound to the clock
					// once more audio was read than was played, waits for the clock.
					var offset = getTime() - bufferTimes[0] + getAudioLatency();
					var queued = bufferTimes.length * AUDIO_BUFFER_SECONDS;
					if (offset > 0) AL.sourcef(handle, AL.SEC_OFFSET, Math.min(offset, queued - AUDIO_BUFFER_SECONDS));
					else start = offset > -AUDIO_MIX_SECONDS;
				}

				if (start && state != AL.PLAYING)
				{
					AL.sourcePlay(handle);
				}
			}

			checkAudio();

			if (clockMode == MONOTONIC)
			{
				checkDrift();
			}
		}

		var time = getTime();

		// Frames that fall far behind the clock, as when the application stops
		// reading them for a while or decoding cannot keep up, are caught up by
		// seeking to the clock rather than shown late. A video that cannot seek
		// is given another second.
		if (playing && !completed && hasFrame && decoder.hasVideo && !decoder.videoComplete && decoder.duration > 0
			&& time - frameEndTime > VIDEO_BEHIND_SECONDS)
		{
			if (seek(time - loopOffset)) return;
			frameEndTime = time;
		}

		if ((decoder.error || (audioDecoder != null && audioDecoder.error)) && !failed)
		{
			// A stream that cannot be decoded stops playback, rather than it
			// carrying on without that stream or completing
			failed = true;
			pause();
			parent.onError.dispatch("Cannot decode " + parent.source);
			return;
		}

		if (playing && !completed && !failed)
		{
			// A video whose first frame comes after its start, as when it has no
			// edit list, shows its last frame at its duration, so the video is done
			// once its frames run out, or a frame after the end if none are read
			var videoDone = !decoder.hasVideo || (decoder.videoComplete && time >= frameEndTime)
				|| (decoder.duration > 0 && time - loopOffset >= decoder.duration + frameDuration);

			if (loops > 0 && loopDecoder == null && !loopOpening && decoder.duration > 0 && parent.source != null
				&& time - loopOffset > decoder.duration - LOOP_OPEN_SECONDS)
			{
				openLoop();
			}

			if (loops > 0 && loopDecoder != null && videoDone
				&& (handle == null || !decoder.hasAudio || audioDecoder == loopDecoder || !loopDecoder.hasAudio))
			{
				startLoop();
				return;
			}

			var audioDone = handle == null || audioStalled || (audioDecoder.audioComplete && bufferTimes.length == 0);

			if (audioDone && videoDone)
			{
				complete();
			}
		}
	}

	@:noCompletion private static function addActiveSource(source:NativeVideoSource):Void
	{
		#if (lime_threads && !html5)
		activeSourcesMutex.acquire();
		activeSources.push(source);
		activeSourcesMutex.release();

		if (!feeding)
		{
			// One thread keeps the sound of every playing video queued, so it plays
			// on while the application's updates pause, as for a garbage collection
			// or a blocking load. Updates still run the clock and the playback.
			feeding = true;
			Thread.create(feedSources);
		}
		#else
		activeSources.push(source);
		#end
	}

	@:noCompletion private function feed():Void
	{
		#if (lime_threads && !html5)
		// A source that is busy on another thread is fed next time
		if (!audioMutex.tryAcquire()) return;

		if (handle != null && decoder != null && !audioSkipping && !audioStalled)
		{
			unqueueBuffers(AL.getSourcei(handle, AL.BUFFERS_PROCESSED));
			fillBuffers();
		}

		audioMutex.release();
		#end
	}

	#if (lime_threads && !html5)
	@:noCompletion private static function feedSources():Void
	{
		while (true)
		{
			for (source in getActiveSources())
			{
				source.feed();
			}

			Sys.sleep(AUDIO_FEED_SECONDS);
		}
	}
	#end

	#if (lime_threads && !html5)
	@:noCompletion private static function runLoopThread():Void
	{
		// One thread opens each next loop and closes the last. Requests are
		// polled for, as the thread pool's waits on a message queue crash with
		// hxcpp 4.3 on ARM64 Linux, whose condition variables in it are not
		// aligned for ARM64's atomics.
		while (true)
		{
			loopRequestsMutex.acquire();
			var request = loopRequests.shift();
			var retired = retiredDecoders.shift();
			loopRequestsMutex.release();

			if (retired != null) retired.close();

			if (request == null)
			{
				if (retired == null) Sys.sleep(LOOP_POLL_SECONDS);
				continue;
			}

			var next = new VideoDecoder();
			next.hardwareDecoding = request.hardwareDecoding;
			request.source.finishLoop(request.token, next.open(request.path, request.format) ? next : null);
		}
	}

	@:noCompletion private static function startLoopThread():Void
	{
		// With the requests' mutex held
		if (!loopThreadStarted)
		{
			loopThreadStarted = true;
			Thread.create(runLoopThread);
		}
	}
	#end

	@:noCompletion private static function getActiveSources():Array<NativeVideoSource>
	{
		#if (lime_threads && !html5)
		activeSourcesMutex.acquire();
		var sources = activeSources.copy();
		activeSourcesMutex.release();
		return sources;
		#else
		return activeSources.copy();
		#end
	}

	@:noCompletion private inline function lockAudio():Void
	{
		#if (lime_threads && !html5)
		audioMutex.acquire();
		#end
	}

	@:noCompletion private static function removeActiveSource(source:NativeVideoSource):Void
	{
		#if (lime_threads && !html5)
		activeSourcesMutex.acquire();
		activeSources.remove(source);
		activeSourcesMutex.release();
		#else
		activeSources.remove(source);
		#end
	}

	@:noCompletion private inline function unlockAudio():Void
	{
		#if (lime_threads && !html5)
		audioMutex.release();
		#end
	}
}

private typedef LoopRequest =
{
	var format:VideoFrameFormat;
	var hardwareDecoding:Bool;
	var path:String;
	var source:NativeVideoSource;
	var token:Int;
}

private typedef QueuedSound =
{
	var data:Bytes;
	var length:Int;
}
