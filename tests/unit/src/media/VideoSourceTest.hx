package media;

import haxe.Timer;
#if (lime_cffi && lime_openal)
import lime.media.AudioManager;
import lime.media.openal.AL;
import lime.media.openal.ALC;
#end
import lime.media.VideoClockMode;
import lime.media.VideoDecoder;
import lime.media.VideoFrame;
import lime.media.VideoSource;
import lime.system.System;
import lime.system.ThreadPool;
#if (lime_cffi && lime_openal)
import lime.utils.Int16Array;
#end
import utest.Assert;
import utest.Test;

class VideoSourceTest extends Test
{
	private static inline var PATH = "assets/video.mp4";

	// Opening can take seconds on a busy or cold machine, such as a CI runner
	private static inline var TIMEOUT = 15;

	public function new()
	{
		super();
	}

	public function testIsSupported():Void
	{
		#if flash
		Assert.isFalse(VideoSource.isSupported);
		#elseif js
		Assert.isTrue(VideoSource.isSupported);
		#else
		Assert.equals(VideoDecoder.isSupported, VideoSource.isSupported);
		#end
	}

	#if sys
	public function testOpenMissingFile():Void
	{
		var video = new VideoSource();

		Assert.isFalse(video.open("assets/missing.mp4"));
		Assert.isNull(video.source);
		Assert.isFalse(video.playing);
		Assert.equals(0, video.length);
		Assert.isFalse(video.readFrame(new VideoFrame()));
	}

	public function testLoadingFromAFileFinishesOnTheMainThread():Void
	{
		if (!VideoSource.isSupported)
		{
			Assert.pass();
			return;
		}

		// Each video opens on a thread of its own, and its future finishes on the
		// main thread when the application's loop runs that thread's events
		var loaded:VideoSource = null;
		var failed = false;
		var onMainThread = false;
		var missingFailed = false;

		var future = VideoSource.loadFromFile(PATH);
		future.onComplete(function(video)
		{
			loaded = video;
			onMainThread = ThreadPool.isMainThread();
		});
		future.onError(function(error) failed = true);
		VideoSource.loadFromFile("assets/missing.mp4").onError(function(error) missingFailed = true);

		var end = Timer.stamp() + TIMEOUT;

		while (((loaded == null && !failed) || !missingFailed) && Timer.stamp() < end)
		{
			runMainThreadEvents();
			Sys.sleep(0.01);
		}

		Assert.isTrue(missingFailed, "loading a missing file did not fail");

		if (failed)
		{
			Assert.warn("Cannot decode H.264 and AAC here, so loading a video was not tested");
			return;
		}

		Assert.notNull(loaded, "loading did not finish");
		if (loaded == null) return;

		Assert.isTrue(onMainThread, "loading finished on another thread");
		Assert.equals(PATH, loaded.source);
		Assert.isTrue(loaded.hasVideo);
		Assert.isTrue(loaded.length > 0);
		loaded.dispose();
	}

	public function testPlaybackState():Void
	{
		var video = open();
		if (video == null) return;

		Assert.equals(PATH, video.source);
		Assert.equals(640, video.width);
		Assert.equals(360, video.height);
		Assert.isTrue(Math.abs(video.length - 2000) <= 100, "length " + video.length);
		Assert.isTrue(video.hasAudio);
		Assert.isFalse(video.playing);
		Assert.equals(0, video.currentTime);

		video.play();
		Assert.isTrue(video.playing);

		video.pause();
		Assert.isFalse(video.playing);

		video.currentTime = 1000;
		Assert.equals(1000, video.currentTime);

		video.stop();
		Assert.isFalse(video.playing);
		Assert.equals(0, video.currentTime);

		video.dispose();
		Assert.isNull(video.source);
	}

	public function testPausedVideoShowsItsFirstFrame():Void
	{
		var video = open();
		if (video == null) return;

		var frame = new VideoFrame();
		Assert.isTrue(nextFrame(video, frame));
		Assert.isTrue(frame.time < 0.05, "first frame at " + frame.time);

		// While paused, no later frame becomes due
		Assert.isFalse(video.readFrame(frame));
		video.dispose();
	}

	public function testSeekShowsTheFrameAtTheNewTime():Void
	{
		var video = open();
		if (video == null) return;

		var frame = new VideoFrame();
		video.currentTime = 1500;

		Assert.isTrue(nextFrame(video, frame));
		Assert.isTrue(frame.time <= 1.501 && frame.time + frame.duration > 1.5, "frame at " + frame.time);
		video.dispose();
	}

	public function testSeekingAgainWhilePausedPlaysFromTheNewTime():Void
	{
		var video = open();
		if (video == null) return;

		// Each seek buffers the audio at its time while paused, so the second
		// has to replace what the first queued
		var frame = new VideoFrame();
		video.currentTime = 1500;
		run(video, frame, 0.3);
		video.currentTime = 200;
		run(video, frame, 0.3);

		// Audio left from the first seek would put the clock near 1500 ms
		video.play();
		var latest = 0;
		var end = Timer.stamp() + 0.5;

		while (Timer.stamp() < end)
		{
			video.readFrame(frame);
			if (video.currentTime > latest) latest = video.currentTime;
			Sys.sleep(0.005);
		}

		var time = video.currentTime;
		video.dispose();

		Assert.isTrue(latest <= 1000, "playing from 200 ms, the clock reached " + latest + " ms");
		Assert.isTrue(time >= 200, "playing from 200 ms, the clock read " + time + " ms");
	}

