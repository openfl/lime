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
class WorkOutput
{
	/**
		Thread-local storage. Tracks how many times `doWork` has been called for
		the current job, including (if applicable) the ongoing call.

		In single-threaded mode, it only counts the number of calls this frame.
		The lower the number, the less accurate `ThreadPool.workLoad` becomes,
		but the higher the number, the more overhead there is. As a ballpark
		estimate, aim for 10-100 iterations.
	**/
	public var workIterations(default, null):Tls<Int> = new Tls();

	/**
		The mode jobs will run in by default. If threads aren't available, jobs
		will always run in `SINGLE_THREADED` mode.
	**/
	public var mode:ThreadMode;

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
		The job that is currently running on this thread, or the job that
		triggered the ongoing `onComplete`, `onError`, or `onProgress` event.
		Will be null in all other cases.
	**/
	public var activeJob(get, set):Null<JobData>;

	@:noCompletion private var __activeJob:Tls<JobData> = new Tls();

	private inline function new(mode:Null<ThreadMode>)
	{
		workIterations.value = 0;
		__jobComplete.value = false;

		#if lime_threads
		this.mode = mode != null ? mode : #if html5 SINGLE_THREADED #else MULTI_THREADED #end;
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

			sendThreadEvent({event: COMPLETE, message: message, jobID: activeJob.id}, transferList);
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

			sendThreadEvent({event: ERROR, message: message, jobID: activeJob.id}, transferList);
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
			sendThreadEvent({event: PROGRESS, message: message, jobID: activeJob.id}, transferList);
		}
	}

	private inline function sendThreadEvent(event:ThreadEvent, transferList:Array<Transferable> = null):Void
	{
		#if (lime_threads && html5)
		if (Thread.current().isWorker())
		{
			Thread.returnMessage(event, transferList);
		}
		else
		#end
		__jobOutput.add(event);
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
		thread.onMessage.add(function(event:ThreadEvent)
		{
			__jobOutput.add(event);
		});
		#end

		return thread;
	}
	#end

	// Getters & Setters

	private inline function get_activeJob():JobData
	{
		return __activeJob.value;
	}

	private inline function set_activeJob(value:JobData):JobData
	{
		return __activeJob.value = value;
	}
}

#if haxe4 enum #else @:enum #end abstract ThreadMode(Bool)
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
		Even so, `doWork` should return periodically, to allow canceling the
		thread. If not canceled, `doWork` will be called again immediately.

		In HTML5, web workers will be used to achieve this. This means `doWork`
		must be a static function, and you can't use `bind()`. Web workers also
		impose a longer delay each time `doWork` returns, so it shouldn't return
		as often in multi-threaded mode as in single-threaded mode.
	**/
	var MULTI_THREADED = true;
}

/**
	A function that performs asynchronous work. This can either be work on
	another thread ("multi-threaded mode"), or it can represent a green thread
	("single-threaded mode").

	In single-threaded mode, the work function shouldn't complete the job all at
	once, as the main thread would lock up. Instead, it should perform a
	fraction of the job each time it's called. `ThreadPool` provides the
	function with a persistent `State` argument for tracking progress, which can
	be any object of your choice.

	Caution: if using multi-threaded mode in HTML5, this must be a static
	function and binding arguments is forbidden. Compile with
	`-Dlime-warn-portability` to highlight functions that won't work.
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
			case TPath({sub: "WorkFunction", params: [TPType(t)]}):
				return macro($self : $t)($a{args});
			default:
				throw "Underlying function type not found.";
		}
	}
}
#end

/**
	An argument of any type to pass to the `doWork` function. Though `doWork`
	only accepts a single argument, you can pass multiple values as part of an
	anonymous structure. (Or an array, or a class.)

		// Does not work: too many arguments.
		// threadPool.run(doWork, argument0, argument1, argument2);

		// Works: all arguments are combined into one `State` object.
		threadPool.run(doWork, { arg0: argument0, arg1: argument1, arg2: argument2 });

		// Alternatives that also work, if everything is the correct type.
		threadPool.run(doWork, [argument0, argument1, argument2]);
		threadPool.run(doWork, new DoWorkArgs(argument0, argument1, argument2));

	Any changes made to this object will persist if and when `doWork` is called
	again for the same job. (See `WorkFunction` for instructions on how to do
	this.) This is the recommended way to store `doWork`'s progress.

	Caution: after passing an object to `doWork`, avoid accessing or modifying
	that object from the main thread, and avoid passing it to other threads.
	Doing either may lead to race conditions. If you need to store an object,
	pass a clone of that object to `doWork`.
**/
typedef State = Dynamic;

class JobData
{
	private static var nextID:Int = 0;

	/**
		`JobData` instances will regularly be copied in HTML5, so checking
		equality won't work. Instead, compare identifiers.
	**/
	public var id(default, null):Int;

	/**
		The function responsible for carrying out the job.
	**/
	public var doWork(default, null):WorkFunction<State->WorkOutput->Void>;

	/**
		The original `State` object passed to the job. Avoid modifying this
		object if the job is running in multi-threaded mode.
	**/
	public var state(default, null):State;

	/**
		The total time spent on this job.

		In multi-threaded mode, this includes the overhead for sending messages,
		plus any time spent waiting for a canceled job to return. The latter
		delay can be reduced by returning at regular intervals.
	**/
	@:allow(lime.system.WorkOutput)
	public var duration(default, null):Float = 0;

	public var started(get, never):Bool;

	@:allow(lime.system.WorkOutput)
	private var startTime:Float = -1;

	@:allow(lime.system.WorkOutput)
	private inline function new(doWork:WorkFunction<State->WorkOutput->Void>, state:State, ?id:Int)
	{
		this.id = id != null ? id : nextID++;
		this.doWork = doWork;
		this.state = state;
	}

	private inline function get_started():Bool
	{
		return startTime >= 0;
	}
}

#if haxe4 enum #else @:enum #end abstract ThreadEventType(String)
{
	// Events sent from a worker to the main thread, in any mode
	var COMPLETE = "COMPLETE";
	var ERROR = "ERROR";
	var PROGRESS = "PROGRESS";

	// Commands sent from the main thread to a worker thread, and returned by
	// the worker to confirm the change of state, in multi-threaded mode only
	var WORK = "WORK";
	var IDLE = "IDLE";
	var EXIT = "EXIT";
}

typedef ThreadEvent =
{
	var event:ThreadEventType;
	@:optional var message:Dynamic;
	@:optional var jobID:Int;

	/**
		Required when a worker thread reports a state change (WORK, IDLE, EXIT).
	**/
	@:optional var threadID:Int;

	// Only for WORK events sent by the main thread to a worker
	@:optional var doWork:WorkFunction<State->WorkOutput->Void>;
	@:optional var state:State;
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
#if target.threaded
// Haxe 3 compatibility: "target.threaded" can't go in parentheses.
#elseif !(cpp || neko)
@:forward(push, add)
abstract Deque<T>(List<T>) from List<T> to List<T>
{
	public inline function new()
	{
		this = new List<T>();
	}

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
