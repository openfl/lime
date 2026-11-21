package lime._internal.backend.html5;

import js.html.VideoElement;
import js.Browser;
import lime.app.Future;
import lime.app.Promise;
import lime.media.VideoClockMode;
import lime.media.VideoFrame;
import lime.media.VideoFrameFormat;
import lime.media.VideoSource;
import lime.utils.Assets;

@:access(lime.media.VideoSource)
class HTML5VideoSource
{
	private var buffering:Bool;
	private var clockMode:VideoClockMode;
	private var completed:Bool;
	private var dropLateFrames:Bool;
	private var element:VideoElement;
	private var frameCallbackID:Int;
	// Frames and media time counted from requestVideoFrameCallback, to measure the frame rate
	private var frameCount:Float;
	private var frameMediaTime:Float;
	private var framePresented:Float;
	private var frameRate:Float;
	private var frameSeconds:Float;
	private var frameTime:Float;
	private var gain:Float;
	private var rate:Float;
	private var loops:Int;
	private var pan:Float;
	private var parent:VideoSource;
	private var path:String;
	private var pendingSeeks:Int;
	private var playing:Bool;
	// The media time of the frame last presented, from requestVideoFrameCallback, or -1
	private var presentedTime:Float;

	public function new(parent:VideoSource)
	{
		this.parent = parent;

		clockMode = SMOOTH;
		completed = false;
		dropLateFrames = true;
		frameCallbackID = -1;
		frameTime = -1;
		gain = 1;
		rate = 1;
		loops = 0;
		pan = 0;
		playing = false;
		presentedTime = -1;
	}

	public function dispose():Void
	{
		close();
	}

	public function getBytesLoaded():Float
	{
		// Browsers do not say how much of a video they have read
		return 0;
	}

	public function getBytesTotal():Float
	{
		return 0;
	}

	public function getClockMode():VideoClockMode
	{
		return clockMode;
	}

	public function getCurrentTime():Int
	{
		return element != null ? Std.int(element.currentTime * 1000) : 0;
	}

	public function getDisplayHeight():Int
	{
		// The browser sizes and turns the picture itself
		return getHeight();
	}

	public function getDisplayWidth():Int
	{
		return getWidth();
	}

	public function getDroppedFrames():Int
	{
		// Browsers that count dropped frames report them in the playback quality
		if (element == null || untyped element.getVideoPlaybackQuality == null) return 0;
		var quality:Dynamic = untyped element.getVideoPlaybackQuality();
		return quality != null ? quality.droppedVideoFrames : 0;
	}

	public function getDropLateFrames():Bool
	{
		return dropLateFrames;
	}

	public function getFrameRate():Float
	{
		return frameRate;
	}

	public function getGain():Float
	{
		return gain;
	}

	public function getRate():Float
	{
		return rate;
	}

	public function setRate(value:Float):Float
	{
		if (Math.isNaN(value)) return rate;
		rate = Math.max(0.25, Math.min(4, value));
		if (element != null) element.playbackRate = rate;
		return rate;
	}

	public function getHasAudio():Bool
	{
		// Browsers do not report whether a video has sound
		return element != null;
	}

	public function getHasVideo():Bool
	{
		// Known once the size is, and a picture the browser cannot decode has none
		return element != null && element.videoWidth > 0;
	}

	public function getHeight():Int
	{
		return element != null ? element.videoHeight : 0;
	}

	public function getLength():Int
	{
		if (element == null || Math.isNaN(element.duration) || !Math.isFinite(element.duration)) return 0;
		return Std.int(element.duration * 1000);
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
		return 1;
	}

	public function getPlaying():Bool
	{
		return playing;
	}

	public function getRotation():Int
	{
		return 0;
	}

	public function getWidth():Int
	{
		return element != null ? element.videoWidth : 0;
	}

	public static function isSupported():Bool
	{
		return true;
	}

