package media;

#if (lime_cffi && !macro && lime_sdl_sound)
import lime.media.AudioBuffer;
import lime.media.AudioManager;
import lime.media.AudioSource;
import lime.media.openal.ALC;
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
