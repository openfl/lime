package media;

import haxe.Timer;
import lime.media.CameraInput;
import lime.media.CameraInputDevice;
import lime.media.CameraPosition;
import lime.media.VideoFrame;
import lime.media.VideoFrameFormat;
import lime.system.PermissionStatus;
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	`CameraInput`, `CameraInputDevice` and `CameraPosition`.

	Opening a camera turns its light on, so frames are only captured where
	`LIME_TEST_CAMERA` is `1`. Elsewhere, as on CI, which has no camera, the
	tests check what needs none: the values asked for, the devices listed,
	the permission, and that a camera that cannot be opened is reported
	through `onError`. On HTML5, `getUserMedia` and `enumerateDevices` are
	stood in for by a canvas stream.
**/
class CameraInputTest extends Test
{
	private var input:CameraInput;
	private var permissionListener:PermissionStatus->Void;

	#if (js && html5)
	private var canvasTimer:Timer;
	private var mediaDevices:Dynamic;
	#end

	public function new()
	{
		super();
	}

	public function teardown():Void
	{
		if (input != null)
		{
			input.dispose();
			input = null;
		}

		if (permissionListener != null)
		{
			CameraInput.onPermission.remove(permissionListener);
			permissionListener = null;
		}

		#if (js && html5)
		if (canvasTimer != null)
		{
			canvasTimer.stop();
			canvasTimer = null;
		}

		if (mediaDevices != null)
		{
			// Removes the stubs, which uncovers the browser's own
			js.Syntax.code("delete {0}.getUserMedia; delete {0}.enumerateDevices", mediaDevices);
			mediaDevices = null;
		}

		@:privateAccess lime._internal.backend.html5.HTML5CameraInput.cachedDevices = null;
		@:privateAccess lime._internal.backend.html5.HTML5CameraInput.permissionState = UNDETERMINED;
		#end
	}

	public function testPositionsHaveTheirNames():Void
	{
		Assert.equals("front", (CameraPosition.FRONT : String));
		Assert.equals("back", (CameraPosition.BACK : String));
		Assert.equals("unknown", (CameraPosition.UNKNOWN : String));
	}

	public function testADeviceWithoutAnIdUsesItsName():Void
	{
		var device = new CameraInputDevice("Camera");
		Assert.equals("Camera", device.name);
		Assert.equals("Camera", device.id);
		Assert.equals(CameraPosition.UNKNOWN, device.position);
		Assert.isFalse(device.isDefault);

		device = new CameraInputDevice("Front Camera", "1", null, true);
		Assert.equals("1", device.id);
		Assert.equals(CameraPosition.UNKNOWN, device.position);
		Assert.isTrue(device.isDefault);

		Assert.equals(CameraPosition.BACK, new CameraInputDevice("Back Camera", "0", BACK).position);
	}

	public function testAnInputHoldsWhatWasAskedForUntilItStarts():Void
	{
		input = new CameraInput(null, 1280, 720, 15, RGBA);
		Assert.equals(1280, input.width);
		Assert.equals(720, input.height);
		Assert.equals(15.0, input.frameRate);
		Assert.equals(VideoFrameFormat.RGBA, input.format);
		Assert.isFalse(input.running);
		Assert.notNull(input.onDisconnect);
		Assert.notNull(input.onError);
	}

	public function testAnInputAsksFor640By480At30InNV12ByDefault():Void
	{
		input = new CameraInput();
		Assert.equals(640, input.width);
		Assert.equals(480, input.height);
		Assert.equals(30.0, input.frameRate);
		Assert.equals(VideoFrameFormat.NV12, input.format);

		// What cannot be asked for falls back to the same
		input.dispose();
		input = new CameraInput(null, 0, -1, 0);
		Assert.equals(640, input.width);
		Assert.equals(480, input.height);
		Assert.equals(30.0, input.frameRate);
	}

	public function testAnInputUsesTheDefaultCameraWhenGivenNone():Void
	{
		input = new CameraInput();
		var defaultDevice = CameraInput.defaultDevice;

		if (defaultDevice == null)
		{
			Assert.isNull(input.device);
		}
		else
		{
			Assert.notNull(input.device);
			if (input.device != null) Assert.equals(defaultDevice.id, input.device.id);
		}
	}

