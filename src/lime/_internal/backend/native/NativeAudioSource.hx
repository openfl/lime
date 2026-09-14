package lime._internal.backend.native;

import haxe.io.Bytes;
import haxe.Int64;
import haxe.Timer;
import lime.math.Vector4;
import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;
import lime.media.vorbis.VorbisFile;
import lime.media.AudioManager;
import lime.media.AudioSource;
import lime.system.CFFIPointer;
import lime.utils.UInt8Array;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.media.AudioBuffer)
class NativeAudioSource
{
	private static var STREAM_BUFFER_SIZE = 48000;
	#if (native_audio_buffers && !macro)
	private static var STREAM_NUM_BUFFERS = Std.parseInt(haxe.macro.Compiler.getDefine("native_audio_buffers"));
	#else
	private static var STREAM_NUM_BUFFERS = 3;
	#end
	private static var STREAM_TIMER_FREQUENCY = 100;

	#if lime_openalsoft
	private static var hasDirectChannelsExt:Null<Bool>;
	#end
	private static var activeSources:Array<NativeAudioSource> = [];

	private var buffers:Array<ALBuffer>;
	private var bufferTimeBlocks:Array<Float>;
	private var completed:Bool;
	private var dataLength:Int;
	private var format:Int;
	private var handle:ALSource;
	private var length:Null<Int>;
	private var loops:Int;
	private var parent:AudioSource;
	private var ownsVorbisStream:Bool;
	private var playing:Bool;
	private var position:Vector4;
	private var queuedBufferCount:Int;
	private var queuedBufferLoopCounts:Array<Int>;
	private var queuedStreamLoopCount:Int;
	private var readArray:UInt8Array;
	private var readBuffer:Bytes;
	private var recoveryCompleted:Bool;
	private var recoveryGain:Float;
	private var recoveryLength:Null<Int>;
	private var recoveryLoops:Int;
	private var recoveryPending:Bool;
	private var recoveryPitch:Float;
	private var recoveryPlaying:Bool;
	private var recoveryPosition:Vector4;
	private var recoveryTime:Int;
	private var sdlSoundStream:CFFIPointer;
	private var samples:Int;
	private var stream:Bool;
	private var streamByteRate:Float;
	private var streamCanSeek:Bool;
	private var streamExhausted:Bool;
	private var streamPosition:Float;
	private var streamTimer:Timer;
	private var timer:Timer;
	private var vorbisStream:VorbisFile;

	public function new(parent:AudioSource)
	{
		this.parent = parent;

		position = new Vector4();
		activeSources.push(this);
	}

	@:allow(lime.media.AudioManager)
	private static function prepareAudioContextRecovery():Void
	{
		for (source in activeSources.copy())
		{
			source.prepareAudioContextRecoverySource();
		}
	}

	@:allow(lime.media.AudioManager)
	private static function restoreAudioContextRecovery():Void
	{
		for (source in activeSources.copy())
		{
			source.restoreAudioContextRecoverySource();
		}
	}

	public function dispose():Void
	{
		activeSources.remove(this);

		if (handle != null)
		{
			stop();
			AL.sourcei(handle, AL.BUFFER, null);
			AL.deleteSource(handle);
			if (buffers != null)
			{
				for (buffer in buffers)
				{
					AL.deleteBuffer(buffer);
				}
				buffers = null;
			}
			handle = null;
		}

		clearSDLSoundStream();
		clearVorbisStream();
		readArray = null;
		readBuffer = null;
	}

