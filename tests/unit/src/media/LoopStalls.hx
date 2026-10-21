package media;

import haxe.Timer;

/**
	Watches a test loop that runs every few milliseconds. When it goes far
	longer without running, the whole process was stopped, as a busy CI
	machine does now and then, and the video's threads stopped with it, so
	the time is not held against playback.
**/
class LoopStalls
{
	// Longer than a loop's few milliseconds, with room for macOS coalescing
	// short sleeps on a busy machine
	private static inline var STALL = 0.05;

	/**
		All the time the loop has lost, in seconds.
	**/
	public var total(default, null):Float = 0;

	private var lastTick:Float;
	private var starts:Array<Float> = [];
	private var ends:Array<Float> = [];

	public function new()
	{
		lastTick = Timer.stamp();
	}

	/**
		Call once each time round the loop, before reading the video.
	**/
	public function tick():Void
	{
		var now = Timer.stamp();

		if (now - lastTick > STALL)
		{
			starts.push(lastTick);
			ends.push(now);
			total += now - lastTick;
		}

		lastTick = now;
	}

	/**
		The time the loop lost since `stamp`, a `Timer.stamp()`, in seconds.
	**/
	public function lostSince(stamp:Float):Float
	{
		var lost = 0.0;

		for (i in 0...starts.length)
		{
			if (ends[i] > stamp) lost += ends[i] - Math.max(starts[i], stamp);
		}

		return lost;
	}
}