	public function testNoFrameIsReadBeforeStarting():Void
	{
		input = new CameraInput();
		var frame = new VideoFrame();
		Assert.isFalse(input.readFrame(frame));
		Assert.isFalse(input.readFrame(null));

		input.dispose();
		input.start();
		Assert.isFalse(input.running, "a disposed input started");
		Assert.isFalse(input.readFrame(frame));
		input = null;
	}

	public function testTheDefaultCameraIsListedFirst():Void
	{
		var devices = CameraInput.devices;
		Assert.notNull(devices);

		if (devices.length == 0)
		{
			Assert.isNull(CameraInput.defaultDevice);
			return;
		}

		var ids = new Map<String, Bool>();

		for (i in 0...devices.length)
		{
			var device = devices[i];
			Assert.equals(i == 0, device.isDefault, device.name + (i == 0 ? " is first but not the default" : " is the default but not first"));
			Assert.isTrue(device.name != null && device.name != "", "a camera has no name");
			Assert.notNull(device.id, device.name + " has no id");
			Assert.isTrue(device.position == FRONT || device.position == BACK || device.position == UNKNOWN, device.name + " faces " + device.position);
			Assert.isFalse(ids.exists(device.id), device.id + " is listed twice");
			ids.set(device.id, true);
		}

		Assert.notNull(CameraInput.defaultDevice);
		if (CameraInput.defaultDevice != null) Assert.equals(devices[0].id, CameraInput.defaultDevice.id);
	}

	public function testThePermissionStatusIsOneOfTheThree():Void
	{
		var status = CameraInput.permissionStatus;
		Assert.isTrue(status == GRANTED || status == DENIED || status == UNDETERMINED, "the status was " + status);
	}

	#if flash
	public function testFlashCannotCapture(async:Async):Void
	{
		Assert.isFalse(CameraInput.isSupported);
		Assert.equals(0, CameraInput.devices.length);

		var errors = [];
		input = new CameraInput();
		input.onError.add(function(message) errors.push(message));
		input.start();
		Assert.isFalse(input.running);
		Assert.equals(1, errors.length, "onError was not dispatched");

		permissionListener = function(status) {
			Assert.equals(PermissionStatus.DENIED, status);
			async.done();
		};
		CameraInput.onPermission.add(permissionListener);
		CameraInput.requestPermission();
	}
	#end

	#if (lime_cffi && !macro)
	public function testACameraThatCannotBeOpenedIsReportedThroughOnError():Void
	{
		// No camera has this id, so nothing is opened, on any machine
		var errors = [];
		input = new CameraInput(new CameraInputDevice("Missing", "\\\\?\\lime-test-no-such-camera"));
		input.onError.add(function(message) errors.push(message));

		try
		{
			input.start();
		}
		catch (error:Dynamic)
		{
			Assert.fail("start() threw " + error);
			return;
		}

		Assert.isFalse(input.running, "a camera that does not exist started");
		Assert.equals(1, errors.length, "onError was not dispatched once");
		if (errors.length > 0) Assert.isTrue(errors[0] != null && errors[0] != "", "onError has no message");
		Assert.isFalse(input.readFrame(new VideoFrame()));

		// The values asked for are kept
		Assert.equals(640, input.width);
		Assert.equals(480, input.height);
	}

	public function testStartingWithoutACameraIsReportedThroughOnError():Void
	{
		if (CameraInput.devices.length > 0)
		{
			// utest takes a warning as a failure, so the test passes, saying why
			trace("There is a camera, which this test does not open");
			Assert.pass();
			return;
		}

		var errors = [];
		input = new CameraInput();
		input.onError.add(function(message) errors.push(message));
		input.start();

		Assert.isFalse(input.running);
		Assert.equals(1, errors.length, "onError was not dispatched once");
	}

	#if (windows || linux || mac)
	public function testListingTheCamerasDoesNotOpenThem():Void
	{
		// Listing is quick, as it only asks the system which cameras there are
		var start = Timer.stamp();
		CameraInput.devices;
		Assert.isTrue(Timer.stamp() - start < 5, "listing the cameras took " + (Timer.stamp() - start) + " s");
	}
	#end