	public function testClockRunsInRealTime():Void
	{
		var video = open();
		if (video == null) return;

		var frame = new VideoFrame();
		startPlaying(video, frame);

		var clock = measureRate(video, frame, 1);
		Assert.floatEquals(1, clock.rate, 0.1, "the clock ran at " + clock.rate + " times real time, standing still for up to " + clock.longestStill + " ms");
		video.dispose();
	}

	public function testClockRunsInRealTimeAfterSeekingWhilePlaying():Void
	{
		var video = open();
		if (video == null) return;

		var frame = new VideoFrame();
		startPlaying(video, frame);

		video.currentTime = 1000;
		waitForTime(video, frame, 1050);

		var clock = measureRate(video, frame, 0.6);
		Assert.floatEquals(1, clock.rate, 0.1, "after seeking, the clock ran at " + clock.rate + " times real time, standing still for up to " + clock.longestStill + " ms");
		video.dispose();
	}

	public function testClockMovesEvenly():Void
	{
		var video = open();
		if (video == null) return;

		var frame = new VideoFrame();
		startPlaying(video, frame);

		// The audio position only moves when the output mixes, every 20 ms here
		// and 60 ms or more on some outputs. A clock that followed it would show
		// frames in uneven bursts.
		var clock = measureRate(video, frame, 1);
		Assert.isTrue(clock.longestStill < 10, "the clock stood still for up to " + clock.longestStill + " ms at a time");
		video.dispose();
	}

	public function testEveryClockModeKeepsTime():Void
	{
		var modes:Array<VideoClockMode> = [VideoClockMode.SMOOTH, VideoClockMode.AUDIO, VideoClockMode.INTERPOLATED, VideoClockMode.MONOTONIC];

		for (mode in modes)
		{
			var video = open();
			if (video == null) return;

			video.clockMode = mode;
			var frame = new VideoFrame();
			startPlaying(video, frame);

			var clock = measureRate(video, frame, 1);
			video.dispose();

			// The audio clock moves in steps, a mix apart, which a second of readings
			// fits less closely when mixes are 60 ms or more apart
			var name = clockModeName(mode);
			Assert.floatEquals(1, clock.rate, mode == VideoClockMode.AUDIO ? 0.15 : 0.1, "the " + name + " clock ran at " + clock.rate + " times real time");

			// The audio clock waits for each mix, and the interpolated one is set
			// back to the sound at each, so only these two move on evenly
			if (mode == VideoClockMode.SMOOTH || mode == VideoClockMode.MONOTONIC)
			{
				Assert.isTrue(clock.longestStill < 10, "the " + name + " clock stood still for up to " + clock.longestStill + " ms at a time");
				Assert.equals(0, clock.furthestBack, "the " + name + " clock went back " + clock.furthestBack + " ms");
			}
		}
	}

	public function testFramesThatFallFarBehindAreCaughtUp():Void
	{
		var video = open();
		if (video == null) return;

		var frame = new VideoFrame();
		startPlaying(video, frame);

		// No frames are read for a while, as when the window is hidden, while the
		// sound plays on
		var backend = @:privateAccess video.__backend;
		var end = Timer.stamp() + 1.2;

		while (Timer.stamp() < end)
		{
			@:privateAccess backend.update();
			Sys.sleep(0.005);
		}

		// The next frame is from where the sound is, not from where reading stopped
		var start = Timer.stamp();

		while (!video.readFrame(frame) && Timer.stamp() - start < TIMEOUT)
		{
			Sys.sleep(0.005);
		}

		var behind = video.currentTime - frame.time * 1000;
		video.dispose();

		Assert.isTrue(Math.abs(behind) < 250, "the first frame after reading again was " + behind + " ms behind the clock");
	}

	public function testFramesKeepUpWithTheClock():Void
	{
		var video = open();
		if (video == null) return;

		var frame = new VideoFrame();
		startPlaying(video, frame);

		var frames = 0;
		var worstLag = 0.0;
		var end = Timer.stamp() + 1;

		while (Timer.stamp() < end)
		{
			if (video.readFrame(frame))
			{
				frames++;

				// A frame is shown while the clock is within it. One that arrives
				// later shows the decoder falling behind.
				var lag = video.currentTime / 1000 - (frame.time + frame.duration);
				if (lag > worstLag) worstLag = lag;
			}

			Sys.sleep(0.002);
		}

		video.dispose();

		// A slow loop skips the frames it missed, so fewer than 30 a second is
		// fine as long as each one is current
		Assert.isTrue(frames >= 10, frames + " frames in a second");
		Assert.isTrue(worstLag < 0.1, "a frame was shown " + Math.round(worstLag * 1000) + " ms after it ended");
	}

