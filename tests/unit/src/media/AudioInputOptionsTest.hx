package media;

import haxe.Timer;
import haxe.io.Bytes;
import lime.media.AudioInput;
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	`AudioInput.echoCancellation`, `noiseSuppression` and `autoGain`.

	What the platform applies depends on the microphone and its driver, so the
	tests check what the options ask for, and what reads back once running only
	where it is certain. Capturing from a microphone only runs where
	`LIME_TEST_MICROPHONE` is `1`, as it opens the user's microphone.
	Elsewhere a start is only tried where there is no capture device, as on CI.
	On HTML5, `getUserMedia` is stood in for, as the browser asks the user.
**/
class AudioInputOptionsTest extends Test
{
	private var input:AudioInput;

	#if (js && html5)
	private var mediaDevices:Dynamic;
	private var streamContext:Dynamic;
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

		#if (js && html5)
		if (mediaDevices != null)
		{
			// Removes the stub, which uncovers the browser's own getUserMedia
			js.Syntax.code("delete {0}.getUserMedia", mediaDevices);
			mediaDevices = null;
		}

		if (streamContext != null)
		{
			streamContext.close();
			streamContext = null;
		}
		#end
	}

	public function testTheOptionsAreOffAtFirst():Void
	{
		input = new AudioInput();
		Assert.isFalse(input.echoCancellation);
		Assert.isFalse(input.noiseSuppression);
		Assert.isFalse(input.autoGain);
	}

	public function testEachOptionIsSetOnItsOwn():Void
	{
		input = new AudioInput();

		input.echoCancellation = true;
		assertOptions(true, false, false);
		input.noiseSuppression = true;
		assertOptions(true, true, false);
		input.autoGain = true;
		assertOptions(true, true, true);

		input.echoCancellation = false;
		assertOptions(false, true, true);
		input.autoGain = false;
		assertOptions(false, true, false);
		input.noiseSuppression = false;
		assertOptions(false, false, false);

		// Setting one twice leaves it set
		input.autoGain = true;
		input.autoGain = true;
		assertOptions(false, false, true);
	}

	public function testTheSetterReturnsTheValueSet():Void
	{
		input = new AudioInput();
		Assert.isTrue(input.echoCancellation = true);
		Assert.isFalse(input.noiseSuppression = false);
		Assert.isTrue(input.autoGain = true);
	}

	public function testADisposedInputReadsWhatWasAskedFor():Void
	{
		input = new AudioInput();
		input.noiseSuppression = true;
		input.dispose();
		assertOptions(false, true, false);
		input = null;
	}

	#if (lime_cffi && !macro)
	public function testStartingWithTheOptionsDoesNotThrow():Void
	{
		if (!canStart()) return;

		input = new AudioInput();
		input.echoCancellation = true;
		input.noiseSuppression = true;
		input.autoGain = true;

		try
		{
			input.start();
		}
		catch (error:Dynamic)
		{
			Assert.fail("start() threw " + error);
			return;
		}

		if (!input.running)
		{
			// Nothing captures, so they read what was asked for
			assertOptions(true, true, true);
			Assert.equals(0, input.read(Bytes.alloc(64), 16));
		}
		else
		{
			// A microphone the platform's voice mode found where OpenAL found none
			Assert.isTrue(input.samplesAvailable >= 0);
		}

		input.stop();
		assertOptions(true, true, true);
	}

	@:timeout(15000)
	public function testWithoutOptionsNothingIsApplied(async:Async):Void
	{
		if (!canCapture())
		{
			async.done();
			return;
		}

		// No option captures through OpenAL, which has no voice processing
		input = new AudioInput(null, 44100, 1, 16);
		capture(input, async, function(rate)
		{
			assertOptions(false, false, false, "while running without options");
			assertRate(44100, rate);
		});
	}

	@:timeout(15000)
	public function testTheOptionsCaptureAtTheSampleRate(async:Async):Void
	{
		if (!canCapture())
		{
			async.done();
			return;
		}

		input = new AudioInput(null, 16000, 1, 16);
		input.echoCancellation = true;
		input.noiseSuppression = true;
		input.autoGain = true;

		capture(input, async, function(rate)
		{
			assertRate(16000, rate);
			trace("Applied with all three asked: echoCancellation " + input.echoCancellation + ", noiseSuppression " + input.noiseSuppression
				+ ", autoGain " + input.autoGain);
		}, function()
		{
			// Stopped, they read what was asked for again
			assertOptions(true, true, true, "once stopped");
		});
	}

	@:timeout(15000)
	public function testTheOptionsCaptureEightBitStereo(async:Async):Void
	{
		if (!canCapture())
		{
			async.done();
			return;
		}

		input = new AudioInput(null, 48000, 2, 8);
		input.echoCancellation = true;

		capture(input, async, function(rate)
		{
			assertRate(48000, rate);
		});
	}

	@:timeout(25000)
	public function testClearingTheOptionsGoesBackToOpenAL(async:Async):Void
	{
		if (!canCapture())
		{
			async.done();
			return;
		}

		input = new AudioInput(null, 44100, 1, 16);
		input.echoCancellation = true;
		input.noiseSuppression = true;
		input.autoGain = true;

		capture(input, null, function(rate)
		{
			assertRate(44100, rate);
		}, function()
		{
			input.echoCancellation = false;
			input.noiseSuppression = false;
			input.autoGain = false;

			capture(input, async, function(rate)
			{
				// OpenAL captures again, with nothing applied
				assertOptions(false, false, false, "after the options were cleared");
				assertRate(44100, rate);
			});
		});
	}

	@:timeout(15000)
	public function testANamedDeviceCapturesWithTheOptions(async:Async):Void
	{
		if (!canCapture())
		{
			async.done();
			return;
		}

		var named = null;
		for (device in AudioInput.devices)
		{
			if (!device.isDefault) named = device;
		}

		if (named == null)
		{
			trace("There is only the default capture device, so a named one was not tried");
			Assert.pass();
			async.done();
			return;
		}

		input = new AudioInput(named, 16000, 1, 16);
		input.echoCancellation = true;

		capture(input, async, function(rate)
		{
			assertRate(16000, rate);
		});
	}

	/**
		Starts `input`, reads what it captures for two seconds after a moment
		to settle, calls `check` with the frames a second it read while still
		running, then stops it and calls `stopped`, and finishes `async`.
	**/
	private function capture(input:AudioInput, async:Async, check:Float->Void, ?stopped:Void->Void):Void
	{
		input.start();
		Assert.isTrue(input.running, "the input did not start");

		if (!input.running)
		{
			if (async != null) async.done();
			return;
		}

		var frameSize = Std.int(input.channels * input.bitsPerSample / 8);
		var buffer = Bytes.alloc(input.sampleRate * frameSize);
		var frames = 0;
		var start = -1.0;
		var settle = Timer.stamp() + 0.5;
		var timer = new Timer(20);

		timer.run = function()
		{
			var available = input.samplesAvailable;
			var read = available > 0 ? input.read(buffer, Std.int(Math.min(available, input.sampleRate))) : 0;
			var now = Timer.stamp();

			if (now < settle) return;

			if (start < 0)
			{
				// What came before is left out, as the device fills its buffer at first
				start = now;
				return;
			}

			frames += read;

			if (now - start >= 2)
			{
				timer.stop();
				Assert.isTrue(input.running, "the input stopped while capturing");
				check(frames / (now - start));
				input.stop();
				Assert.isFalse(input.running);
				if (stopped != null) stopped();
				if (async != null) async.done();
			}
		};
	}

	private static function assertRate(expected:Int, rate:Float):Void
	{
		// Reads come as the device hands over its buffers, so the rate over two seconds is near, not exact
		Assert.isTrue(rate > expected * 0.75 && rate < expected * 1.25, "captured " + Std.int(rate) + " frames a second where " + expected + " were asked for");
	}

	private static function canCapture():Bool
	{
		if (Sys.getEnv("LIME_TEST_MICROPHONE") != "1")
		{
			// utest takes a warning as a failure, so the test passes, saying why
			trace("LIME_TEST_MICROPHONE is not 1, so the microphone was not opened");
			Assert.pass();
			return false;
		}

		if (!AudioInput.isSupported)
		{
			trace("There is no capture device, so nothing was captured");
			Assert.pass();
			return false;
		}

		return true;
	}

	private static function canStart():Bool
	{
		// Starting opens the microphone, so it is only tried where there is none or the test asks for it
		if (AudioInput.isSupported && Sys.getEnv("LIME_TEST_MICROPHONE") != "1")
		{
			trace("LIME_TEST_MICROPHONE is not 1, so the microphone was not opened");
			Assert.pass();
			return false;
		}

		return true;
	}
	#end

	#if (js && html5)
	@:timeout(5000)
	public function testTheOptionsAreAskedOfTheBrowserAndReadFromTheTrack(async:Async):Void
	{
		var constraints:Dynamic = null;
		if (!stubGetUserMedia(function(value) constraints = value, {echoCancellation: true, noiseSuppression: false, autoGainControl: true}))
		{
			async.done();
			return;
		}

		input = new AudioInput();
		input.echoCancellation = true;
		input.noiseSuppression = true;
		input.autoGain = true;
		input.start();

		whenRunning(async, function()
		{
			Assert.notNull(constraints, "getUserMedia was not called");
			if (constraints != null)
			{
				Assert.isTrue(constraints.audio.echoCancellation == true);
				Assert.isTrue(constraints.audio.noiseSuppression == true);
				Assert.isTrue(constraints.audio.autoGainControl == true);
			}

			// The browser applied echo cancellation and gain, but not noise suppression
			assertOptions(true, false, true, "while running");

			input.stop();
			assertOptions(true, true, true, "once stopped");
		});
	}

	@:timeout(5000)
	public function testWithoutOptionsTheBrowserIsAskedForNone(async:Async):Void
	{
		var constraints:Dynamic = null;
		if (!stubGetUserMedia(function(value) constraints = value, {echoCancellation: false, noiseSuppression: false, autoGainControl: false}))
		{
			async.done();
			return;
		}

		input = new AudioInput();
		input.noiseSuppression = true;
		input.noiseSuppression = false;
		input.start();

		whenRunning(async, function()
		{
			Assert.notNull(constraints, "getUserMedia was not called");
			if (constraints != null)
			{
				Assert.isTrue(constraints.audio.echoCancellation == false);
				Assert.isTrue(constraints.audio.noiseSuppression == false);
				Assert.isTrue(constraints.audio.autoGainControl == false);
			}

			assertOptions(false, false, false, "while running");
		});
	}

	@:timeout(5000)
	public function testATrackWithoutSettingsReadsNoneApplied(async:Async):Void
	{
		// Older browsers have no getSettings, so nothing can be known to be applied
		if (!stubGetUserMedia(function(_) {}, null))
		{
			async.done();
			return;
		}

		input = new AudioInput();
		input.echoCancellation = true;
		input.start();

		whenRunning(async, function()
		{
			assertOptions(false, false, false, "while running");
		});
	}

	/**
		Stands in for the browser: getUserMedia passes its constraints to
		`record`, and opens a silent stream whose track's settings are
		`settings`, or which has no settings when it is `null`.
	**/
	private function stubGetUserMedia(record:Dynamic->Void, settings:Dynamic):Bool
	{
		var navigator:Dynamic = js.Browser.navigator;
		var AudioContextClass:Dynamic = js.Syntax.code("window.AudioContext || window.webkitAudioContext");

		if (navigator.mediaDevices == null || AudioContextClass == null)
		{
			// Only secure contexts have mediaDevices. utest takes a warning as a
			// failure, so the test passes, saying why
			trace("navigator.mediaDevices or AudioContext is not available, so the browser was not stood in for");
			Assert.pass();
			return false;
		}

		streamContext = js.Syntax.construct(AudioContextClass);
		var stream:Dynamic = streamContext.createMediaStreamDestination().stream;
		var track:Dynamic = stream.getAudioTracks()[0];
		track.getSettings = settings != null ? function() return settings : null;

		mediaDevices = navigator.mediaDevices;
		mediaDevices.getUserMedia = function(constraints:Dynamic):Dynamic
		{
			record(constraints);
			return js.lib.Promise.resolve(stream);
		};

		return true;
	}

	private function whenRunning(async:Async, check:Void->Void):Void
	{
		var end = Timer.stamp() + 3;
		var timer = new Timer(20);

		timer.run = function()
		{
			if (input.running || Timer.stamp() > end)
			{
				timer.stop();
				Assert.isTrue(input.running, "the input did not start");
				if (input.running) check();
				async.done();
			}
		};
	}
	#end

	private function assertOptions(echoCancellation:Bool, noiseSuppression:Bool, autoGain:Bool, ?when:String):Void
	{
		var suffix = when != null ? " " + when : "";
		Assert.equals(echoCancellation, input.echoCancellation, "echoCancellation" + suffix);
		Assert.equals(noiseSuppression, input.noiseSuppression, "noiseSuppression" + suffix);
		Assert.equals(autoGain, input.autoGain, "autoGain" + suffix);
	}
}