	#if windows
	public function testWindowsReportsWhatThePrivacySettingsSay():Void
	{
		// Desktop applications are refused the camera where either of these is "Deny"
		var store = "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\CapabilityAccessManager\\ConsentStore\\webcam";
		var denied = registryValue(store) == "Deny" || registryValue(store + "\\NonPackaged") == "Deny";

		Assert.equals(denied ? PermissionStatus.DENIED : PermissionStatus.GRANTED, CameraInput.permissionStatus);
	}

	private static function registryValue(key:String):String
	{
		// HashLink starts a process by its path, without looking through PATH
		var root = Sys.getEnv("SystemRoot");
		var path = root != null ? root + "\\System32\\reg.exe" : null;
		var executable = path != null && sys.FileSystem.exists(path) ? path : "reg";

		var process = new sys.io.Process(executable, ["query", key, "/v", "Value"]);
		var output = process.stdout.readAll().toString();
		process.exitCode();
		process.close();

		// "    Value    REG_SZ    Allow"
		var pattern = ~/Value\s+REG_SZ\s+(\S+)/;
		return pattern.match(output) ? pattern.matched(1) : null;
	}
	#end

	#if (windows || linux)
	@:timeout(5000)
	public function testEachRequestIsAnsweredOnceOnALaterUpdate(async:Async):Void
	{
		// Desktops without a prompt answer at once with the status
		var answers = [];
		var requesting = false;
		var answeredDuringRequest = false;

		permissionListener = function(status:PermissionStatus)
		{
			if (requesting) answeredDuringRequest = true;
			answers.push(status);
		};
		CameraInput.onPermission.add(permissionListener);

		requesting = true;
		CameraInput.requestPermission();
		CameraInput.requestPermission();
		requesting = false;

		Assert.isFalse(answeredDuringRequest, "onPermission was dispatched inside requestPermission()");
		Assert.same([], answers);

		Timer.delay(function()
		{
			var answer = CameraInput.permissionStatus == GRANTED ? PermissionStatus.GRANTED : PermissionStatus.DENIED;
			Assert.same([answer, answer], answers);
			async.done();
		}, 1000);
	}
	#end

	@:timeout(20000)
	public function testFramesComeInNV12AtTheSizeTheCameraGives(async:Async):Void
	{
		if (!canCapture())
		{
			async.done();
			return;
		}

		input = new CameraInput(null, 640, 480, 30, NV12);
		capture(async, function(frames, seconds)
		{
			var frame = frames[frames.length - 1];
			Assert.equals(VideoFrameFormat.NV12, frame.format);
			Assert.equals(input.width, frame.width);
			Assert.equals(input.height, frame.height);
			// A full size luma plane, and a half size plane of chroma pairs
			Assert.equals(frame.width * frame.height + Std.int((frame.width + 1) / 2) * Std.int((frame.height + 1) / 2) * 2, frame.length);
			Assert.notNull(frame.data);
			if (frame.data != null) Assert.isTrue(frame.data.length >= frame.length, "the data is shorter than the frame");
			Assert.isNull(frame.src);

			// Webcams slow down in low light, so only a fraction of the rate is asked of them
			Assert.isTrue(frames.length / seconds > input.frameRate * 0.3,
				frames.length + " frames came in " + seconds + " s at " + input.frameRate + " frames a second");
		});
	}

	@:timeout(20000)
	public function testFramesComeInEachRGBLayout(async:Async):Void
	{
		if (!canCapture())
		{
			async.done();
			return;
		}

		var formats:Array<VideoFrameFormat> = [RGBA, BGRA, ARGB, TEXTURE];
		var next = 0;

		var tryNext = null;
		tryNext = function()
		{
			if (next >= formats.length)
			{
				async.done();
				return;
			}

			var format = formats[next++];
			if (input != null) input.dispose();
			input = new CameraInput(null, 1280, 720, 30, format);

			capture(null, function(frames, seconds)
			{
				var frame = frames[frames.length - 1];
				// Native frames are in memory, so a texture is read as RGBA
				Assert.equals(format == TEXTURE ? VideoFrameFormat.RGBA : format, frame.format, "the frame asked for in " + format);
				Assert.equals(input.width * input.height * 4, frame.length, format + "'s length");
			}, tryNext);
		};

		tryNext();
	}