	public function testGainAndLoops():Void
	{
		var video = open();
		if (video == null) return;

		video.gain = 0.5;
		video.loops = 2;

		Assert.equals(0.5, video.gain);
		Assert.equals(2, video.loops);
		video.dispose();
	}

	public function testPanStaysInRange():Void
	{
		var video = open();
		if (video == null) return;

		Assert.equals(0.0, video.pan);

		video.pan = -0.5;
		Assert.equals(-0.5, video.pan);

		video.pan = 2;
		Assert.equals(1.0, video.pan);
		video.dispose();
	}

	#if (lime_cffi && lime_openal)
	public function testClockCarriesOnWhenTheAudioOutputStalls():Void
	{
		var video = open();
		if (video == null) return;

		var context = ALC.getCurrentContext();
		var device = context != null ? ALC.getContextsDevice(context) : null;

		if (device == null)
		{
			Assert.warn("There is no audio output here, so a stalled output was not tested");
			video.dispose();
			return;
		}

		var frame = new VideoFrame();
		startPlaying(video, frame);

		// A paused device stops taking audio, as a sound server that hangs does
		var before = video.currentTime;
		ALC.pauseDevice(device);
		run(video, frame, 1.6);
		ALC.resumeDevice(device);

		var moved = video.currentTime - before;
		video.dispose();

		Assert.isTrue(moved >= 500, "the clock moved " + moved + " ms in 1.6 s while the output was stalled");
	}

	public function testBadAudioPositionsDoNotMoveTheClock():Void
	{
		var video = open();
		if (video == null) return;

		if (!hasAudioOutput())
		{
			video.dispose();
			return;
		}

		var frame = new VideoFrame();
		startPlaying(video, frame);

		// A source whose device went away can report any position, here an hour
		// past the audio that is queued
		var before = video.currentTime;
		@:privateAccess video.__backend.lockAudio();
		var bufferTimes:Array<Float> = @:privateAccess video.__backend.bufferTimes;

		for (i in 0...bufferTimes.length)
		{
			bufferTimes[i] += 3600;
		}

		@:privateAccess video.__backend.unlockAudio();

		var latest = 0;
		var end = Timer.stamp() + 0.4;

		while (Timer.stamp() < end)
		{
			video.readFrame(frame);
			if (video.currentTime > latest) latest = video.currentTime;
			Sys.sleep(0.005);
		}

		video.dispose();

		Assert.isTrue(latest < before + 1000, "after a bad audio position at " + before + " ms, the clock reached " + latest + " ms");
		Assert.isTrue(latest > before, "the clock stopped at " + before + " ms");
	}

	public function testSuspendedAudioHoldsTheVideo():Void
	{
		var video = open();
		if (video == null) return;

		if (!hasAudioOutput())
		{
			video.dispose();
			return;
		}

		var frame = new VideoFrame();
		startPlaying(video, frame);

		// Lime suspends audio while the window is hidden, which is not a stall,
		// so the video waits for it
		var before = video.currentTime;
		AudioManager.suspend();
		run(video, frame, 1.6);
		var held = video.currentTime - before;
		AudioManager.resume();
		run(video, frame, 0.4);
		var resumed = video.currentTime - before - held;

		video.dispose();

		Assert.isTrue(held < 150, "the clock moved " + held + " ms while audio was suspended");
		Assert.isTrue(resumed >= 200, "the clock moved " + resumed + " ms in 0.4 s after audio resumed");
	}

	public function testTimerClocksHoldWhileSuspended():Void
	{
		if (!VideoSource.isSupported)
		{
			Assert.pass();
			return;
		}

		// A video without sound, and a clock on the timer alone, hold while Lime
		// suspends audio too, rather than running on without it
		for (setup in [{path: "assets/video-noaudio.mp4", mode: VideoClockMode.SMOOTH}, {path: PATH, mode: VideoClockMode.MONOTONIC}])
		{
			var video = new VideoSource();

			if (!video.open(setup.path))
			{
				Assert.warn("Cannot decode " + setup.path + " here, so it was not tested");
				continue;
			}

			video.clockMode = setup.mode;

			var frame = new VideoFrame();
			startPlaying(video, frame);

			var before = video.currentTime;
			AudioManager.suspend();
			run(video, frame, 0.4);
			var held = video.currentTime - before;
			AudioManager.resume();
			run(video, frame, 0.3);
			var resumed = video.currentTime - before - held;

			video.dispose();

			Assert.isTrue(held < 100, setup.path + " moved " + held + " ms while audio was suspended");
			Assert.isTrue(resumed >= 150, setup.path + " moved " + resumed + " ms in 0.3 s after audio resumed");
		}
	}

