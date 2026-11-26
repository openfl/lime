package media;

#if (lime_cffi && !macro && lime_sdl_sound)
import haxe.Timer;
import lime.media.AudioBuffer;
import lime.media.AudioManager;
import lime.media.AudioSource;
import lime.media.openal.AL;
import lime.media.openal.ALC;
import lime.media.openal.ALSource;
import lime.math.Vector4;
import lime.utils.AssetLibrary;
import lime.utils.Assets;
#end
import utest.Assert;
import utest.Test;

class AudioSourceTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro && lime_sdl_sound)
	// A stream that loops queues its next loop as it runs out, and counts it then. A completion
	// timer would count the loop again, and start the sound over.
	public function testAStreamThatLoopsKeepsNoTimerWhenItsPitchChanges():Void
	{
		var source = playStream(2);
		if (source == null) return;

		Assert.isNull(timerOf(source));
		source.pitch = 1.5;
		Assert.isNull(timerOf(source), "changing the pitch started a completion timer");

		source.dispose();
	}

	public function testAStreamMadeToLoopWhilePlayingDropsItsTimer():Void
	{
		var source = playStream(0);
		if (source == null) return;

		// Without loops, the timer completes the sound at its end
		Assert.notNull(timerOf(source));
		source.loops = 2;
		Assert.isNull(timerOf(source), "the completion timer was kept for a stream that loops");

		source.dispose();
	}

	public function testAStreamedAssetLeavesTheDecodedOneToGetAudioBuffer():Void
	{
		// The tests run before the application loads its own library
		if (Assets.getLibrary("audiotest") == null)
		{
			Assets.registerLibrary("audiotest", AssetLibrary.fromFile("manifest/default.json"));
		}

		var stream = Assets.getAudioBufferStream("audiotest:assets/tone.wav");
		Assert.notNull(stream);

		// A streamed sound has no data of its own to play from
		var decoded = Assets.getAudioBuffer("audiotest:assets/tone.wav");
		Assert.notNull(decoded);
		if (decoded == null) return;
		Assert.notNull(decoded.data, "getAudioBuffer gave the streamed sound");
		Assert.equals(2205 * 2, decoded.data.length);

		// The decoded sound is cached, and plays as well streamed
		Assert.equals(decoded, Assets.getAudioBufferStream("audiotest:assets/tone.wav"));
	}

	public function testSoundRecoveredWhileSuspendedStaysPaused():Void
	{
		if (ALC.getCurrentContext() == null)
		{
			trace("There is no audio output here, so recovery was not tested");
			Assert.pass();
			return;
		}

		var source = new AudioSource(AudioBuffer.fromBytes(AudioBufferTest.createWAV(AudioBufferTest.tone(22050 * 2))), 0, null, 10);
		source.play();
		AudioManager.suspend();

		// As when the output device is lost while the window is in the background
		@:privateAccess AudioManager.recoverOutputDevice();

		var before = source.currentTime;
		Sys.sleep(0.3);
		Assert.equals(before, source.currentTime, "the sound played on while the application was suspended");

		AudioManager.resume();
		source.dispose();
	}

	public function testPlayTogetherStartsTheSourcesInTheSameMixerUpdate():Void
	{
		if (ALC.getCurrentContext() == null)
		{
			trace("There is no audio output here, so playTogether was not tested");
			Assert.pass();
			return;
		}

		var bytes = AudioBufferTest.createWAV(AudioBufferTest.tone(22050 * 2));
		var instrumental = new AudioSource(AudioBuffer.fromBytes(bytes));
		var vocals = new AudioSource(AudioBuffer.fromBytes(bytes));
		var other = new AudioSource(AudioBuffer.fromBytes(bytes));

		// Missing and repeated sources are passed over
		AudioSource.playTogether([instrumental, null, vocals, instrumental]);

		Assert.equals(AL.PLAYING, stateOf(instrumental));
		Assert.equals(AL.PLAYING, stateOf(vocals));
		Assert.equals(AL.INITIAL, stateOf(other), "a source that was not listed was started");

		// Started in the same mixer update, the two have mixed the same number of
		// samples. They play until the output has mixed some of them, however long
		// a busy machine takes to get to that.
		var end = Timer.stamp() + 5;
		while (AL.getSourcei(handleOf(instrumental), AL.SAMPLE_OFFSET) == 0 && Timer.stamp() < end)
		{
			Sys.sleep(0.005);
		}

		// Read while playing, a mix could land between the two reads. Paused in one
		// call, the two stop in the same mixer update, and OpenAL Soft no longer
		// moves a voice it is pausing, so both offsets are final once
		// alSourcePausev returns.
		AL.sourcePausev([handleOf(instrumental), handleOf(vocals)]);
		Assert.equals(AL.PAUSED, stateOf(instrumental));
		Assert.equals(AL.PAUSED, stateOf(vocals));
		var instrumentalOffset = AL.getSourcei(handleOf(instrumental), AL.SAMPLE_OFFSET);
		var vocalsOffset = AL.getSourcei(handleOf(vocals), AL.SAMPLE_OFFSET);
		Assert.isTrue(instrumentalOffset > 0, "the sound did not play");
		Assert.equals(instrumentalOffset, vocalsOffset);

		// A source played on its own afterwards starts at once
		other.play();
		Assert.equals(AL.PLAYING, stateOf(other));

		instrumental.dispose();
		vocals.dispose();
		other.dispose();
	}

	public function testAPositionReadsBackAsItWasSet():Void
	{
		if (!hasOutput("positions")) return;

		var source = new AudioSource(AudioBuffer.fromBytes(AudioBufferTest.createWAV(AudioBufferTest.tone(2205))));

		source.position = new Vector4(1.5, -2.25, 3.125, 1);
		var position = source.position;
		Assert.equals(1.5, position.x);
		Assert.equals(-2.25, position.y);
		Assert.equals(3.125, position.z);

		// OpenAL holds the same position
		var values = AL.getSource3f(handleOf(source), AL.POSITION);
		Assert.equals("1.5,-2.25,3.125", values.join(","));

		source.position = new Vector4(-4, 0.5, 0);
		Assert.equals("-4,0.5,0", [source.position.x, source.position.y, source.position.z].join(","));

		source.dispose();
	}

	public function testAPositionedSourceIsNotAttenuatedByDistance():Void
	{
		if (!hasOutput("positions")) return;

		var source = new AudioSource(AudioBuffer.fromBytes(AudioBufferTest.createWAV(AudioBufferTest.tone(2205))));
		source.position = new Vector4(100, 0, -100);

		// Lime places sounds by position for panning, without the fall-off that OpenAL applies by default
		Assert.equals(AL.NONE, AL.getInteger(AL.DISTANCE_MODEL));

		source.dispose();
	}

	@Ignored("Waiting on #2226")
	public function testSettingAPositionLeavesTheDistanceModelAsTheApplicationSetIt():Void
	{
		if (!hasOutput("positions")) return;

		var source = new AudioSource(AudioBuffer.fromBytes(AudioBufferTest.createWAV(AudioBufferTest.tone(2205))));
		var before = AL.getInteger(AL.DISTANCE_MODEL);

		// The distance model belongs to the context, and is set once, so an application's own choice stays
		AL.distanceModel(AL.INVERSE_DISTANCE_CLAMPED);
		source.position = new Vector4(1, 2, 3);
		var after = AL.getInteger(AL.DISTANCE_MODEL);
		AL.distanceModel(before);

		Assert.equals(AL.INVERSE_DISTANCE_CLAMPED, after, "setting the position changed the distance model to " + after);
		source.dispose();
	}

	#if hl
	@Ignored("Waiting on #2226")
	public function testReadingAPositionAllocatesNothing():Void
	{
		// The position is only ever set through setPosition, so it needn't be asked of OpenAL
		if (!hasOutput("positions")) return;

		var source = new AudioSource(AudioBuffer.fromBytes(AudioBufferTest.createWAV(AudioBufferTest.tone(2205))));
		source.position = new Vector4(1, 2, 3);
		var x = 0.0;

		var total = 0.0, count = 0.0, memory = 0.0;
		@:privateAccess hl.Gc._stats(total, count, memory);
		var before = count;

		for (i in 0...100)
		{
			x += source.position.x;
		}

		@:privateAccess hl.Gc._stats(total, count, memory);
		Assert.equals(0.0, count - before, "reading the position 100 times allocated " + (count - before) + " times");
		Assert.equals(100.0, x);

		source.dispose();
	}
	#end

	private static function hasOutput(what:String):Bool
	{
		if (ALC.getCurrentContext() == null)
		{
			trace("There is no audio output here, so " + what + " were not tested");
			Assert.pass();
			return false;
		}

		return true;
	}

	private static function handleOf(source:AudioSource):ALSource
	{
		return @:privateAccess source.__backend.handle;
	}

	private static function stateOf(source:AudioSource):Int
	{
		return AL.getSourcei(handleOf(source), AL.SOURCE_STATE);
	}

	private static function playStream(loops:Int):AudioSource
	{
		if (ALC.getCurrentContext() == null)
		{
			// utest takes a warning as a failure, so the test passes, saying why
			trace("There is no audio output here, so streams were not played");
			Assert.pass();
			return null;
		}

		var buffer = AudioBuffer.fromBytesStream(AudioBufferTest.createWAV(AudioBufferTest.tone(22050)));
		var source = new AudioSource(buffer, 0, null, loops);
		source.play();
		return source;
	}

	private static function timerOf(source:AudioSource):Dynamic
	{
		return @:privateAccess source.__backend.timer;
	}
	#end
}