	@:timeout(20000)
	public function testTheSizeAndRateAreTheCamerasOwnOnceOpen(async:Async):Void
	{
		if (!canCapture())
		{
			async.done();
			return;
		}

		// Few cameras give exactly this, so they give what is nearest
		input = new CameraInput(null, 321, 241, 7, BGRA);
		capture(async, function(frames, seconds)
		{
			Assert.isTrue(input.width > 0 && input.height > 0);
			Assert.isTrue(input.frameRate > 0);
			var frame = frames[frames.length - 1];
			Assert.equals(input.width, frame.width);
			Assert.equals(input.height, frame.height);
		});
	}

	@:timeout(25000)
	public function testStoppingAndStartingCarriesOn(async:Async):Void
	{
		if (!canCapture())
		{
			async.done();
			return;
		}

		input = new CameraInput();
		capture(null, function(frames, seconds) {}, function()
		{
			Assert.isFalse(input.running);
			Assert.isFalse(input.readFrame(new VideoFrame()), "a frame was read while stopped");

			capture(async, function(frames, seconds)
			{
				Assert.isTrue(frames.length > 0);
			});
		});
	}

	/**
		Starts `input` and reads frames for two seconds after the first, checks
		each is newer than the last and is only read once, then calls `check`
		with copies of what was read, stops the input, and calls `done` or
		finishes `async`.
	**/
	private function capture(async:Async, check:Array<VideoFrame>->Float->Void, ?done:Void->Void):Void
	{
		var errors = [];
		var onError = function(message) errors.push(message);
		input.onError.add(onError);
		input.start();
		input.onError.remove(onError);

		Assert.isTrue(input.running, "the camera did not start: " + errors.join(", "));

		var finish = function()
		{
			input.stop();
			if (done != null) done();
			if (async != null) async.done();
		};

		if (!input.running)
		{
			finish();
			return;
		}

		var frame = new VideoFrame();
		var frames:Array<VideoFrame> = [];
		var first = -1.0;
		var end = Timer.stamp() + 8;
		var timer = new Timer(5);

		timer.run = function()
		{
			var now = Timer.stamp();

			if (input.readFrame(frame))
			{
				if (frames.length > 0) Assert.isTrue(frame.time > frames[frames.length - 1].time, "a frame's time is not after the last one's");
				// Only a frame newer than the last read is read
				if (frames.length == 0) Assert.isFalse(input.readFrame(frame), "the same frame was read twice");

				var copy = new VideoFrame();
				copy.data = frame.data;
				copy.format = frame.format;
				copy.height = frame.height;
				copy.length = frame.length;
				copy.src = frame.src;
				copy.time = frame.time;
				copy.width = frame.width;
				frames.push(copy);

				if (first < 0) first = now;
			}

			if ((first >= 0 && now - first >= 2) || now > end)
			{
				timer.stop();
				Assert.isTrue(frames.length > 0, "no frame came");
				if (frames.length > 0) check(frames, first >= 0 ? now - first : 0);
				finish();
			}
		};
	}

	private static function canCapture():Bool
	{
		if (Sys.getEnv("LIME_TEST_CAMERA") != "1")
		{
			trace("LIME_TEST_CAMERA is not 1, so the camera was not opened");
			Assert.pass();
			return false;
		}

		if (CameraInput.devices.length == 0)
		{
			trace("There is no camera, so nothing was captured");
			Assert.pass();
			return false;
		}

		return true;
	}
	#end

	#if (js && html5)
	@:timeout(5000)
	public function testTheCameraIsAskedForTheSizeAndRate(async:Async):Void
	{
		var constraints:Dynamic = null;
		if (!stubCamera(function(value) constraints = value, null))
		{
			async.done();
			return;
		}

		input = new CameraInput(null, 320, 240, 24);
		Assert.isFalse(input.running);
		input.start();
		// The browser hands the camera over after start returns
		Assert.isFalse(input.running);

		whenRunning(async, function()
		{
			Assert.notNull(constraints, "getUserMedia was not called");
			if (constraints == null) return;

			Assert.equals(320, constraints.video.width.ideal);
			Assert.equals(240, constraints.video.height.ideal);
			Assert.equals(24, constraints.video.frameRate.ideal);
			Assert.isNull(constraints.video.deviceId, "the default camera was asked for by id");

			// What the track says it gives
			Assert.equals(320, input.width);
			Assert.equals(240, input.height);
			Assert.equals(30.0, input.frameRate);
		});
	}