	public function testSoundPlaysOnThroughAPauseInUpdates():Void
	{
		var video = open();
		if (video == null) return;

		if (!hasAudioOutput())
		{
			video.dispose();
			return;
		}

		var frame = new VideoFrame();
		startPlaying(video, frame);
		run(video, frame, 0.3);

		// The application stops updating for a while, as for a garbage collection
		// or a blocking load, and the sound already queued keeps playing
		var backend = @:privateAccess video.__backend;
		@:privateAccess backend.lockAudio();
		var bufferTimes:Array<Float> = @:privateAccess backend.bufferTimes;
		var queued = bufferTimes.length > 0 ? bufferTimes[bufferTimes.length - 1] + 0.04 - @:privateAccess backend.getAudioPosition() : 0;
		@:privateAccess backend.unlockAudio();
		var start = System.getTimer();
		Sys.sleep(0.3);
		var paused = (System.getTimer() - start) / 1000;
		var state = AL.getSourcei(@:privateAccess backend.handle, AL.SOURCE_STATE);
		video.dispose();

		var described = Math.round(queued * 1000) + " ms queued, paused for " + Math.round(paused * 1000) + " ms";
		Assert.isTrue(queued >= 0.4, "only " + described);

		// A busy machine can pause the test for longer than asked, or have its
		// output catch up in a burst afterwards, which no queue survives
		if (paused < queued - 0.15)
		{
			Assert.equals(AL.PLAYING, state, "the sound ran out with " + described);
		}
	}

	#if (lime_threads && (target.threaded || cpp || neko))
	public function testSoundPlaysOnThroughALongPauseInUpdates():Void
	{
		var video = open();
		if (video == null) return;

		if (!hasAudioOutput())
		{
			video.dispose();
			return;
		}

		var frame = new VideoFrame();
		startPlaying(video, frame);

		// Longer than the sound that is queued at once, which another thread tops up
		var start = System.getTimer();
		Sys.sleep(1);
		var paused = System.getTimer() - start;
		var state = AL.getSourcei(@:privateAccess video.__backend.handle, AL.SOURCE_STATE);
		video.dispose();

		Assert.equals(AL.PLAYING, state, "the sound ran out during a pause of " + paused + " ms");
	}
	#end

	public function testLoopsFollowOnWithoutAPause():Void
	{
		var video = open();
		if (video == null) return;

		if (!hasAudioOutput())
		{
			video.dispose();
			return;
		}

		var completed = false;
		video.onComplete.add(function() completed = true);
		video.loops = 1;

		var frame = new VideoFrame();
		startPlaying(video, frame);

		// The sound plays straight on into the next loop, and the frames keep coming
		var stopped = 0;
		var wrapped = false;
		var lastTime = video.currentTime;
		var lastFrame = System.getTimer();
		var longestGap = 0;
		var decoder = @:privateAccess video.__backend.decoder;
		var handovers = 0;
		var end = Timer.stamp() + TIMEOUT;

		while (!completed && Timer.stamp() < end)
		{
			if (@:privateAccess video.__backend.decoder != decoder && @:privateAccess video.__backend.decoder != null)
			{
				decoder = @:privateAccess video.__backend.decoder;
				handovers++;
			}

			if (video.readFrame(frame))
			{
				var now = System.getTimer();
				if (now - lastFrame > longestGap) longestGap = now - lastFrame;
				lastFrame = now;
			}

			// The last loop's sound ends a little before its picture, as in the file,
			// so the sound is checked until halfway through it
			var crossing = handovers == 0 || video.currentTime < video.length / 2;
			if (!completed && crossing && AL.getSourcei(@:privateAccess video.__backend.handle, AL.SOURCE_STATE) != AL.PLAYING) stopped++;

			var time = video.currentTime;
			if (time < lastTime - 500) wrapped = true;
			lastTime = time;
			pause(0.005);
		}

		video.dispose();

		Assert.isTrue(completed, "playback did not complete");
		Assert.isTrue(wrapped, "currentTime did not start again for the second loop");
		Assert.equals(1, handovers, "the next loop did not take over from the first");
		Assert.equals(0, stopped, "the sound stopped across the loop");
		Assert.isTrue(longestGap < 250, "frames stopped for " + longestGap + " ms");
	}

	public function testPanTurnsDownTheOppositeChannel():Void
	{
		for (pan in [-1.0, 1.0])
		{
			var video = open();
			if (video == null) return;

			if (!hasAudioOutput())
			{
				video.dispose();
				return;
			}

			// Both channels of the test video carry a loud tone
			var frame = new VideoFrame();
			video.pan = pan;
			startPlaying(video, frame);

			var peaks = nextQueuedPeaks(video, frame);
			video.dispose();

			var opposite = pan < 0 ? peaks[1] : peaks[0];
			var kept = pan < 0 ? peaks[0] : peaks[1];
			Assert.equals(0, opposite, "with pan " + pan + ", the opposite channel peaked at " + opposite);
			Assert.isTrue(kept > 1000, "with pan " + pan + ", the panned channel peaked at " + kept);
		}
	}

	public function testPanReachesTheSoundAlreadyQueued():Void
	{
		var video = open();
		if (video == null) return;

		if (!hasAudioOutput())
		{
			video.dispose();
			return;
		}

		// Opening fills the queue with sound before anything plays, so none of it
		// is played, and none is added, while the pan changes
		var backend = @:privateAccess video.__backend;
		var end = Timer.stamp() + TIMEOUT;
		while (@:privateAccess backend.freeBuffers.length > 0 && Timer.stamp() < end) pause(0.01);
		var queued = @:privateAccess backend.bufferTimes.length;

		video.pan = 1;

		var peaks = bufferedPeaks(video);
		video.dispose();

		Assert.isTrue(queued > 0, "no sound was queued on opening");
		Assert.equals(0, peaks[0], "with pan 1, sound queued before it was set peaked at " + peaks[0] + " on the left");
		Assert.isTrue(peaks[1] > 1000, "with pan 1, sound queued before it was set peaked at " + peaks[1] + " on the right");
	}

