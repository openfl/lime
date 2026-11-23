package lime.media;

import haxe.io.Bytes;
import lime._internal.backend.native.NativeCFFI;
#if (lime_opengl || lime_opengles)
import lime.graphics.opengl.GL;
#end
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

	Frames are decoded as they are stored. A video recorded on a phone held
	upright is usually stored sideways, with a `rotation` to apply when it is
	shown, and some videos have pixels that are not square, so draw frames at
	`displayWidth` by `displayHeight`, turned by `rotation`.

	Availability: native targets, using Media Foundation on Windows,
	AVFoundation on macOS and iOS, MediaCodec on Android and GStreamer on Linux.
	Which formats can be decoded depends on the codecs the platform provides,
	but H.264 video with AAC audio in an MP4 file works everywhere. A video
	whose picture or sound uses a codec the platform lacks still opens with
	the stream that can be decoded, and `videoUnsupported` or
	`audioUnsupported` tells when one was left out. Android does not report a
	codec it does not recognise at all.

	On Linux, MP4 files need GStreamer's good plugins and its libav plugin,
	which distributions package separately, as `gstreamer1.0-plugins-good`
	and `gstreamer1.0-libav` on Debian and Ubuntu. `isSupported` only checks
	for GStreamer itself.

	URLs are read over HTTP and HTTPS on Windows, Android and Linux. On macOS
	and iOS, AVFoundation's reader only decodes local files, so a URL is
	downloaded to a temporary file while it opens, and a live stream cannot
	play; App Transport Security blocks plain HTTP there unless the
	application allows it. Before Android 10,
	closing or seeking a URL whose connection stalls waits until the connection
	gives up. HDR video, in PQ
	or HLG, is tone mapped to standard range BT.709, by the platform where it
	can and otherwise by Lime, which shows HDR's reference white of 203 nits
	as white.
**/
@:access(lime._internal.backend.native.NativeCFFI)
#if (lime_opengl || lime_opengles)
@:access(lime.graphics.opengl.GLObject)
#end
class VideoDecoder
{
	@:noCompletion private static inline var READ_END:Int = -1;
	@:noCompletion private static inline var READ_ERROR:Int = -2;
	@:noCompletion private static inline var READ_BUFFER_TOO_SMALL:Int = -3;

	// The order the native decoder writes a frame's details in
	@:noCompletion private static inline var FRAME_INFO_COLOR_MATRIX:Int = 0;
	@:noCompletion private static inline var FRAME_INFO_DROPPED_FRAMES:Int = 1;
	@:noCompletion private static inline var FRAME_INFO_DURATION:Int = 2;
	@:noCompletion private static inline var FRAME_INFO_FULL_RANGE:Int = 3;
	@:noCompletion private static inline var FRAME_INFO_HEIGHT:Int = 4;
	@:noCompletion private static inline var FRAME_INFO_LENGTH:Int = 5;
	@:noCompletion private static inline var FRAME_INFO_TEXTURE:Int = 6;
	@:noCompletion private static inline var FRAME_INFO_TIME:Int = 7;
	@:noCompletion private static inline var FRAME_INFO_WIDTH:Int = 8;
	@:noCompletion private static inline var FRAME_INFO_COUNT:Int = 9;

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
		Whether the video has sound that cannot be decoded on this platform,
		such as sound in a codec it lacks. The video then opens without sound,
		and `hasAudio` is `false`.
	**/
	public var audioUnsupported(default, null):Bool = false;

	/**
		The height to show frames at, after `pixelAspectRatio` and `rotation`.
	**/
	public var displayHeight(get, never):Int;

	/**
		The width to show frames at, after `pixelAspectRatio` and `rotation`.
	**/
	public var displayWidth(get, never):Int;

	/**
		Whether `readFrame`, given a time, skips the frames that are already
		late, so playback keeps in step with its clock and drops frames when
		decoding falls behind. When `false`, every frame is returned in order,
		each once it is due, so playback slows down instead. `true` by default.
		It has no effect on `readFrame` without a time, which returns every frame.
	**/
	public var dropLateFrames(default, set):Bool = true;

	/**
		How many frames have been skipped since opening because they were late,
		as when decoding falls behind or `readFrame` is given a later time.
		Late frames are dropped before they are converted, so a decoder that
		falls behind catches up, while still showing one every quarter of a
		second if it cannot keep up.
	**/
	public var droppedFrames(default, null):Int = 0;

