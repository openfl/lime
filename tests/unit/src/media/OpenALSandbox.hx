package media;

#if (lime_cffi && lime_openal && !macro)
import haxe.PosInfos;
import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALC;
import lime.media.openal.ALContext;
import lime.media.openal.ALDevice;
import lime.utils.UInt8Array;
import utest.Assert;
#end

/**
	A device and a context of a test's own. OpenAL keeps its listener, its
	global state and its sources in the context, so a test that starts in a new
	one starts from the defaults the specification gives, whatever the suites
	before it left behind, and leaves the application's context as it was.
**/
class OpenALSandbox
{
	#if (lime_cffi && lime_openal && !macro)
	public static inline var SAMPLE_RATE = 22050;

	public var context(default, null):ALContext;
	public var device(default, null):ALDevice;

	private var previous:ALContext;

	private function new() {}

	/**
		Opens the default device again and makes a new context on it current.
		Returns null where there is no audio output to open.
	**/
	public static function open(attributes:Array<Int> = null):OpenALSandbox
	{
		var previous = ALC.getCurrentContext();
		if (previous == null) return null;

		var device = ALC.openDevice();
		if (device == null) return null;

		var context = ALC.createContext(device, attributes);

		if (context == null)
		{
			ALC.closeDevice(device);
			return null;
		}

		var sandbox = new OpenALSandbox();
		sandbox.previous = previous;
		sandbox.device = device;
		sandbox.context = context;

		ALC.makeContextCurrent(context);
		AL.getError();
		return sandbox;
	}

	public function close():Void
	{
		ALC.makeContextCurrent(previous);
		ALC.destroyContext(context);
		ALC.closeDevice(device);
	}

	/**
		A buffer of silence, 16-bit mono at 22050 Hz, that lasts `milliseconds`.
	**/
	public static function silence(milliseconds:Int):ALBuffer
	{
		var data = new UInt8Array(Std.int(SAMPLE_RATE * milliseconds / 1000) * 2);
		var buffer = AL.createBuffer();
		AL.bufferData(buffer, AL.FORMAT_MONO16, data, data.length, SAMPLE_RATE);
		return buffer;
	}

	/**
		Reads OpenAL's error, which clears it, and checks it is `expected`.
	**/
	public static function error(expected:Int, ?message:String, ?pos:PosInfos):Void
	{
		var actual = AL.getError();
		Assert.equals(errorName(expected), errorName(actual), message != null ? message + ": " + errorName(actual) : null, pos);
	}

	public static function errorName(error:Int):String
	{
		return switch (error)
		{
			case AL.NO_ERROR: "NO_ERROR";
			case AL.INVALID_NAME: "INVALID_NAME";
			case AL.INVALID_ENUM: "INVALID_ENUM";
			case AL.INVALID_VALUE: "INVALID_VALUE";
			case AL.INVALID_OPERATION: "INVALID_OPERATION";
			case AL.OUT_OF_MEMORY: "OUT_OF_MEMORY";
			default: "0x" + StringTools.hex(error);
		}
	}

	public static function floats(expected:Array<Float>, actual:Array<Float>, ?message:String, ?pos:PosInfos):Void
	{
		var described = (message != null ? message + ": " : "") + "expected " + expected + " but it was " + actual;

		if (actual == null || actual.length != expected.length)
		{
			Assert.fail(described, pos);
			return;
		}

		for (i in 0...expected.length)
		{
			var value:Null<Float> = actual[i];

			if (value == null || Math.abs(value - expected[i]) > 0.0001)
			{
				Assert.fail(described, pos);
				return;
			}
		}

		Assert.isTrue(true, null, pos);
	}

	public static function ints(expected:Array<Int>, actual:Array<Int>, ?message:String, ?pos:PosInfos):Void
	{
		var described = (message != null ? message + ": " : "") + "expected " + expected + " but it was " + actual;

		if (actual == null || actual.length != expected.length)
		{
			Assert.fail(described, pos);
			return;
		}

		for (i in 0...expected.length)
		{
			var value:Null<Int> = actual[i];

			if (value == null || value != expected[i])
			{
				Assert.fail(described, pos);
				return;
			}
		}

		Assert.isTrue(true, null, pos);
	}

	/**
		Waits until `source` is in `state`, or for `timeout` seconds. The null
		output plays in real time, as a sound card does.
	**/
	public static function waitForState(source:lime.media.openal.ALSource, state:Int, timeout:Float = 5):Bool
	{
		var end = haxe.Timer.stamp() + timeout;

		while (haxe.Timer.stamp() < end)
		{
			var current:Int = AL.getSourcei(source, AL.SOURCE_STATE);
			if (current == state) return true;
			Sys.sleep(0.005);
		}

		return false;
	}
	#end
}
