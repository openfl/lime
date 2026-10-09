package lime.media;

import haxe.io.Bytes;
import lime._internal.backend.native.NativeCFFI;
import lime.utils.Assets;
import lime.utils.UInt8Array;
#if sys
import haxe.io.Path;
import lime.system.System;
import sys.FileSystem;
#end

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

/**
	Decodes the pictures and sound of a video file.

	Decoding runs on two background threads, one for each stream, which keep a
	few frames and a fraction of a second of audio ready ahead of the reader.
	`readFrame` and `readAudio` never wait for the decoder, so they can be
	called every frame from the main thread. Audio can also be read from another
	thread.

	`VideoSource` plays a video with this class, handling the audio output and
	the timing of frames. Use `VideoDecoder` directly to process the frames or
	audio yourself.

	Example usage:
	```haxe
	var decoder = VideoDecoder.fromFile("assets/intro.mp4");
	var frame = new VideoFrame();

	// in the render loop, with time in seconds
	if (decoder.readFrame(frame, time))
	{
		// upload frame.data
	}
	```

	Availability: native targets, using Media Foundation on Windows,
	AVFoundation on macOS and iOS, MediaCodec on Android and GStreamer on Linux.
	Which formats can be decoded depends on the codecs the platform provides,
	but H.264 video with AAC audio in an MP4 file works everywhere.
**/
@:access(lime._internal.backend.native.NativeCFFI)
class VideoDecoder
{
	@:noCompletion private static inline var READ_END:Int = -1;
	@:noCompletion private static inline var READ_ERROR:Int = -2;
	@:noCompletion private static inline var READ_BUFFER_TOO_SMALL:Int = -3;

	/**
		Whether this platform can decode video.
	**/
	public static var isSupported(get, never):Bool;

	/**
		The number of audio channels, 1 or 2. Sources with more channels are
		mixed down to stereo.
	**/
	public var audioChannels(default, null):Int = 0;

	/**
		Whether all of the audio has been read, or the audio could not be
		decoded. Seeking resets it.
	**/
	public var audioComplete(default, null):Bool = true;

	/**
		The audio sample rate in Hz.
	**/
	public var audioSampleRate(default, null):Int = 0;

	/**
		The time of the next sample `readAudio` returns, in seconds.
	**/
	public var audioTime(get, never):Float;

	/**
		The length of the video in seconds, or 0 when it is unknown, such as for
		a live stream.
	**/
	public var duration(default, null):Float = 0;

	/**
		The layout of the frames this decoder returns, chosen when it is opened.
	**/
	public var format(default, null):VideoFrameFormat = NV12;

	/**
		The nominal frame rate in frames per second, or 0 when it is unknown.
	**/
	public var frameRate(default, null):Float = 0;

	/**
		Whether to decode on the GPU when the platform supports it, which
		greatly reduces CPU use. Set it before calling `open`. Decoding falls
		back to the CPU when the GPU cannot decode the video.
	**/
	public var hardwareDecoding:Bool = true;

	/**
		Whether the video has an audio stream.
	**/
	public var hasAudio(default, null):Bool = false;

	/**
		Whether the video has a picture stream.
	**/
	public var hasVideo(default, null):Bool = false;

	/**
		The height of the frames in pixels.
	**/
	public var height(default, null):Int = 0;

	/**
		The path or URL that was opened.
	**/
	public var source(default, null):String;

	/**
		Whether all of the frames have been read, or the video could not be
		decoded. Seeking resets it.
	**/
	public var videoComplete(default, null):Bool = true;

	/**
		The width of the frames in pixels.
	**/
	public var width(default, null):Int = 0;

	@:noCompletion private var __handle:Dynamic;

	/**
		Creates a decoder. Call `open` to start decoding a video.
	**/
	public function new() {}

	/**
		Stops decoding and releases the video. The decoder can be opened again.
	**/
	public function close():Void
	{
		#if (lime_cffi && !macro)
		if (__handle != null)
		{
			NativeCFFI.lime_video_decoder_close(__handle);
		}
		#end

		audioChannels = 0;
		audioComplete = true;
		audioSampleRate = 0;
		duration = 0;
		frameRate = 0;
		hasAudio = false;
		hasVideo = false;
		height = 0;
		source = null;
		videoComplete = true;
		width = 0;
	}

	/**
		Opens a video file, returning `null` when it cannot be decoded.

		@param	path	A file path, asset ID or URL
		@param	format	The layout of the frames to return
	**/
	public static function fromFile(path:String, format:VideoFrameFormat = NV12):VideoDecoder
	{
		var decoder = new VideoDecoder();
		return decoder.open(path, format) ? decoder : null;
	}

