package lime.system;

#if target.threaded
import sys.thread.Deque;
import sys.thread.Thread;
import sys.thread.Tls;
#elseif cpp
import cpp.vm.Deque;
import cpp.vm.Thread;
import cpp.vm.Tls;
#elseif neko
import neko.vm.Deque;
import neko.vm.Thread;
import neko.vm.Tls;
#end

#if html5
import lime._internal.backend.html5.HTML5Thread as Thread;
import lime._internal.backend.html5.HTML5Thread.Transferable;
#end

#if macro
import haxe.macro.Expr;

using haxe.macro.Context;
#end

// In addition to `WorkOutput`, this module contains a number of small enums,
// abstracts, and classes used by all of Lime's threading classes.

/**
	Functions and variables available to the `doWork` function. For instance,
	the `sendProgress()`, `sendComplete()`, and `sendError()` functions allow
	returning output.

	`doWork` should exclusively use `WorkOutput` to communicate with the main
	thread. On many targets it's also possible to access static or instance
	variables, but this isn't thread safe and won't work in HTML5.
**/
@:allow(lime.system.BackgroundWorker)
@:allow(lime.system.ThreadPool)
class WorkOutput
{
	/**
		Thread-local storage. Tracks how many times `doWork` has been called for
		the current job, including (if applicable) the ongoing call.

		In single-threaded mode, it only counts the number of calls this frame.
		This helps you adjust `doWork`'s length: too few iterations per frame
		means `workLoad` may be inaccurate, while too many may add overhead.
	**/
	public var workIterations(default, null):Tls<Int> = new Tls();

	/**
		Whether background threads are being/will be used. If threads aren't
		available on this target, `mode` will always be `SINGLE_THREADED`.
	**/
	public var mode(get, never):ThreadMode;
	#if lime_threads
	/**
		__Set this only via the constructor.__
	**/
	private var __mode:ThreadMode;
	#end

	/**
		Messages sent by active jobs, received by the main thread.
	**/
	private var __jobOutput:Deque<ThreadEvent> = new Deque();
	/**
		Thread-local storage. Tracks whether `sendError()` or `sendComplete()`
		was called by this job.
	**/
	private var __jobComplete:Tls<Bool> = new Tls();

	/**
		A list of active jobs, including associated threads if applicable.
	**/
	private var __activeJobs:ActiveJobs = new ActiveJobs();

	/**
		The `state` provided to the active job. Will only have a value during
		`__update()` in single-threaded mode, and will otherwise be `null`.

		Include this when creating new `ThreadEvent`s.
	**/
	private var __activeJob:Null<State> = null;

	private inline function new(mode:Null<ThreadMode>)
	{
		workIterations.value = 0;
		__jobComplete.value = false;

		#if lime_threads
		__mode = mode != null ? mode : #if html5 SINGLE_THREADED #else MULTI_THREADED #end;
		#end
	}

	/**
		Dispatches `onComplete` on the main thread, with the given message.
		`doWork` should return after calling this.

		If using web workers, you can also pass a list of transferable objects.
		@see https://developer.mozilla.org/en-US/docs/Glossary/Transferable_objects
	**/
	public function sendComplete(message:Dynamic = null, transferList:Array<Transferable> = null):Void
	{
		if (!__jobComplete.value)
		{
			__jobComplete.value = true;

			#if (lime_threads && html5)
			if (mode == MULTI_THREADED)
				Thread.returnMessage(new ThreadEvent(COMPLETE, message, __activeJob), transferList);
			else
			#end
			__jobOutput.add(new ThreadEvent(COMPLETE, message, __activeJob));
		}
	}

	/**
		Dispatches `onError` on the main thread, with the given message.
		`doWork` should return after calling this.

		If using web workers, you can also pass a list of transferable objects.
		@see https://developer.mozilla.org/en-US/docs/Glossary/Transferable_objects
	**/
	public function sendError(message:Dynamic = null, transferList:Array<Transferable> = null):Void
	{
		if (!__jobComplete.value)
		{
			__jobComplete.value = true;

			#if (lime_threads && html5)
			if (mode == MULTI_THREADED)
				Thread.returnMessage(new ThreadEvent(ERROR, message, __activeJob), transferList);
			else
			#end
			__jobOutput.add(new ThreadEvent(ERROR, message, __activeJob));
		}
	}

	/**
		Dispatches `onProgress` on the main thread, with the given message. This
		can be called any number of times per job.

		If using web workers, you can also pass a list of transferable objects.
		@see https://developer.mozilla.org/en-US/docs/Glossary/Transferable_objects
	**/
	public function sendProgress(message:Dynamic = null, transferList:Array<Transferable> = null):Void
	{
		if (!__jobComplete.value)
		{
			#if (lime_threads && html5)
			if (mode == MULTI_THREADED)
				Thread.returnMessage(new ThreadEvent(PROGRESS, message, __activeJob), transferList);
			else
			#end
			__jobOutput.add(new ThreadEvent(PROGRESS, message, __activeJob));
		}
	}

