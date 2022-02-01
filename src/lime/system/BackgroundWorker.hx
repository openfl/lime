package lime.system;

import lime.app.Event;
#if target.threaded
import sys.thread.Deque;
import sys.thread.Thread;
import sys.thread.Tls;
#elseif cpp
import cpp.vm.Deque;
import cpp.vm.Thread;
import cpp.thread.Tls;
#elseif neko
import neko.vm.Deque;
import neko.vm.Thread;
import neko.thread.Tls;
#end

#if macro
import haxe.macro.Expr;

using haxe.macro.Context;
#else
// Application imports non-macro-safe classes on some targets.
import lime.app.Application;
#end

/**
	A simple way to run a job on another thread. If threads aren't available,
	it will fall back to single-threaded mode, running jobs on the main thread.

	The worker function (often called `doWork`) can return data using the
	`sendProgress()`, `sendError()`, and `sendComplete()` functions. The main
	thread receives this data via the `onProgress`, `onError`, and `onComplete`
	events, respectively.

	For best results, `doWork` shouldn't complete the job all at once. Instead,
	it can expect to be called multiple times, each time doing a fraction of the
	total work. After doing one frame's worth of work, it should return, at
	which point `BackgroundWorker` will schedule it to run again with the same
	argument. This argument (often called `state`) can store persistent
	information. Once the entire job is done, `doWork` can exit the loop by
	calling `sendComplete()`. (`sendError()` will also exit the loop.)

	Sample usage:

		private var bgWorker:BackgroundWorker;

		private static function doWork(state:{ ?items:Array<Item>, total:Int }):Void {
			if (state.items == null)
			{
				state.items = [];
			}

			var end:Int = state.items.length + 500;
			if (end > state.total)
			{
				end = state.total;
			}

			for (i in state.items.length...end)
			{
				state.items.push(Item.generateRandomItem());
			}

			if (state.items.length >= state.total)
			{
				bgWorker.sendComplete(state.items);
			}
			else
			{
				bgWorker.sendProgress(state.items.length);
			}
		}

		public function new() {
			bgWorker = new BackgroundWorker();

			bgWorker.onProgress(function(count:Int) {
				trace(count + " items done!");
			});
			bgWorker.onComplete(function(items:Array<Item>) {
				this.items = items;
				trace('Finished creating ${items.length} items!');
			});

			bgWorker.run(doWork, { total: 3000 });
		}
	@see https://player03.com/openfl/threads-guide/ for a tutorial.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class BackgroundWorker
{
	#if (!force_synchronous && (target.threaded || cpp || neko))
	private static var __mainThread:Thread = Thread.current();
	#end

	/**
		Indicates that no further events will be dispatched.
	**/
	public var canceled(get, never):Bool;

	/**
		Indicates that the latest job finished successfully, and no other job
		has been started/is ongoing.
	**/
	// __Set this only from the main thread.__
	public var completed(default, null):Bool;

	/**
		This is public for backwards compatibility only.

		__Set this by passing it as an argument to `run()`.__
	**/
	@:noCompletion @:dox(hide) public var doWork:WorkFunction<Dynamic->Void>;

	/**
		Dispatched on the main thread when `doWork` calls `sendComplete()`.
		Dispatched at most once per job. For best results, add all listeners
		before starting the new thread.
	**/
	public var onComplete = new Event<Dynamic->Void>();
	/**
		Dispatched on the main thread when `doWork` calls `sendError()`.
		Dispatched at most once per job. For best results, add all listeners
		before starting the new thread.
	**/
	public var onError = new Event<Dynamic->Void>();
	/**
		Dispatched on the main thread when `doWork` calls `sendProgress()`. May
		be dispatched any number of times per job. For best results, add all
		listeners before starting the new thread.
	**/
	public var onProgress = new Event<Dynamic->Void>();

	/**
		Whether background threads are being/will be used. If threads aren't
		available on this target, `mode` will always be `SINGLE_THREADED`.
	**/
	public var mode(get, never):ThreadMode;
	#if (!force_synchronous && (target.threaded || cpp || neko))
	/**
		__Set this only via the constructor.__
	**/
	private var __mode:ThreadMode;

	private var __latestThread:Thread;
	#end

	/**
		The argument to pass to `doWork`.
	**/
	private var __state:Dynamic;

	/**
		__Add messages only from `sendProgress()`, `sendError()`, or__
		__`sendComplete()`.__
	**/
	private var __messageQueue:Deque<ThreadEvent> = new Deque();
	/**
		Thread-local storage. Tracks whether `sendError()` or `sendComplete()`
		was called on this thread. If it was, there's no need to rerun `doWork`.
	**/
	private var __jobComplete:Tls<Bool> = new Tls();

	public function new(?mode:ThreadMode = MULTI_THREADED) {
		#if (!force_synchronous && (target.threaded || cpp || neko))
		this.__mode = mode;
		#end
	}

	/**
		Cancels all events and begins the process of closing background threads,
		though the thread won't actually shut down until `doWork` returns.
	**/
	public function cancel():Void
	{
		#if (!force_synchronous && (target.threaded || cpp || neko))
		if (Thread.current() != __mainThread)
		{
			throw "Call cancel() only from the main thread.";
		}
		#end

		#if !macro
		Application.current.onUpdate.remove(__update);
		#end

		#if (!force_synchronous && (target.threaded || cpp || neko))
		__latestThread = null;
		#end

		__state = null;
		completed = false;
	}

	/**
		Begins work on a job, running `doWork` repeatedly with the given `state`
		until it either finishes or encounters an error.

		In multi-threaded mode, the main thread should avoid modifying `state`
		until the job completes.

		@param doWork The function to execute. Treat this parameter as though it
		wasn't optional.
	**/
	public function run(?doWork:Dynamic->Void, ?state:Dynamic):Void
	{
		#if (!force_synchronous && (target.threaded || cpp || neko))
		if (Thread.current() != __mainThread)
		{
			throw "Call run() only from the main thread.";
		}
		#end

		if (doWork == null)
		{
			doWork = this.doWork;
			if (doWork == null)
			{
				throw "doWork argument omitted from call to run().";
			}
		}

		completed = false;
		__jobComplete.value = false;
		this.doWork = doWork;
		__state = state;

		#if (!force_synchronous && (target.threaded || cpp || neko))
		if (mode == MULTI_THREADED)
		{
			__latestThread = Thread.create(function():Void
			{
				// Don't jump the gun, or `__latestThread` could still be null.
				Thread.readMessage(true);

				var thisThread:Thread = Thread.current();
				__jobComplete.value = false;

				while (!__jobComplete.value && thisThread == __latestThread)
				{
					doWork(state);
				}
			});
			__latestThread.sendMessage(ThreadEventType.WORK);
		}
		#end

		#if !macro
		if (!Application.current.onUpdate.has(__update))
		{
			Application.current.onUpdate.add(__update);
		}
		#end
	}

	/**
		__Call this only from `doWork`.__

		Dispatches `onComplete` on the main thread, with the given message.
		`doWork` should return after calling this.
	**/
	public function sendComplete(message:Dynamic = null):Void
	{
		if (!__jobComplete.value)
		{
			__jobComplete.value = true;
			__messageQueue.add(new ThreadEvent(COMPLETE, message));
		}
	}

	/**
		__Call this only from `doWork`.__

		Dispatches `onError` on the main thread, with the given message.
		`doWork` should return after calling this.
	**/
	public function sendError(message:Dynamic = null):Void
	{
		if (!__jobComplete.value)
		{
			__jobComplete.value = true;
			__messageQueue.add(new ThreadEvent(ERROR, message));
		}
	}

	/**
		__Call this only from `doWork`.__

		Dispatches `onProgress` on the main thread, with the given message. This
		can be called any number of times per job.
	**/
	public function sendProgress(message:Dynamic = null):Void
	{
		if (!__jobComplete.value)
		{
			__messageQueue.add(new ThreadEvent(PROGRESS, message));
		}
	}

	private function __update(deltaTime:Int):Void
	{
		if (mode == SINGLE_THREADED && doWork != null && __state != null)
		{
			doWork.dispatch(__state);
		}

		var threadEvent:ThreadEvent;

		while ((threadEvent = __messageQueue.pop(false)) != null)
		{
			#if (target.threaded || cpp || neko)
			if (mode == MULTI_THREADED && threadEvent.sourceThread != __latestThread)
			{
				continue;
			}
			#end

			switch (threadEvent.event)
			{
				case ERROR:
					cancel();
					onError.dispatch(threadEvent.state);
				case COMPLETE:
					cancel();
					completed = true;
					onComplete.dispatch(threadEvent.state);
				case PROGRESS:
					onProgress.dispatch(threadEvent.state);
				default:
			}
		}
	}

	// Getters & Setters

	private function get_canceled():Bool
	{
		return __state == null;
	}

	private inline function get_mode():ThreadMode
	{
		#if (!force_synchronous && (target.threaded || cpp || neko))
		return __mode;
		#else
		return SINGLE_THREADED;
		#end
	}
}