	public function testPanWhilePlayingCarriesOnFromTheSameSound():Void
	{
		var video = open();
		if (video == null) return;

		if (!hasAudioOutput())
		{
			video.dispose();
			return;
		}

		var frame = new VideoFrame();
		startPlaying(video, frame);
		run(video, frame, 0.3);

		// The sound is queued again from where the output is, so it neither
		// repeats nor skips, and plays on
		var backend = @:privateAccess video.__backend;
		var before = @:privateAccess backend.getAudioPosition();
		video.pan = -1;
		var after = @:privateAccess backend.getAudioPosition();
		var state = AL.getSourcei(@:privateAccess backend.handle, AL.SOURCE_STATE);

		var clock = video.currentTime;
		run(video, frame, 0.3);
		var moved = video.currentTime - clock;
		video.dispose();

		Assert.isTrue(Math.abs(after - before) < 0.05, "the sound moved from " + before + " s to " + after + " s");
		Assert.equals(AL.PLAYING, state, "the sound stopped");
		Assert.isTrue(moved > 200, "the clock moved " + moved + " ms in 0.3 s");
	}

	public function testVideoPlaysOnWhenTheAudioDeviceIsReplaced():Void
	{
		var video = open();
		if (video == null) return;

		if (!hasAudioOutput())
		{
			video.dispose();
			return;
		}

		var frame = new VideoFrame();
		startPlaying(video, frame);

		// Lime replaces the OpenAL context when the output device is unplugged or
		// changes, and the sources move to the new one
		var before = video.currentTime;
		@:privateAccess AudioManager.recoverOutputDevice();
		run(video, frame, 0.8);

		var moved = video.currentTime - before;
		var error = AL.getError();
		video.dispose();

		Assert.isTrue(moved >= 500, "the clock moved " + moved + " ms in 0.8 s after the device was replaced");
		Assert.equals(AL.NO_ERROR, error);
	}

	public function testMonotonicClockBringsTheSoundBackAfterAStall():Void
	{
		var video = open();
		if (video == null) return;

		var context = ALC.getCurrentContext();
		var device = context != null ? ALC.getContextsDevice(context) : null;

		if (device == null)
		{
			Assert.warn("There is no audio output here, so a stalled output was not tested");
			video.dispose();
			return;
		}

		video.clockMode = MONOTONIC;
		var frame = new VideoFrame();
		startPlaying(video, frame);

		// The clock carries on while the output takes no audio, and afterwards the
		// sound is moved to the clock
		ALC.pauseDevice(device);
		var clock = measureRate(video, frame, 0.6);
		ALC.resumeDevice(device);
		run(video, frame, 0.5);

		// The sound is moved back once it is more than AUDIO_DRIFT_SECONDS (0.1 s)
		// from the clock, and its position moves a mix at a time, 56 to 84 ms on
		// some outputs, so the gap is averaged over many readings. Left as it was,
		// it would be the 0.6 s the output stalled for.
		var backend = @:privateAccess video.__backend;
		var gaps = 0.0;
		var readings = 0;
		var end = Timer.stamp() + 0.3;

		while (Timer.stamp() < end)
		{
			@:privateAccess backend.lockAudio();
			if (@:privateAccess backend.bufferTimes.length > 0)
			{
				gaps += Math.abs(@:privateAccess backend.getAudioPosition() * 1000 - video.currentTime);
				readings++;
			}
			@:privateAccess backend.unlockAudio();

			video.readFrame(frame);
			pause(0.005);
		}

		video.dispose();

		var gap = readings > 0 ? gaps / readings : Math.POSITIVE_INFINITY;
		Assert.floatEquals(1, clock.rate, 0.1, "while the output stalled, the clock ran at " + clock.rate + " times real time");
		Assert.isTrue(gap < 150, "after the output came back, the sound was " + Math.round(gap) + " ms from the clock on average");
	}

	#if lime_openalsoft
	public function testClockFollowsTheSoundBeingHeard():Void
	{
		if (!hasAudioOutput()) return;

		var modes:Array<VideoClockMode> = [VideoClockMode.SMOOTH, VideoClockMode.AUDIO, VideoClockMode.INTERPOLATED];

		for (mode in modes)
		{
			var video = open();
			if (video == null) return;

			video.clockMode = mode;
			var frame = new VideoFrame();
			startPlaying(video, frame);
			run(video, frame, 0.3);

			var heard = measureHeard(video, frame, 300);
			video.dispose();

			var name = clockModeName(mode);

			if (heard.mixes < 5)
			{
				Assert.fail("the position of the " + name + " clock's sound only moved " + heard.mixes + " times");
				continue;
			}

			Assert.isTrue(Math.abs(heard.offset) < 10, "when the " + name + " clock's sound was mixed, the clock was " + heard.offset + " ms from what was heard ("
				+ heard.latency + ", reads " + heard.readGap + " ms apart)");
		}
	}