	/**
		The length of the video in seconds, or 0 when it is unknown, such as for
		a live stream.
	**/
	public var duration(default, null):Float = 0;

	/**
		Whether a stream stopped because it could not be decoded, rather than
		at its end, such as when the file is damaged. That stream's
		`audioComplete` or `videoComplete` is then `true`. Seeking or opening
		again resets it.
	**/
	public var error(default, null):Bool = false;

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
		back to the CPU when the GPU cannot decode the video. On macOS and iOS,
		AVFoundation chooses for itself, so it is only a hint there.
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
		The width of a pixel relative to its height, which is 1 for the square
		pixels of most videos. Some videos are stored narrower than they are
		shown, so their frames are stretched to `displayWidth`.
	**/
	public var pixelAspectRatio(default, null):Float = 1;

	/**
		How far to turn frames clockwise to show them upright, in degrees: 0,
		90, 180 or 270. Phones store video recorded upright as sideways frames
		with a rotation of 90.
	**/
	public var rotation(default, null):Int = 0;

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
		Whether the video has a picture that cannot be decoded on this
		platform, such as one in a codec it lacks. The video then opens with
		only its sound, and `hasVideo` is `false`.
	**/
	public var videoUnsupported(default, null):Bool = false;

	/**
		The width of the frames in pixels.
	**/
	public var width(default, null):Int = 0;

	@:noCompletion private var __frameInfo:Bytes;
	@:noCompletion private var __handle:Dynamic;
	// A file written for openBytes, deleted when the video is closed
	@:noCompletion private var __temporaryPath:String;
	#if (lime_opengl || lime_opengles)
	@:noCompletion private var __textures:Map<Int, GLObject>;
	#end

	/**
		Creates a decoder. Call `open` to start decoding a video.
	**/
	public function new() {}