	public static function loadFromFile(path:String, format:VideoFrameFormat):Future<VideoSource>
	{
		var promise = new Promise<VideoSource>();
		var source = new VideoSource();

		if (!source.open(path, format))
		{
			promise.error("Cannot play " + path);
			return promise.future;
		}

		var element = source.__backend.element;

		if (element.readyState >= 1)
		{
			promise.complete(source);
		}
		else
		{
			var onMetadata:Dynamic = null;
			var onError:Dynamic = null;

			onMetadata = function(_)
			{
				element.removeEventListener("loadedmetadata", onMetadata);
				element.removeEventListener("error", onError);
				promise.complete(source);
			};

			onError = function(_)
			{
				element.removeEventListener("loadedmetadata", onMetadata);
				element.removeEventListener("error", onError);
				promise.error("Cannot play " + path);
			};

			element.addEventListener("loadedmetadata", onMetadata);
			element.addEventListener("error", onError);
		}

		return promise.future;
	}

	public function open(path:String, format:VideoFrameFormat):Bool
	{
		close();

		if (path == null || path == "") return false;

		var url = path;

		if (Assets.exists(path))
		{
			var assetPath = Assets.getPath(path);
			if (assetPath != null) url = assetPath;
		}

		element = cast Browser.document.createElement("video");
		element.crossOrigin = "anonymous";
		element.preload = "auto";
		element.playbackRate = rate;
		element.volume = Math.max(0, Math.min(1, gain));
		// Play inline on iOS rather than in the full screen player
		element.setAttribute("playsinline", "");
		element.addEventListener("ended", element_onEnded);
		element.addEventListener("error", element_onError);
		element.addEventListener("loadedmetadata", element_onLoadedMetadata);
		element.addEventListener("playing", element_onPlaying);
		element.addEventListener("seeked", element_onSeeked);
		element.addEventListener("waiting", element_onWaiting);
		element.src = url;
		element.load();

		buffering = false;
		completed = false;
		frameCount = 0;
		frameMediaTime = -1;
		framePresented = -1;
		frameRate = 0;
		frameSeconds = 0;
		pendingSeeks = 0;
		frameTime = -1;
		presentedTime = -1;
		requestFrameCallback();
		this.path = path;
		return true;
	}

	public function pause():Void
	{
		playing = false;

		if (element != null)
		{
			element.pause();
		}

		setBuffering(false);
	}

	public function play():Void
	{
		if (element == null || playing) return;

		if (completed)
		{
			element.currentTime = 0;
			completed = false;
		}

		playing = true;

		// Haxe 3 types play as Void, from before browsers returned a promise
		var result:Dynamic = untyped element.play();

		if (result != null)
		{
			// Browsers refuse to start sound before the user interacts with the page
			result.then(null, function(_)
			{
				playing = false;
			});
		}
	}

	public function readFrame(frame:VideoFrame):Bool
	{
		// HAVE_CURRENT_DATA, so the element has a picture to upload
		if (element == null || frame == null || element.readyState < 2) return false;

		// currentTime is the media clock, which moves on every animation frame while a video plays,
		// so where the browser says when each frame is presented, that is used instead. Until it
		// has, as for a paused video's first frame, currentTime still is.
		var time = (presentedTime >= 0) ? presentedTime : element.currentTime;
		if (time == frameTime) return false;

		frameTime = time;

		frame.data = null;
		frame.duration = 0;
		frame.format = RGBA;
		frame.fullRange = true;
		frame.height = element.videoHeight;
		frame.length = 0;
		frame.src = element;
		frame.time = time;
		frame.width = element.videoWidth;

		return true;
	}

	public function setClockMode(value:VideoClockMode):VideoClockMode
	{
		// The browser keeps a <video> element in sync itself
		return clockMode = value;
	}

	public function setCurrentTime(value:Int):Int
	{
		if (element != null)
		{
			// Only seeks asked for here dispatch onSeek, not those for loops or stop()
			pendingSeeks++;
			element.currentTime = Math.max(0, value / 1000);
			completed = false;
			frameTime = -1;
		}

		return value;
	}

	public function setDropLateFrames(value:Bool):Bool
	{
		// Browsers always skip late frames
		return dropLateFrames = value;
	}

