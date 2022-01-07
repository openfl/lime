package lime.system;

import haxe.Constraints.Function;
import lime.app.Application;
import lime.app.Event;
import lime.system.ThreadBase.ThreadEvent;
import lime.utils.ArrayBuffer;
#if !force_synchronous
#if target.threaded
import sys.thread.Deque;
import sys.thread.Thread;
#elseif cpp
import cpp.vm.Deque;
import cpp.vm.Thread;
#elseif neko
import neko.vm.Deque;
import neko.vm.Thread;
#elseif js
import js.html.Blob;
import js.html.MessageEvent;
import js.html.URL;
import js.html.Worker;
import js.Syntax;
#end
#end
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
/**
	A simple way to distribute tasks across a pre-defined
	number of background threads. If threads aren't
	available, `ThreadPool` falls back to synchronous code,
	running each function immediately.

	The background threads can return data in a thread-safe
	manner using the `sendProgress()`, `sendError()`, and
	`sendComplete()` functions. The main thread receives
	this data via the `onProgress`, `onError`, and
	`onComplete` events.

	For a working example, see `lime.app.Future.FutureWork`.
**/
class ThreadPool extends ThreadBase
{
	/**
		The number of threads in this pool, including both
		active and idle ones.

		Setting this value will actually create or destroy
		threads, and will ignore both `minThreads` and
		`maxThreads`. (Active threads will be allowed to
		finish before being cleaned up.)

		Only the main thread should set this value.
	**/
	public var currentThreads(default, set):Int;
	/**
		The maximum number of threads this pool will create.

		Only the main thread should set this value.
	**/
	public var maxThreads(default, set):Int;
	/**
		The number of threads that will be kept active at
		all times, even if there's no work to do. This never
		adds new threads, just keeps existing ones running.

		Only the main thread should set this value.
	**/
	public var minThreads:Int;
	/**
		Dispatched on the main thread when any background
		thread begins working on a new task. For best
		results, add all listeners before calling `queue()`.
	**/
	public var onRun = new Event<Dynamic->Void>();

	#if !force_synchronous
	#if (target.threaded || cpp || neko)
	@:noCompletion private var __workIncoming = new Deque<ThreadEvent>();
	@:noCompletion private var __workQueued:Int = 0;
	#elseif js
	@:noCompletion private var __idleWorkers = new Array<WorkerWithURL>();
	@:noCompletion private var __workIncoming = new List<{state:Dynamic, ?transferList:Array<ArrayBuffer>}>();
	@:noCompletion private var __workersToTerminate:Int = 0;
	#end
	#end

	/**
		@param doWork The function that handles tasks in the
		background. It will run once for each time `queue()`
		is called, each time receiving a different argument.
	**/
	public function new(?doWork:ThreadFunction<Dynamic->Void>, minThreads:Int = 0, maxThreads:Int = 1)
	{
		super(doWork);
		this.minThreads = minThreads;
		@:bypassAccessor this.maxThreads = maxThreads;
		@:bypassAccessor currentThreads = 0;
	}

	/**
		[Call this from the main thread.]

		Queues a task for the next background thread that
		becomes available. The thread will receive `state`
		as an argument.

		**Caution:** if web workers are enabled, `doWork`
		will be almost completely isolated from the main
		thread. It will have access to three main things:
		(1) common JavaScript functions, (2) inline
		variables and functions (including all three "send"
		functions), and (3) the contents of `state`.
		@param state Data to pass to `doWork`. Web workers
		impose several restrictions on this data:
		https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Structured_clone_algorithm
		If this is a function, make sure to convert to
		`ThreadFunction` first, keeping in mind the above
		restrictions on functions.
		@param transferList (Web workers only) A list of
		buffers in `state` that should be moved rather than
		copied to the background thread. For details, see
		https://developer.mozilla.org/en-US/docs/Glossary/Transferable_objects
	**/
	public function queue(state:Dynamic = null, transferList:Array<ArrayBuffer> = null):Void
	{
		#if ((target.threaded || cpp || neko) && !force_synchronous)
		// TODO: Better way to handle this?

		if (Application.current != null && Application.current.window != null && !__synchronous)
		{
			__workIncoming.add(new ThreadEvent(WORK, state));
			__workQueued++;

			if (currentThreads < maxThreads && currentThreads < __workQueued)
			{
				currentThreads++;
			}

			if (!Application.current.onUpdate.has(__update))
			{
				Application.current.onUpdate.add(__update);
			}
		}
		else
		{
			__synchronous = true;
			__runWork(state);
		}
		#elseif (js && !force_synchronous)
		if (currentThreads < maxThreads && __idleWorkers.length == 0)
		{
			currentThreads++;
		}

		__workIncoming.add({ state: state, transferList: transferList });
		__startIdleWorkers();
		#else
		__runWork(state);
		#end
	}

	#if (!js || force_synchronous)
	/**
		[Call this from a background thread, or the main
		thread in synchronous mode.]

		Runs a single job on the calling thread.
	**/
	@:noCompletion private function __runWork(state:Dynamic = null):Void
	{
		#if ((target.threaded || cpp || neko) && !force_synchronous)
		if (!__synchronous)
		{
			__workResult.add(new ThreadEvent(WORK, state));
			doWork.dispatch(state);
			return;
		}
		#end

		onRun.dispatch(state);
		doWork.dispatch(state);
	}
	#end

