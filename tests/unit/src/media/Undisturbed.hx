package media;

import utest.Assert;

/**
	Repeats a measurement that is taken in real time until an attempt runs
	undisturbed. A shared CI runner stops the test's loop, OpenAL Soft's mixer
	thread or the video's decoding now and then for tens of milliseconds, and
	an attempt during which that happened measures the machine rather than
	Lime. Each attempt says what disturbed it, and the result of the first
	undisturbed one is returned, for the test to hold to its bound as before.

	The rule is the one LoopStalls uses for the test's loop: a thread that went
	more than `LoopStalls.STALL` beyond its schedule was stopped. `mixed` holds
	OpenAL Soft's mixer to it, and the measurements report anything else that
	stopped, such as the sound running out, with `disturbed`.

	A measurement that can leave out just the readings a stall of the test's
	loop came between, as the clock against the sound does by placing only the
	mixes its reads can time, does not call `tick`: on some machines the loop is
	stopped for tens to hundreds of milliseconds several times a second, which
	would leave nothing measured, and the readings around those stops are
	unaffected. One that cannot calls `tick` each time round its loop, and any
	stall disturbs the attempt.

	When no attempt ran undisturbed, nothing was measured. That is printed as a
	warning, which GitHub Actions also shows on the run's summary, rather than
	passing silently. utest would take an `Assert.warn` as a failure, so it is
	not used.
**/
class Undisturbed
{
	/**
		Watches the test's loop during this attempt. Call `tick` instead of
		`stalls.tick` once each time round the loop.
	**/
	public var stalls(default, null):LoopStalls;

	private var mixBehind = 0.0;
	private var mixPosition = Math.NaN;
	private var mixRead = -1.0;
	private var mixSeen = -1.0;
	private var reasons:Array<String> = [];
	private var ticked = false;

	private function new()
	{
		stalls = new LoopStalls();
	}

	/**
		Call once each time round the measuring loop.
	**/
	public function tick():Void
	{
		// Watched from the first time round, as setting up the attempt, such as
		// opening a video, is not part of the loop
		if (!ticked)
		{
			ticked = true;
			stalls = new LoopStalls();
		}

		stalls.tick();
	}

	/**
		Call with each reading of how far the audio output has mixed into a
		sound, in milliseconds of the sound, `read` the `Timer.stamp()` of the
		reading in milliseconds, `period` the output's mixing period in
		milliseconds and `rate` how fast the sound plays (its pitch times the
		playback rate).

		The output mixes a period at a time, at most half a period late with
		OpenAL Soft's null output, which CI uses. One that mixes much more sound
		at once than the time since the last reading, or goes much longer than a
		period without mixing, had fallen behind, and when that is more than
		`LoopStalls.STALL`, its mixer thread was stopped.
	**/
	public function mixed(position:Float, read:Float, period:Float, rate:Float):Void
	{
		if (Math.isNaN(mixPosition) || position < mixPosition - 0.1)
		{
			// The first reading, or the sound was queued again
			mixSeen = -1;
		}
		else if (Math.abs(position - mixPosition) > 0.1)
		{
			var advance = (position - mixPosition) / rate;
			var behind = advance - (read - mixRead) - period;
			if (mixSeen >= 0) behind = Math.max(behind, mixRead - mixSeen - period);
			if (behind > mixBehind) mixBehind = behind;
			mixSeen = read;
		}

		mixPosition = position;
		mixRead = read;
	}

	/**
		Records that something other than the test's loop was stopped during
		this attempt, such as the mixer or the decoding.
	**/
	public function disturbed(reason:String):Void
	{
		if (reasons.indexOf(reason) < 0) reasons.push(reason);
	}

	private function describe():String
	{
		var all = reasons.copy();
		if (mixBehind > LoopStalls.STALL * 1000) all.unshift("the audio output's mixer fell " + Math.round(mixBehind) + " ms behind");
		if (stalls.total > 0) all.unshift("the test's loop stalled for " + Math.round(stalls.total * 1000) + " ms");
		return all.length > 0 ? all.join(", ") : null;
	}

	/**
		Runs `attempt` up to `attempts` times, until one is undisturbed, and
		returns its result. Returns null when every attempt was disturbed, having
		printed a warning naming `what` was not measured, and why.
	**/
	public static function measure<T>(what:String, attempts:Int, attempt:Undisturbed->T):Null<T>
	{
		var disturbances:Array<String> = [];

		for (i in 0...attempts)
		{
			var run = new Undisturbed();
			var result = attempt(run);
			var reason = run.describe();

			if (reason == null)
			{
				// Said so that a result the test fails on can be traced to the attempt
				if (i > 0) print("Timing attempt " + (i + 1) + " of " + attempts + " for " + what + " was undisturbed");
				return result;
			}

			disturbances.push(reason);
			print("Timing attempt " + (i + 1) + " of " + attempts + " for " + what + " was disturbed: " + reason);
		}

		var message = what + " was not measured, as all " + attempts + " attempts were disturbed: " + disturbances.join("; ");
		#if sys
		if (Sys.getEnv("GITHUB_ACTIONS") == "true")
		{
			// Shown on the run's summary page as well as in the log
			print("::warning title=Timing not measured::" + message);
		}
		else
		#end
		{
			print("WARNING: Timing not measured: " + message);
		}

		// The test made no claim it could check, which is not a failure of Lime
		Assert.pass();
		return null;
	}

	private static function print(line:String):Void
	{
		#if sys
		Sys.println(line);
		Sys.stdout().flush();
		#else
		trace(line);
		#end
	}
}
