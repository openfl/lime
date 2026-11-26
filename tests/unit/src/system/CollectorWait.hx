package system;

#if (cpp || hl)
import haxe.Timer;
import sys.thread.Lock;
import sys.thread.Thread;
#end

/**
	Shows whether a collection on this thread has to wait for a native call on another thread.

	On C++ and HashLink a collection stops every thread at a safe point first. A thread inside a native
	call can't reach one unless the call has told the collector it is blocking, so a collection started
	meanwhile waits for the call to return, or for the call's first allocation when it makes one before
	it returns. `collectDuring` runs the call on a new thread, starts a major collection here while the
	call is under way, and reports whether the collection took more than half the time the call did.
	When the call blocks the collector, the collection lasts nearly as long as the call, every time, so a
	test that asks for less fails every time rather than now and then. When it doesn't, the call has to
	take a good deal longer than a collection, which is up to the work the test gives it.

	Neko's collector stops threads without their help, so the question doesn't arise there.
**/
class CollectorWait
{
	#if (cpp || hl)
	/**
		Runs `work` on a new thread and, `settle` seconds after it has started, runs a major collection on
		this thread.
	**/
	public static function collectDuring(work:Void->Void, settle:Float = 0.005):CollectorWaitResult
	{
		var started = new Lock();
		var finished = new Lock();
		var workStart = 0.0;
		var workEnd = 0.0;
		var error:Dynamic = null;

		Thread.create(function()
		{
			workStart = Timer.stamp();
			started.release();

			try
			{
				work();
			}
			catch (e:Dynamic)
			{
				error = e;
			}

			workEnd = Timer.stamp();
			finished.release();
		});

		started.wait();
		Sys.sleep(settle);

		var collectStart = Timer.stamp();
		collect();
		var collectEnd = Timer.stamp();

		finished.wait();

		return new CollectorWaitResult(workEnd - workStart - settle, collectEnd - collectStart, error);
	}

	public static function collect():Void
	{
		#if cpp
		cpp.vm.Gc.run(true);
		#elseif hl
		hl.Gc.major();
		#end
	}
	#end
}

class CollectorWaitResult
{
	/** Whether the collection lasted more than half as long as the work had left to do when it started **/
	public var waited(get, never):Bool;

	/** How long the work had left when the collection started **/
	public var workSeconds(default, null):Float;

	public var collectSeconds(default, null):Float;
	public var error(default, null):Dynamic;

	public function new(workSeconds:Float, collectSeconds:Float, error:Dynamic)
	{
		this.workSeconds = workSeconds;
		this.collectSeconds = collectSeconds;
		this.error = error;
	}

	public function toString():String
	{
		return "the collection took " + ms(collectSeconds) + " while the work had " + ms(workSeconds) + " left"
			+ (error != null ? " (the work threw " + error + ")" : "");
	}

	private function get_waited():Bool
	{
		return collectSeconds > workSeconds / 2;
	}

	private static function ms(seconds:Float):String
	{
		return Math.round(seconds * 10000) / 10 + " ms";
	}
}