	public function testSmoothClockLearnsAnOutputThatRunsFast():Void
	{
		var video = open();
		if (video == null) return;

		if (!hasAudioOutput())
		{
			video.dispose();
			return;
		}

		// Playing the sound 5% fast stands in for an output whose clock runs fast
		// against the timer, as in some virtual machines. Steering alone would
		// leave the clock behind by however far it takes to run that much faster.
		// The rate is learned during the first pass and kept from then on, through
		// the loop.
		var frame = new VideoFrame();
		video.loops = 1;
		AL.sourcef(@:privateAccess video.__backend.handle, AL.PITCH, 1.05);
		startPlaying(video, frame);
		run(video, frame, 2.2);

		var heard = measureHeard(video, frame, 200);
		video.dispose();

		// What was learned would carry on to the next video
		@:privateAccess lime._internal.backend.native.NativeVideoSource.timerDrift = 0;

		// Outputs that mix further apart give fewer, rougher readings
		var tolerance = Math.max(10, heard.period / 5);
		Assert.isTrue(heard.mixes >= 5, "the position of the sound only moved " + heard.mixes + " times");
		Assert.isTrue(Math.abs(heard.offset) < tolerance, "with the sound 5% fast, the clock was " + heard.offset + " ms from what was heard ("
			+ heard.latency + ", reads " + heard.readGap + " ms apart)");
	}
	#end
	#end

	#if (lime_cffi && lime_openal)
	private static function nextQueuedPeaks(video:VideoSource, frame:VideoFrame):Array<Int>
	{
		// Sound skipped to catch up with the clock is read into the same buffer
		// and dropped, so the peaks are read once a buffer has been queued after it
		var backend = @:privateAccess video.__backend;
		var queued = -1.0;
		var peaks:Array<Int> = null;
		var end = Timer.stamp() + TIMEOUT;

		while (peaks == null && Timer.stamp() < end)
		{
			@:privateAccess backend.lockAudio();
			var times:Array<Float> = @:privateAccess backend.bufferTimes;
			var last = times.length > 0 ? times[times.length - 1] : -1.0;

			if (@:privateAccess backend.audioSkipping)
			{
				queued = -1;
			}
			else if (queued < 0)
			{
				queued = last;
			}
			else if (last != queued)
			{
				peaks = bufferedPeaks(video);
			}

			@:privateAccess backend.unlockAudio();

			video.readFrame(frame);
			pause(0.005);
		}

		Assert.notNull(peaks, "no sound was queued while playing");
		return peaks != null ? peaks : [0, 0];
	}

	private static function bufferedPeaks(video:VideoSource):Array<Int>
	{
		// The left and right peaks of the audio last given to OpenAL
		var samples:Int16Array = @:privateAccess video.__backend.audioSamples;
		var peaks = [0, 0];

		for (i in 0...samples.length)
		{
			var value = Std.int(Math.abs(samples[i]));
			if (value > peaks[i & 1]) peaks[i & 1] = value;
		}

		return peaks;
	}

	#if lime_openalsoft
	private static function measureHeard(video:VideoSource, frame:VideoFrame, reads:Int):HeardOffset
	{
		// Each time the position moves, the output has just mixed. Outputs that
		// measure their latency report what is heard then, and most readings fall
		// below the most seen. The others report a fixed estimate, all but one
		// period, so what is heard then is a period further back. OpenAL Soft
		// also takes up to a period off an estimate now and then, when a mix lands
		// while it reads, so the most seen is the estimate. The audio clock should
		// match what is heard at the mix. The others run on to the present,
		// placing the mix halfway since they last read it.
		var device = ALC.getContextsDevice(ALC.getCurrentContext());
		var refresh = ALC.getIntegerv(device, ALC.REFRESH, 1)[0];
		var period = refresh > 0 ? 1000 / refresh : 0;
		var backend = @:privateAccess video.__backend;
		var runsOn = video.clockMode != VideoClockMode.AUDIO;
		var lastMixed = Math.NaN;
		var lastRead = -1;
		var most = 0.0;
		var belowMost = 0;
		var samples = 0;
		var gaps = 0.0;
		var latencies:Array<Float> = [];
		var offsets:Array<Float> = [];

		for (i in 0...reads)
		{
			video.readFrame(frame);

			// The clock on the timeline the sound is queued on, which runs on
			// through each loop, where currentTime starts again
			var clock = @:privateAccess backend.getTime() * 1000;
			var read = System.getTimer();

			// The queue and the position are read together, as the sound is queued
			// from another thread
			@:privateAccess backend.lockAudio();
			var bufferTimes:Array<Float> = @:privateAccess backend.bufferTimes;
			var values = bufferTimes.length > 0 ? AL.getSourcedvSOFT(@:privateAccess backend.handle, AL.SEC_OFFSET_LATENCY_SOFT, 2) : null;
			var queueStart = bufferTimes.length > 0 ? bufferTimes[0] : 0;
			@:privateAccess backend.unlockAudio();

			if (values != null)
			{
				var mixed = (queueStart + values[0]) * 1000;
				var latency = values[1] * 1000;

				most = Math.max(most, latency);
				if (latency < most - 0.1) belowMost++;
				samples++;

				if (!Math.isNaN(lastMixed) && Math.abs(mixed - lastMixed) > 0.1)
				{
					var gap = lastRead >= 0 ? read - lastRead : 0;
					offsets.push(clock - mixed - (runsOn ? gap / 2 : 0));
					latencies.push(latency);
					gaps += gap;
				}

				lastMixed = mixed;
			}

			lastRead = read;
			pause(0.005);
		}

		var measured = samples > 0 && belowMost / samples > 0.3;
		var offset = 0.0;

		for (i in 0...offsets.length)
		{
			offset += (offsets[i] + (measured ? latencies[i] : most + period)) / offsets.length;
		}

		return {
			offset: offset,
			mixes: offsets.length,
			period: period,
			latency: measured ? "measured latency" : "estimated latency, " + period + " ms periods",
			readGap: offsets.length > 0 ? Math.round(gaps / offsets.length) : 0
		};
	}
	#end