	public function init():Void
	{
		dataLength = 0;
		format = 0;
		stream = false;
		streamByteRate = 0;
		streamCanSeek = false;
		streamExhausted = false;
		streamPosition = 0;
		queuedBufferCount = 0;
		queuedBufferLoopCounts = [];
		queuedStreamLoopCount = 0;
		ownsVorbisStream = false;
		clearVorbisStream();
		clearSDLSoundStream();

		if (parent.buffer.channels == 1)
		{
			if (parent.buffer.bitsPerSample == 8)
			{
				format = AL.FORMAT_MONO8;
			}
			else if (parent.buffer.bitsPerSample == 16)
			{
				format = AL.FORMAT_MONO16;
			}
		}
		else if (parent.buffer.channels == 2)
		{
			if (parent.buffer.bitsPerSample == 8)
			{
				format = AL.FORMAT_STEREO8;
			}
			else if (parent.buffer.bitsPerSample == 16)
			{
				format = AL.FORMAT_STEREO16;
			}
		}

		streamByteRate = parent.buffer.sampleRate * parent.buffer.channels * (parent.buffer.bitsPerSample / 8);

		if (hasSDLSoundStreamSource())
		{
			if (openSDLSoundStream())
			{
				stream = true;
				if (parent.buffer.__srcSDLSoundDuration > 0)
				{
					dataLength = Std.int(Math.ceil(parent.buffer.__srcSDLSoundDuration * streamByteRate / 1000));
					dataLength = alignStreamRequestLength(dataLength);
				}
				else
				{
					dataLength = -1;
				}

				buffers = new Array();
				bufferTimeBlocks = new Array();

				for (i in 0...STREAM_NUM_BUFFERS)
				{
					buffers.push(AL.createBuffer());
					bufferTimeBlocks.push(0);
				}

				handle = AL.createSource();
			}
			else if (parent.buffer.__srcVorbisFile == null && parent.buffer.data == null)
			{
				handle = null;
				return;
			}
		}

		if (!stream && hasVorbisStreamSource())
		{
			if (openVorbisStream())
			{
				stream = true;
				dataLength = Std.int(Int64.toInt(vorbisStream.pcmTotal()) * parent.buffer.channels * (parent.buffer.bitsPerSample / 8));

				buffers = new Array();
				bufferTimeBlocks = new Array();

				for (i in 0...STREAM_NUM_BUFFERS)
				{
					buffers.push(AL.createBuffer());
					bufferTimeBlocks.push(0);
				}

				handle = AL.createSource();
			}
			else if (parent.buffer.data == null)
			{
				handle = null;
				return;
			}
		}
		else if (!stream)
		{
			if (parent.buffer.__srcBuffer == null)
			{
				parent.buffer.__srcBuffer = AL.createBuffer();

				if (parent.buffer.__srcBuffer != null)
				{
					AL.bufferData(parent.buffer.__srcBuffer, format, parent.buffer.data, parent.buffer.data.length, parent.buffer.sampleRate);
					parent.buffer.__srcBufferContext = AudioManager.__contextGeneration;
				}
			}
			else if (parent.buffer.__srcBufferContext != AudioManager.__contextGeneration)
			{
				parent.buffer.__srcBuffer = null;
				init();
				return;
			}

			dataLength = parent.buffer.data.length;

			handle = AL.createSource();

			if (handle != null)
			{
				AL.sourcei(handle, AL.BUFFER, parent.buffer.__srcBuffer);
			}
		}

		#if lime_openalsoft
		if (hasDirectChannelsExt == null)
		{
			hasDirectChannelsExt = AL.isExtensionPresent("AL_SOFT_direct_channels")
				&& AL.isExtensionPresent("AL_SOFT_direct_channels_remix");
		}

		if (hasDirectChannelsExt)
		{
			AL.sourcei(handle, AL.DIRECT_CHANNELS_SOFT, AL.REMIX_UNMATCHED_SOFT);
		}
		#end

		if (dataLength > 0)
		{
			samples = Std.int((dataLength * 8.0) / (parent.buffer.channels * parent.buffer.bitsPerSample));
		}
		else
		{
			samples = 0;
		}
	}

