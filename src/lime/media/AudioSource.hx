package lime.media;

import lime.app.Event;
import lime.media.openal.AL;
import lime.media.openal.ALSource;
import lime.math.Vector4;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class AudioSource
{
	public var onComplete = new Event<Void->Void>();
	public var buffer:AudioBuffer;
	public var currentTime(get, set):Int;
	public var gain(get, set):Float;
	public var length(get, set):Int;
	public var loops(get, set):Int;
	public var offset:Int;
	public var position(get, set):Vector4;

	@:noCompletion private var __backend:AudioSourceBackend;

	public function new(buffer:AudioBuffer = null, offset:Int = 0, length:Null<Int> = null, loops:Int = 0)
	{
		this.buffer = buffer;
		this.offset = offset;

		__backend = new AudioSourceBackend(this);

		if (length != null && length != 0)
		{
			this.length = length;
		}

		this.loops = loops;

		if (buffer != null)
		{
			init();
		}
	}

	
	public function dispose():Void
	{
		if (__backend != null)
			__backend.dispose();
	}

	@:noCompletion private function init():Void
	{
		if (__backend != null)
			__backend.init();
	}

	public function play():Void
	{
		if (__backend != null)
			__backend.play();
	}

	public function pause():Void
	{
		if (__backend != null)
			__backend.pause();
	}

	public function stop():Void
	{
		if (__backend != null)
			__backend.stop();
	}

	// Get & Set Methods
	@:noCompletion private function get_currentTime():Int
	{
		if (__backend != null)
		{
			return __backend.getCurrentTime();
		}

		return 0;
	}

	@:noCompletion private function set_currentTime(value:Int):Int
	{
		if (__backend != null)
		{
			return __backend.setCurrentTime(value);
		}

		return get_currentTime();
	}

	@:noCompletion private function get_gain():Float
	{
		if (__backend != null)
		{
			return __backend.getGain();
		}

		return 1;
	}

	@:noCompletion private function set_gain(value:Float):Float
	{
		if (__backend != null)
		{
			return __backend.setGain(value);
		}

		return get_gain();
	}

	@:noCompletion private function get_length():Int
	{
		if (__backend != null)
		{
			return __backend.getLength();
		}

		return 0;
	}

	@:noCompletion private function set_length(value:Int):Int
	{
		if (__backend != null)
		{
			return __backend.setLength(value);
		}

		return get_length();
	}

	@:noCompletion private function get_loops():Int
	{
		if (__backend != null)
		{
			return __backend.getLoops();
		}

		return 0;
	}

	@:noCompletion private function set_loops(value:Int):Int
	{
		if (__backend != null)
		{
			return __backend.setLoops(value);
		}

		return get_loops();
	}

	@:noCompletion private function get_position():Vector4
	{
		if (__backend != null)
		{
			return __backend.getPosition();
		}

		return 0;
	}

	@:noCompletion private function set_position(value:Vector4):Vector4
	{
		if (__backend != null)
		{
			return __backend.setPosition(value);
		}

		return get_position();
	}

#if flash
@:noCompletion private typedef AudioSourceBackend = lime._internal.backend.flash.FlashAudioSource;
#elseif (js && html5)
@:noCompletion private typedef AudioSourceBackend = lime._internal.backend.html5.HTML5AudioSource;
#else
@:noCompletion private typedef AudioSourceBackend = lime._internal.backend.native.NativeAudioSource;
#end
