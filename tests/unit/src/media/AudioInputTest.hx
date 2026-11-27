package media;

import haxe.Timer;
import lime.media.AudioInput;
import lime.system.PermissionStatus;
#if (lime_cffi && lime_openal && !macro)
import lime.media.openal.ALC;
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	OpenAL's null output, which the tests use, has no capture devices, so these
	only see more than one where the machine has them.
**/
class AudioInputTest extends Test
{
	private var permissionListener:PermissionStatus->Void;

	#if (js && html5)
	private var input:AudioInput;
	private var mediaDevices:Dynamic;
	private var previousPermissionState:PermissionStatus;
	#end

	public function new()
	{
		super();
	}

	public function teardown():Void
	{
		if (permissionListener != null)
		{
			AudioInput.onPermission.remove(permissionListener);
			permissionListener = null;
		}

		#if (js && html5)
		if (input != null)
		{
			input.dispose();
			input = null;
		}

		if (mediaDevices != null)
		{
			// Removes the stub, which uncovers the browser's own getUserMedia
			js.Syntax.code("delete {0}.getUserMedia", mediaDevices);
			mediaDevices = null;
		}

		if (previousPermissionState != null)
		{
			@:privateAccess lime._internal.backend.html5.HTML5AudioInput.permissionState = previousPermissionState;
			previousPermissionState = null;
		}
		#end
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

	public function testPermissionStatusesUseFlashsNames():Void
	{
		// OpenFL passes these on as flash.permissions.PermissionStatus
		Assert.equals("granted", (PermissionStatus.GRANTED : String));
		Assert.equals("denied", (PermissionStatus.DENIED : String));
		Assert.equals("undetermined", (PermissionStatus.UNDETERMINED : String));
	}

	public function testThePermissionStatusIsOneOfTheThree():Void
	{
		// Also where capture is not supported, as on a machine without a microphone
		var status = AudioInput.permissionStatus;
		Assert.isTrue(status == GRANTED || status == DENIED || status == UNDETERMINED, "the status was " + status);
	}

	#if (lime_cffi && (windows || linux) && !macro)
	public function testDesktopsWithoutAPromptReportGranted():Void
	{
		Assert.equals(PermissionStatus.GRANTED, AudioInput.permissionStatus);
	}

	@:timeout(5000)
	public function testEachRequestIsAnsweredOnceOnALaterUpdate(async:Async):Void
	{
		var answers = [];
		var requesting = false;
		var answeredDuringRequest = false;

		permissionListener = function(status:PermissionStatus)
		{
			if (requesting) answeredDuringRequest = true;
			answers.push(status);
		};
		AudioInput.onPermission.add(permissionListener);

		// Also where capture is not supported
		requesting = true;
		AudioInput.requestPermission();
		AudioInput.requestPermission();
		requesting = false;

		Assert.isFalse(answeredDuringRequest, "onPermission was dispatched inside requestPermission()");
		Assert.same([], answers);

		// Long enough for the answers to come, and for any extra ones to show up
		Timer.delay(function()
		{
			Assert.same([PermissionStatus.GRANTED, PermissionStatus.GRANTED], answers);
			Assert.equals(PermissionStatus.GRANTED, AudioInput.permissionStatus);
			async.done();
		}, 1000);
	}
	#end

	#if (js && html5)
	@:timeout(5000)
	public function testARefusedRequestReportsDenied(async:Async):Void
	{
		if (!stubGetUserMedia("NotAllowedError"))
		{
			async.done();
			return;
		}

		expectAnswers([PermissionStatus.DENIED], async, function()
		{
			Assert.equals(PermissionStatus.DENIED, AudioInput.permissionStatus);
		});

		AudioInput.requestPermission();
	}

	@:timeout(5000)
	public function testARefusedStartReportsDenied(async:Async):Void
	{
		if (!stubGetUserMedia("NotAllowedError"))
		{
			async.done();
			return;
		}

		expectAnswers([PermissionStatus.DENIED], async, function()
		{
			Assert.equals(PermissionStatus.DENIED, AudioInput.permissionStatus);
			Assert.isFalse(input.running);
		});

		input = new AudioInput();
		input.start();
	}

	@:timeout(5000)
	public function testAMissingMicrophoneIsNotADenial(async:Async):Void
	{
		if (!stubGetUserMedia("NotFoundError"))
		{
			async.done();
			return;
		}

		expectAnswers([PermissionStatus.DENIED], async, function()
		{
			Assert.equals(PermissionStatus.UNDETERMINED, AudioInput.permissionStatus);
		});

		AudioInput.requestPermission();
	}

	@:timeout(5000)
	public function testAnAllowedRequestReportsGranted(async:Async):Void
	{
		if (!stubGetUserMedia(null))
		{
			async.done();
			return;
		}

		expectAnswers([PermissionStatus.GRANTED], async, function()
		{
			Assert.equals(PermissionStatus.GRANTED, AudioInput.permissionStatus);
		});

		AudioInput.requestPermission();
	}

	/**
		Stands in for the browser's prompt: getUserMedia fails with `errorName`,
		or opens a stream with no tracks when it is `null`. The status is set back
		to undetermined, as before the user is asked.
	**/
	private function stubGetUserMedia(errorName:String):Bool
	{
		var navigator:Dynamic = js.Browser.navigator;

		if (navigator.mediaDevices == null)
		{
			// Only secure contexts have mediaDevices. utest takes a warning as a
			// failure, so the test passes, saying why
			trace("navigator.mediaDevices is not available, so the browser's answers were not stood in for");
			Assert.pass();
			return false;
		}

		// Reads the status once first, so the browser's permission query does not
		// overwrite the undetermined status set below while the test runs
		AudioInput.permissionStatus;

		mediaDevices = navigator.mediaDevices;
		mediaDevices.getUserMedia = function(constraints:Dynamic):Dynamic
		{
			if (errorName == null)
			{
				var stream = {getTracks: function() return []};
				return js.lib.Promise.resolve(stream);
			}

			return js.lib.Promise.reject(js.Syntax.code("new DOMException('Stand-in answer', {0})", errorName));
		};

		previousPermissionState = @:privateAccess lime._internal.backend.html5.HTML5AudioInput.permissionState;
		@:privateAccess lime._internal.backend.html5.HTML5AudioInput.permissionState = UNDETERMINED;
		return true;
	}

	private function expectAnswers(expected:Array<PermissionStatus>, async:Async, check:Void->Void):Void
	{
		var answers = [];

		permissionListener = function(status:PermissionStatus)
		{
			answers.push(status);
		};
		AudioInput.onPermission.add(permissionListener);

		// Long enough for the answer to come, and for any extra ones to show up
		Timer.delay(function()
		{
			Assert.same(expected, answers);
			check();
			async.done();
		}, 500);
	}
	#end
}
