package lime._internal.backend.flash;

import lime.app.Future;
import lime.media.VideoClockMode;
import lime.media.VideoFrame;
import lime.media.VideoFrameFormat;
import lime.media.VideoSource;

class FlashVideoSource
{
	public function new(parent:VideoSource) {}

	public function dispose():Void {}

	public function getClockMode():VideoClockMode
	{
		return SMOOTH;
	}

	public function getCurrentTime():Int
	{
		return 0;
	}

	public function getDisplayHeight():Int
	{
		return 0;
	}

	public function getDisplayWidth():Int
	{
		return 0;
	}

	public function getDroppedFrames():Int
	{
		return 0;
	}

	public function getDropLateFrames():Bool
	{
		return true;
	}

	public function getGain():Float
	{
		return 1;
	}

	public function getHasAudio():Bool
	{
		return false;
	}

	public function getHasVideo():Bool
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

	public function getPan():Float
	{
		return 0;
	}

	public function getPixelAspectRatio():Float
	{
		return 1;
	}

	public function getPlaying():Bool
	{
		return false;
	}

	public function getRotation():Int
	{
		return 0;
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

	public function setClockMode(value:VideoClockMode):VideoClockMode
	{
		return value;
	}

	public function setCurrentTime(value:Int):Int
	{
		return value;
	}

	public function setDropLateFrames(value:Bool):Bool
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

	public function setPan(value:Float):Float
	{
		return value;
	}

	public function stop():Void {}
}