	private inline function resetJobProgress():Void
	{
		__jobComplete.value = false;
		workIterations.value = 0;
	}

	#if lime_threads
	private function createThread(executeThread:WorkFunction<Void->Void>):Thread
	{
		var thread:Thread = Thread.create(executeThread);

		#if html5
		thread.onMessage.add(onMessageFromWorker.bind(thread));
		#end

		return thread;
	}

	#if html5
	private function onMessageFromWorker(thread:Thread, threadEvent:ThreadEvent):Void
	{
		if (threadEvent.event == null)
		{
			return;
		}

		threadEvent.associatedJob = __activeJobs.getByThread(thread);

		__jobOutput.add(threadEvent);
	}
	#end
	#end

	// Getters & Setters

	private inline function get_mode():ThreadMode
	{
		#if lime_threads
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

		To avoid lag spikes, `doWork` should return after completing a fraction
		of a frame's worth of work, storing its progress in `state`. It will be
		called again with the same `state` next frame, or this frame if there's
		still time.

		@see https://en.wikipedia.org/wiki/Green_threads
		@see https://en.wikipedia.org/wiki/Cooperative_multitasking
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
	A function that performs asynchronous work. This can either be work on
	another thread ("multi-threaded mode"), or it can represent a virtual
	thread ("single-threaded mode").

	In single-threaded mode, the work function shouldn't complete the job all at
	once, as the main thread would lock up. Instead, it should perform a
	fraction of the job each time it's called. `BackgroundWorker` and
	`ThreadPool` each provide the function with a persistent `State` argument,
	which can be used to track progress. In other contexts, you may be able to
	`bind` your own `State` argument.

	If using multi-threaded mode in HTML5, instance methods and `bind()` are
	both forbidden. Inline functions may work as long as they don't try to
	access `this`, but static functions are preferred. (All of these are fine in
	single-threaded mode.)

	The exact length of `doWork` can vary, but single-threaded mode will run
	more smoothly if it's short enough to run several times per frame.
**/
#if (lime_threads && html5)
typedef WorkFunction<T:haxe.Constraints.Function> = lime._internal.backend.html5.HTML5Thread.WorkFunction<T>;
#else
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
}
#end

/**
	An argument to pass to the `doWork` function. `doWork`'s parameter can be
	`Dynamic`; this is only called `State` for clarity of documentation.

	Any changes made to this object will persist if `doWork` is called multiple
	times for the same job. This provides an easy way to store information and
	track progress.
**/
typedef State = Dynamic;

@:forward @:forward.new
abstract ActiveJobs(List<ActiveJob>)
{
	#if lime_threads
	public function getByThread(thread:Thread):ActiveJob
	{
		for (job in this)
		{
			if (job.thread == thread)
			{
				return job;
			}
		}
		return null;
	}

	public inline function removeThread(thread:Thread):Bool
	{
		return this.remove(getByThread(thread));
	}
	#end
}

@:forward
abstract ActiveJob({ #if lime_threads ?thread:Thread, #end workEvent:ThreadEvent })
{
	public inline function new(workEvent:ThreadEvent)
	{
		this = {
			workEvent: workEvent
		};
	}
}

@:enum abstract ThreadEventType(String)
{
	/**
		Sent by the background thread, indicating completion.
	**/
	var COMPLETE = "COMPLETE";
	/**
		Sent by the background thread, indicating failure.
	**/
	var ERROR = "ERROR";
	/**
		Sent by the background thread.
	**/
	var PROGRESS = "PROGRESS";
	/**
		Sent by the main thread, indicating that the provided job should begin
		in place of any ongoing job. If `state == null`, the existing job will
		stop and the thread will go idle. (To run a job with no argument, set
		`state = {}` instead.)
	**/
	var WORK = "WORK";
	/**
		Sent by the main thread to shut down a thread.
	**/
	var EXIT = "EXIT";
}

class ThreadEvent
{
	public var event(default, null):ThreadEventType;
	public var state(default, null):Dynamic;

	#if (lime_threads && !html5)
	public var sourceThread:Thread;
	#end

	public var associatedJob:Null<ActiveJob>;

	public inline function new(event:ThreadEventType, state:Dynamic, activeJob:ActiveJob = null)
	{
		this.event = event;
		this.state = state;
		associatedJob = activeJob;

		#if (lime_threads && !html5)
		sourceThread = Thread.current();
		#end
	}
}

class JSAsync
{
	/**
		In JavaScript, runs the given block of code within an `async` function,
		enabling the `await` keyword. On other targets, runs the code normally.
	**/
	public static macro function async(code:Expr):Expr
	{
		if (Context.defined("js"))
		{
			var jsCode:Expr = #if haxe4 macro js.Syntax.code #else macro untyped __js__ #end;
			return macro $jsCode("(async {0})()", function() $code);
		}
		else
		{
			return code;
		}
	}
}

// Define platform-specific types

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

#if !html5
typedef Transferable = Dynamic;
#end