	/**
		Stops decoding and releases the video. The decoder can be opened again.

		With `TEXTURE` frames, close it on the thread that reads them, with the
		same GL context current, so it can delete its textures at once. A decoder
		closed elsewhere, or garbage collected, leaves them to the next `TEXTURE`
		frame read with that context current, which deletes them.
	**/
	public function close():Void
	{
		#if (lime_cffi && !macro)
		if (__handle != null)
		{
			NativeCFFI.lime_video_decoder_close(__handle);
		}
		#end

		#if (lime_opengl || lime_opengles)
		__textures = null;
		#end

		__deleteTemporaryFile();

		audioChannels = 0;
		audioComplete = true;
		audioSampleRate = 0;
		audioUnsupported = false;
		duration = 0;
		error = false;
		frameRate = 0;
		hasAudio = false;
		hasVideo = false;
		height = 0;
		pixelAspectRatio = 1;
		rotation = 0;
		source = null;
		videoComplete = true;
		videoUnsupported = false;
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
		Opens a video held in memory, returning `null` when it cannot be decoded.

		@param	bytes	The whole video file
		@param	format	The layout of the frames to return
	**/
	public static function fromBytes(bytes:Bytes, format:VideoFrameFormat = NV12):VideoDecoder
	{
		var decoder = new VideoDecoder();
		return decoder.openBytes(bytes, format) ? decoder : null;
	}

	/**
		Opens a video held in memory and starts decoding it, closing any video
		already open.

		The platform decoders read files, so the bytes are written to a
		temporary file, which is deleted when the video is closed. A video that
		is an asset embedded in the application is opened this way by `open`.

		@param	bytes	The whole video file
		@param	format	The layout of the frames to return
		@return	Whether the video can be decoded
	**/
	public function openBytes(bytes:Bytes, format:VideoFrameFormat = NV12):Bool
	{
		return __openBytes(bytes, format, null, null);
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

		// An embedded asset has no file to open
		if (path.indexOf("://") == -1 && Assets.exists(path) && Assets.getPath(path) == null)
		{
			var bytes = Assets.getBytes(path);
			return bytes != null && __openBytes(bytes, format, path, path);
		}

		return __openPath(__resolvePath(path), path, format);
	}

	@:noCompletion private function __openPath(path:String, source:String, format:VideoFrameFormat):Bool
	{
		#if (lime_cffi && !macro)
		if (__handle == null)
		{
			__handle = NativeCFFI.lime_video_decoder_create();
			if (__handle == null) return false;

			// Only set when turned off, so an older native library still plays
			if (!dropLateFrames) NativeCFFI.lime_video_decoder_set_drop_late_frames(__handle, false);
		}

		var info:Dynamic = NativeCFFI.lime_video_decoder_open(__handle, path, hardwareDecoding, format);
		if (info == null) return false;

		audioChannels = info.audioChannels;
		audioSampleRate = info.audioSampleRate;
		duration = info.duration;
		frameRate = info.frameRate;
		hasAudio = info.hasAudio;
		hasVideo = info.hasVideo;
		height = info.height;
		width = info.width;

		// A native library from before these leaves them out
		var audioUnsupported:Null<Bool> = info.audioUnsupported;
		var pixelAspectRatio:Null<Float> = info.pixelAspectRatio;
		var rotation:Null<Int> = info.rotation;
		var videoUnsupported:Null<Bool> = info.videoUnsupported;
		this.audioUnsupported = audioUnsupported == true;
		this.pixelAspectRatio = pixelAspectRatio != null && pixelAspectRatio > 0 ? pixelAspectRatio : 1;
		this.rotation = rotation != null ? rotation : 0;
		this.videoUnsupported = videoUnsupported == true;

		audioComplete = !hasAudio;
		videoComplete = !hasVideo;
		this.source = source;
		this.format = format;
		droppedFrames = 0;
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
			if (result == READ_ERROR) error = true;
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
			var info = __readFrameInfo();
			frame.data = new UInt8Array(Std.int(info.getDouble(FRAME_INFO_LENGTH << 3)));
			result = __readFrame(frame.data, time);
		}

		if (result > 0)
		{
			var info = __readFrameInfo();
			#if (lime_opengl || lime_opengles)
			var texture = Std.int(info.getDouble(FRAME_INFO_TEXTURE << 3));
			frame.texture = texture != 0 ? __getTexture(texture) : null;
			#end
			frame.colorMatrix = cast Std.int(info.getDouble(FRAME_INFO_COLOR_MATRIX << 3));
			frame.duration = info.getDouble(FRAME_INFO_DURATION << 3);
			droppedFrames = Std.int(info.getDouble(FRAME_INFO_DROPPED_FRAMES << 3));
			frame.format = format;
			frame.fullRange = info.getDouble(FRAME_INFO_FULL_RANGE << 3) != 0;
			frame.height = Std.int(info.getDouble(FRAME_INFO_HEIGHT << 3));
			frame.length = format == VideoFrameFormat.TEXTURE ? 0 : result;
			frame.time = info.getDouble(FRAME_INFO_TIME << 3);
			frame.width = Std.int(info.getDouble(FRAME_INFO_WIDTH << 3));
			return true;
		}

		if (result == READ_END || result == READ_ERROR)
		{
			if (result == READ_ERROR) error = true;
			videoComplete = true;
		}

		return false;
		#else
		return false;
		#end
	}

	/**
		Moves both streams to a new time. Seeking to the end of the video or
		past it completes both streams.

		@param	time	The time in seconds
		@param	accurate	Whether to start exactly at `time`, decoding from the
		keyframe before it. Otherwise reading starts from that keyframe, which is
		faster.
		@return	Whether the streams moved. A video that cannot seek, such as a
		live stream, carries on from where it was.
	**/
	public function seek(time:Float, accurate:Bool = true):Bool
	{
		#if (lime_cffi && !macro)
		if (__handle == null || source == null) return false;

		if (!NativeCFFI.lime_video_decoder_seek(__handle, time, accurate)) return false;

		audioComplete = !hasAudio;
		error = false;
		videoComplete = !hasVideo;
		return true;
		#else
		return false;
		#end
	}