	private static function hasAudioOutput():Bool
	{
		if (ALC.getCurrentContext() != null) return true;

		Assert.warn("There is no audio output here, so it was not tested");
		return false;
	}
	#end

	private static function clockModeName(mode:VideoClockMode):String
	{
		return switch (mode)
		{
			case AUDIO: "audio";
			case INTERPOLATED: "interpolated";
			case MONOTONIC: "monotonic";
			default: "smooth";
		}
	}

	private static function startPlaying(video:VideoSource, frame:VideoFrame):Void
	{
		// The clock holds until the first frame and the audio arrive, which can
		// take a moment after opening
		video.play();
		waitForTime(video, frame, 50);
	}

	public function testDisposingInTheCompleteHandler():Void
	{
		if (!VideoSource.isSupported)
		{
			Assert.pass();
			return;
		}

		// As an intro does when it ends, while the frame that ends it is read
		var video = new VideoSource("assets/video-noaudio.mp4");

		if (video.source == null)
		{
			Assert.warn("Cannot decode H.264 here, so it was not tested");
			return;
		}

		var completed = false;

		video.onComplete.add(function()
		{
			completed = true;
			video.dispose();
		});

		video.play();

		var frame = new VideoFrame();
		var start = Timer.stamp();

		while (!completed && Timer.stamp() - start < TIMEOUT)
		{
			video.readFrame(frame);
			Sys.sleep(0.005);
		}

		Assert.isTrue(completed, "playback did not complete");
		Assert.isFalse(video.readFrame(frame));
		Assert.isFalse(video.playing);

		// Playing a disposed source does nothing
		video.play();
		Assert.isFalse(video.playing);
	}

	public function testSeekingPastTheEndCompletes():Void
	{
		var video = open();
		if (video == null) return;

		var completed = false;
		video.onComplete.add(function() completed = true);

		var frame = new VideoFrame();
		startPlaying(video, frame);

		var length = video.length;
		video.currentTime = length + 5000;

		var start = Timer.stamp();

		while (!completed && Timer.stamp() - start < TIMEOUT)
		{
			video.readFrame(frame);
			Sys.sleep(0.005);
		}

		Assert.isTrue(completed, "playback did not complete");
		Assert.isTrue(Math.abs(video.currentTime - length) < 50, "the clock is at " + video.currentTime + " ms of " + length);
		Assert.isFalse(video.playing);

		// Playing again starts over
		video.play();
		waitForTime(video, frame, 50);
		Assert.isTrue(video.currentTime < 1000, "playing again went to " + video.currentTime + " ms");

		// As does playing a video that was moved to its end while paused
		video.pause();
		video.currentTime = length;
		completed = false;
		video.play();
		waitForTime(video, frame, 50);
		Assert.isFalse(completed, "playing from the end completed straight away");
		Assert.isTrue(video.currentTime < 1000, "playing from the end went to " + video.currentTime + " ms");
		video.dispose();
	}

	public function testStreamsAndDisplaySize():Void
	{
		if (!VideoSource.isSupported)
		{
			Assert.pass();
			return;
		}

		var video = new VideoSource("assets/video-rotated.mp4");

		if (video.source == null)
		{
			Assert.warn("Cannot decode H.264 here, so it was not tested");
			return;
		}

		// Shown upright whether the platform turns the frames or reports the turn
		Assert.isTrue(video.hasVideo);
		Assert.isFalse(video.hasAudio);
		Assert.isTrue(video.rotation == 90 && video.width == 320 || video.rotation == 0 && video.width == 180,
			"rotation " + video.rotation + " for " + video.width + "x" + video.height + " frames");
		Assert.floatEquals(1, video.pixelAspectRatio);
		Assert.equals(180, video.displayWidth);
		Assert.equals(320, video.displayHeight);
		video.dispose();

		Assert.isFalse(video.hasVideo);
		Assert.equals(0, video.displayWidth);

		video = new VideoSource("assets/audio-only.m4a");

		if (video.source != null)
		{
			Assert.isFalse(video.hasVideo);
			Assert.isTrue(video.hasAudio);
			Assert.equals(0, video.rotation);
			Assert.equals(0, video.displayWidth);
			video.dispose();
		}
	}

