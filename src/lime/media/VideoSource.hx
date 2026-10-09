package lime.media;

import lime.app.Event;
import lime.app.Future;
import lime.app.Promise;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

/**
	Plays a video file: its sound through the audio device, and its pictures
	as frames that the application draws.

	The sound drives the timing. Each frame, call `readFrame` and draw the
	frame it returns, keeping the previous one when it returns `false`.

	Example usage:
	```haxe
	var video = new VideoSource("assets/intro.mp4");
	var frame = new VideoFrame();
	video.onComplete.add(() -> trace("done"));
	video.play();

	// in render ()
	if (video.readFrame(frame))
	{
		// upload the frame to textures, then draw them
	}
	```

	On native targets, frames are `NV12` by default (see `VideoFrameFormat`),
	ready for a YUV to RGB shader. On HTML5, `VideoFrame.src` is the playing
	`<video>` element, which WebGL can upload with `texImage2D`.

	Availability: native targets where `VideoDecoder.isSupported` is `true`,
	and HTML5.

	@see lime.media.VideoDecoder
**/
class VideoSource
{
	/**
		Whether videos can be played on this platform.
	**/
	public static var isSupported(get, never):Bool;

	/**
		Dispatched when playback reaches the end and has no loops left.
	**/
	public var onComplete = new Event<Void->Void>();

	/**
		The playback position in milliseconds. Setting it seeks to that time.
	**/
	public var currentTime(get, set):Int;

	/**
		The volume of the video's sound, from 0 for silent to 1 for full volume.
	**/
	public var gain(get, set):Float;

	/**
		Whether the video has sound.
	**/
	public var hasAudio(get, never):Bool;

	/**
		The height of the video's frames in pixels.
	**/
	public var height(get, never):Int;

	/**
		The length of the video in milliseconds, or 0 when it is unknown.
	**/
	public var length(get, never):Int;

	/**
		The number of times to play the video again after it ends.
	**/
	public var loops(get, set):Int;

	/**
		Whether the video is playing.
	**/
	public var playing(get, never):Bool;

	/**
		The path or URL of the video.
	**/
	public var source(default, null):String;

	/**
		The width of the video's frames in pixels.
	**/
	public var width(get, never):Int;

	@:noCompletion private var __backend:VideoSourceBackend;

	/**
		Creates a video source, opening `path` when one is given.

		On native targets opening reads the start of the file, so for a URL
		prefer `loadFromFile`, which opens it without blocking.

		@param	path	A file path, asset ID or URL
		@param	format	The layout of frames on native targets
	**/
	public function new(path:String = null, format:VideoFrameFormat = NV12)
	{
		__backend = new VideoSourceBackend(this);

		if (path != null)
		{
			open(path, format);
		}
	}

	/**
		Stops playback and releases the video.
	**/
	public function dispose():Void
	{
		__backend.dispose();
		source = null;
	}

	/**
		Opens a video without blocking.

		@param	path	A file path, asset ID or URL
		@param	format	The layout of frames on native targets
		@return	A future that completes with the source once its size and
		length are known, or fails when the video cannot be played
	**/
	public static function loadFromFile(path:String, format:VideoFrameFormat = NV12):Future<VideoSource>
	{
		return VideoSourceBackend.loadFromFile(path, format);
	}

	/**
		Opens a video, closing any video already open. Playback starts paused
		at the beginning.

		@param	path	A file path, asset ID or URL
		@param	format	The layout of frames on native targets
		@return	Whether the video can be played. On HTML5 the video loads in
		the background, and this only fails when video is unavailable.
	**/
	public function open(path:String, format:VideoFrameFormat = NV12):Bool
	{
		source = null;

		if (__backend.open(path, format))
		{
			source = path;
			return true;
		}

		return false;
	}

	/**
		Pauses playback, keeping the position.
	**/
	public function pause():Void
	{
		__backend.pause();
	}

	/**
		Starts or resumes playback.
	**/
	public function play():Void
	{
		__backend.play();
	}

	/**
		Reads the frame due at the current playback position.

		@param	frame	The frame to fill
		@return	Whether `frame` holds a new frame to draw. It is `false` while
		the previous frame is still current.
	**/
	public function readFrame(frame:VideoFrame):Bool
	{
		return __backend.readFrame(frame);
	}

	/**
		Stops playback and returns to the beginning.
	**/
	public function stop():Void
	{
		__backend.stop();
	}

	// Get & Set Methods
	@:noCompletion private function get_currentTime():Int
	{
		return __backend.getCurrentTime();
	}

	@:noCompletion private function set_currentTime(value:Int):Int
	{
		return __backend.setCurrentTime(value);
	}

	@:noCompletion private function get_gain():Float
	{
		return __backend.getGain();
	}

	@:noCompletion private function set_gain(value:Float):Float
	{
		return __backend.setGain(value);
	}

	@:noCompletion private function get_hasAudio():Bool
	{
		return __backend.getHasAudio();
	}

	@:noCompletion private function get_height():Int
	{
		return __backend.getHeight();
	}

	@:noCompletion private static function get_isSupported():Bool
	{
		return VideoSourceBackend.isSupported();
	}

	@:noCompletion private function get_length():Int
	{
		return __backend.getLength();
	}

	@:noCompletion private function get_loops():Int
	{
		return __backend.getLoops();
	}

	@:noCompletion private function set_loops(value:Int):Int
	{
		return __backend.setLoops(value);
	}

	@:noCompletion private function get_playing():Bool
	{
		return __backend.getPlaying();
	}

	@:noCompletion private function get_width():Int
	{
		return __backend.getWidth();
	}
}

#if flash
@:noCompletion private typedef VideoSourceBackend = lime._internal.backend.flash.FlashVideoSource;
#elseif (js && html5)
@:noCompletion private typedef VideoSourceBackend = lime._internal.backend.html5.HTML5VideoSource;
#else
@:noCompletion private typedef VideoSourceBackend = lime._internal.backend.native.NativeVideoSource;
#end