	/**
		Opens a video and starts decoding it, closing any video already open.

		Opening reads the start of the file, and for a URL waits for the server,
		so it may take a moment.

		@param	path	A file path, asset ID or URL
		@param	format	The layout of the frames to return
		@return	Whether the video can be decoded
	**/
	public function open(path:String, format:VideoFrameFormat = NV12):Bool
	{
		close();

		if (path == null || path == "") return false;

		#if (lime_cffi && !macro)
		if (__handle == null)
		{
			__handle = NativeCFFI.lime_video_decoder_create();
			if (__handle == null) return false;
		}

		var info:Dynamic = NativeCFFI.lime_video_decoder_open(__handle, __resolvePath(path), hardwareDecoding, format);
		if (info == null) return false;

		audioChannels = info.audioChannels;
		audioSampleRate = info.audioSampleRate;
		duration = info.duration;
		frameRate = info.frameRate;
		hasAudio = info.hasAudio;
		hasVideo = info.hasVideo;
		height = info.height;
		width = info.width;

		audioComplete = !hasAudio;
		videoComplete = !hasVideo;
		source = path;
		this.format = format;
		return true;
		#else
		return false;
		#end
	}

	/**
		Copies decoded audio as interleaved signed 16-bit little-endian PCM,
		`audioChannels * 2` bytes per sample frame.

		@param	buffer	The bytes to write to
		@param	position	The offset in `buffer` to start writing at
		@param	length	The most bytes to write
		@return	The number of bytes written, which is 0 when no audio is ready
		yet or when `audioComplete` is `true`
	**/
	public function readAudio(buffer:Bytes, position:Int, length:Int):Int
	{
		#if (lime_cffi && !macro)
		if (__handle == null || audioComplete || buffer == null) return 0;

		var result:Int = NativeCFFI.lime_video_decoder_read_audio(__handle, buffer, position, length);

		if (result < 0)
		{
			audioComplete = true;
			return 0;
		}

		return result;
		#else
		return 0;
		#end
	}

	/**
		Reads the next decoded frame into `frame`.

		With a `time`, frames that a later frame replaces by then are skipped
		without being copied, and a frame is only returned once its time has
		come. This keeps the picture in step with a clock even when rendering
		falls behind.

		@param	frame	The frame to fill
		@param	time	The current time on the video's timeline in seconds, or
		a negative value to read every frame in order
		@return	Whether `frame` holds a new frame. It is `false` while no frame
		is due or ready yet, and once `videoComplete` is `true`.
	**/
	public function readFrame(frame:VideoFrame, time:Float = -1):Bool
	{
		#if (lime_cffi && !macro)
		if (__handle == null || videoComplete || frame == null) return false;

		var result:Int = __readFrame(frame.data, time);

		if (result == READ_BUFFER_TOO_SMALL)
		{
			var info:Dynamic = NativeCFFI.lime_video_decoder_get_frame_info(__handle);
			frame.data = new UInt8Array(info.length);
			result = __readFrame(frame.data, time);
		}

		if (result > 0)
		{
			var info:Dynamic = NativeCFFI.lime_video_decoder_get_frame_info(__handle);
			frame.colorMatrix = info.colorMatrix;
			frame.duration = info.duration;
			frame.format = format;
			frame.fullRange = info.fullRange;
			frame.height = info.height;
			frame.length = result;
			frame.time = info.time;
			frame.width = info.width;
			return true;
		}

		if (result == READ_END || result == READ_ERROR)
		{
			videoComplete = true;
		}

		return false;
		#else
		return false;
		#end
	}

	/**
		Moves both streams to a new time.

		@param	time	The time in seconds
		@param	accurate	Whether to start exactly at `time`, decoding from the
		keyframe before it. Otherwise reading starts from that keyframe, which is
		faster.
	**/
	public function seek(time:Float, accurate:Bool = true):Void
	{
		#if (lime_cffi && !macro)
		if (__handle == null || source == null) return;

		NativeCFFI.lime_video_decoder_seek(__handle, time, accurate);
		audioComplete = !hasAudio;
		videoComplete = !hasVideo;
		#end
	}

	@:noCompletion private function __readFrame(data:UInt8Array, time:Float):Int
	{
		#if (lime_cffi && !macro)
		if (data == null)
		{
			return NativeCFFI.lime_video_decoder_read_frame(__handle, null, 0, 0, time);
		}

		return NativeCFFI.lime_video_decoder_read_frame(__handle, data.buffer, data.byteOffset, data.byteLength, time);
		#else
		return READ_ERROR;
		#end
	}

	@:noCompletion private static function __resolvePath(path:String):String
	{
		if (path.indexOf("://") > -1) return path;

		var resolved = path;

		if (Assets.exists(path))
		{
			var assetPath = Assets.getPath(path);
			if (assetPath != null) resolved = assetPath;
		}

		#if sys
		// Asset paths are relative to the application, which may not be the
		// working directory
		if (!Path.isAbsolute(resolved) && !FileSystem.exists(resolved))
		{
			var directory = System.applicationDirectory;

			if (directory != null && directory != "")
			{
				var applicationPath = Path.join([directory, resolved]);
				if (FileSystem.exists(applicationPath)) resolved = applicationPath;
			}
		}
		#end

		return resolved;
	}

	// Get & Set Methods
	@:noCompletion private function get_audioTime():Float
	{
		#if (lime_cffi && !macro)
		if (__handle != null && source != null)
		{
			return NativeCFFI.lime_video_decoder_get_audio_time(__handle);
		}
		#end

		return 0;
	}

	@:noCompletion private static function get_isSupported():Bool
	{
		#if (lime_cffi && !macro)
		return NativeCFFI.lime_video_decoder_is_supported();
		#else
		return false;
		#end
	}
}
