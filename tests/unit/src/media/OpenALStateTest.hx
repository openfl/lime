package media;

#if (lime_cffi && lime_openal && !macro)
import lime.media.openal.AL;
import lime.media.openal.ALC;
import lime.utils.UInt8Array;
#end
import utest.Assert;
import utest.Test;

/**
	OpenAL's global state, its listener, its strings and its errors, through
	lime.media.openal.AL. The defaults, the values each call takes and the error
	each misuse sets are those of the OpenAL 1.1 Specification (section 2.7 for
	errors, 3 for the global state and its queries, 4.2 for the listener). Each
	test runs in a context of its own, so it starts from those defaults.
**/
class OpenALStateTest extends Test
{
	#if (lime_cffi && lime_openal && !macro)
	// No OpenAL enumeration has this value
	private static inline var UNKNOWN = 0x7FFF;

	private var sandbox:OpenALSandbox;
	#end

	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_openal && !macro)
	public function setup():Void
	{
		sandbox = OpenALSandbox.open();
	}

	public function teardown():Void
	{
		if (sandbox != null) sandbox.close();
		sandbox = null;
	}

	public function testANewContextStartsWithTheDefaultGlobalState():Void
	{
		if (!hasContext()) return;

		Assert.floatEquals(1.0, AL.getFloat(AL.DOPPLER_FACTOR));
		Assert.floatEquals(1.0, AL.getFloat(AL.DOPPLER_VELOCITY));
		Assert.floatEquals(343.3, AL.getFloat(AL.SPEED_OF_SOUND), 0.001);
		Assert.equals(AL.INVERSE_DISTANCE_CLAMPED, AL.getInteger(AL.DISTANCE_MODEL));
		OpenALSandbox.error(AL.NO_ERROR);
	}

	public function testDopplerFactorReadsBackThroughEveryQuery():Void
	{
		if (!hasContext()) return;

		AL.dopplerFactor(3);

		Assert.floatEquals(3.0, AL.getFloat(AL.DOPPLER_FACTOR));
		Assert.floatEquals(3.0, AL.getDouble(AL.DOPPLER_FACTOR));
		Assert.equals(3, AL.getInteger(AL.DOPPLER_FACTOR));
		Assert.isTrue(AL.getBoolean(AL.DOPPLER_FACTOR));

		OpenALSandbox.floats([3.0], AL.getFloatv(AL.DOPPLER_FACTOR));
		OpenALSandbox.floats([3.0], AL.getDoublev(AL.DOPPLER_FACTOR));
		OpenALSandbox.ints([3], AL.getIntegerv(AL.DOPPLER_FACTOR));
		Assert.same([true], AL.getBooleanv(AL.DOPPLER_FACTOR));

		// A factor of zero turns the effect off, and reads as false
		AL.dopplerFactor(0);
		Assert.isFalse(AL.getBoolean(AL.DOPPLER_FACTOR));
		Assert.same([false], AL.getBooleanv(AL.DOPPLER_FACTOR));

		// The value arrives as a float, not a whole number
		AL.dopplerFactor(0.25);
		Assert.floatEquals(0.25, AL.getFloat(AL.DOPPLER_FACTOR));
		Assert.floatEquals(0.25, AL.getDouble(AL.DOPPLER_FACTOR));
		OpenALSandbox.error(AL.NO_ERROR);
	}

	public function testDopplerVelocityAndTheSpeedOfSoundReadBack():Void
	{
		if (!hasContext()) return;

		AL.dopplerVelocity(2.5);
		AL.speedOfSound(1234.5);

		// Each is read by its own name, so neither stands in for the other
		Assert.floatEquals(2.5, AL.getFloat(AL.DOPPLER_VELOCITY));
		Assert.floatEquals(1234.5, AL.getFloat(AL.SPEED_OF_SOUND));
		Assert.floatEquals(1234.5, AL.getDouble(AL.SPEED_OF_SOUND));
		OpenALSandbox.floats([2.5], AL.getFloatv(AL.DOPPLER_VELOCITY));
		OpenALSandbox.floats([1234.5], AL.getDoublev(AL.SPEED_OF_SOUND));
		Assert.floatEquals(1.0, AL.getFloat(AL.DOPPLER_FACTOR));
		OpenALSandbox.error(AL.NO_ERROR);
	}

	public function testGlobalValuesOutOfRangeAreRefused():Void
	{
		if (!hasContext()) return;

		// None of them can be negative, and sound has to travel
		AL.dopplerFactor(-1);
		OpenALSandbox.error(AL.INVALID_VALUE, "a negative doppler factor");
		AL.dopplerVelocity(-1);
		OpenALSandbox.error(AL.INVALID_VALUE, "a negative doppler velocity");
		AL.speedOfSound(0);
		OpenALSandbox.error(AL.INVALID_VALUE, "a speed of sound of zero");
		AL.speedOfSound(-343.3);
		OpenALSandbox.error(AL.INVALID_VALUE, "a negative speed of sound");

		// A call that sets an error changes nothing
		Assert.floatEquals(1.0, AL.getFloat(AL.DOPPLER_FACTOR));
		Assert.floatEquals(1.0, AL.getFloat(AL.DOPPLER_VELOCITY));
		Assert.floatEquals(343.3, AL.getFloat(AL.SPEED_OF_SOUND), 0.001);
	}

	public function testEachDistanceModelReadsBack():Void
	{
		if (!hasContext()) return;

		var models = [
			AL.NONE,
			AL.INVERSE_DISTANCE,
			AL.INVERSE_DISTANCE_CLAMPED,
			AL.LINEAR_DISTANCE,
			AL.LINEAR_DISTANCE_CLAMPED,
			AL.EXPONENT_DISTANCE,
			AL.EXPONENT_DISTANCE_CLAMPED
		];

		for (model in models)
		{
			AL.distanceModel(model);
			Assert.equals(model, AL.getInteger(AL.DISTANCE_MODEL));
			OpenALSandbox.ints([model], AL.getIntegerv(AL.DISTANCE_MODEL));
		}

		OpenALSandbox.error(AL.NO_ERROR);

		AL.distanceModel(AL.LINEAR_DISTANCE);
		AL.distanceModel(AL.DISTANCE_MODEL);
		OpenALSandbox.error(AL.INVALID_VALUE, "a value that is not a distance model");
		Assert.equals(AL.LINEAR_DISTANCE, AL.getInteger(AL.DISTANCE_MODEL));
	}

	@Ignored("Waiting on #2124, since OpenAL Soft 1.20.1 reports an unknown name as INVALID_VALUE")
	public function testQueriesOfAnUnknownNameSetInvalidEnum():Void
	{
		if (!hasContext()) return;

		Assert.isFalse(AL.getBoolean(UNKNOWN));
		OpenALSandbox.error(AL.INVALID_ENUM, "getBoolean");
		Assert.equals(0, AL.getInteger(UNKNOWN));
		OpenALSandbox.error(AL.INVALID_ENUM, "getInteger");
		Assert.floatEquals(0.0, AL.getFloat(UNKNOWN));
		OpenALSandbox.error(AL.INVALID_ENUM, "getFloat");
		Assert.floatEquals(0.0, AL.getDouble(UNKNOWN));
		OpenALSandbox.error(AL.INVALID_ENUM, "getDouble");
	}

	public function testGetBooleanvGivesAsManyValuesAsAskedFor():Void
	{
		if (!hasContext()) return;

		// As the other queries that take a count do
		Assert.equals(2, AL.getIntegerv(AL.DISTANCE_MODEL, 2).length);
		Assert.equals(2, AL.getFloatv(AL.DOPPLER_FACTOR, 2).length);
		Assert.equals(2, AL.getDoublev(AL.DOPPLER_FACTOR, 2).length);
		Assert.equals(2, AL.getBooleanv(AL.DOPPLER_FACTOR, 2).length);
	}

	public function testEnableAndDisableSwitchACapability():Void
	{
		if (!hasContext()) return;

		// OpenAL 1.1 itself has no capabilities, so this one comes from an extension
		if (!AL.isExtensionPresent("AL_EXT_source_distance_model"))
		{
			Assert.pass("This OpenAL has no capability to switch");
			return;
		}

		var capability = AL.getEnumValue("AL_SOURCE_DISTANCE_MODEL");
		Assert.equals(0x200, capability);
		Assert.isFalse(AL.isEnabled(capability));

		AL.enable(capability);
		Assert.isTrue(AL.isEnabled(capability));

		AL.disable(capability);
		Assert.isFalse(AL.isEnabled(capability));
		OpenALSandbox.error(AL.NO_ERROR);
	}

	public function testAnUnknownCapabilityIsRefused():Void
	{
		if (!hasContext()) return;

		// The specification says INVALID_ENUM, and OpenAL Soft answers INVALID_VALUE
		AL.enable(UNKNOWN);
		Assert.notEquals(AL.NO_ERROR, AL.getError(), "enable");
		AL.disable(UNKNOWN);
		Assert.notEquals(AL.NO_ERROR, AL.getError(), "disable");
		Assert.isFalse(AL.isEnabled(UNKNOWN));
		Assert.notEquals(AL.NO_ERROR, AL.getError(), "isEnabled");
	}

	public function testTheImplementationNamesItself():Void
	{
		if (!hasContext()) return;

		for (name in [AL.VENDOR, AL.RENDERER, AL.VERSION])
		{
			var value = AL.getString(name);
			Assert.notNull(value);
			if (value != null) Assert.isTrue(value.length > 0);
		}

		// The version of the specification comes first, then the implementation's own
		Assert.isTrue(~/^[0-9]+\.[0-9]+/.match(AL.getString(AL.VERSION)), AL.getString(AL.VERSION));
		Assert.notEquals(AL.getString(AL.VENDOR), AL.getString(AL.VERSION));
		OpenALSandbox.error(AL.NO_ERROR);
	}

	public function testEveryExtensionListedIsPresent():Void
	{
		if (!hasContext()) return;

		var extensions = AL.getString(AL.EXTENSIONS);
		Assert.notNull(extensions);
		if (extensions == null) return;

		var missing = [for (name in extensions.split(" ")) if (name.length > 0 && !AL.isExtensionPresent(name)) name];
		Assert.same([], missing);

		Assert.isFalse(AL.isExtensionPresent("AL_LIME_not_an_extension"));
		OpenALSandbox.error(AL.NO_ERROR);
	}

	public function testTheStringOfAnUnknownNameIsNull():Void
	{
		if (!hasContext()) return;

		Assert.isNull(AL.getString(UNKNOWN));
		// The specification says INVALID_ENUM, and OpenAL Soft answers INVALID_VALUE
		Assert.notEquals(AL.NO_ERROR, AL.getError());
	}

	@Ignored("Waiting on #2124, since OpenAL Soft 1.20.1 reports an unknown name as INVALID_VALUE")
	public function testAnErrorIsReportedOnceThenCleared():Void
	{
		if (!hasContext()) return;

		Assert.equals(AL.NO_ERROR, AL.getError());

		AL.getFloat(UNKNOWN);
		Assert.equals(AL.INVALID_ENUM, AL.getError());
		Assert.equals(AL.NO_ERROR, AL.getError());
	}

	@Ignored("Waiting on #2124, since OpenAL Soft 1.20.1 reports an unknown name as INVALID_VALUE")
	public function testTheFirstErrorIsKeptUntilItIsRead():Void
	{
		if (!hasContext()) return;

		// Later errors do not replace one the application has not read
		AL.getFloat(UNKNOWN);
		AL.dopplerFactor(-1);
		AL.listenerf(AL.GAIN, -1);

		Assert.equals(AL.INVALID_ENUM, AL.getError());
		Assert.equals(AL.NO_ERROR, AL.getError());
	}

	@Ignored("Waiting on #2124, since OpenAL Soft 1.20.1 reports an unknown name as INVALID_VALUE")
	public function testEachErrorHasItsOwnMessage():Void
	{
		if (!hasContext()) return;

		Assert.equals("", AL.getErrorString());

		var source = AL.createSource();
		AL.deleteSource(source);
		AL.sourcef(source, AL.GAIN, 1);
		Assert.equals(0, AL.getErrorString().indexOf("INVALID_NAME"));

		AL.getFloat(UNKNOWN);
		Assert.equals(0, AL.getErrorString().indexOf("INVALID_ENUM"));

		AL.dopplerFactor(-1);
		Assert.equals(0, AL.getErrorString().indexOf("INVALID_VALUE"));

		source = AL.createSource();
		var buffer = OpenALSandbox.silence(50);
		AL.sourcei(source, AL.BUFFER, buffer);
		AL.sourceQueueBuffer(source, buffer);
		Assert.equals(0, AL.getErrorString().indexOf("INVALID_OPERATION"));

		// Reading the message read the error
		Assert.equals("", AL.getErrorString());
		Assert.equals(AL.NO_ERROR, AL.getError());

		AL.deleteSource(source);
		AL.deleteBuffer(buffer);
	}

	public function testCreatingAnObjectKeepsAnErrorTheApplicationHasNotRead():Void
	{
		if (!hasContext()) return;

		// Only reading the error clears it. Which error an unknown name gives differs between
		// OpenAL versions (INVALID_ENUM or INVALID_VALUE), so it is read once first.
		AL.getFloat(UNKNOWN);
		var pending = AL.getError();
		Assert.notEquals(AL.NO_ERROR, pending);

		AL.getFloat(UNKNOWN);
		var buffer = AL.createBuffer();
		OpenALSandbox.error(pending, "after createBuffer");

		AL.getFloat(UNKNOWN);
		var source = AL.createSource();
		OpenALSandbox.error(pending, "after createSource");

		AL.getFloat(UNKNOWN);
		var buffers = AL.genBuffers(2);
		OpenALSandbox.error(pending, "after genBuffers");

		AL.getFloat(UNKNOWN);
		var sources = AL.genSources(2);
		OpenALSandbox.error(pending, "after genSources");

		AL.deleteSource(source);
		AL.deleteSources(sources);
		AL.deleteBuffer(buffer);
		AL.deleteBuffers(buffers);
	}

	public function testTheListenerStartsAtTheOriginFacingDownTheNegativeZAxis():Void
	{
		if (!hasContext()) return;

		OpenALSandbox.floats([0.0, 0.0, 0.0], AL.getListenerfv(AL.POSITION, 3), "position");
		OpenALSandbox.floats([0.0, 0.0, 0.0], AL.getListenerfv(AL.VELOCITY, 3), "velocity");
		// The "at" vector, then the "up" vector
		OpenALSandbox.floats([0.0, 0.0, -1.0, 0.0, 1.0, 0.0], AL.getListenerfv(AL.ORIENTATION, 6), "orientation");
		OpenALSandbox.ints([0, 0, -1, 0, 1, 0], AL.getListeneriv(AL.ORIENTATION, 6), "orientation");
		Assert.floatEquals(1.0, AL.getListenerf(AL.GAIN));
		OpenALSandbox.floats([1.0], AL.getListenerfv(AL.GAIN));
		OpenALSandbox.error(AL.NO_ERROR);
	}

	public function testListener3fSetsThreeValuesInOrder():Void
	{
		if (!hasContext()) return;

		AL.listener3f(AL.POSITION, 1.5, -2.25, 3.75);
		AL.listener3f(AL.VELOCITY, -4.5, 5.25, 6.75);

		OpenALSandbox.floats([1.5, -2.25, 3.75], AL.getListenerfv(AL.POSITION, 3), "position");
		OpenALSandbox.floats([-4.5, 5.25, 6.75], AL.getListenerfv(AL.VELOCITY, 3), "velocity");
		OpenALSandbox.error(AL.NO_ERROR);
	}

	public function testListenerfvSetsThreeValuesInOrder():Void
	{
		if (!hasContext()) return;

		AL.listenerfv(AL.POSITION, [7.5, 8.25, -9.75]);
		AL.listenerfv(AL.VELOCITY, [0.5, -0.25, 0.125]);

		OpenALSandbox.floats([7.5, 8.25, -9.75], AL.getListenerfv(AL.POSITION, 3), "position");
		OpenALSandbox.floats([0.5, -0.25, 0.125], AL.getListenerfv(AL.VELOCITY, 3), "velocity");
		OpenALSandbox.error(AL.NO_ERROR);
	}

	public function testGetListener3fGivesThreeValuesInOrder():Void
	{
		if (!hasContext()) return;

		AL.listener3f(AL.POSITION, 1.5, -2.25, 3.75);
		AL.listener3f(AL.VELOCITY, -4.5, 5.25, 6.75);

		OpenALSandbox.floats([1.5, -2.25, 3.75], AL.getListener3f(AL.POSITION), "position");
		OpenALSandbox.floats([-4.5, 5.25, 6.75], AL.getListener3f(AL.VELOCITY), "velocity");
		OpenALSandbox.error(AL.NO_ERROR);
	}

	public function testListener3iAndListenerivSetWholeNumbers():Void
	{
		if (!hasContext()) return;

		AL.listener3i(AL.POSITION, 10, -20, 30);
		AL.listeneriv(AL.VELOCITY, [-4, 5, 6]);

		OpenALSandbox.ints([10, -20, 30], AL.getListeneriv(AL.POSITION, 3), "position");
		OpenALSandbox.ints([-4, 5, 6], AL.getListeneriv(AL.VELOCITY, 3), "velocity");
		OpenALSandbox.floats([10.0, -20.0, 30.0], AL.getListenerfv(AL.POSITION, 3), "position");
		OpenALSandbox.floats([-4.0, 5.0, 6.0], AL.getListenerfv(AL.VELOCITY, 3), "velocity");
		OpenALSandbox.error(AL.NO_ERROR);
	}

	public function testGetListener3iGivesThreeValuesInOrder():Void
	{
		if (!hasContext()) return;

		AL.listener3i(AL.POSITION, 10, -20, 30);
		AL.listener3i(AL.VELOCITY, -4, 5, 6);

		OpenALSandbox.ints([10, -20, 30], AL.getListener3i(AL.POSITION), "position");
		OpenALSandbox.ints([-4, 5, 6], AL.getListener3i(AL.VELOCITY), "velocity");
		OpenALSandbox.error(AL.NO_ERROR);
	}

	public function testTheListenersOrientationHoldsItsAtAndUpVectors():Void
	{
		if (!hasContext()) return;

		AL.listenerfv(AL.ORIENTATION, [1.0, 0.0, 0.0, 0.0, 0.0, 1.0]);
		OpenALSandbox.floats([1.0, 0.0, 0.0, 0.0, 0.0, 1.0], AL.getListenerfv(AL.ORIENTATION, 6));
		OpenALSandbox.ints([1, 0, 0, 0, 0, 1], AL.getListeneriv(AL.ORIENTATION, 6));

		AL.listeneriv(AL.ORIENTATION, [0, -1, 0, 0, 0, -1]);
		OpenALSandbox.floats([0.0, -1.0, 0.0, 0.0, 0.0, -1.0], AL.getListenerfv(AL.ORIENTATION, 6));
		OpenALSandbox.error(AL.NO_ERROR);
	}

	public function testTheListenersGainReadsBack():Void
	{
		if (!hasContext()) return;

		AL.listenerf(AL.GAIN, 0.25);
		Assert.floatEquals(0.25, AL.getListenerf(AL.GAIN));
		OpenALSandbox.floats([0.25], AL.getListenerfv(AL.GAIN));

		AL.listenerfv(AL.GAIN, [0.75]);
		Assert.floatEquals(0.75, AL.getListenerf(AL.GAIN));
		OpenALSandbox.error(AL.NO_ERROR);

		AL.listenerf(AL.GAIN, -0.5);
		OpenALSandbox.error(AL.INVALID_VALUE, "a negative gain");
		Assert.floatEquals(0.75, AL.getListenerf(AL.GAIN));
	}

	public function testListenerCallsOfTheWrongFormSetInvalidEnum():Void
	{
		if (!hasContext()) return;

		// A position is three values, and the gain is one
		AL.listenerf(AL.POSITION, 1);
		OpenALSandbox.error(AL.INVALID_ENUM, "listenerf");
		AL.listener3f(AL.GAIN, 1, 1, 1);
		OpenALSandbox.error(AL.INVALID_ENUM, "listener3f");
		AL.listeneri(AL.POSITION, 1);
		OpenALSandbox.error(AL.INVALID_ENUM, "listeneri");
		AL.listener3i(AL.GAIN, 1, 1, 1);
		OpenALSandbox.error(AL.INVALID_ENUM, "listener3i");
		AL.listenerfv(UNKNOWN, [1.0]);
		OpenALSandbox.error(AL.INVALID_ENUM, "listenerfv");
		AL.listeneriv(UNKNOWN, [1]);
		OpenALSandbox.error(AL.INVALID_ENUM, "listeneriv");

		// A query OpenAL refuses gives zero
		Assert.floatEquals(0.0, AL.getListenerf(AL.POSITION));
		OpenALSandbox.error(AL.INVALID_ENUM, "getListenerf");
		Assert.equals(0, AL.getListeneri(AL.POSITION));
		OpenALSandbox.error(AL.INVALID_ENUM, "getListeneri");

		OpenALSandbox.floats([0.0, 0.0, 0.0], AL.getListenerfv(AL.POSITION, 3));
		Assert.floatEquals(1.0, AL.getListenerf(AL.GAIN));
	}

	public function testAThreeValueQueryOpenALRefusesGivesZeros():Void
	{
		if (!hasContext()) return;

		OpenALSandbox.floats([0.0, 0.0, 0.0], AL.getListener3f(AL.GAIN));
		OpenALSandbox.error(AL.INVALID_ENUM, "getListener3f");
		OpenALSandbox.ints([0, 0, 0], AL.getListener3i(AL.GAIN));
		OpenALSandbox.error(AL.INVALID_ENUM, "getListener3i");
	}

	#if hl
	@Ignored("Waiting on #2124, since OpenAL Soft 1.20.1 reports an unknown name as INVALID_VALUE")
	#end
	public function testAnArrayQueryOpenALRefusesGivesZeros():Void
	{
		if (!hasContext()) return;

		// The values the last query read are still in the memory the next one is given
		AL.listener3f(AL.POSITION, 7, 8, 9);

		for (i in 0...8)
		{
			AL.getListenerfv(AL.POSITION, 3);
			OpenALSandbox.floats([0.0, 0.0, 0.0], AL.getListenerfv(UNKNOWN, 3), "getListenerfv");
			OpenALSandbox.error(AL.INVALID_ENUM, "getListenerfv");

			AL.getListeneriv(AL.POSITION, 3);
			OpenALSandbox.ints([0, 0, 0], AL.getListeneriv(UNKNOWN, 3), "getListeneriv");
			OpenALSandbox.error(AL.INVALID_ENUM, "getListeneriv");

			AL.getFloatv(AL.SPEED_OF_SOUND, 3);
			OpenALSandbox.floats([0.0, 0.0, 0.0], AL.getFloatv(UNKNOWN, 3), "getFloatv");
			// OpenAL Soft refuses this with INVALID_ENUM on HashLink and INVALID_VALUE through the
			// C++ and Neko binding. Either way the query is refused, which is what is checked here
			var error = AL.getError();
			Assert.isTrue(error == AL.INVALID_ENUM || error == AL.INVALID_VALUE, "getFloatv: " + OpenALSandbox.errorName(error));
		}
	}

	public function testEveryConstantHasTheValueOpenALGivesItsName():Void
	{
		if (!hasContext()) return;

		var constants:Array<{name:String, value:Int}> = [
			{name: "AL_NONE", value: AL.NONE},
			{name: "AL_FALSE", value: AL.FALSE},
			{name: "AL_TRUE", value: AL.TRUE},
			{name: "AL_SOURCE_RELATIVE", value: AL.SOURCE_RELATIVE},
			{name: "AL_CONE_INNER_ANGLE", value: AL.CONE_INNER_ANGLE},
			{name: "AL_CONE_OUTER_ANGLE", value: AL.CONE_OUTER_ANGLE},
			{name: "AL_PITCH", value: AL.PITCH},
			{name: "AL_POSITION", value: AL.POSITION},
			{name: "AL_DIRECTION", value: AL.DIRECTION},
			{name: "AL_VELOCITY", value: AL.VELOCITY},
			{name: "AL_LOOPING", value: AL.LOOPING},
			{name: "AL_BUFFER", value: AL.BUFFER},
			{name: "AL_GAIN", value: AL.GAIN},
			{name: "AL_MIN_GAIN", value: AL.MIN_GAIN},
			{name: "AL_MAX_GAIN", value: AL.MAX_GAIN},
			{name: "AL_ORIENTATION", value: AL.ORIENTATION},
			{name: "AL_SOURCE_STATE", value: AL.SOURCE_STATE},
			{name: "AL_INITIAL", value: AL.INITIAL},
			{name: "AL_PLAYING", value: AL.PLAYING},
			{name: "AL_PAUSED", value: AL.PAUSED},
			{name: "AL_STOPPED", value: AL.STOPPED},
			{name: "AL_BUFFERS_QUEUED", value: AL.BUFFERS_QUEUED},
			{name: "AL_BUFFERS_PROCESSED", value: AL.BUFFERS_PROCESSED},
			{name: "AL_REFERENCE_DISTANCE", value: AL.REFERENCE_DISTANCE},
			{name: "AL_ROLLOFF_FACTOR", value: AL.ROLLOFF_FACTOR},
			{name: "AL_CONE_OUTER_GAIN", value: AL.CONE_OUTER_GAIN},
			{name: "AL_MAX_DISTANCE", value: AL.MAX_DISTANCE},
			{name: "AL_SEC_OFFSET", value: AL.SEC_OFFSET},
			{name: "AL_SAMPLE_OFFSET", value: AL.SAMPLE_OFFSET},
			{name: "AL_BYTE_OFFSET", value: AL.BYTE_OFFSET},
			{name: "AL_SOURCE_TYPE", value: AL.SOURCE_TYPE},
			{name: "AL_STATIC", value: AL.STATIC},
			{name: "AL_STREAMING", value: AL.STREAMING},
			{name: "AL_UNDETERMINED", value: AL.UNDETERMINED},
			{name: "AL_FORMAT_MONO8", value: AL.FORMAT_MONO8},
			{name: "AL_FORMAT_MONO16", value: AL.FORMAT_MONO16},
			{name: "AL_FORMAT_STEREO8", value: AL.FORMAT_STEREO8},
			{name: "AL_FORMAT_STEREO16", value: AL.FORMAT_STEREO16},
			{name: "AL_FREQUENCY", value: AL.FREQUENCY},
			{name: "AL_BITS", value: AL.BITS},
			{name: "AL_CHANNELS", value: AL.CHANNELS},
			{name: "AL_SIZE", value: AL.SIZE},
			{name: "AL_NO_ERROR", value: AL.NO_ERROR},
			{name: "AL_INVALID_NAME", value: AL.INVALID_NAME},
			{name: "AL_INVALID_ENUM", value: AL.INVALID_ENUM},
			{name: "AL_INVALID_VALUE", value: AL.INVALID_VALUE},
			{name: "AL_INVALID_OPERATION", value: AL.INVALID_OPERATION},
			{name: "AL_OUT_OF_MEMORY", value: AL.OUT_OF_MEMORY},
			{name: "AL_VENDOR", value: AL.VENDOR},
			{name: "AL_VERSION", value: AL.VERSION},
			{name: "AL_RENDERER", value: AL.RENDERER},
			{name: "AL_EXTENSIONS", value: AL.EXTENSIONS},
			{name: "AL_DOPPLER_FACTOR", value: AL.DOPPLER_FACTOR},
			{name: "AL_DOPPLER_VELOCITY", value: AL.DOPPLER_VELOCITY},
			{name: "AL_SPEED_OF_SOUND", value: AL.SPEED_OF_SOUND},
			{name: "AL_DISTANCE_MODEL", value: AL.DISTANCE_MODEL},
			{name: "AL_INVERSE_DISTANCE", value: AL.INVERSE_DISTANCE},
			{name: "AL_INVERSE_DISTANCE_CLAMPED", value: AL.INVERSE_DISTANCE_CLAMPED},
			{name: "AL_LINEAR_DISTANCE", value: AL.LINEAR_DISTANCE},
			{name: "AL_LINEAR_DISTANCE_CLAMPED", value: AL.LINEAR_DISTANCE_CLAMPED},
			{name: "AL_EXPONENT_DISTANCE", value: AL.EXPONENT_DISTANCE},
			{name: "AL_EXPONENT_DISTANCE_CLAMPED", value: AL.EXPONENT_DISTANCE_CLAMPED}
		];

		var wrong = [];

		for (constant in constants)
		{
			var value = AL.getEnumValue(constant.name);
			if (value != constant.value) wrong.push(constant.name + " is " + StringTools.hex(value) + ", not " + StringTools.hex(constant.value));
		}

		Assert.same([], wrong);
		OpenALSandbox.error(AL.NO_ERROR);
	}

	public function testTheValueOfAnUnknownNameIsZero():Void
	{
		if (!hasContext()) return;

		Assert.equals(0, AL.getEnumValue("AL_LIME_NOT_AN_ENUM"));
		AL.getError();
	}

	private function hasContext():Bool
	{
		if (sandbox == null)
		{
			Assert.pass("There is no audio output here, so OpenAL was not tested");
			return false;
		}

		return true;
	}
	#end
}
