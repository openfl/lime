package lime.system;

import haxe.Constraints.Function;
import lime.app.Application;
import lime.app.Event;
import lime.system.BackgroundWorker.ThreadFunction;
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
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class ThreadPool
{
	public var currentThreads(default, null):Int;
	public var doWork:ThreadFunction;
	public var maxThreads:Int;
	public var minThreads:Int;
	public var onComplete = new Event<Dynamic->Void>();
	public var onError = new Event<Dynamic->Void>();
	public var onProgress = new Event<Dynamic->Void>();
	public var onRun = new Event<Dynamic->Void>();

	#if (target.threaded || cpp || neko)
	@:noCompletion private var __synchronous:Bool;
	@:noCompletion private var __workCompleted:Int;
	@:noCompletion private var __workIncoming = new Deque<ThreadPoolMessage>();
	@:noCompletion private var __workQueued:Int;
	@:noCompletion private var __workResult = new Deque<ThreadPoolMessage>();
	#elseif js
	@:noCompletion private var __idleWorkers = new Array<Worker>();
	@:noCompletion private var __workIncoming = new List<Dynamic>();
	#end

	public function new(minThreads:Int = 0, maxThreads:Int = 1)
	{
		this.minThreads = minThreads;
		this.maxThreads = maxThreads;

		currentThreads = 0;

		#if (target.threaded || cpp || neko)
		__workQueued = 0;
		__workCompleted = 0;

		#if (emscripten || force_synchronous)
		__synchronous = true;
		#end
		#end
	}

	// public function cancel (id:String):Void {
	//
	//
	//
	// }
	// public function isCanceled (id:String):Bool {
	//
	//
	//
	// }
	public function queue(state:Dynamic = null):Void
	{
		#if (target.threaded || cpp || neko)
		// TODO: Better way to handle this?

		if (Application.current != null && Application.current.window != null && !__synchronous)
		{
			__workIncoming.add(new ThreadPoolMessage(WORK, state));
			__workQueued++;

			if (currentThreads < maxThreads && currentThreads < (__workQueued - __workCompleted))
			{
				currentThreads++;
				Thread.create(__doWork);
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
		#elseif js
		if (currentThreads < maxThreads && __idleWorkers.length == 0)
		{
			doWork.checkJS();

			var workerURL:String = URL.createObjectURL(new Blob([
				BackgroundWorker.initializeWorker,
				"this.onmessage = function(messageEvent) {\n",
				'    ($doWork)(messageEvent.data);\n',
				"};"
			]));

			var worker:Worker = new Worker(workerURL);
			worker.onmessage = __handleMessage.bind(worker, workerURL);
			__idleWorkers.push(worker);

			currentThreads++;
		}

		__workIncoming.add(state);
		__startIdleWorkers();
		#else
		__runWork(state);
		#end
	}

	#if js inline #end
	public function sendComplete(state:Dynamic = null):Void
	{
		#if (target.threaded || cpp || neko)
		if (!__synchronous)
		{
			__workResult.add(new ThreadPoolMessage(COMPLETE, state));
			return;
		}
		#end

		#if js
		Syntax.code("postMessage({0})", new ThreadPoolMessage(COMPLETE, state));
		#else
		onComplete.dispatch(state);
		#end
	}

	#if js inline #end
	public function sendError(state:Dynamic = null):Void
	{
		#if (target.threaded || cpp || neko)
		if (!__synchronous)
		{
			__workResult.add(new ThreadPoolMessage(ERROR, state));
			return;
		}
		#end

		#if js
		Syntax.code("postMessage({0})", new ThreadPoolMessage(ERROR, state));
		#else
		onError.dispatch(state);
		#end
	}

	#if js inline #end
	public function sendProgress(state:Dynamic = null):Void
	{
		#if (target.threaded || cpp || neko)
		if (!__synchronous)
		{
			__workResult.add(new ThreadPoolMessage(PROGRESS, state));
			return;
		}
		#end

		#if js
		Syntax.code("postMessage({0})", new ThreadPoolMessage(PROGRESS, state));
		#else
		onProgress.dispatch(state);
		#end
	}

	#if !js
	@:noCompletion private function __runWork(state:Dynamic = null):Void
	{
		#if (target.threaded || cpp || neko)
		if (!__synchronous)
		{
			__workResult.add(new ThreadPoolMessage(WORK, state));
			doWork.dispatch(state);
			return;
		}
		#end

		onRun.dispatch(state);
		doWork.dispatch(state);
	}
	#end

	#if (target.threaded || cpp || neko)
	@:noCompletion private function __doWork():Void
	{
		while (true)
		{
			var message = __workIncoming.pop(true);

			if (message.type == WORK)
			{
				__runWork(message.state);
			}
			else if (message.type == EXIT)
			{
				break;
			}
		}
	}

	@:noCompletion private function __update(deltaTime:Int):Void
	{
		if (__workQueued > __workCompleted)
		{
			var message = __workResult.pop(false);

			while (message != null)
			{
				switch (message.type)
				{
					case WORK:
						onRun.dispatch(message.state);

					case PROGRESS:
						onProgress.dispatch(message.state);

					case COMPLETE, ERROR:
						__workCompleted++;

						if ((currentThreads > (__workQueued - __workCompleted) && currentThreads > minThreads)
							|| currentThreads > maxThreads)
						{
							currentThreads--;
							__workIncoming.add(new ThreadPoolMessage(EXIT, null));
						}

						if (message.type == COMPLETE)
						{
							onComplete.dispatch(message.state);
						}
						else
						{
							onError.dispatch(message.state);
						}

					default:
				}

				message = __workResult.pop(false);
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
	#elseif js
	@:noCompletion private function __startIdleWorkers():Void
	{
		while (__idleWorkers.length > 0 && !__workIncoming.isEmpty())
		{
			__idleWorkers.pop().postMessage(__workIncoming.pop());
		}
	}

	@:noCompletion private function __handleMessage(worker:Worker, workerURL:String, event:MessageEvent):Void
	{
		var message:ThreadPoolMessage = event.data;

		switch (message.type)
		{
			case WORK:
				onRun.dispatch(message.state);

			case PROGRESS:
				onProgress.dispatch(message.state);

			case COMPLETE, ERROR:
				if (__workIncoming.isEmpty() && currentThreads > minThreads || currentThreads > maxThreads)
				{
					currentThreads--;
					worker.terminate();
					URL.revokeObjectURL(workerURL);
				}
				else
				{
					__idleWorkers.push(worker);
				}

				if (message.type == COMPLETE)
				{
					onComplete.dispatch(message.state);
				}
				else
				{
					onError.dispatch(message.state);
				}

				__startIdleWorkers();
			default:
		}
	}
	#end
}

@:enum private abstract ThreadPoolMessageType(String)
{
	var COMPLETE = "COMPLETE";
	var ERROR = "ERROR";
	var EXIT = "EXIT";
	var PROGRESS = "PROGRESS";
	var WORK = "WORK";
}

@:forward
private abstract ThreadPoolMessage({ state:Dynamic, type:ThreadPoolMessageType })
{
	public inline function new(type:ThreadPoolMessageType, state:Dynamic)
	{
		this = {
			type: type,
			state: state
		};
	}
}