	public function setGain(value:Float):Float
	{
		gain = value;

		if (element != null)
		{
			element.volume = Math.max(0, Math.min(1, value));
		}

		return value;
	}

	public function setLoops(value:Int):Int
	{
		return loops = value;
	}

	public function setPan(value:Float):Float
	{
		// A <video> element has no pan of its own
		return pan = Math.max(-1, Math.min(1, value));
	}

	public function stop():Void
	{
		pause();

		if (element != null)
		{
			element.currentTime = 0;
			completed = false;
			frameTime = -1;
			presentedTime = -1;
		}
	}

	@:noCompletion private function close():Void
	{
		if (element != null)
		{
			if (frameCallbackID >= 0 && untyped element.cancelVideoFrameCallback != null)
			{
				untyped element.cancelVideoFrameCallback(frameCallbackID);
			}

			frameCallbackID = -1;
			presentedTime = -1;
			element.removeEventListener("ended", element_onEnded);
			element.removeEventListener("error", element_onError);
			element.removeEventListener("loadedmetadata", element_onLoadedMetadata);
			element.removeEventListener("playing", element_onPlaying);
			element.removeEventListener("seeked", element_onSeeked);
			element.removeEventListener("waiting", element_onWaiting);
			element.pause();
			element.removeAttribute("src");
			element.load();
			element = null;
		}

		buffering = false;
		pendingSeeks = 0;
		playing = false;
	}

	@:noCompletion private function measureFrameRate(metadata:Dynamic):Void
	{
		var presented:Dynamic = metadata.presentedFrames;
		var mediaTime:Dynamic = metadata.mediaTime;

		if (framePresented >= 0 && presented != null && mediaTime != null)
		{
			var frames = presented - framePresented;
			var seconds = mediaTime - frameMediaTime;

			// Gaps from seeking, pausing or a hidden page are left out
			if (frames > 0 && seconds > 0 && seconds < 0.5 * frames)
			{
				frameCount += frames;
				frameSeconds += seconds;
				frameRate = frameCount / frameSeconds;
			}
		}

		framePresented = presented != null ? presented : -1;
		frameMediaTime = mediaTime != null ? mediaTime : -1;
	}

	@:noCompletion private function requestFrameCallback():Void
	{
		// Not in every browser yet; without it readFrame() compares currentTime
		var target = element;

		if (target != null && untyped target.requestVideoFrameCallback != null)
		{
			frameCallbackID = untyped target.requestVideoFrameCallback(function(now:Float, metadata:Dynamic)
			{
				// One still queued for an element this source has since let go of
				if (element != target) return;

				presentedTime = metadata.mediaTime;
				measureFrameRate(metadata);
				requestFrameCallback();
			});
		}
	}

	// Event Handlers
	@:noCompletion private function element_onEnded(_):Void
	{
		if (loops > 0)
		{
			loops--;
			element.currentTime = 0;
			element.play();
			return;
		}

		playing = false;
		completed = true;
		parent.onComplete.dispatch();
	}

	@:noCompletion private function setBuffering(value:Bool):Void
	{
		if (buffering == value) return;
		buffering = value;
		parent.onBuffering.dispatch(value);
	}

	@:noCompletion private function element_onLoadedMetadata(_):Void
	{
		var target = element;

		// After loadFromFile completes its future, as native targets do
		Browser.window.setTimeout(function()
		{
			if (element == target) parent.onReady.dispatch();
		}, 0);
	}

	@:noCompletion private function element_onPlaying(_):Void
	{
		setBuffering(false);
	}

	@:noCompletion private function element_onSeeked(_):Void
	{
		if (pendingSeeks > 0)
		{
			pendingSeeks = 0;
			parent.onSeek.dispatch();
		}
	}

	@:noCompletion private function element_onWaiting(_):Void
	{
		if (playing) setBuffering(true);
	}

	@:noCompletion private function element_onError(_):Void
	{
		// Older externs leave out the message, which browsers give
		var error:Dynamic = element.error;
		playing = false;
		parent.onError.dispatch("Cannot play " + path + (error != null && error.message != null && error.message != "" ? ": " + error.message : ""));
	}
}