	public function play():Void
	{
		/*var pitch:Float = AL.getSourcef (handle, AL.PITCH);
			trace(pitch);
			AL.sourcef (handle, AL.PITCH, pitch*0.9);
			pitch = AL.getSourcef (handle, AL.PITCH);
			trace(pitch); */
		/*var pos = getPosition();
			trace(AL.DISTANCE_MODEL);
			AL.distanceModel(AL.INVERSE_DISTANCE);
			trace(AL.DISTANCE_MODEL);
			AL.sourcef(handle, AL.ROLLOFF_FACTOR, 5);
			setPosition(new Vector4(10, 10, -100));
			pos = getPosition();
			trace(pos); */
		/*var filter = AL.createFilter();
			trace(AL.getErrorString());

			AL.filteri(filter, AL.FILTER_TYPE, AL.FILTER_LOWPASS);
			trace(AL.getErrorString());

			AL.filterf(filter, AL.LOWPASS_GAIN, 0.5);
			trace(AL.getErrorString());

			AL.filterf(filter, AL.LOWPASS_GAINHF, 0.5);
			trace(AL.getErrorString());

			AL.sourcei(handle, AL.DIRECT_FILTER, filter);
			trace(AL.getErrorString()); */

		if (playing || handle == null)
		{
			return;
		}

		playing = true;

		if (stream)
		{
			var time = completed ? 0 : getCurrentTime();
			setCurrentTime(time);

			streamTimer = new Timer(STREAM_TIMER_FREQUENCY);
			streamTimer.run = streamTimer_onRun;
		}
		else
		{
			var time = completed ? 0 : getCurrentTime();

			setCurrentTime(time);
		}
	}

	public function pause():Void
	{
		playing = false;

		if (handle == null) return;
		AL.sourcePause(handle);

		if (streamTimer != null)
		{
			streamTimer.stop();
			streamTimer = null;
		}

		if (timer != null)
		{
			timer.stop();
			timer = null;
		}
	}

	private function clearSDLSoundStream():Void
	{
		#if (lime_sdl_sound && !macro)
		if (sdlSoundStream != null)
		{
			NativeCFFI.lime_sdl_sound_stream_clear(sdlSoundStream);
			sdlSoundStream = null;
		}
		#end
	}

	private function clearVorbisStream():Void
	{
		#if lime_vorbis
		if (ownsVorbisStream && vorbisStream != null)
		{
			vorbisStream.clear();
		}
		#end

		vorbisStream = null;
		ownsVorbisStream = false;
	}

	private function hasSDLSoundStreamSource():Bool
	{
		return parent.buffer != null && (parent.buffer.__srcSDLSoundBytes != null || parent.buffer.__srcSDLSoundPath != null);
	}

	private function hasVorbisStreamSource():Bool
	{
		return parent.buffer != null
			&& (parent.buffer.__srcVorbisBytes != null || parent.buffer.__srcVorbisPath != null || parent.buffer.__srcVorbisFile != null);
	}

	private function openSDLSoundStream():Bool
	{
		#if (lime_sdl_sound && !macro)
		clearSDLSoundStream();

		if (parent.buffer.__srcSDLSoundBytes != null)
		{
			sdlSoundStream = NativeCFFI.lime_sdl_sound_stream_from_bytes(parent.buffer.__srcSDLSoundBytes);
		}
		else if (parent.buffer.__srcSDLSoundPath != null)
		{
			sdlSoundStream = NativeCFFI.lime_sdl_sound_stream_from_file(parent.buffer.__srcSDLSoundPath);
		}

		if (sdlSoundStream != null)
		{
			streamCanSeek = parent.buffer.__srcSDLSoundCanSeek;
			streamExhausted = false;
			streamPosition = 0;
			return true;
		}
		#end

		return false;
	}

