package lime._internal.backend.html5;

import js.html.VideoElement;
import js.Browser;
import lime.app.Future;
import lime.app.Promise;
import lime.media.VideoFrame;
import lime.media.VideoFrameFormat;
import lime.media.VideoSource;
import lime.utils.Assets;

@:access(lime.media.VideoSource)
class HTML5VideoSource
{
	private var completed:Bool;
	private var element:VideoElement;
	private var frameTime:Float;
	private var gain:Float;
	private var loops:Int;
	private var parent:VideoSource;
	private var playing:Bool;

	public function new(parent:VideoSource)
	{
		this.parent = parent;

		completed = false;
		frameTime = -1;
		gain = 1;
		loops = 0;
		playing = false;
	}

	public function dispose():Void
	{
		close();
	}

	public function getCurrentTime():Int
	{
		return element != null ? Std.int(element.currentTime * 1000) : 0;
	}

	public function getGain():Float
	{
		return gain;
	}

	public function getHasAudio():Bool
	{
		// Browsers do not report whether a video has sound
		return element != null;
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

	public function getPlaying():Bool
	{
		return playing;
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
			element.addEventListener("loadedmetadata", function(_) promise.complete(source), {once: true});
			element.addEventListener("error", function(_) promise.error("Cannot play " + path), {once: true});
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
		element.volume = Math.max(0, Math.min(1, gain));
		// Play inline on iOS rather than in the full screen player
		element.setAttribute("playsinline", "");
		element.addEventListener("ended", element_onEnded);
		element.src = url;
		element.load();

		completed = false;
		frameTime = -1;
		return true;
	}

	public function pause():Void
	{
		playing = false;

		if (element != null)
		{
			element.pause();
		}
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
		var result:Dynamic = element.play();

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
		if (element.currentTime == frameTime) return false;

		frameTime = element.currentTime;

		frame.data = null;
		frame.duration = 0;
		frame.format = RGBA;
		frame.fullRange = true;
		frame.height = element.videoHeight;
		frame.length = 0;
		frame.src = element;
		frame.time = element.currentTime;
		frame.width = element.videoWidth;

		return true;
	}

	public function setCurrentTime(value:Int):Int
	{
		if (element != null)
		{
			element.currentTime = Math.max(0, value / 1000);
			completed = false;
			frameTime = -1;
		}

		return value;
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

	public function stop():Void
	{
		pause();

		if (element != null)
		{
			element.currentTime = 0;
			completed = false;
			frameTime = -1;
		}
	}

	@:noCompletion private function close():Void
	{
		if (element != null)
		{
			element.removeEventListener("ended", element_onEnded);
			element.pause();
			element.removeAttribute("src");
			element.load();
			element = null;
		}

		playing = false;
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
}
