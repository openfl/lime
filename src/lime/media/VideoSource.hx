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

	The sound drives the timing, as `clockMode` sets out. Each frame, call
	`readFrame` and draw the frame it returns, keeping the previous one when it
	returns `false`. Draw frames at `displayWidth` by `displayHeight`, turned
	clockwise by `rotation`, as phones store video recorded upright sideways.

	Call `dispose` when done with a video. Until then it keeps playing, and
	stays in memory, even when nothing else refers to it.

	Example usage:
	```haxe
	var video = new VideoSource("assets/intro.mp4");
	var frame = new VideoFrame();
	video.onComplete.add(() -> trace("done"));
	video.onError.add((message) -> trace(message));
	video.play();

	// in render ()
	if (video.readFrame(frame))
	{
		// upload the frame to textures, then draw them
	}
	```

	On native targets, frames are `NV12` by default (see `VideoFrameFormat`),
	ready for a YUV to RGB shader. Videos are decoded on background threads,
	but a `VideoSource` is used from the main thread. On HTML5,
	`VideoFrame.src` is the playing `<video>` element, which WebGL can upload
	with `texImage2D`, and the browser turns and sizes it already.

	Availability: native targets where `VideoDecoder.isSupported` is `true`,
	and HTML5. On macOS and iOS, only local files play, not URLs.

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
		Dispatched with a message when the video stops because it cannot be
		decoded, such as when the file is damaged. Playback pauses, and
		`onComplete` is not dispatched. Calling `play` again tries again from
		where it stopped. On HTML5, where videos load in the background, it is
		also dispatched when the video cannot be loaded.
	**/
	public var onError = new Event<String->Void>();

	/**
		How frames are timed against the sound, `SMOOTH` by default. On HTML5,
		the browser keeps the `<video>` element in sync itself, and this has no
		effect.
	**/
	public var clockMode(get, set):VideoClockMode;

	/**
		The playback position in milliseconds. Setting it seeks to that time,
		which a video that cannot seek, such as a live stream, ignores.
	**/
	public var currentTime(get, set):Int;

	/**
		The height to draw frames at, after `pixelAspectRatio` and `rotation`.
	**/
	public var displayHeight(get, never):Int;

	/**
		The width to draw frames at, after `pixelAspectRatio` and `rotation`.
	**/
	public var displayWidth(get, never):Int;

	/**
		How many frames have been skipped because they were late, since the
		video was opened.
	**/
	public var droppedFrames(get, never):Int;

	/**
		Whether frames that are already late are skipped, so the picture keeps
		in step with the sound when decoding falls behind. When `false`, every
		frame is shown, so the picture falls behind instead. `true` by default.
		Browsers always skip late frames, so this has no effect on HTML5.
	**/
	public var dropLateFrames(get, set):Bool;

	/**
		The volume of the video's sound, from 0 for silent to 1 for full volume.
	**/
	public var gain(get, set):Float;

	/**
		Whether the video has sound that can be played. A video whose sound
		uses a codec the platform lacks plays without it.
	**/
	public var hasAudio(get, never):Bool;

	/**
		Whether the video has a picture that can be decoded. A video whose
		picture uses a codec the platform lacks plays only its sound, so check
		this when a video must be seen.
	**/
	public var hasVideo(get, never):Bool;

	/**
		The height of the video's frames in pixels.
	**/
	public var height(get, never):Int;

	/**
		The length of the video in milliseconds, or 0 when it is unknown.
	**/
	public var length(get, never):Int;

	/**
		The number of times to play the video again after it ends. On native
		targets, each loop follows the last without a pause, and `currentTime`
		starts again from 0. A video that cannot seek, such as a live stream,
		does not loop.
	**/
	public var loops(get, set):Int;

	/**
		The balance of the video's sound, from -1 for the left speaker only to 1
		for the right speaker only. A stereo video turns down the channel opposite
		the pan, which applies to sound buffered from then on, within half a
		second. It has no effect on HTML5.
	**/
	public var pan(get, set):Float;

	/**
		The width of a pixel relative to its height, which is 1 for the square
		pixels of most videos. Some videos are stored narrower than they are
		shown, so their frames are stretched to `displayWidth`. It is always 1
		on HTML5, where the browser sizes frames itself.
	**/
	public var pixelAspectRatio(get, never):Float;

	/**
		Whether the video is playing.
	**/
	public var playing(get, never):Bool;

	/**
		How far to turn frames clockwise to show them upright, in degrees: 0,
		90, 180 or 270. Phones store video recorded upright as sideways frames
		with a rotation of 90. It is always 0 on HTML5, where the browser turns
		frames itself.
	**/
	public var rotation(get, never):Int;

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
		Creates a video source, opening `path` when one is given. When the video
		cannot be opened, `source` is `null`.

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
		Stops playback and releases the video. A source that is not disposed of
		keeps playing, and stays in memory, as its sound is played on a timer.
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
	@:noCompletion private function get_clockMode():VideoClockMode
	{
		return __backend.getClockMode();
	}

	@:noCompletion private function set_clockMode(value:VideoClockMode):VideoClockMode
	{
		return __backend.setClockMode(value);
	}

	@:noCompletion private function get_currentTime():Int
	{
		return __backend.getCurrentTime();
	}

	@:noCompletion private function set_currentTime(value:Int):Int
	{
		return __backend.setCurrentTime(value);
	}

	@:noCompletion private function get_displayHeight():Int
	{
		return __backend.getDisplayHeight();
	}

	@:noCompletion private function get_displayWidth():Int
	{
		return __backend.getDisplayWidth();
	}

	@:noCompletion private function get_droppedFrames():Int
	{
		return __backend.getDroppedFrames();
	}

	@:noCompletion private function get_dropLateFrames():Bool
	{
		return __backend.getDropLateFrames();
	}

	@:noCompletion private function set_dropLateFrames(value:Bool):Bool
	{
		return __backend.setDropLateFrames(value);
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

	@:noCompletion private function get_hasVideo():Bool
	{
		return __backend.getHasVideo();
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

	@:noCompletion private function get_pan():Float
	{
		return __backend.getPan();
	}

	@:noCompletion private function set_pan(value:Float):Float
	{
		return __backend.setPan(value);
	}

	@:noCompletion private function get_pixelAspectRatio():Float
	{
		return __backend.getPixelAspectRatio();
	}

	@:noCompletion private function get_playing():Bool
	{
		return __backend.getPlaying();
	}

	@:noCompletion private function get_rotation():Int
	{
		return __backend.getRotation();
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
