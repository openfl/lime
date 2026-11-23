package media;

#if (lime_cffi && lime_openal && !macro)
import lime.media.openal.AL;
import lime.media.openal.ALBuffer;
import lime.media.openal.ALSource;
import lime.utils.UInt8Array;
#end
import utest.Assert;
import utest.Test;

/**
	OpenAL's sources and buffers, through lime.media.openal.AL. The defaults of
	each property, the forms it is set and read in, the states a source moves
	through and the error each misuse sets are those of the OpenAL 1.1
	Specification (section 4.3 for sources, 5.3 for buffers and 4.3.4 for
	queues). Each test runs in a context of its own, and plays into whatever
	output there is, which on the test machines is OpenAL's null output.
**/
class OpenALSourceTest extends Test
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

	public function testANewSourceHasTheDefaultProperties():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();

		Assert.floatEquals(1.0, AL.getSourcef(source, AL.PITCH), "pitch");
		Assert.floatEquals(1.0, AL.getSourcef(source, AL.GAIN), "gain");
		Assert.floatEquals(0.0, AL.getSourcef(source, AL.MIN_GAIN), "minimum gain");
		Assert.floatEquals(1.0, AL.getSourcef(source, AL.MAX_GAIN), "maximum gain");
		Assert.floatEquals(1.0, AL.getSourcef(source, AL.REFERENCE_DISTANCE), "reference distance");
		Assert.floatEquals(1.0, AL.getSourcef(source, AL.ROLLOFF_FACTOR), "rolloff factor");
		Assert.floatEquals(0.0, AL.getSourcef(source, AL.CONE_OUTER_GAIN), "outer cone gain");
		Assert.floatEquals(360.0, AL.getSourcef(source, AL.CONE_INNER_ANGLE), "inner cone angle");
		Assert.floatEquals(360.0, AL.getSourcef(source, AL.CONE_OUTER_ANGLE), "outer cone angle");
		// The largest float, so distance never cuts a source off
		Assert.isTrue(AL.getSourcef(source, AL.MAX_DISTANCE) > 1e38, "maximum distance");

		OpenALSandbox.floats([0.0, 0.0, 0.0], AL.getSourcefv(source, AL.POSITION, 3), "position");
		OpenALSandbox.floats([0.0, 0.0, 0.0], AL.getSourcefv(source, AL.VELOCITY, 3), "velocity");
		OpenALSandbox.floats([0.0, 0.0, 0.0], AL.getSourcefv(source, AL.DIRECTION, 3), "direction");

		Assert.equals(AL.FALSE, integer(source, AL.SOURCE_RELATIVE), "relative");
		Assert.equals(AL.FALSE, integer(source, AL.LOOPING), "looping");
		Assert.equals(AL.INITIAL, integer(source, AL.SOURCE_STATE), "state");
		Assert.equals(AL.UNDETERMINED, integer(source, AL.SOURCE_TYPE), "type");
		Assert.equals(0, integer(source, AL.BUFFERS_QUEUED), "buffers queued");
		Assert.equals(0, integer(source, AL.BUFFERS_PROCESSED), "buffers processed");
		Assert.equals(0, integer(source, AL.SAMPLE_OFFSET), "sample offset");
		Assert.equals(0, integer(source, AL.BYTE_OFFSET), "byte offset");
		Assert.floatEquals(0.0, AL.getSourcef(source, AL.SEC_OFFSET), "offset in seconds");
		Assert.isNull(AL.getSourcei(source, AL.BUFFER), "buffer");
		OpenALSandbox.error(AL.NO_ERROR);

		AL.deleteSource(source);
	}

	public function testEachFloatPropertyReadsBack():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();

		// A value of its own for each, so none can be read in place of another
		var properties:Array<{name:String, param:Int, value:Float}> = [
			{name: "pitch", param: AL.PITCH, value: 1.5},
			{name: "gain", param: AL.GAIN, value: 0.25},
			{name: "minimum gain", param: AL.MIN_GAIN, value: 0.125},
			{name: "maximum gain", param: AL.MAX_GAIN, value: 0.875},
			{name: "reference distance", param: AL.REFERENCE_DISTANCE, value: 2.5},
			{name: "rolloff factor", param: AL.ROLLOFF_FACTOR, value: 3.5},
			{name: "outer cone gain", param: AL.CONE_OUTER_GAIN, value: 0.375},
			{name: "inner cone angle", param: AL.CONE_INNER_ANGLE, value: 90.5},
			{name: "outer cone angle", param: AL.CONE_OUTER_ANGLE, value: 180.25},
			{name: "maximum distance", param: AL.MAX_DISTANCE, value: 500.5}
		];

		for (property in properties)
		{
			AL.sourcef(source, property.param, property.value);
		}

		OpenALSandbox.error(AL.NO_ERROR);

		for (property in properties)
		{
			Assert.floatEquals(property.value, AL.getSourcef(source, property.param), property.name);
			OpenALSandbox.floats([property.value], AL.getSourcefv(source, property.param), property.name);
		}

		// The same again through the array form, with other values
		for (property in properties)
		{
			AL.sourcefv(source, property.param, [property.value / 2]);
		}

		for (property in properties)
		{
			Assert.floatEquals(property.value / 2, AL.getSourcef(source, property.param), property.name);
		}

		OpenALSandbox.error(AL.NO_ERROR);
		AL.deleteSource(source);
	}

	public function testSource3fAndSourcefvSetThreeValuesInOrder():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();

		AL.source3f(source, AL.POSITION, 1.5, -2.25, 3.75);
		AL.source3f(source, AL.VELOCITY, -4.5, 5.25, 6.75);
		AL.source3f(source, AL.DIRECTION, 0.5, 0.25, -0.125);

		OpenALSandbox.floats([1.5, -2.25, 3.75], AL.getSourcefv(source, AL.POSITION, 3), "position");
		OpenALSandbox.floats([-4.5, 5.25, 6.75], AL.getSourcefv(source, AL.VELOCITY, 3), "velocity");
		OpenALSandbox.floats([0.5, 0.25, -0.125], AL.getSourcefv(source, AL.DIRECTION, 3), "direction");

		AL.sourcefv(source, AL.POSITION, [7.5, 8.25, -9.75]);
		AL.sourcefv(source, AL.VELOCITY, [10.5, -11.25, 12.75]);
		AL.sourcefv(source, AL.DIRECTION, [-1.5, 2.25, 0.75]);

		OpenALSandbox.floats([7.5, 8.25, -9.75], AL.getSourcefv(source, AL.POSITION, 3), "position");
		OpenALSandbox.floats([10.5, -11.25, 12.75], AL.getSourcefv(source, AL.VELOCITY, 3), "velocity");
		OpenALSandbox.floats([-1.5, 2.25, 0.75], AL.getSourcefv(source, AL.DIRECTION, 3), "direction");
		OpenALSandbox.error(AL.NO_ERROR);

		AL.deleteSource(source);
	}

	public function testGetSource3fGivesThreeValuesInOrder():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();

		AL.source3f(source, AL.POSITION, 1.5, -2.25, 3.75);
		AL.source3f(source, AL.VELOCITY, -4.5, 5.25, 6.75);
		AL.source3f(source, AL.DIRECTION, 0.5, 0.25, -0.125);

		OpenALSandbox.floats([1.5, -2.25, 3.75], AL.getSource3f(source, AL.POSITION), "position");
		OpenALSandbox.floats([-4.5, 5.25, 6.75], AL.getSource3f(source, AL.VELOCITY), "velocity");
		OpenALSandbox.floats([0.5, 0.25, -0.125], AL.getSource3f(source, AL.DIRECTION), "direction");
		OpenALSandbox.error(AL.NO_ERROR);

		AL.deleteSource(source);
	}

	public function testSource3iAndSourceivSetWholeNumbers():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();

		AL.source3i(source, AL.POSITION, 10, -20, 30);
		AL.source3i(source, AL.VELOCITY, -4, 5, 6);
		AL.sourceiv(source, AL.DIRECTION, [7, 8, -9]);

		OpenALSandbox.ints([10, -20, 30], AL.getSourceiv(source, AL.POSITION, 3), "position");
		OpenALSandbox.ints([-4, 5, 6], AL.getSourceiv(source, AL.VELOCITY, 3), "velocity");
		OpenALSandbox.ints([7, 8, -9], AL.getSourceiv(source, AL.DIRECTION, 3), "direction");
		OpenALSandbox.floats([10.0, -20.0, 30.0], AL.getSourcefv(source, AL.POSITION, 3), "position");
		OpenALSandbox.error(AL.NO_ERROR);

		AL.deleteSource(source);
	}

	public function testGetSource3iGivesThreeValuesInOrder():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();

		AL.source3i(source, AL.POSITION, 10, -20, 30);
		AL.source3i(source, AL.VELOCITY, -4, 5, 6);
		AL.source3i(source, AL.DIRECTION, 7, 8, -9);

		OpenALSandbox.ints([10, -20, 30], AL.getSource3i(source, AL.POSITION), "position");
		OpenALSandbox.ints([-4, 5, 6], AL.getSource3i(source, AL.VELOCITY), "velocity");
		OpenALSandbox.ints([7, 8, -9], AL.getSource3i(source, AL.DIRECTION), "direction");
		OpenALSandbox.error(AL.NO_ERROR);

		AL.deleteSource(source);
	}

	public function testEachIntegerPropertyReadsBack():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();

		AL.sourcei(source, AL.SOURCE_RELATIVE, AL.TRUE);
		Assert.equals(AL.TRUE, integer(source, AL.SOURCE_RELATIVE));
		Assert.equals(AL.FALSE, integer(source, AL.LOOPING));

		AL.sourcei(source, AL.SOURCE_RELATIVE, AL.FALSE);
		AL.sourcei(source, AL.LOOPING, AL.TRUE);
		Assert.equals(AL.FALSE, integer(source, AL.SOURCE_RELATIVE));
		Assert.equals(AL.TRUE, integer(source, AL.LOOPING));
		OpenALSandbox.ints([AL.TRUE], AL.getSourceiv(source, AL.LOOPING));

		AL.sourceiv(source, AL.LOOPING, [AL.FALSE]);
		Assert.equals(AL.FALSE, integer(source, AL.LOOPING));

		// The properties that are floats also take and give whole numbers
		AL.sourcei(source, AL.CONE_INNER_ANGLE, 45);
		AL.sourcei(source, AL.CONE_OUTER_ANGLE, 270);
		AL.sourcei(source, AL.REFERENCE_DISTANCE, 7);
		AL.sourcei(source, AL.ROLLOFF_FACTOR, 2);
		AL.sourcei(source, AL.MAX_DISTANCE, 300);

		Assert.equals(45, integer(source, AL.CONE_INNER_ANGLE));
		Assert.equals(270, integer(source, AL.CONE_OUTER_ANGLE));
		Assert.equals(7, integer(source, AL.REFERENCE_DISTANCE));
		Assert.equals(2, integer(source, AL.ROLLOFF_FACTOR));
		Assert.equals(300, integer(source, AL.MAX_DISTANCE));
		Assert.floatEquals(45.0, AL.getSourcef(source, AL.CONE_INNER_ANGLE));
		Assert.floatEquals(300.0, AL.getSourcef(source, AL.MAX_DISTANCE));
		OpenALSandbox.error(AL.NO_ERROR);

		AL.deleteSource(source);
	}

	public function testValuesOutOfRangeAreRefused():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();

		for (param in [AL.PITCH, AL.GAIN, AL.MIN_GAIN, AL.MAX_GAIN, AL.REFERENCE_DISTANCE, AL.ROLLOFF_FACTOR, AL.MAX_DISTANCE, AL.CONE_OUTER_GAIN])
		{
			var before = AL.getSourcef(source, param);
			AL.sourcef(source, param, -1);
			OpenALSandbox.error(AL.INVALID_VALUE, "a negative value for " + StringTools.hex(param));
			Assert.floatEquals(before, AL.getSourcef(source, param));
		}

		AL.sourcef(source, AL.CONE_OUTER_GAIN, 1.5);
		OpenALSandbox.error(AL.INVALID_VALUE, "an outer cone gain above 1");

		// Both are either true or false
		AL.sourcei(source, AL.LOOPING, 2);
		OpenALSandbox.error(AL.INVALID_VALUE, "looping");
		AL.sourcei(source, AL.SOURCE_RELATIVE, 2);
		OpenALSandbox.error(AL.INVALID_VALUE, "relative");
		Assert.equals(AL.FALSE, integer(source, AL.LOOPING));

		AL.deleteSource(source);
	}

	public function testIntegerPropertiesReadWithoutABoxMatchGetSourcei():Void
	{
		if (!hasContext()) return;

		// The binding Lime's own sources poll with, which gives an Int
		var source = AL.createSource();
		AL.sourcei(source, AL.LOOPING, AL.TRUE);

		for (param in [AL.SOURCE_STATE, AL.SOURCE_TYPE, AL.LOOPING, AL.BUFFERS_QUEUED, AL.BUFFERS_PROCESSED, AL.SAMPLE_OFFSET, AL.BYTE_OFFSET])
		{
			var boxed:Int = AL.getSourcei(source, param);
			Assert.equals(boxed, @:privateAccess AL.__getSourceInt(source, param), "property " + param);
		}

		Assert.equals(AL.INITIAL, @:privateAccess AL.__getSourceInt(source, AL.SOURCE_STATE));
		Assert.equals(AL.TRUE, @:privateAccess AL.__getSourceInt(source, AL.LOOPING));
		AL.deleteSource(source);
	}

	public function testAnUnknownPropertySetsInvalidEnum():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();

		AL.sourcef(source, UNKNOWN, 1);
		OpenALSandbox.error(AL.INVALID_ENUM, "sourcef");
		AL.source3f(source, UNKNOWN, 1, 1, 1);
		OpenALSandbox.error(AL.INVALID_ENUM, "source3f");
		AL.sourcefv(source, UNKNOWN, [1.0]);
		OpenALSandbox.error(AL.INVALID_ENUM, "sourcefv");
		AL.sourcei(source, UNKNOWN, 1);
		OpenALSandbox.error(AL.INVALID_ENUM, "sourcei");
		AL.source3i(source, UNKNOWN, 1, 1, 1);
		OpenALSandbox.error(AL.INVALID_ENUM, "source3i");
		AL.sourceiv(source, UNKNOWN, [1]);
		OpenALSandbox.error(AL.INVALID_ENUM, "sourceiv");

		// A query OpenAL refuses gives zero
		Assert.floatEquals(0.0, AL.getSourcef(source, UNKNOWN));
		OpenALSandbox.error(AL.INVALID_ENUM, "getSourcef");
		Assert.equals(0, integer(source, UNKNOWN));
		OpenALSandbox.error(AL.INVALID_ENUM, "getSourcei");
		OpenALSandbox.floats([0.0, 0.0, 0.0], AL.getSource3f(source, UNKNOWN));
		OpenALSandbox.error(AL.INVALID_ENUM, "getSource3f");

		// A position is three values, and the gain is one
		AL.sourcef(source, AL.POSITION, 1);
		OpenALSandbox.error(AL.INVALID_ENUM, "a position of one value");
		AL.source3f(source, AL.GAIN, 1, 1, 1);
		OpenALSandbox.error(AL.INVALID_ENUM, "a gain of three values");

		AL.deleteSource(source);
	}

	public function testAnArrayQueryOpenALRefusesGivesZeros():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();
		var buffer = OpenALSandbox.silence(50);
		AL.source3f(source, AL.POSITION, 7, 8, 9);

		// The values the last query read are still in the memory the next one is given
		for (i in 0...8)
		{
			AL.getSourcefv(source, AL.POSITION, 3);
			OpenALSandbox.floats([0.0, 0.0, 0.0], AL.getSourcefv(source, UNKNOWN, 3), "getSourcefv");
			OpenALSandbox.error(AL.INVALID_ENUM, "getSourcefv");

			AL.getSourceiv(source, AL.POSITION, 3);
			OpenALSandbox.ints([0, 0, 0], AL.getSourceiv(source, UNKNOWN, 3), "getSourceiv");
			OpenALSandbox.error(AL.INVALID_ENUM, "getSourceiv");

			AL.getSourceiv(source, AL.POSITION, 3);
			OpenALSandbox.ints([0, 0, 0], AL.getBufferiv(buffer, UNKNOWN, 3), "getBufferiv");
			OpenALSandbox.error(AL.INVALID_ENUM, "getBufferiv");

			AL.getSourcefv(source, AL.POSITION, 3);
			OpenALSandbox.floats([0.0, 0.0, 0.0], AL.getBufferfv(buffer, UNKNOWN, 3), "getBufferfv");
			OpenALSandbox.error(AL.INVALID_ENUM, "getBufferfv");
		}

		AL.deleteSource(source);
		AL.deleteBuffer(buffer);
	}

	public function testADeletedSourceIsNoLongerASource():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();
		var others = AL.genSources(2);

		Assert.isTrue(AL.isSource(source));
		Assert.isTrue(AL.isSource(others[0]));
		Assert.isTrue(AL.isSource(others[1]));

		AL.deleteSource(source);
		AL.deleteSources(others);
		OpenALSandbox.error(AL.NO_ERROR);

		Assert.isFalse(AL.isSource(source));
		Assert.isFalse(AL.isSource(others[0]));
		Assert.isFalse(AL.isSource(others[1]));

		// Its name means nothing to OpenAL any more
		AL.sourcef(source, AL.GAIN, 0.5);
		OpenALSandbox.error(AL.INVALID_NAME, "setting a deleted source");
		AL.sourcePlay(source);
		OpenALSandbox.error(AL.INVALID_NAME, "playing a deleted source");

		// Deleting it again is not an error the application sees
		AL.deleteSource(source);
		OpenALSandbox.error(AL.NO_ERROR);
	}

	public function testGenSourcesMakesAsManySourcesAsAskedFor():Void
	{
		if (!hasContext()) return;

		Assert.same([], AL.genSources(0));

		var sources = AL.genSources(3);
		Assert.equals(3, sources.length);

		// Each is a source of its own
		for (i in 0...sources.length)
		{
			Assert.isTrue(AL.isSource(sources[i]));
			AL.sourcef(sources[i], AL.GAIN, (i + 1) / 8);
		}

		for (i in 0...sources.length)
		{
			Assert.floatEquals((i + 1) / 8, AL.getSourcef(sources[i], AL.GAIN));
		}

		OpenALSandbox.error(AL.NO_ERROR);
		AL.deleteSources(sources);
	}

	@:haxe.warning("-WDeprecated")
	public function testTheOldNamesStillMakeASourceAndABuffer():Void
	{
		if (!hasContext()) return;

		var source = AL.genSource();
		var buffer = AL.genBuffer();

		Assert.isTrue(AL.isSource(source));
		Assert.isTrue(AL.isBuffer(buffer));
		OpenALSandbox.error(AL.NO_ERROR);

		AL.deleteSource(source);
		AL.deleteBuffer(buffer);
	}

	public function testASourcePlaysPausesStopsAndRewinds():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();
		var buffer = OpenALSandbox.silence(1000);
		AL.sourcei(source, AL.BUFFER, buffer);
		AL.sourcei(source, AL.LOOPING, AL.TRUE);
		Assert.equals(AL.INITIAL, integer(source, AL.SOURCE_STATE));

		AL.sourcePlay(source);
		Assert.equals(AL.PLAYING, integer(source, AL.SOURCE_STATE));

		AL.sourcePause(source);
		Assert.equals(AL.PAUSED, integer(source, AL.SOURCE_STATE));

		AL.sourcePlay(source);
		Assert.equals(AL.PLAYING, integer(source, AL.SOURCE_STATE));

		AL.sourceStop(source);
		Assert.equals(AL.STOPPED, integer(source, AL.SOURCE_STATE));

		AL.sourceRewind(source);
		Assert.equals(AL.INITIAL, integer(source, AL.SOURCE_STATE));

		// A paused source can be stopped or rewound without playing again
		AL.sourcePlay(source);
		AL.sourcePause(source);
		AL.sourceStop(source);
		Assert.equals(AL.STOPPED, integer(source, AL.SOURCE_STATE));

		AL.sourcePlay(source);
		AL.sourcePause(source);
		AL.sourceRewind(source);
		Assert.equals(AL.INITIAL, integer(source, AL.SOURCE_STATE));
		OpenALSandbox.error(AL.NO_ERROR);

		AL.deleteSource(source);
		AL.deleteBuffer(buffer);
	}

	public function testPausingOrStoppingASourceThatIsNotPlayingChangesNothing():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();
		var buffer = OpenALSandbox.silence(1000);
		AL.sourcei(source, AL.BUFFER, buffer);

		// Neither is an error on a source that has not played
		AL.sourcePause(source);
		Assert.equals(AL.INITIAL, integer(source, AL.SOURCE_STATE));
		AL.sourceStop(source);
		Assert.equals(AL.INITIAL, integer(source, AL.SOURCE_STATE));

		AL.sourcePlay(source);
		AL.sourceStop(source);
		AL.sourcePause(source);
		Assert.equals(AL.STOPPED, integer(source, AL.SOURCE_STATE));
		OpenALSandbox.error(AL.NO_ERROR);

		AL.deleteSource(source);
		AL.deleteBuffer(buffer);
	}

	public function testTheArrayFormsActOnEverySourceListed():Void
	{
		if (!hasContext()) return;

		var buffer = OpenALSandbox.silence(1000);
		var sources = AL.genSources(3);

		for (source in sources)
		{
			AL.sourcei(source, AL.BUFFER, buffer);
			AL.sourcei(source, AL.LOOPING, AL.TRUE);
		}

		var listed = [sources[0], sources[1]];

		AL.sourcePlayv(listed);
		Assert.same([AL.PLAYING, AL.PLAYING, AL.INITIAL], states(sources));

		AL.sourcePausev(listed);
		Assert.same([AL.PAUSED, AL.PAUSED, AL.INITIAL], states(sources));

		AL.sourceStopv(listed);
		Assert.same([AL.STOPPED, AL.STOPPED, AL.INITIAL], states(sources));

		AL.sourceRewindv(listed);
		Assert.same([AL.INITIAL, AL.INITIAL, AL.INITIAL], states(sources));
		OpenALSandbox.error(AL.NO_ERROR);

		AL.deleteSources(sources);
		AL.deleteBuffer(buffer);
	}

	public function testAnArrayCallNamingADeletedSourceActsOnNone():Void
	{
		if (!hasContext()) return;

		var buffer = OpenALSandbox.silence(1000);
		var source = AL.createSource();
		var deleted = AL.createSource();
		AL.sourcei(source, AL.BUFFER, buffer);
		AL.deleteSource(deleted);

		AL.sourcePlayv([source, deleted]);
		OpenALSandbox.error(AL.INVALID_NAME, "sourcePlayv");
		Assert.equals(AL.INITIAL, integer(source, AL.SOURCE_STATE));

		AL.deleteSource(source);
		AL.deleteBuffer(buffer);
	}

	public function testASourceStopsAtTheEndOfItsBuffer():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();
		var buffer = OpenALSandbox.silence(50);
		AL.sourcei(source, AL.BUFFER, buffer);
		AL.sourcePlay(source);

		Assert.isTrue(OpenALSandbox.waitForState(source, AL.STOPPED), "the source did not stop");

		// Playing it again starts it from the beginning
		AL.sourcePlay(source);
		Assert.equals(AL.PLAYING, integer(source, AL.SOURCE_STATE));
		Assert.isTrue(OpenALSandbox.waitForState(source, AL.STOPPED), "the source did not stop the second time");
		OpenALSandbox.error(AL.NO_ERROR);

		AL.deleteSource(source);
		AL.deleteBuffer(buffer);
	}

	public function testALoopingSourcePlaysOnPastTheEndOfItsBuffer():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();
		var buffer = OpenALSandbox.silence(50);
		AL.sourcei(source, AL.BUFFER, buffer);
		AL.sourcei(source, AL.LOOPING, AL.TRUE);
		AL.sourcePlay(source);

		// Four times the length of the buffer
		Assert.isFalse(OpenALSandbox.waitForState(source, AL.STOPPED, 0.2), "the source stopped");

		// Without looping, it stops at the end it reaches next
		AL.sourcei(source, AL.LOOPING, AL.FALSE);
		Assert.isTrue(OpenALSandbox.waitForState(source, AL.STOPPED), "the source did not stop");

		AL.deleteSource(source);
		AL.deleteBuffer(buffer);
	}

	public function testAPausedSourceHoldsItsOffset():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();
		var buffer = OpenALSandbox.silence(1000);
		AL.sourcei(source, AL.BUFFER, buffer);
		AL.sourcei(source, AL.LOOPING, AL.TRUE);
		AL.sourcePlay(source);

		var end = haxe.Timer.stamp() + 5;

		while (integer(source, AL.SAMPLE_OFFSET) == 0 && haxe.Timer.stamp() < end)
		{
			Sys.sleep(0.005);
		}

		AL.sourcePause(source);

		var samples = integer(source, AL.SAMPLE_OFFSET);
		Assert.isTrue(samples > 0, "the source did not play");
		Assert.isTrue(samples < OpenALSandbox.SAMPLE_RATE);

		// The same place in each unit: the buffer is 16-bit mono, so two bytes a sample
		Assert.equals(samples * 2, integer(source, AL.BYTE_OFFSET));
		Assert.floatEquals(samples / OpenALSandbox.SAMPLE_RATE, AL.getSourcef(source, AL.SEC_OFFSET), 0.0001);
		// The float offset also counts the part of a sample played, which the integer one drops
		var exact = AL.getSourcef(source, AL.SAMPLE_OFFSET);
		Assert.isTrue(exact >= samples && exact < samples + 1, "SAMPLE_OFFSET " + exact + " for " + samples + " whole samples");

		Sys.sleep(0.1);
		Assert.equals(samples, integer(source, AL.SAMPLE_OFFSET), "the source played on while paused");

		// It carries on from there
		AL.sourcePlay(source);
		Assert.isTrue(integer(source, AL.SAMPLE_OFFSET) >= samples);
		OpenALSandbox.error(AL.NO_ERROR);

		AL.deleteSource(source);
		AL.deleteBuffer(buffer);
	}

	public function testAnOffsetSetWhilePausedIsWhereTheSourceIs():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();
		var buffer = OpenALSandbox.silence(1000);
		AL.sourcei(source, AL.BUFFER, buffer);
		AL.sourcePlay(source);
		AL.sourcePause(source);

		AL.sourcei(source, AL.SAMPLE_OFFSET, 11025);
		Assert.equals(11025, integer(source, AL.SAMPLE_OFFSET));
		Assert.equals(22050, integer(source, AL.BYTE_OFFSET));
		Assert.floatEquals(0.5, AL.getSourcef(source, AL.SEC_OFFSET), 0.0001);

		AL.sourcei(source, AL.BYTE_OFFSET, 4410);
		Assert.equals(2205, integer(source, AL.SAMPLE_OFFSET));

		AL.sourcef(source, AL.SEC_OFFSET, 0.25);
		Assert.equals(5512, integer(source, AL.SAMPLE_OFFSET));
		OpenALSandbox.error(AL.NO_ERROR);

		// The buffer holds 22050 samples
		AL.sourcei(source, AL.SAMPLE_OFFSET, 22051);
		OpenALSandbox.error(AL.INVALID_VALUE, "an offset past the end");
		Assert.equals(5512, integer(source, AL.SAMPLE_OFFSET));

		AL.deleteSource(source);
		AL.deleteBuffer(buffer);
	}

	public function testAttachingABufferMakesTheSourceStatic():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();
		var buffer = OpenALSandbox.silence(50);

		AL.sourcei(source, AL.BUFFER, buffer);
		Assert.equals(AL.STATIC, integer(source, AL.SOURCE_TYPE));
		Assert.equals(1, integer(source, AL.BUFFERS_QUEUED));

		// The handle the application made comes back, not another for the same buffer
		var attached:ALBuffer = AL.getSourcei(source, AL.BUFFER);
		Assert.isTrue(attached == buffer, "the source gave a different handle for its buffer");

		AL.sourcei(source, AL.BUFFER, null);
		Assert.equals(AL.UNDETERMINED, integer(source, AL.SOURCE_TYPE));
		Assert.equals(0, integer(source, AL.BUFFERS_QUEUED));
		Assert.isNull(AL.getSourcei(source, AL.BUFFER));
		OpenALSandbox.error(AL.NO_ERROR);

		AL.deleteSource(source);
		AL.deleteBuffer(buffer);
	}

	public function testTheBufferOfAPlayingSourceCannotBeChanged():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();
		var buffer = OpenALSandbox.silence(1000);
		var other = OpenALSandbox.silence(50);
		AL.sourcei(source, AL.BUFFER, buffer);
		AL.sourcei(source, AL.LOOPING, AL.TRUE);
		AL.sourcePlay(source);

		AL.sourcei(source, AL.BUFFER, other);
		OpenALSandbox.error(AL.INVALID_OPERATION, "while playing");

		AL.sourcePause(source);
		AL.sourcei(source, AL.BUFFER, other);
		OpenALSandbox.error(AL.INVALID_OPERATION, "while paused");

		var attached:ALBuffer = AL.getSourcei(source, AL.BUFFER);
		Assert.isTrue(attached == buffer);

		// A stopped source takes another
		AL.sourceStop(source);
		AL.sourcei(source, AL.BUFFER, other);
		OpenALSandbox.error(AL.NO_ERROR);
		attached = AL.getSourcei(source, AL.BUFFER);
		Assert.isTrue(attached == other);

		AL.deleteSource(source);
		AL.deleteBuffers([buffer, other]);
	}

	public function testQueuedBuffersMakeTheSourceStreaming():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();
		var first = OpenALSandbox.silence(50);
		var second = OpenALSandbox.silence(50);

		AL.sourceQueueBuffer(source, first);
		Assert.equals(AL.STREAMING, integer(source, AL.SOURCE_TYPE));
		Assert.equals(1, integer(source, AL.BUFFERS_QUEUED));

		AL.sourceQueueBuffer(source, second);
		Assert.equals(2, integer(source, AL.BUFFERS_QUEUED));
		Assert.equals(0, integer(source, AL.BUFFERS_PROCESSED));
		OpenALSandbox.error(AL.NO_ERROR);

		AL.deleteSource(source);
		AL.deleteBuffers([first, second]);
	}

	public function testSourceQueueBuffersQueuesTheNumberGiven():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();
		var buffers = [OpenALSandbox.silence(50), OpenALSandbox.silence(50), OpenALSandbox.silence(50)];

		AL.sourceQueueBuffers(source, 2, buffers);
		Assert.equals(2, integer(source, AL.BUFFERS_QUEUED));
		OpenALSandbox.error(AL.NO_ERROR);

		// The third was left out, so it is free to delete while the others are held
		AL.deleteBuffer(buffers[2]);
		OpenALSandbox.error(AL.NO_ERROR);
		Assert.isFalse(AL.isBuffer(buffers[2]));

		AL.deleteSource(source);
		AL.deleteBuffers([buffers[0], buffers[1]]);
	}

	public function testBuffersUnqueueInTheOrderTheyWereQueued():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();
		var first = OpenALSandbox.silence(50);
		var second = OpenALSandbox.silence(50);
		var third = OpenALSandbox.silence(50);

		AL.sourceQueueBuffers(source, 3, [first, second, third]);
		AL.sourcePlay(source);
		Assert.isTrue(OpenALSandbox.waitForState(source, AL.STOPPED), "the source did not stop");

		// A stopped source has played all it was given
		Assert.equals(3, integer(source, AL.BUFFERS_PROCESSED));

		var unqueued = AL.sourceUnqueueBuffer(source);
		Assert.isTrue(unqueued == first, "the first buffer unqueued was not the first queued");
		Assert.equals(2, integer(source, AL.BUFFERS_QUEUED));
		Assert.equals(2, integer(source, AL.BUFFERS_PROCESSED));

		var rest = AL.sourceUnqueueBuffers(source, 2);
		Assert.equals(2, rest.length);
		Assert.isTrue(rest[0] == second);
		Assert.isTrue(rest[1] == third);
		Assert.equals(0, integer(source, AL.BUFFERS_QUEUED));
		OpenALSandbox.error(AL.NO_ERROR);

		AL.deleteSource(source);
		AL.deleteBuffers([first, second, third]);
	}

	public function testUnqueueingMoreThanHasPlayedIsRefused():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();
		var first = OpenALSandbox.silence(50);
		var second = OpenALSandbox.silence(50);
		AL.sourceQueueBuffers(source, 2, [first, second]);

		Assert.same([], AL.sourceUnqueueBuffers(source, 1));
		OpenALSandbox.error(AL.INVALID_VALUE);
		Assert.equals(2, integer(source, AL.BUFFERS_QUEUED));

		AL.deleteSource(source);
		AL.deleteBuffers([first, second]);
	}

	public function testAStaticSourceTakesNoQueue():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();
		var buffer = OpenALSandbox.silence(50);
		var other = OpenALSandbox.silence(50);
		AL.sourcei(source, AL.BUFFER, buffer);

		AL.sourceQueueBuffer(source, other);
		OpenALSandbox.error(AL.INVALID_OPERATION);
		Assert.equals(AL.STATIC, integer(source, AL.SOURCE_TYPE));
		Assert.equals(1, integer(source, AL.BUFFERS_QUEUED));

		AL.deleteSource(source);
		AL.deleteBuffers([buffer, other]);
	}

	public function testBuffersOfDifferentFormatsCannotShareAQueue():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();
		var mono = OpenALSandbox.silence(50);
		var stereo = AL.createBuffer();
		var data = new UInt8Array(2048);
		AL.bufferData(stereo, AL.FORMAT_STEREO16, data, data.length, OpenALSandbox.SAMPLE_RATE);

		AL.sourceQueueBuffer(source, mono);
		OpenALSandbox.error(AL.NO_ERROR);
		AL.sourceQueueBuffer(source, stereo);
		OpenALSandbox.error(AL.INVALID_OPERATION);
		Assert.equals(1, integer(source, AL.BUFFERS_QUEUED));

		AL.deleteSource(source);
		AL.deleteBuffers([mono, stereo]);
	}

	public function testANewBufferIsEmpty():Void
	{
		if (!hasContext()) return;

		var buffer = AL.createBuffer();

		Assert.isTrue(AL.isBuffer(buffer));
		Assert.equals(0, AL.getBufferi(buffer, AL.SIZE));
		OpenALSandbox.ints([0], AL.getBufferiv(buffer, AL.SIZE));
		OpenALSandbox.error(AL.NO_ERROR);

		AL.deleteBuffer(buffer);
	}

	public function testBufferDataGivesTheBufferItsFormat():Void
	{
		if (!hasContext()) return;

		var formats:Array<{format:Int, bits:Int, channels:Int, frequency:Int, size:Int}> = [
			{format: AL.FORMAT_MONO8, bits: 8, channels: 1, frequency: 8000, size: 300},
			{format: AL.FORMAT_MONO16, bits: 16, channels: 1, frequency: 22050, size: 4410},
			{format: AL.FORMAT_STEREO8, bits: 8, channels: 2, frequency: 11025, size: 600},
			{format: AL.FORMAT_STEREO16, bits: 16, channels: 2, frequency: 44100, size: 1200}
		];

		// A value of its own for each property, so none can be read in place of another
		for (expected in formats)
		{
			var buffer = AL.createBuffer();
			var data = new UInt8Array(expected.size);
			AL.bufferData(buffer, expected.format, data, data.length, expected.frequency);
			OpenALSandbox.error(AL.NO_ERROR);

			Assert.equals(expected.bits, AL.getBufferi(buffer, AL.BITS));
			Assert.equals(expected.channels, AL.getBufferi(buffer, AL.CHANNELS));
			Assert.equals(expected.frequency, AL.getBufferi(buffer, AL.FREQUENCY));
			Assert.equals(expected.size, AL.getBufferi(buffer, AL.SIZE));

			OpenALSandbox.ints([expected.bits], AL.getBufferiv(buffer, AL.BITS));
			OpenALSandbox.ints([expected.channels], AL.getBufferiv(buffer, AL.CHANNELS));
			OpenALSandbox.ints([expected.frequency], AL.getBufferiv(buffer, AL.FREQUENCY));
			OpenALSandbox.ints([expected.size], AL.getBufferiv(buffer, AL.SIZE));
			OpenALSandbox.error(AL.NO_ERROR);

			AL.deleteBuffer(buffer);
		}
	}

	public function testBufferDataTakesOnlyTheSizeGiven():Void
	{
		if (!hasContext()) return;

		var buffer = AL.createBuffer();
		var data = new UInt8Array(4096);

		AL.bufferData(buffer, AL.FORMAT_MONO16, data, 1000, OpenALSandbox.SAMPLE_RATE);
		Assert.equals(1000, AL.getBufferi(buffer, AL.SIZE));

		// Filling it again replaces what it held
		AL.bufferData(buffer, AL.FORMAT_MONO8, data, 4096, 8000);
		Assert.equals(4096, AL.getBufferi(buffer, AL.SIZE));
		Assert.equals(8, AL.getBufferi(buffer, AL.BITS));
		OpenALSandbox.error(AL.NO_ERROR);

		AL.deleteBuffer(buffer);
	}

	public function testBufferDataRefusesDataItCannotHold():Void
	{
		if (!hasContext()) return;

		var buffer = AL.createBuffer();
		var data = new UInt8Array(64);

		AL.bufferData(buffer, UNKNOWN, data, data.length, OpenALSandbox.SAMPLE_RATE);
		OpenALSandbox.error(AL.INVALID_ENUM, "an unknown format");

		// Three bytes is a sample and a half
		AL.bufferData(buffer, AL.FORMAT_MONO16, data, 3, OpenALSandbox.SAMPLE_RATE);
		OpenALSandbox.error(AL.INVALID_VALUE, "part of a sample");

		AL.bufferData(buffer, AL.FORMAT_MONO16, data, data.length, -1);
		OpenALSandbox.error(AL.INVALID_VALUE, "a negative frequency");

		Assert.equals(0, AL.getBufferi(buffer, AL.SIZE));
		AL.deleteBuffer(buffer);
	}

	public function testABufferInUseCannotBeRefilledOrDeleted():Void
	{
		if (!hasContext()) return;

		var source = AL.createSource();
		var buffer = OpenALSandbox.silence(50);
		var data = new UInt8Array(64);
		AL.sourcei(source, AL.BUFFER, buffer);

		AL.bufferData(buffer, AL.FORMAT_MONO16, data, data.length, OpenALSandbox.SAMPLE_RATE);
		OpenALSandbox.error(AL.INVALID_OPERATION, "refilling");
		Assert.equals(2204, AL.getBufferi(buffer, AL.SIZE));

		AL.deleteBuffer(buffer);
		OpenALSandbox.error(AL.INVALID_OPERATION, "deleting");
		Assert.isTrue(AL.isBuffer(buffer));

		// Once the source lets go of it, both work
		AL.sourcei(source, AL.BUFFER, null);
		AL.bufferData(buffer, AL.FORMAT_MONO16, data, data.length, OpenALSandbox.SAMPLE_RATE);
		Assert.equals(64, AL.getBufferi(buffer, AL.SIZE));
		AL.deleteBuffer(buffer);
		OpenALSandbox.error(AL.NO_ERROR);
		Assert.isFalse(AL.isBuffer(buffer));

		AL.deleteSource(source);
	}

	public function testGenBuffersMakesAsManyBuffersAsAskedFor():Void
	{
		if (!hasContext()) return;

		Assert.same([], AL.genBuffers(0));

		var buffers = AL.genBuffers(3);
		Assert.equals(3, buffers.length);

		// Each is a buffer of its own
		for (i in 0...buffers.length)
		{
			Assert.isTrue(AL.isBuffer(buffers[i]));
			var data = new UInt8Array((i + 1) * 100);
			AL.bufferData(buffers[i], AL.FORMAT_MONO16, data, data.length, OpenALSandbox.SAMPLE_RATE);
		}

		for (i in 0...buffers.length)
		{
			Assert.equals((i + 1) * 100, AL.getBufferi(buffers[i], AL.SIZE));
		}

		AL.deleteBuffers(buffers);
		OpenALSandbox.error(AL.NO_ERROR);

		for (buffer in buffers)
		{
			Assert.isFalse(AL.isBuffer(buffer));
		}
	}

	public function testBufferCallsOfTheWrongFormSetInvalidEnum():Void
	{
		if (!hasContext()) return;

		var buffer = OpenALSandbox.silence(50);

		// OpenAL 1.1 gives a buffer only whole numbers, which are read, not set
		AL.bufferf(buffer, AL.FREQUENCY, 1);
		OpenALSandbox.error(AL.INVALID_ENUM, "bufferf");
		AL.buffer3f(buffer, AL.FREQUENCY, 1, 1, 1);
		OpenALSandbox.error(AL.INVALID_ENUM, "buffer3f");
		AL.bufferfv(buffer, AL.FREQUENCY, [1.0]);
		OpenALSandbox.error(AL.INVALID_ENUM, "bufferfv");
		AL.bufferi(buffer, AL.FREQUENCY, 1);
		OpenALSandbox.error(AL.INVALID_ENUM, "bufferi");
		AL.buffer3i(buffer, AL.FREQUENCY, 1, 1, 1);
		OpenALSandbox.error(AL.INVALID_ENUM, "buffer3i");
		AL.bufferiv(buffer, AL.FREQUENCY, [1]);
		OpenALSandbox.error(AL.INVALID_ENUM, "bufferiv");

		// A query OpenAL refuses gives zero
		Assert.floatEquals(0.0, AL.getBufferf(buffer, AL.FREQUENCY));
		OpenALSandbox.error(AL.INVALID_ENUM, "getBufferf");
		Assert.equals(0, AL.getBufferi(buffer, UNKNOWN));
		OpenALSandbox.error(AL.INVALID_ENUM, "getBufferi");
		OpenALSandbox.floats([0.0, 0.0, 0.0], AL.getBuffer3f(buffer, AL.FREQUENCY));
		OpenALSandbox.error(AL.INVALID_ENUM, "getBuffer3f");
		OpenALSandbox.ints([0, 0, 0], AL.getBuffer3i(buffer, AL.FREQUENCY));
		OpenALSandbox.error(AL.INVALID_ENUM, "getBuffer3i");

		Assert.equals(OpenALSandbox.SAMPLE_RATE, AL.getBufferi(buffer, AL.FREQUENCY));
		AL.deleteBuffer(buffer);
	}

	public function testTheLoopPointsOfABufferReadBack():Void
	{
		if (!hasContext()) return;

		if (!AL.isExtensionPresent("AL_SOFT_loop_points"))
		{
			Assert.pass("This OpenAL gives a buffer no property of several whole numbers");
			return;
		}

		var loopPoints = AL.getEnumValue("AL_LOOP_POINTS_SOFT");
		var buffer = OpenALSandbox.silence(100);

		// The whole buffer, until they are set
		OpenALSandbox.ints([0, 2205], AL.getBufferiv(buffer, loopPoints, 2));

		AL.bufferiv(buffer, loopPoints, [100, 2000]);
		OpenALSandbox.ints([100, 2000], AL.getBufferiv(buffer, loopPoints, 2));
		OpenALSandbox.error(AL.NO_ERROR);

		// The loop cannot end before it starts
		AL.bufferiv(buffer, loopPoints, [2000, 100]);
		OpenALSandbox.error(AL.INVALID_VALUE);
		OpenALSandbox.ints([100, 2000], AL.getBufferiv(buffer, loopPoints, 2));

		AL.deleteBuffer(buffer);
	}

	public function testTheBlockAlignmentOfABufferReadsBack():Void
	{
		if (!hasContext()) return;

		if (!AL.isExtensionPresent("AL_SOFT_block_alignment"))
		{
			Assert.pass("This OpenAL gives a buffer no whole number to set");
			return;
		}

		var unpack = AL.getEnumValue("AL_UNPACK_BLOCK_ALIGNMENT_SOFT");
		var pack = AL.getEnumValue("AL_PACK_BLOCK_ALIGNMENT_SOFT");
		var buffer = AL.createBuffer();

		AL.bufferi(buffer, unpack, 64);
		AL.bufferi(buffer, pack, 128);
		Assert.equals(64, AL.getBufferi(buffer, unpack));
		Assert.equals(128, AL.getBufferi(buffer, pack));
		OpenALSandbox.error(AL.NO_ERROR);

		AL.bufferi(buffer, unpack, -1);
		OpenALSandbox.error(AL.INVALID_VALUE);
		Assert.equals(64, AL.getBufferi(buffer, unpack));

		AL.deleteBuffer(buffer);
	}

	private static function integer(source:ALSource, param:Int):Int
	{
		var value:Null<Int> = AL.getSourcei(source, param);
		return value != null ? value : 0;
	}

	private static function states(sources:Array<ALSource>):Array<Int>
	{
		return [for (source in sources) integer(source, AL.SOURCE_STATE)];
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