@:enum abstract ThreadMode(Bool)
{
	/**
		All work will be done on the main thread, during `Application.onUpdate`.

		To avoid lag spikes, `doWork` should return after completing one frame's
		worth of work, storing its progress in `state`. It will be called again
		with the same `state` next frame.
	**/
	var SINGLE_THREADED = false;

	/**
		All work will be done on a background thread.

		Unlike single-threaded mode, there is no risk of causing lag spikes.
		Even so, `doWork` should return at regular intervals, storing its
		progress in `state`. This will make it easier to cancel the thread. If
		not canceled, `doWork` will be called again immediately.
	**/
	var MULTI_THREADED = true;
}

/**
	A function that performs asynchronous work. Emulates the `lime.app.Event`
	API for backwards compatibility. Most of this API can be ignored, but
	calling the function requires using `dispatch()`.
**/
abstract WorkFunction<T:haxe.Constraints.Function>(T) from T to T
{
	/**
		Executes this function with the given arguments.
	**/
	public macro function dispatch(self:Expr, args:Array<Expr>):Expr
	{
		switch (self.typeof().follow().toComplexType())
		{
			case TPath({ sub: "WorkFunction", params: [TPType(t)] }):
				return macro ($self:$t)($a{args});
			default:
				throw "Underlying function type not found.";
		}
	}

	// Backwards compatibility functions

	@:deprecated("Instead, pass doWork to BackgroundWorker.run() or ThreadPool's constructor.")
	@:noCompletion @:dox(hide) public inline function add(callback:WorkFunction<T>):Void
	{
		this = callback;
	}

	@:noCompletion @:dox(hide) public inline function has(callback:T):Bool
	{
		return Reflect.compareMethods(this, callback);
	}

	@:noCompletion @:dox(hide) public inline function remove(callback:T):Void
	{
		if (has(callback)) this = null;
	}

	@:noCompletion @:dox(hide) public inline function removeAll():Void
	{
		this = null;
	}
}

@:enum abstract ThreadEventType(String)
{
	var COMPLETE = "COMPLETE";
	var ERROR = "ERROR";
	var PROGRESS = "PROGRESS";
	var WORK = "WORK";
	var EXIT = "EXIT";
}

class ThreadEvent
{
	public var event(default, null):ThreadEventType;
	public var state(default, null):Dynamic;

	#if (target.threaded || cpp || neko)
	public var sourceThread(default, null):Thread;
	#end

	public inline function new(event:ThreadEventType, state:Dynamic)
	{
		this.event = event;
		this.state = state;

		#if (target.threaded || cpp || neko)
		sourceThread = Thread.current();
		#end
	}
}

#if !(target.threaded || cpp || neko)
@:forward(push, add) @:forward.new
abstract Deque<T>(List<T>) from List<T> to List<T>
{
	public inline function pop(block:Bool):Null<T>
	{
		return this.pop();
	}
}

class Tls<T>
{
	public var value:T;

	public inline function new() {}
}
#end