	private function openVorbisStream():Bool
	{
		#if lime_vorbis
		clearVorbisStream();

		if (parent.buffer.__srcVorbisBytes != null)
		{
			vorbisStream = VorbisFile.fromBytes(parent.buffer.__srcVorbisBytes);
			ownsVorbisStream = (vorbisStream != null);
		}
		else if (parent.buffer.__srcVorbisPath != null)
		{
			vorbisStream = VorbisFile.fromFile(parent.buffer.__srcVorbisPath);
			ownsVorbisStream = (vorbisStream != null);
		}
		else if (parent.buffer.__srcVorbisFile != null)
		{
			vorbisStream = parent.buffer.__srcVorbisFile;
			ownsVorbisStream = false;
		}

		if (vorbisStream != null)
		{
			streamCanSeek = vorbisStream.seekable();
			streamExhausted = false;
			return true;
		}
		#end

		return false;
	}

	private function resetSDLSoundStream(time:Int):Bool
	{
		#if (lime_sdl_sound && !macro)
		if (time < 0)
		{
			time = 0;
		}

		if (sdlSoundStream == null && !openSDLSoundStream())
		{
			return false;
		}

		if (time == 0)
		{
			if (streamCanSeek && NativeCFFI.lime_sdl_sound_stream_rewind(sdlSoundStream))
			{
				streamExhausted = false;
				streamPosition = 0;
				return true;
			}

			return openSDLSoundStream();
		}

		if (streamCanSeek && NativeCFFI.lime_sdl_sound_stream_seek(sdlSoundStream, time))
		{
			streamExhausted = false;
			streamPosition = time / 1000;
			return true;
		}
		#end

		return false;
	}

	private function resetVorbisStream(time:Int):Bool
	{
		#if lime_vorbis
		if (time < 0)
		{
			time = 0;
		}

		if (vorbisStream == null && !openVorbisStream())
		{
			return false;
		}

		if (!streamCanSeek)
		{
			return (time == 0 && openVorbisStream());
		}

		if (vorbisStream.timeSeek(time / 1000) == 0)
		{
			streamExhausted = false;
			return true;
		}

		if (time == 0)
		{
			return openVorbisStream();
		}
		#end

		return false;
	}

	private function shiftBufferTimeBlocks(time:Float):Void
	{
		for (i in 0...STREAM_NUM_BUFFERS - 1)
		{
			bufferTimeBlocks[i] = bufferTimeBlocks[i + 1];
		}

		bufferTimeBlocks[STREAM_NUM_BUFFERS - 1] = time;
	}

	private function alignStreamRequestLength(length:Int):Int
	{
		var frameSize = Std.int(parent.buffer.channels * (parent.buffer.bitsPerSample / 8));

		if (frameSize <= 0 || length <= frameSize)
		{
			return length;
		}

		return length - (length % frameSize);
	}

	private function getStreamBytePosition(useSDLSound:Bool, vorbisFile:VorbisFile):Int
	{
		if (useSDLSound)
		{
			return Std.int(streamPosition * streamByteRate);
		}

		#if lime_vorbis
		return (vorbisFile != null) ? Int64.toInt(vorbisFile.pcmTell()) : 0;
		#else
		return 0;
		#end
	}

	private function shouldLoopStreamInline():Bool
	{
		return stream && loops > 0 && length == null;
	}

	private function resetStreamForLoop(useSDLSound:Bool):Bool
	{
		if (!shouldLoopStreamInline() || loops <= queuedStreamLoopCount)
		{
			return false;
		}

		var streamTime = parent.offset;
		var reset = useSDLSound ? resetSDLSoundStream(streamTime) : resetVorbisStream(streamTime);

		if (!reset)
		{
			return false;
		}

		queuedStreamLoopCount++;
		streamExhausted = false;
		return true;
	}

	private function consumeProcessedStreamLoopCounts(processed:Int):Void
	{
		if (queuedBufferLoopCounts == null || processed <= 0)
		{
			return;
		}

		var completedLoops = 0;
		for (i in 0...processed)
		{
			if (queuedBufferLoopCounts.length == 0)
			{
				break;
			}

			completedLoops += queuedBufferLoopCounts.shift();
		}

		if (completedLoops > 0)
		{
			loops -= completedLoops;
			if (loops < 0)
			{
				loops = 0;
			}

			queuedStreamLoopCount -= completedLoops;
			if (queuedStreamLoopCount < 0)
			{
				queuedStreamLoopCount = 0;
			}
		}
	}

