package lime._internal.backend.native;

import haxe.io.Bytes;
import haxe.Timer;
import lime.app.Future;
import lime.app.Promise;
import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;
import lime.media.VideoDecoder;
import lime.media.VideoFrame;
import lime.media.VideoFrameFormat;
import lime.media.VideoSource;
import lime.utils.UInt8Array;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime.media.VideoSource)
class NativeVideoSource
{
	private static inline var AUDIO_BUFFER_COUNT:Int = 6;
	private static inline var AUDIO_BUFFER_SECONDS:Float = 0.04;
	private static inline var UPDATE_INTERVAL:Int = 10;

	private var audioBuffer:Bytes;
	private var audioData:UInt8Array;
	private var audioFormat:Int;
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
	private var parent:VideoSource;
	private var playing:Bool;
	private var timer:Timer;

	public function new(parent:VideoSource)
	{
		this.parent = parent;

		bufferTimes = [];
		clockStamp = 0;
		clockTime = 0;
		completed = false;
		frameEndTime = 0;
		gain = 1;
		hasFrame = false;
		loops = 0;
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
		clockStamp = Timer.stamp();
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

		clockStamp = Timer.stamp();
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
		clockStamp = Timer.stamp();
		clockTime = 0;
		completed = false;
		frameEndTime = 0;
		hasFrame = false;

		if (decoder.hasAudio)
		{
			handle = AL.createSource();

			if (handle != null)
			{
				AL.sourcef(handle, AL.GAIN, gain);

				buffers = AL.genBuffers(AUDIO_BUFFER_COUNT);
				freeBuffers = buffers.copy();

				var blockAlign = decoder.audioChannels * 2;
				audioFormat = decoder.audioChannels == 1 ? AL.FORMAT_MONO16 : AL.FORMAT_STEREO16;
				audioBuffer = Bytes.alloc(Std.int(decoder.audioSampleRate * AUDIO_BUFFER_SECONDS) * blockAlign);
				audioData = UInt8Array.fromBytes(audioBuffer);
				bytesPerSecond = decoder.audioSampleRate * blockAlign;
			}
		}
	}

	@:noCompletion private function close():Void
	{
		stopTimer();
		playing = false;

		if (handle != null)
		{
			AL.sourceStop(handle);
			unqueueBuffers(AL.getSourcei(handle, AL.BUFFERS_QUEUED));
			AL.deleteSource(handle);
			handle = null;
		}

		if (buffers != null)
		{
			AL.deleteBuffers(buffers);
			buffers = null;
			freeBuffers = null;
		}

		if (decoder != null)
		{
			decoder.close();
			decoder = null;
		}

		audioBuffer = null;
		audioData = null;
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

	@:noCompletion private function getTime():Float
	{
		if (decoder == null) return 0;

		if (isWaitingForFrame())
		{
			return clockTime;
		}

		if (handle != null && bufferTimes.length > 0)
		{
			// The time of the sample being heard
			var offset:Int = AL.getSourcei(handle, AL.SAMPLE_OFFSET);
			return bufferTimes[0] + offset / decoder.audioSampleRate;
		}

		if (handle != null && !decoder.audioComplete)
		{
			// Waiting for audio, so hold the picture too
			return clockTime;
		}

		return playing ? clockTime + (Timer.stamp() - clockStamp) : clockTime;
	}

	@:noCompletion private inline function isWaitingForFrame():Bool
	{
		// After opening or seeking, the sound and the clock wait for the first
		// frame, which takes longer to decode, so both start together
		return !hasFrame && decoder.hasVideo && !decoder.videoComplete;
	}

	@:noCompletion private function seek(time:Float):Void
	{
		decoder.seek(time, true);

		if (handle != null)
		{
			AL.sourceStop(handle);
			unqueueBuffers(AL.getSourcei(handle, AL.BUFFERS_QUEUED));

			// A stopped source counts every buffer queued on it as played, so
			// return it to its initial state before buffering the new position
			AL.sourceRewind(handle);
		}

		clockStamp = Timer.stamp();
		clockTime = time;
		completed = false;
		frameEndTime = 0;
		hasFrame = false;

		update();
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

			while (freeBuffers.length > 0 && !decoder.audioComplete)
			{
				var length = decoder.readAudio(audioBuffer, 0, audioBuffer.length);
				if (length <= 0) break;

				var buffer = freeBuffers.pop();
				AL.bufferData(buffer, audioFormat, audioData, length, decoder.audioSampleRate);
				AL.sourceQueueBuffer(handle, buffer);
				bufferTimes.push(decoder.audioTime - length / bytesPerSecond);
			}

			if (playing && bufferTimes.length > 0 && !isWaitingForFrame() && AL.getSourcei(handle, AL.SOURCE_STATE) != AL.PLAYING)
			{
				AL.sourcePlay(handle);
			}
		}

		var time = getTime();

		if (playing && !completed)
		{
			// Keep the clock current so it carries on smoothly when the audio ends
			clockTime = time;
			clockStamp = Timer.stamp();

			var audioDone = handle == null || (decoder.audioComplete && bufferTimes.length == 0);
			var videoDone = !decoder.hasVideo || (decoder.videoComplete && time >= frameEndTime)
				|| (decoder.duration > 0 && time >= decoder.duration);

			if (audioDone && videoDone)
			{
				complete();
			}
		}
	}
}