	// The details of the frame last read, written by the native decoder as
	// doubles into a buffer kept for it, as an object made for every frame was
	// allocated for every frame of every video. They are read from the bytes,
	// as Haxe 4.2's HashLink output allocates for each read of a Float64Array.
	@:noCompletion private function __readFrameInfo():Bytes
	{
		if (__frameInfo == null) __frameInfo = Bytes.alloc(FRAME_INFO_COUNT << 3);

		#if (lime_cffi && !macro)
		NativeCFFI.lime_video_decoder_read_frame_info(__handle, __frameInfo);
		#end

		return __frameInfo;
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

	@:noCompletion private function __deleteTemporaryFile():Void
	{
		#if sys
		if (__temporaryPath != null)
		{
			try
			{
				FileSystem.deleteFile(__temporaryPath);
			}
			catch (e:Dynamic) {}

			__temporaryPath = null;
		}
		#end
	}

	@:noCompletion private function __openBytes(bytes:Bytes, format:VideoFrameFormat, name:String, source:String):Bool
	{
		close();

		if (bytes == null || bytes.length == 0) return false;

		#if (sys && lime_cffi && !macro)
		var path = __writeTemporaryFile(bytes, name);
		if (path == null) return false;

		__temporaryPath = path;

		if (!__openPath(path, source, format))
		{
			__deleteTemporaryFile();
			return false;
		}

		return true;
		#else
		return false;
		#end
	}

	#if sys
	@:noCompletion private static function __getTemporaryDirectory():String
	{
		#if (ios || android)
		var base = System.applicationStorageDirectory;
		#else
		var base = Sys.getEnv("TEMP");
		if (base == null || base == "") base = Sys.getEnv("TMPDIR");
		if (base == null || base == "") base = "/tmp";
		#end

		return base != null ? Path.join([base, "lime-video"]) : null;
	}

	// The platform decoders tell some formats apart by the extension
	@:noCompletion private static function __getVideoExtension(bytes:Bytes, name:String):String
	{
		var extension = name != null ? Path.extension(name) : "";
		if (extension != "") return extension.toLowerCase();

		if (bytes.length >= 12)
		{
			if (bytes.getString(4, 4) == "ftyp") return bytes.getString(8, 2) == "qt" ? "mov" : "mp4";
			if (bytes.get(0) == 0x1A && bytes.get(1) == 0x45 && bytes.get(2) == 0xDF && bytes.get(3) == 0xA3) return "webm";
			if (bytes.getString(0, 4) == "OggS") return "ogv";
			if (bytes.getString(0, 4) == "RIFF" && bytes.getString(8, 4) == "AVI ") return "avi";
		}

		return "mp4";
	}

	// Neko's ints have 31 bits, and Std.random() throws for a larger maximum
	@:noCompletion private static function __randomHex():String
	{
		return StringTools.hex(Std.random(0x10000), 4) + StringTools.hex(Std.random(0x10000), 4);
	}

	@:noCompletion private static function __writeTemporaryFile(bytes:Bytes, name:String):String
	{
		var directory = __getTemporaryDirectory();
		if (directory == null) return null;

		try
		{
			if (!FileSystem.exists(directory)) FileSystem.createDirectory(directory);

			var path = Path.join([
				directory,
				"video-" + StringTools.hex(Std.int(Date.now().getTime() / 1000) & 0xFFFFFF, 6) + "-" + __randomHex() + "."
				+ __getVideoExtension(bytes, name)
			]);

			sys.io.File.saveBytes(path, bytes);
			return path;
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}
	#end

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

	#if (lime_opengl || lime_opengles)
	@:noCompletion private function __getTexture(id:Int):GLObject
	{
		// The decoder owns these textures. GLObject.fromInt would register the
		// wrappers with Lime, which deletes the texture of any wrapper it garbage
		// collects, and frames rotate through several textures
		if (__textures == null) __textures = new Map();

		var texture = __textures.get(id);

		if (texture == null)
		{
			texture = new GLObject(id);
			__textures.set(id, texture);
		}

		return texture;
	}
	#end

	// Get & Set Methods
	@:noCompletion private function get_displayHeight():Int
	{
		return rotation == 90 || rotation == 270 ? getStretchedWidth() : height;
	}

	@:noCompletion private function get_displayWidth():Int
	{
		return rotation == 90 || rotation == 270 ? height : getStretchedWidth();
	}

	@:noCompletion private inline function getStretchedWidth():Int
	{
		return Math.round(width * pixelAspectRatio);
	}

	@:noCompletion private function set_dropLateFrames(value:Bool):Bool
	{
		#if (lime_cffi && !macro)
		if (__handle != null && value != dropLateFrames) NativeCFFI.lime_video_decoder_set_drop_late_frames(__handle, value);
		#end
		return dropLateFrames = value;
	}

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