	private function clearQueuedBuffers():Void
	{
		if (handle == null)
		{
			queuedBufferCount = 0;
			return;
		}

		var queued = AL.getSourcei(handle, AL.BUFFERS_QUEUED);

		if (queued > 0)
		{
			AL.sourceUnqueueBuffers(handle, queued);
		}

		queuedBufferCount = 0;
		queuedBufferLoopCounts = [];
		queuedStreamLoopCount = 0;
	}

	private function prepareAudioContextRecoverySource():Void
	{
		if (parent.buffer == null)
		{
			recoveryPending = false;
			return;
		}

		recoveryPending = true;
		recoveryCompleted = completed;
		recoveryGain = getGain();
		recoveryLength = length;
		recoveryLoops = loops;
		recoveryPitch = getPitch();
		recoveryPlaying = playing;
		recoveryPosition = getPosition().clone();
		recoveryTime = getCurrentTime();

		if (streamTimer != null)
		{
			streamTimer.stop();
			streamTimer = null;
		}

		if (timer != null)
		{
			timer.stop();
			timer = null;
		}

		playing = false;
		handle = null;
		buffers = null;
		bufferTimeBlocks = null;
		queuedBufferCount = 0;
		queuedBufferLoopCounts = [];
		queuedStreamLoopCount = 0;

		if (parent.buffer != null)
		{
			parent.buffer.__srcBuffer = null;
			parent.buffer.__srcBufferContext = 0;
		}

		clearSDLSoundStream();
		clearVorbisStream();
	}

	private function restoreAudioContextRecoverySource():Void
	{
		if (!recoveryPending || parent.buffer == null)
		{
			return;
		}

		recoveryPending = false;
		completed = recoveryCompleted;
		length = recoveryLength;
		loops = recoveryLoops;
		playing = false;

		init();

		if (handle == null)
		{
			return;
		}

		setGain(recoveryGain);
		setPitch(recoveryPitch);
		setPosition(recoveryPosition);
		setCurrentTime(recoveryTime);
		completed = recoveryCompleted;

		if (recoveryPlaying)
		{
			play();
		}
	}

	private function ensureReadBuffer(length:Int):Bool
	{
		if (length <= 0)
		{
			return false;
		}

		if (readBuffer == null || readBuffer.length < length)
		{
			readBuffer = Bytes.alloc(length);
			readArray = UInt8Array.fromBytes(readBuffer);
		}

		return true;
	}

	private function readSDLSoundBuffer(length:Int):Int
	{
		#if (lime_sdl_sound && !macro)
		if (sdlSoundStream == null || length <= 0 || streamByteRate <= 0)
		{
			return 0;
		}

		if (!ensureReadBuffer(length))
		{
			return 0;
		}

		var read = NativeCFFI.lime_sdl_sound_stream_read(sdlSoundStream, readBuffer, length);

		if (read <= 0)
		{
			return read;
		}

		shiftBufferTimeBlocks(streamPosition);
		streamPosition += read / streamByteRate;
		return read;
		#else
		return 0;
		#end
	}

	private function readVorbisFileBuffer(vorbisFile:VorbisFile, length:Int):Int
	{
		#if lime_vorbis
		if (vorbisFile == null || !ensureReadBuffer(length))
		{
			return 0;
		}

		var read = 0, total = 0, readMax;
		shiftBufferTimeBlocks(vorbisFile.timeTell());

		while (total < length)
		{
			readMax = 4096;

			if (readMax > length - total)
			{
				readMax = length - total;
			}

			read = vorbisFile.read(readBuffer, total, readMax);

			if (read > 0)
			{
				total += read;
			}
			else
			{
				break;
			}
		}

		return total;
		#else
		return 0;
		#end
	}