	private static function waitForTime(video:VideoSource, frame:VideoFrame, time:Int):Void
	{
		var end = Timer.stamp() + TIMEOUT;

		while (video.currentTime < time && Timer.stamp() < end)
		{
			video.readFrame(frame);
			pause(0.005);
		}

		Assert.isTrue(video.currentTime >= time, "the clock did not reach " + time + " ms" + describeStart(video));
	}

	private static function describeStart(video:VideoSource):String
	{
		// What the clock was waiting for, when it does not start
		#if (lime_cffi && lime_openal && !macro)
		var backend = @:privateAccess video.__backend;
		var decoder = @:privateAccess backend.decoder;
		var handle = @:privateAccess backend.handle;
		var bufferTimes:Array<Float> = @:privateAccess backend.bufferTimes;
		return " (clock " + video.currentTime + " ms, frame shown " + @:privateAccess backend.hasFrame + ", waiting for sound "
			+ @:privateAccess backend.audioStarting + ", stalled " + @:privateAccess backend.audioStalled + ", " + bufferTimes.length
			+ " buffers queued, source " + (handle != null ? Std.string(AL.getSourcei(handle, AL.SOURCE_STATE)) : "none") + ", video "
			+ (decoder != null && decoder.videoComplete ? "ended" : "decoding") + ", " + (decoder != null ? decoder.droppedFrames : 0)
			+ " frames dropped)";
		#else
		return "";
		#end
	}

	private static function measureRate(video:VideoSource, frame:VideoFrame, seconds:Float):ClockRate
	{
		// The clock steps forward as the audio device mixes, and a busy machine
		// can delay the mixing, so the rate is fitted to every reading rather
		// than taken from the first and last. Readings use the monotonic clock
		// the video keeps time with.
		var start = System.getTimer();
		var end = Timer.stamp() + seconds;
		var clocks:Array<Float> = [];
		var times:Array<Float> = [];
		var lastClock = video.currentTime;
		var movedAt = start;
		var longestStill = 0;
		var furthestBack = 0;

		while (Timer.stamp() < end)
		{
			video.readFrame(frame);

			var now = System.getTimer();
			var clock = video.currentTime;

			if (clock < lastClock && lastClock - clock > furthestBack)
			{
				furthestBack = lastClock - clock;
			}

			if (clock != lastClock)
			{
				lastClock = clock;
				movedAt = now;
			}
			else if (now - movedAt > longestStill)
			{
				longestStill = now - movedAt;
			}

			clocks.push(clock);
			times.push(now - start);
			pause(0.005);
		}

		var clockMean = 0.0;
		var timeMean = 0.0;

		for (i in 0...times.length)
		{
			clockMean += clocks[i] / times.length;
			timeMean += times[i] / times.length;
		}

		var covariance = 0.0;
		var variance = 0.0;

		for (i in 0...times.length)
		{
			covariance += (times[i] - timeMean) * (clocks[i] - clockMean);
			variance += (times[i] - timeMean) * (times[i] - timeMean);
		}

		return {rate: variance > 0 ? covariance / variance : 0, longestStill: longestStill, furthestBack: furthestBack};
	}

	private static function nextFrame(video:VideoSource, frame:VideoFrame):Bool
	{
		var start = Timer.stamp();

		while (!video.readFrame(frame))
		{
			if (Timer.stamp() - start > TIMEOUT) return false;
			Sys.sleep(0.001);
		}

		return true;
	}

	private static function pause(seconds:Float):Void
	{
		// Short sleeps can last several times longer on a busy machine, as macOS
		// coalesces them, which would read the clock far less often than a render
		// loop does. The time is waited out instead.
		var end = Timer.stamp() + seconds;
		while (Timer.stamp() < end) {}
	}

	private static function run(video:VideoSource, frame:VideoFrame, seconds:Float):Void
	{
		// Keeps the video updating, as a render loop would
		var end = Timer.stamp() + seconds;

		while (Timer.stamp() < end)
		{
			video.readFrame(frame);
			pause(0.005);
		}
	}

	private static function runMainThreadEvents():Void
	{
		// As the application's loop does between frames
		#if (haxe_ver >= 4.2)
		#if target.threaded
		sys.thread.Thread.current().events.progress();
		#else
		@:privateAccess haxe.EntryPoint.processEvents();
		#end
		#else
		@:privateAccess haxe.EntryPoint.processEvents();
		#end
	}

	private static function open():VideoSource
	{
		if (!VideoSource.isSupported)
		{
			Assert.pass();
			return null;
		}

		var video = new VideoSource();

		if (!video.open(PATH))
		{
			Assert.warn("Cannot decode H.264 and AAC here, so video playback was not tested");
			return null;
		}

		return video;
	}
	#end
}

private typedef HeardOffset =
{
	latency:String,
	mixes:Int,
	offset:Float,
	period:Float,
	readGap:Int
}

private typedef ClockRate =
{
	furthestBack:Int,
	longestStill:Int,
	rate:Float
}
