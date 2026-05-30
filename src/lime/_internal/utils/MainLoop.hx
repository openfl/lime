package lime._internal.utils;

#if haxe5
import haxe.EventLoop;

/**
 * Wrapper for compatibility with Haxe 5.
 */
@:forwardStatics
abstract MainLoop(haxe.MainLoop)
{
	public static inline function runInMainThread(f:Void->Void)
	{
		EventLoop.main.run(f);
	}

	public static inline function addThread(f:Void->Void)
	{
		EventLoop.addTask(f);
	}
}
#else
typedef MainLoop = haxe.MainLoop;
#end