	private function refillBuffers(buffers:Array<ALBuffer> = null):Void
	{
		if (!stream || handle == null)
		{
			return;
		}

		var useSDLSound = hasSDLSoundStreamSource();
		var hasKnownStreamLength = (dataLength > 0);
		var vorbisFile = null;
		var position = 0;

		if (buffers == null)
		{
			var buffersProcessed:Int = AL.getSourcei(handle, AL.BUFFERS_PROCESSED);

			if (buffersProcessed > 0)
			{
				if (useSDLSound)
				{
					position = Std.int(streamPosition * streamByteRate);
				}
				else
				{
					#if lime_vorbis
					vorbisFile = vorbisStream;
					position = (vorbisFile != null) ? Int64.toInt(vorbisFile.pcmTell()) : 0;
					#end
				}

				buffers = AL.sourceUnqueueBuffers(handle, buffersProcessed);

				if (buffers != null)
				{
					queuedBufferCount -= buffers.length;
					consumeProcessedStreamLoopCounts(buffers.length);
				}
				else
				{
					queuedBufferCount -= buffersProcessed;
					consumeProcessedStreamLoopCounts(buffersProcessed);
				}

				if (queuedBufferCount < 0)
				{
					queuedBufferCount = 0;
				}
			}
		}

		if (buffers != null)
		{
			if (!useSDLSound)
			{
				#if lime_vorbis
				if (vorbisFile == null)
				{
					vorbisFile = vorbisStream;
					position = (vorbisFile != null) ? Int64.toInt(vorbisFile.pcmTell()) : 0;
				}
				#end
			}
			else
			{
				position = Std.int(streamPosition * streamByteRate);
			}

			var numBuffers = 0;
			var bytesRead = 0;
			var newBufferLoopCounts = [];

			for (buffer in buffers)
			{
				var bufferLoopCount = 0;

				if (hasKnownStreamLength && position >= dataLength)
				{
					if (resetStreamForLoop(useSDLSound))
					{
						if (!useSDLSound)
						{
							#if lime_vorbis
							vorbisFile = vorbisStream;
							#end
						}

						position = getStreamBytePosition(useSDLSound, vorbisFile);
					}
					else
					{
						streamExhausted = true;
						break;
					}
				}

				var requestLength = hasKnownStreamLength ? (dataLength - position) : STREAM_BUFFER_SIZE;

				if (requestLength > STREAM_BUFFER_SIZE)
				{
					requestLength = STREAM_BUFFER_SIZE;
				}

				requestLength = alignStreamRequestLength(requestLength);

				if (useSDLSound)
				{
					bytesRead = readSDLSoundBuffer(requestLength);
				}
				else
				{
					#if lime_vorbis
					bytesRead = readVorbisFileBuffer(vorbisFile, requestLength);
					#else
					bytesRead = 0;
					#end
				}

				if (bytesRead <= 0 || readArray == null)
				{
					if (resetStreamForLoop(useSDLSound))
					{
						if (!useSDLSound)
						{
							#if lime_vorbis
							vorbisFile = vorbisStream;
							#end
						}

						position = getStreamBytePosition(useSDLSound, vorbisFile);
						continue;
					}
					else
					{
						streamExhausted = true;
						break;
					}
				}

				AL.bufferData(buffer, format, readArray, bytesRead, parent.buffer.sampleRate);
				position += bytesRead;
				numBuffers++;

				var stopAfterBuffer = false;

				if (bytesRead < requestLength || (hasKnownStreamLength && position >= dataLength))
				{
					if (resetStreamForLoop(useSDLSound))
					{
						bufferLoopCount++;

						if (!useSDLSound)
						{
							#if lime_vorbis
							vorbisFile = vorbisStream;
							#end
						}

						position = getStreamBytePosition(useSDLSound, vorbisFile);
					}
					else
					{
						streamExhausted = true;
						stopAfterBuffer = true;
					}
				}

				newBufferLoopCounts.push(bufferLoopCount);

				if (stopAfterBuffer)
				{
					break;
				}
			}

			if (numBuffers > 0)
			{
				var buffersToQueue = (numBuffers == buffers.length) ? buffers : buffers.slice(0, numBuffers);
				AL.sourceQueueBuffers(handle, numBuffers, buffersToQueue);
				queuedBufferCount += numBuffers;

				for (i in 0...numBuffers)
				{
					queuedBufferLoopCounts.push(newBufferLoopCounts[i]);
				}
			}

			// OpenAL can unexpectedly stop playback if the buffers run out
			// of data, which typically happens if an operation (such as
			// resizing a window) freezes the main thread.
			// If AL is supposed to be playing but isn't, restart it here.
			if (playing && handle != null && queuedBufferCount > 0 && AL.getSourcei(handle, AL.SOURCE_STATE) == AL.STOPPED)
			{
				AL.sourcePlay(handle);
			}
		}
	}

