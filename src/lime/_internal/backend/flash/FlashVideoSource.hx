package lime._internal.backend.flash;

import lime.app.Future;
import lime.media.VideoFrame;
import lime.media.VideoFrameFormat;
import lime.media.VideoSource;

class FlashVideoSource
{
	public function new(parent:VideoSource) {}

	public function dispose():Void {}

	public function getCurrentTime():Int
	{
		return 0;
	}

	public function getGain():Float
	{
		return 1;
	}

	public function getHasAudio():Bool
	{
		return false;
	}

	public function getHeight():Int
	{
		return 0;
	}

	public function getLength():Int
	{
		return 0;
	}

	public function getLoops():Int
	{
		return 0;
	}

	public function getPlaying():Bool
	{
		return false;
	}

	public function getWidth():Int
	{
		return 0;
	}

	public static function isSupported():Bool
	{
		return false;
	}

	public static function loadFromFile(path:String, format:VideoFrameFormat):Future<VideoSource>
	{
		return cast Future.withError("Video is not supported on this target");
	}

	public function open(path:String, format:VideoFrameFormat):Bool
	{
		return false;
	}

	public function pause():Void {}

	public function play():Void {}

	public function readFrame(frame:VideoFrame):Bool
	{
		return false;
	}

	public function setCurrentTime(value:Int):Int
	{
		return value;
	}

	public function setGain(value:Float):Float
	{
		return value;
	}

	public function setLoops(value:Int):Int
	{
		return value;
	}

	public function stop():Void {}
}
