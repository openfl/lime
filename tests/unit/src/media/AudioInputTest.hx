package media;

#if (lime_cffi && lime_openal && !macro)
import lime.media.AudioInput;
import lime.media.openal.ALC;
#end
import utest.Assert;
import utest.Test;

/**
	OpenAL's null output, which the tests use, has no capture devices, so these
	only see more than one where the machine has them.
**/
class AudioInputTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_openal && !macro)
	public function testEveryCaptureDeviceIsListed():Void
	{
		var names = ALC.getStringList(null, ALC.CAPTURE_DEVICE_SPECIFIER);

		// The default device is added when OpenAL leaves it out of the list
		var listed = [for (device in AudioInput.devices) if (names.indexOf(device.name) >= 0) device.name];
		Assert.same(names, listed);
	}

	public function testOnlyTheDefaultDeviceIsMarkedDefault():Void
	{
		var defaultDevice = AudioInput.defaultDevice;
		var marked = [for (device in AudioInput.devices) if (device.isDefault) device.name];

		Assert.same(defaultDevice != null ? [defaultDevice.name] : [], marked);
	}
	#end
}