	public function stop():Void
	{
		if (playing && handle != null && AL.getSourcei(handle, AL.SOURCE_STATE) == AL.PLAYING)
		{
			AL.sourceStop(handle);
		}

		playing = false;

		if (streamTimer != null)
		{
			streamTimer.stop();
			streamTimer = null;
		}

		if (timer != null)
		{
			timer.stop();
			timer = null;
		}

		setCurrentTime(0);
	}

	// Event Handlers
	private function streamTimer_onRun():Void
	{
		if (!playing || handle == null)
		{
			return;
		}

		refillBuffers();

		if (playing
			&& timer == null
			&& streamExhausted
			&& queuedBufferCount == 0
			&& handle != null
			&& AL.getSourcei(handle, AL.SOURCE_STATE) != AL.PLAYING)
		{
			if (length == null && parent.buffer.__srcSDLSoundDuration <= 0)
			{
				length = Std.int(streamPosition * 1000) - parent.offset;
				if (length < 0)
				{
					length = 0;
				}
			}

			timer_onRun();
		}
	}

	private function timer_onRun():Void
	{
		if (loops > 0)
		{
			playing = false;
			loops--;
			setCurrentTime(0);
			play();
			return;
		}
		else
		{
			stop();
		}

		completed = true;
		parent.onComplete.dispatch();
	}

	// Get & Set Methods
	public function getCurrentTime():Int
	{
		if (completed)
		{
			return getLength();
		}
		else if (handle != null)
		{
			if (stream)
			{
				var time = (Std.int(bufferTimeBlocks[0] * 1000) + Std.int(AL.getSourcef(handle, AL.SEC_OFFSET) * 1000)) - parent.offset;
				if (time < 0) return 0;
				return time;
			}
			else
			{
				var offset = AL.getSourcei(handle, AL.BYTE_OFFSET);
				var ratio = (offset / dataLength);
				var totalSeconds = samples / parent.buffer.sampleRate;

				var time = Std.int(totalSeconds * ratio * 1000) - parent.offset;

				// var time = Std.int (AL.getSourcef (handle, AL.SEC_OFFSET) * 1000) - parent.offset;
				if (time < 0) return 0;
				return time;
			}
		}

		return 0;
	}