	@:timeout(5000)
	public function testANamedCameraIsAskedForByItsId(async:Async):Void
	{
		var constraints:Dynamic = null;
		if (!stubCamera(function(value) constraints = value, null))
		{
			async.done();
			return;
		}

		input = new CameraInput(new CameraInputDevice("Second Camera", "second-camera-id", UNKNOWN, false));
		input.start();

		whenRunning(async, function()
		{
			Assert.notNull(constraints, "getUserMedia was not called");
			if (constraints != null) Assert.equals("second-camera-id", constraints.video.deviceId.exact);
		});
	}

	@:timeout(5000)
	public function testFramesCarryTheVideoElement(async:Async):Void
	{
		if (!stubCamera(function(_) {}, null))
		{
			async.done();
			return;
		}

		input = new CameraInput();
		input.start();

		whenRunning(async, function() {}, function(done)
		{
			// The element has a picture once the stream's first frame has played
			var frame = new VideoFrame();
			var end = Timer.stamp() + 3;
			var timer = new Timer(20);

			timer.run = function()
			{
				var read = input.readFrame(frame);

				if (read || Timer.stamp() > end)
				{
					timer.stop();
					Assert.isTrue(read, "no frame came");

					if (read)
					{
						Assert.equals(VideoFrameFormat.RGBA, frame.format);
						Assert.isNull(frame.data);
						Assert.equals(0, frame.length);
						Assert.notNull(frame.src);
						Assert.equals("VIDEO", frame.src != null ? (frame.src : Dynamic).nodeName : null);
						Assert.equals(320, frame.width);
						Assert.equals(240, frame.height);
						Assert.isFalse(input.readFrame(frame), "the same frame was read twice");
					}

					input.stop();
					Assert.isFalse(input.running);
					Assert.isFalse(input.readFrame(frame), "a frame was read while stopped");
					done();
				}
			};
		});
	}

	@:timeout(5000)
	public function testTheCamerasAreListedWithTheWayTheyFace(async:Async):Void
	{
		if (!stubCamera(function(_) {}, null))
		{
			async.done();
			return;
		}

		// A listing an earlier test started from the browser itself may still come in, so it is let finish
		Timer.delay(function()
		{
			@:privateAccess lime._internal.backend.html5.HTML5CameraInput.cachedDevices = null;
			@:privateAccess lime._internal.backend.html5.HTML5CameraInput.enumeratingDevices = false;

			// The first read starts listing them, and later reads have the list
			CameraInput.devices;
			Timer.delay(checkListedCameras.bind(async), 300);
		}, 300);
	}

	private function checkListedCameras(async:Async):Void
	{
		var devices = CameraInput.devices;
		Assert.equals(2, devices.length);

		if (devices.length == 2)
		{
			Assert.equals("Stand-in Front Camera", devices[0].name);
			Assert.equals("front-camera-id", devices[0].id);
			Assert.equals(CameraPosition.FRONT, devices[0].position);
			Assert.isTrue(devices[0].isDefault);
			Assert.equals(CameraPosition.BACK, devices[1].position);
			Assert.isFalse(devices[1].isDefault);
		}

		async.done();
	}

	@:timeout(5000)
	public function testARefusedCameraIsReportedThroughOnError(async:Async):Void
	{
		if (!stubCamera(function(_) {}, "NotAllowedError"))
		{
			async.done();
			return;
		}

		var errors = [];
		var answers = [];
		permissionListener = function(status) answers.push(status);
		CameraInput.onPermission.add(permissionListener);

		input = new CameraInput();
		input.onError.add(function(message) errors.push(message));
		input.start();

		Timer.delay(function()
		{
			Assert.isFalse(input.running);
			Assert.equals(1, errors.length, "onError was not dispatched once");
			Assert.equals(PermissionStatus.DENIED, CameraInput.permissionStatus);
			Assert.same([PermissionStatus.DENIED], answers);
			async.done();
		}, 500);
	}

	@:timeout(5000)
	public function testAMissingCameraIsNotARefusal(async:Async):Void
	{
		if (!stubCamera(function(_) {}, "NotFoundError"))
		{
			async.done();
			return;
		}

		var errors = [];
		input = new CameraInput();
		input.onError.add(function(message) errors.push(message));
		input.start();

		Timer.delay(function()
		{
			Assert.isFalse(input.running);
			Assert.equals(1, errors.length, "onError was not dispatched once");
			Assert.equals(PermissionStatus.UNDETERMINED, CameraInput.permissionStatus);
			async.done();
		}, 500);
	}