	#if ((target.threaded || cpp || neko) && !force_synchronous)
	/**
		[Pass this as an argument to `Thread.create()`.]

		Executes jobs one by one as they arrive. Returns
		once an `EXIT` message is received.
	**/
	@:noCompletion private function __doWork():Void
	{
		while (true)
		{
			var threadEvent = __workIncoming.pop(true);

			if (threadEvent.event == WORK)
			{
				__runWork(threadEvent.message);
			}
			else if (threadEvent.event == EXIT)
			{
				break;
			}
		}
	}

	@:noCompletion private function __update(deltaTime:Int):Void
	{
		if (__workQueued > 0)
		{
			var threadEvent = __workResult.pop(false);

			while (threadEvent != null)
			{
				switch (threadEvent.event)
				{
					case WORK:
						onRun.dispatch(threadEvent.message);

					case PROGRESS:
						onProgress.dispatch(threadEvent.message);

					case COMPLETE, ERROR:
						__workQueued--;

						if (currentThreads > __workQueued && currentThreads > minThreads)
						{
							currentThreads--;
						}

						if (threadEvent.event == COMPLETE)
						{
							onComplete.dispatch(threadEvent.message);
						}
						else
						{
							onError.dispatch(threadEvent.message);
						}

					default:
				}

				threadEvent = __workResult.pop(false);
			}
		}
		else
		{
			// TODO: Add sleep if keeping minThreads running with no work?

			if (currentThreads == 0 && minThreads <= 0 && Application.current != null)
			{
				Application.current.onUpdate.remove(__update);
			}
		}
	}
	#elseif (js && !force_synchronous)
	/**
		[Call this from the main thread.]

		Assigns pending jobs to available workers.
	**/
	@:noCompletion private function __startIdleWorkers():Void
	{
		while (__idleWorkers.length > 0 && !__workIncoming.isEmpty())
		{
			var work = __workIncoming.pop();
			__idleWorkers.pop().postMessage(work.state, work.transferList);
		}
	}

	@:noCompletion private function __handleMessage(worker:WorkerWithURL, event:MessageEvent):Void
	{
		var threadEvent:ThreadEvent = event.data;

		switch (threadEvent.event)
		{
			case WORK:
				onRun.dispatch(threadEvent.message);

			case PROGRESS:
				onProgress.dispatch(threadEvent.message);

			case COMPLETE, ERROR:
				if (__workersToTerminate > 0)
				{
					__workersToTerminate--;
					worker.terminate();
				}
				else if (__workIncoming.isEmpty() && currentThreads > minThreads)
				{
					currentThreads--;
				}
				else
				{
					__idleWorkers.push(worker);
				}

				if (threadEvent.event == COMPLETE)
				{
					onComplete.dispatch(threadEvent.message);
				}
				else
				{
					onError.dispatch(threadEvent.message);
				}

				__startIdleWorkers();

			default:
		}
	}
	#end

	// Getters & Setters

	private function set_currentThreads(value:Int):Int
	{
		#if force_synchronous
		return currentThreads = value;
		#else
		while (currentThreads < value)
		{
			currentThreads++;

			#if (target.threaded || cpp || neko)
			Thread.create(__doWork);
			#elseif js
			doWork.checkJS();

			var worker = new WorkerWithURL(new Blob([
				headerCode.toString(),
				"this.onmessage = function(messageEvent) {\n",
				'    ($doWork)(messageEvent.data);\n',
				"};"
			], {type: "text/javascript"}));

			worker.onmessage = __handleMessage.bind(worker);
			__idleWorkers.push(worker);
			#end
		}

		while (currentThreads > value)
		{
			currentThreads--;

			#if (target.threaded || cpp || neko)
			// `EXIT` messages take priority over `WORK`.
			__workIncoming.push(new ThreadEvent(EXIT, null));
			#elseif js
			var worker = __idleWorkers.pop();
			if (worker != null)
			{
				worker.terminate();
			}
			else
			{
				__workersToTerminate++;
			}
			#end
		}

		return currentThreads;
		#end
	}

	private function set_maxThreads(value:Int):Int
	{
		if (currentThreads > value)
		{
			currentThreads = value;
		}
		return maxThreads = value;
	}
}

#if (js && !force_synchronous)
private class WorkerWithURL {
	public var url:String;
	public var worker:Worker;

	public var onmessage(get, set):haxe.Constraints.Function;

	public function new(blob:Blob)
	{
		url = URL.createObjectURL(blob);
		worker = new Worker(url);
	}

	public inline function postMessage(message:Dynamic, ?transfer:Array<Dynamic>):Void
	{
		worker.postMessage(message, transfer);
	}

	public function terminate():Void
	{
		worker.terminate();
		URL.revokeObjectURL(url);
	}

	// Getters & Setters

	private inline function get_onmessage():haxe.Constraints.Function
	{
		return worker.onmessage;
	}

	private inline function set_onmessage(value:haxe.Constraints.Function):haxe.Constraints.Function
	{
		return worker.onmessage = value;
	}
}
#end