	public function setCurrentTime(value:Int):Int
	{
		// `setCurrentTime()` has side effects and is never safe to skip.
		/* if (value == getCurrentTime())
			{
				return value;
		}*/

		if (handle != null)
		{
			if (stream)
			{
				AL.sourceStop(handle);
				var streamTime = value + parent.offset;

				if (hasSDLSoundStreamSource())
				{
					if (!resetSDLSoundStream(streamTime))
					{
						value = 0;
						streamTime = parent.offset;
						resetSDLSoundStream(streamTime);
					}
				}
				else
				{
					if (!resetVorbisStream(streamTime))
					{
						value = 0;
						streamTime = parent.offset;
						resetVorbisStream(streamTime);
					}
				}

				clearQueuedBuffers();

				for (i in 0...STREAM_NUM_BUFFERS)
				{
					bufferTimeBlocks[i] = 0;
				}

				refillBuffers(buffers);

				if (playing)
				{
					AL.sourcePlay(handle);
				}
			}
			else if (parent.buffer != null)
			{
				AL.sourceRewind(handle);

				// AL.sourcef (handle, AL.SEC_OFFSET, (value + parent.offset) / 1000);

				var secondOffset = (value + parent.offset) / 1000;
				var totalSeconds = samples / parent.buffer.sampleRate;

				if (secondOffset < 0) secondOffset = 0;
				if (secondOffset > totalSeconds) secondOffset = totalSeconds;

				var ratio = (secondOffset / totalSeconds);
				var totalOffset = Std.int(dataLength * ratio);

				AL.sourcei(handle, AL.BYTE_OFFSET, totalOffset);
				if (playing) AL.sourcePlay(handle);
			}
		}

		if (playing)
		{
			if (timer != null)
			{
				timer.stop();
			}

			var totalLength = getLength();
			var timeRemaining = Std.int((totalLength - value) / getPitch());

			if (timeRemaining > 0 && !shouldLoopStreamInline())
			{
				completed = false;
				timer = new Timer(timeRemaining);
				timer.run = timer_onRun;
			}
			else if (stream && (totalLength <= 0 || shouldLoopStreamInline()))
			{
				completed = false;
				timer = null;
			}
			else
			{
				playing = false;
				completed = true;
			}
		}

		return value;
	}

	public function getGain():Float
	{
		if (handle != null)
		{
			return AL.getSourcef(handle, AL.GAIN);
		}
		else
		{
			return 1;
		}
	}

	public function setGain(value:Float):Float
	{
		if (handle != null)
		{
			AL.sourcef(handle, AL.GAIN, value);
		}

		return value;
	}

	public function getLength():Int
	{
		if (length != null)
		{
			return length;
		}

		if (stream && hasSDLSoundStreamSource() && parent.buffer.__srcSDLSoundDuration > 0)
		{
			return parent.buffer.__srcSDLSoundDuration - parent.offset;
		}

		return Std.int(samples / parent.buffer.sampleRate * 1000) - parent.offset;
	}

	public function setLength(value:Int):Int
	{
		if (playing && length != value)
		{
			if (timer != null)
			{
				timer.stop();
			}

			var timeRemaining = Std.int((value - getCurrentTime()) / getPitch());

			if (timeRemaining > 0)
			{
				timer = new Timer(timeRemaining);
				timer.run = timer_onRun;
			}
		}

		return length = value;
	}

	public function getLoops():Int
	{
		return loops;
	}

	public function setLoops(value:Int):Int
	{
		return loops = value;
	}

	public function getPitch():Float
	{
		if (handle != null)
		{
			return AL.getSourcef(handle, AL.PITCH);
		}
		else
		{
			return 1;
		}
	}

	public function setPitch(value:Float):Float
	{
		if (playing && value != getPitch())
		{
			if (timer != null)
			{
				timer.stop();
			}

			var totalLength = getLength();
			var timeRemaining = Std.int((totalLength - getCurrentTime()) / value);

			if (timeRemaining > 0)
			{
				timer = new Timer(timeRemaining);
				timer.run = timer_onRun;
			}
			else
			{
				timer = null;
			}
		}

		if (handle != null)
		{
			AL.sourcef(handle, AL.PITCH, value);
		}

		return value;
	}

	public function getPosition():Vector4
	{
		if (handle != null)
		{
			#if !webassembly
			var value = AL.getSource3f(handle, AL.POSITION);
			position.x = value[0];
			position.y = value[1];
			position.z = value[2];
			#end
		}

		return position;
	}

	public function setPosition(value:Vector4):Vector4
	{
		position.x = value.x;
		position.y = value.y;
		position.z = value.z;
		position.w = value.w;

		if (handle != null)
		{
			AL.distanceModel(AL.NONE);
			AL.source3f(handle, AL.POSITION, position.x, position.y, position.z);
		}

		return position;
	}
}