	@:timeout(5000)
	public function testAnEndedTrackDisconnectsTheInput(async:Async):Void
	{
		var stream:Dynamic = null;
		if (!stubCamera(function(_) {}, null, function(value) stream = value))
		{
			async.done();
			return;
		}

		var disconnects = 0;
		input = new CameraInput();
		input.onDisconnect.add(function() disconnects++);
		input.start();

		whenRunning(async, function()
		{
			// A track ends this way when its camera is unplugged
			var track:Dynamic = stream.getVideoTracks()[0];
			track.dispatchEvent(new js.html.Event("ended"));

			Assert.equals(1, disconnects, "onDisconnect was not dispatched once");
			Assert.isFalse(input.running);
		});
	}

	/**
		Stands in for the browser: getUserMedia passes its constraints to
		`record` and opens a 320 by 240 canvas stream, or fails with
		`errorName`, and enumerateDevices lists a front and a back camera.
	**/
	private function stubCamera(record:Dynamic->Void, errorName:String, ?opened:Dynamic->Void):Bool
	{
		var navigator:Dynamic = js.Browser.navigator;
		var canvas:Dynamic = js.Browser.document.createElement("canvas");

		if (navigator.mediaDevices == null || canvas.captureStream == null)
		{
			// Only secure contexts have mediaDevices. utest takes a warning as a
			// failure, so the test passes, saying why
			trace("navigator.mediaDevices or captureStream is not available, so the camera was not stood in for");
			Assert.pass();
			return false;
		}

		canvas.width = 320;
		canvas.height = 240;
		var context:Dynamic = canvas.getContext("2d");
		var shade = 0;

		// A canvas stream only has frames while the canvas is drawn to
		canvasTimer = new Timer(33);
		canvasTimer.run = function()
		{
			shade = (shade + 16) % 256;
			context.fillStyle = "rgb(" + shade + ",0,0)";
			context.fillRect(0, 0, 320, 240);
		};
		canvasTimer.run();

		mediaDevices = navigator.mediaDevices;
		mediaDevices.getUserMedia = function(constraints:Dynamic):Dynamic
		{
			record(constraints);

			if (errorName != null)
			{
				return js.lib.Promise.reject(js.Syntax.code("new DOMException('Stand-in answer', {0})", errorName));
			}

			var stream:Dynamic = canvas.captureStream(30);
			var track:Dynamic = stream.getVideoTracks()[0];
			track.getSettings = function() return {width: 320, height: 240, frameRate: 30};
			if (opened != null) opened(stream);
			return js.lib.Promise.resolve(stream);
		};

		mediaDevices.enumerateDevices = function():Dynamic
		{
			return js.lib.Promise.resolve([
				{kind: "audioinput", label: "Microphone", deviceId: "microphone-id"},
				{
					kind: "videoinput",
					label: "Stand-in Front Camera",
					deviceId: "front-camera-id",
					getCapabilities: function() return {facingMode: ["user"]}
				},
				{
					kind: "videoinput",
					label: "Stand-in Back Camera",
					deviceId: "back-camera-id",
					getCapabilities: function() return {facingMode: ["environment"]}
				}
			]);
		};

		@:privateAccess lime._internal.backend.html5.HTML5CameraInput.cachedDevices = null;
		@:privateAccess lime._internal.backend.html5.HTML5CameraInput.enumeratingDevices = false;
		@:privateAccess lime._internal.backend.html5.HTML5CameraInput.permissionState = UNDETERMINED;
		return true;
	}

	/**
		Calls `check` once the input runs, then `then` with a function that
		finishes `async`, or finishes it after `check` when there is no `then`.
	**/
	private function whenRunning(async:Async, check:Void->Void, ?then:(Void->Void)->Void):Void
	{
		var end = Timer.stamp() + 3;
		var timer = new Timer(20);

		timer.run = function()
		{
			if (input.running || Timer.stamp() > end)
			{
				timer.stop();
				Assert.isTrue(input.running, "the camera did not start");

				if (!input.running)
				{
					async.done();
					return;
				}

				check();
				if (then != null) then(function() async.done()) else async.done();
			}
		};
	}
	#end
}
