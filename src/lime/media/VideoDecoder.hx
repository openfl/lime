package lime.media;

import haxe.io.Bytes;
import haxe.io.Path;
import lime._internal.backend.native.NativeCFFI;
import lime.utils.Assets;
import lime.utils.UInt8Array;
#if sys
import haxe.crypto.Md5;
import lime.system.System;
import sys.FileSystem;
import sys.io.File;
#end

@:access(lime._internal.backend.native.NativeCFFI)
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class VideoDecoder
{
	/**
		Returns `true` when this target has a native decoder backend.
	**/
	public static var isSupported(get, never):Bool;

	/**
		The number of bits per decoded audio sample, or `0` when unavailable.
	**/
	public var audioBitsPerSample(default, null):Int = 0;

	/**
		The number of decoded audio channels, or `0` when unavailable.
	**/
	public var audioChannels(default, null):Int = 0;

	/**
		The decoded audio sample rate in Hz, or `0` when unavailable.
	**/
	public var audioSampleRate(default, null):Int = 0;

	/**
		Current decode position in seconds on the media timeline.
	**/
	public var currentTime(get, set):Float;

	/**
		Total duration in seconds, or `0` when unavailable.
	**/
	public var duration(default, null):Float = 0.0;

	/**
		Nominal video frame rate, or `0` when unavailable.
	**/
	public var frameRate(default, null):Float = 0.0;

	/**
		Enables hardware decoding when the backend supports it.
	**/
	public var hardwareDecodingEnabled(get, set):Bool;

	/**
		The decoded video height in pixels.
	**/
	public var height(default, null):Int = 0;

	/**
		The original path or asset id passed to `load`.
	**/
	public var source(default, null):String;

	/**
		The decoded video width in pixels.
	**/
	public var width(default, null):Int = 0;

	@:noCompletion private var __frame:VideoFrame;
	@:noCompletion private var __frameBytes:Bytes;
	@:noCompletion private var __frameSerial:Int = 0;
	@:noCompletion private var __handle:Dynamic;
	@:noCompletion private var __hardwareDecodingEnabled:Bool = true;
	@:noCompletion private var __resolvedSource:String;
	@:noCompletion private var __time:Float = 0.0;

	public function new() {}

	/**
		Closes the current source and releases native decoder resources.
	**/
	public function close():Void
	{
		#if (lime_cffi && !macro && (cpp || hl) && (windows || linux))
		if (__handle != null)
		{
			NativeCFFI.lime_video_decoder_close(__handle);
		}
		#end

		source = null;
		__resolvedSource = null;
		width = 0;
		height = 0;
		duration = 0.0;
		frameRate = 0.0;
		audioBitsPerSample = 0;
		audioChannels = 0;
		audioSampleRate = 0;
		__time = 0.0;
		__frame = null;
		__frameBytes = null;
		__frameSerial = 0;
	}

	/**
		Closes the current source. The native handle is reclaimed by the runtime.
	**/
	public function dispose():Void
	{
		close();
		__handle = null;
	}

	/**
		Loads a file path or asset id.
	**/
	public function load(path:String):Bool
	{
		if (!isSupported || path == null || path == "") return false;

		#if (lime_cffi && !macro && (cpp || hl) && (windows || linux))
		close();
		ensureHandle();
		if (__handle == null) return false;

		NativeCFFI.lime_video_decoder_set_hardware_decoding_enabled(__handle, __hardwareDecodingEnabled);
		var resolved = resolveSource(path);
		if (!NativeCFFI.lime_video_decoder_load(__handle, resolved))
		{
			close();
			return false;
		}

		source = path;
		__resolvedSource = resolved;
		width = NativeCFFI.lime_video_decoder_get_width(__handle);
		height = NativeCFFI.lime_video_decoder_get_height(__handle);
		duration = Math.max(0, NativeCFFI.lime_video_decoder_get_duration(__handle)) * 0.001;
		frameRate = Math.max(0, NativeCFFI.lime_video_decoder_get_frame_rate(__handle));
		audioBitsPerSample = Std.int(Math.max(0, NativeCFFI.lime_video_decoder_get_audio_bits_per_sample(__handle)));
		audioChannels = Std.int(Math.max(0, NativeCFFI.lime_video_decoder_get_audio_channel_count(__handle)));
		audioSampleRate = Std.int(Math.max(0, NativeCFFI.lime_video_decoder_get_audio_sample_rate(__handle)));
		__time = 0.0;
		return width > 0 && height > 0;
		#else
		return false;
		#end
	}

	/**
		Reads decoded PCM bytes into `buffer`.
	**/
	public function readAudio(buffer:Bytes, length:Int = -1):Int
	{
		if (buffer == null || source == null) return -1;
		if (length < 0 || length > buffer.length) length = buffer.length;
		if (length <= 0) return 0;

		#if (lime_cffi && !macro && (cpp || hl) && (windows || linux))
		return NativeCFFI.lime_video_decoder_read_audio(__handle, buffer, length);
		#else
		return -1;
		#end
	}

	/**
		Reads the next decoded video frame. Returns `null` when no frame is available or decoding reaches the end.
	**/
	public function readFrame(format:VideoFrameFormat = RGBA):VideoFrame
	{
		if (source == null || width <= 0 || height <= 0) return null;
		if (format != VideoFrameFormat.RGBA) return null;

		#if (lime_cffi && !macro && (cpp || hl) && (windows || linux))
		ensureFrameBuffer();
		if (!NativeCFFI.lime_video_decoder_read_rgba_frame(__handle, __frameBytes, __frameBytes.length))
		{
			return null;
		}

		__time = Math.max(0, NativeCFFI.lime_video_decoder_get_video_position(__handle)) * 0.001;
		__frameSerial++;
		__frame.timestamp = __time;
		__frame.serial = __frameSerial;
		return __frame;
		#else
		return null;
		#end
	}

	/**
		Seeks to `time` seconds on the media timeline.
	**/
	public function seek(time:Float):Void
	{
		currentTime = time;
	}

	/**
		Creates and loads a decoder from a file path or asset id.
	**/
	public static function fromFile(path:String):VideoDecoder
	{
		var decoder = new VideoDecoder();
		return decoder.load(path) ? decoder : null;
	}

	@:noCompletion private function ensureFrameBuffer():Void
	{
		var length = width * height * 4;
		if (__frameBytes == null || __frameBytes.length != length)
		{
			__frameBytes = Bytes.alloc(length);
			__frame = new VideoFrame(UInt8Array.fromBytes(__frameBytes), width, height, VideoFrameFormat.RGBA, __time, __frameSerial);
		}
		else
		{
			__frame.width = width;
			__frame.height = height;
		}
	}

	@:noCompletion private function ensureHandle():Void
	{
		#if (lime_cffi && !macro && (cpp || hl) && (windows || linux))
		if (__handle == null)
		{
			__handle = NativeCFFI.lime_video_decoder_create();
		}
		#end
	}

	@:noCompletion private static function get_isSupported():Bool
	{
		#if (lime_cffi && !macro && (cpp || hl) && (windows || linux))
		return NativeCFFI.lime_video_decoder_is_supported();
		#else
		return false;
		#end
	}

	@:noCompletion private function get_currentTime():Float
	{
		#if (lime_cffi && !macro && (cpp || hl) && (windows || linux))
		if (__handle != null && source != null)
		{
			__time = Math.max(0, NativeCFFI.lime_video_decoder_get_video_position(__handle)) * 0.001;
		}
		#end
		return __time;
	}

	@:noCompletion private function get_hardwareDecodingEnabled():Bool
	{
		return __hardwareDecodingEnabled;
	}

	@:noCompletion private static function resolveSource(path:String):String
	{
		#if sys
		if (FileSystem.exists(path)) return path;

		var assetPath:String = null;
		try
		{
			assetPath = Assets.getPath(path);
		}
		catch (_:Dynamic) {}

		if (assetPath != null && assetPath != "" && FileSystem.exists(assetPath)) return assetPath;

		#if (ios || android)
		var bytes:Bytes = null;
		try
		{
			bytes = Assets.getBytes(path);
		}
		catch (_:Dynamic) {}

		if (bytes != null)
		{
			var extension = Path.extension(path);
			if (extension == null || extension == "") extension = "bin";

			var cacheDir = Path.join([System.applicationStorageDirectory, "lime-video-cache"]);
			if (!FileSystem.exists(cacheDir)) FileSystem.createDirectory(cacheDir);

			var cachePath = Path.join([cacheDir, Md5.encode(path) + "." + extension]);
			if (!FileSystem.exists(cachePath) || File.getBytes(cachePath).length != bytes.length)
			{
				File.saveBytes(cachePath, bytes);
			}
			return cachePath;
		}
		#end
		#end

		return path;
	}

	@:noCompletion private function set_currentTime(value:Float):Float
	{
		if (Math.isNaN(value) || value < 0) value = 0.0;
		__time = value;

		#if (lime_cffi && !macro && (cpp || hl) && (windows || linux))
		if (__handle != null && source != null)
		{
			NativeCFFI.lime_video_decoder_seek(__handle, Std.int(value * 1000.0));
		}
		#end

		return value;
	}

	@:noCompletion private function set_hardwareDecodingEnabled(value:Bool):Bool
	{
		__hardwareDecodingEnabled = value;
		#if (lime_cffi && !macro && (cpp || hl) && (windows || linux))
		if (__handle != null)
		{
			NativeCFFI.lime_video_decoder_set_hardware_decoding_enabled(__handle, value);
		}
		#end
		return value;
	}
}
