package lime.system;

import lime.app.Application;
import lime.app.Event;
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
import haxe.Template;
import js.html.Blob;
import js.html.DedicatedWorkerGlobalScope;
import js.html.MessageEvent;
import js.html.URL;
import js.html.Worker;
import js.Syntax;
#end
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class BackgroundWorker
{
	private static inline var MESSAGE_COMPLETE = "__COMPLETE__";
	private static inline var MESSAGE_ERROR = "__ERROR__";
	private static inline var MESSAGE_CANCEL = "__CANCEL__";

	#if js
	private static var WORKER_TEMPLATE = new Template(
		"this.onmessage = function(event) {"
		+ "this.onmessage = null;"
		+ "::foreach workers::(::listener::)(event.data);"
		+ "::end::"
		+ "};"
	);
	#end

	public var canceled(default, null):Bool;
	public var completed(default, null):Bool;
	public var doWork = new Event<Dynamic->Void>();
	public var onComplete = new Event<Dynamic->Void>();
	public var onError = new Event<Dynamic->Void>();
	public var onProgress = new Event<Dynamic->Void>();

	@:noCompletion private var __alreadyRun:Bool = false;
	@:noCompletion private var __runMessage:Dynamic;
	#if (target.threaded || cpp || neko)
	@:noCompletion private var __messageQueue:Deque<{ ?event:String, message:Dynamic }>;
	@:noCompletion private var __workerThread:Thread;
	#elseif js
	@:noCompletion private var __worker:Worker;
	@:noCompletion private var __workerURL:String;
	#end

	public function new() {}

	public function cancel():Void
	{
		canceled = true;

		#if (target.threaded || cpp || neko)
		Application.current.onUpdate.remove(__update);

		if (__workerThread != null)
		{
			// Canceling `doWork` causes the background
			// thread to stop after the active function,
			// instead of calling the remaining listeners.
			doWork.cancel();

			// Send a message to the active function,
			// telling it to return early.
			__workerThread.sendMessage(MESSAGE_CANCEL);

			__workerThread = null;
			__messageQueue = null;
		}
		#elseif js
		if (__worker != null)
		{
			__worker.terminate();
			__worker = null;
		}
		#end
	}

	#if (target.threaded || cpp || neko)
	public inline function isThreadCanceled():Bool
	{
		return Thread.current().readMessage(false) == MESSAGE_CANCEL;
	}
	#end

	public function run(message:Dynamic = null):Void
	{
		if (__alreadyRun)
		{
			return;
		}

		__alreadyRun = true;
		__runMessage = message;

		#if (target.threaded || cpp || neko)
		__messageQueue = new Deque();
		__workerThread = Thread.create(__doWork);

		// TODO: Better way to do this

		if (Application.current != null)
		{
			Application.current.onUpdate.add(__update);
		}
		#elseif js
		var workerJS = WORKER_TEMPLATE.execute(
			{
				workers: [for(listener in doWork.__listeners)
					{ listener: Syntax.code("'' + {0}", listener) }
				]
			}
		);

		__workerURL = URL.createObjectURL(new Blob([workerJS]));

		__worker = new Worker(__workerURL);
		__worker.onmessage = __handleMessage;
		__worker.postMessage(__runMessage);
		#else
		__doWork();
		#end
	}

	#if js inline #end
	public function sendComplete(message:Dynamic = null):Void
	{
		#if (target.threaded || cpp || neko)
		if (__messageQueue != null)
		{
			__messageQueue.add({
				event: MESSAGE_COMPLETE,
				message: message
			});
		}
		#elseif js
		Syntax.code("this.postMessage({0})", {
			event: MESSAGE_COMPLETE,
			message: message
		});
		#else
		completed = true;

		if (!canceled)
		{
			canceled = true;
			onComplete.dispatch(message);
		}
		#end
	}

	#if js inline #end
	public function sendError(message:Dynamic = null):Void
	{
		#if (target.threaded || cpp || neko)
		if (__messageQueue != null)
		{
			__messageQueue.add({
				event: MESSAGE_ERROR,
				message: message
			});
		}
		#elseif js
		Syntax.code("this.postMessage({0})", {
			event: MESSAGE_ERROR,
			message: message
		});
		#else
		if (!canceled)
		{
			canceled = true;
			onError.dispatch(message);
		}
		#end
	}

	#if js inline #end
	public function sendProgress(message:Dynamic = null):Void
	{
		#if (target.threaded || cpp || neko)
		if (__messageQueue != null)
		{
			__messageQueue.add({
				message: message
			});
		}
		#elseif js
		Syntax.code("this.postMessage({0})", {
			message: message
		});
		#else
		if (!canceled)
		{
			onProgress.dispatch(message);
		}
		#end
	}

	@:noCompletion private function __doWork():Void
	{
		doWork.dispatch(__runMessage);

		// #if (target.threaded || cpp || neko)
		//
		// __messageQueue.add (MESSAGE_COMPLETE);
		//
		// #else
		//
		// if (!canceled) {
		//
		// canceled = true;
		// onComplete.dispatch (null);
		//
		// }
		//
		// #end
	}

	@:noCompletion private function __update(deltaTime:Int):Void
	{
		#if (target.threaded || cpp || neko)
		var data = __messageQueue.pop(false);

		if (data != null)
		{
			if (data.event == MESSAGE_ERROR)
			{
				Application.current.onUpdate.remove(__update);

				if (!canceled)
				{
					canceled = true;
					onError.dispatch(data.message);
				}
			}
			else if (data.event == MESSAGE_COMPLETE)
			{
				completed = true;
				Application.current.onUpdate.remove(__update);

				if (!canceled)
				{
					canceled = true;
					onComplete.dispatch(data.message);
				}
			}
			else
			{
				if (!canceled)
				{
					onProgress.dispatch(data.message);
				}
			}
		}
		#end
	}

	#if js
	@:noCompletion private function __handleMessage(event:MessageEvent):Void
	{
		if (event.data.event == MESSAGE_COMPLETE)
		{
			completed = true;
			canceled = true;
			onComplete.dispatch(event.data.message);
		}
		else if (event.data.event == MESSAGE_ERROR)
		{
			canceled = true;
			onError.dispatch(event.data.message);
		}
		else
		{
			onProgress.dispatch(event.data.message);
		}
	}
	#end
}
