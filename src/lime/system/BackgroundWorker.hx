package lime.system;

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

/**
	A simple way to run a task on another thread. If threads
	threads aren't available, `BackgroundWorker` falls back
	to synchronous code, running the function immediately.
	Use `#if (target.threaded || js)` to check if threads
	are supported.

	The worker function can return data in a thread-safe
	manner using the `sendProgress()`, `sendError()`, and
	`sendComplete()` functions. The main thread receives
	this data via the `onProgress`, `onError`, and
	`onComplete` events.

	Sample usage:

		private var bgWorker:BackgroundWorker;

		@:analyzer(optimize)
		private static function makeItems(_):Void {
			var items:Array<Item> = [];

			try
			{
				for (i in 0...3000)
				{
					items.push(Item.generateRandomItem());

					if (i % 100 == 0)
					{
						bgWorker.sendProgress(i);
					}
				}
			}
			catch (e:Dynamic)
			{
				bgWorker.sendError(e);
				return;
			}

			bgWorker.sendComplete(items);
		}

		public function new() {
			bgWorker = new BackgroundWorker();

			bgWorker.onProgress(function(count:Int) {
				trace(count + " items done!");
			});

			bgWorker.onError.add(function(error:Dynamic) {
				trace("Error: " + Std.string(error));
			});

			bgWorker.onComplete(function(items:Array<Item>) {
				this.items = items;
				trace('Created ${items.length} items!');
			});

			bgWorker.run(makeItems);
		}
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class BackgroundWorker extends ThreadBase
{
	private static inline var MESSAGE_COMPLETE = "__COMPLETE__";
	private static inline var MESSAGE_ERROR = "__ERROR__";

	/**
		Indicates that `cancel()`, `sendComplete()`, or
		`sendError()` has been called. This also means that
		"send" functions will be ignored from now on.

		Only the main thread should set this value, but
		workers are encouraged to check it periodically and
		return if it's ever true. (This is technically not
		thread-safe, but it's very unlikely to matter.)
	**/
	public var canceled(default, null):Bool;

	/**
		Indicates that `sendComplete()` has been called
		at least once.
	**/
	public var completed(default, null):Bool;

	#if !force_synchronous
	#if (target.threaded || cpp || neko)
	@:noCompletion private var __workerThread:Thread;
	#elseif js
	@:noCompletion private var __worker:Worker;
	@:noCompletion private var __workerURL:String;
	#end
	#end

	public function new()
	{
		super(null);
	}

	/**
		[Call this from the main thread.]

		Sets `canceled` and stops reporting events from the
		background thread.

		On system targets, it's impossible to forcefully
		stop a thread, so it's up to that thread to check
		the value of `canceled` and return.

		On HTML5, the thread will be forcefully stopped.
	**/
	public function cancel():Void
	{
		canceled = true;

		#if !force_synchronous
		#if (target.threaded || cpp || neko)
		Application.current.onUpdate.remove(__update);

		if (__workerThread != null)
		{
			__workerThread = null;
			__workResult = null;
		}
		#elseif js
		if (__worker != null)
		{
			__worker.terminate();
			__worker = null;
			URL.revokeObjectURL(__workerURL);
			__workerURL = null;
		}
		#end
		#end
	}

	/**
		[Call this from the main thread.]

		Creates a background thread to run `doWork`. The
		function will receive `message` as an argument, and
		it can call `sendComplete()`, `sendError()`, and/or
		`sendProgress()` to send data.

		**Caution:** if web workers are enabled, `doWork`
		will be almost completely isolated from the main
		thread. It will have access to three main things:
		(1) common JavaScript functions, (2) inline
		variables and functions (including all three "send"
		functions), and (3) the contents of `message`.
		@param doWork A `Dynamic -> Void` function to run in
		the background. (Optional only for backwards
		compatibility. Treat this as a required argument.)
		@param message Data to pass to `doWork`. Web workers
		impose several restrictions on this data:
		https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Structured_clone_algorithm
		@param transferList (Web workers only) A list of
		buffers in `message` that should be moved rather
		than copied to the background thread. For details,
		see https://developer.mozilla.org/en-US/docs/Glossary/Transferable_objects
	**/
	public function run(?doWork:ThreadFunction<Dynamic->Void>, ?message:Dynamic, transferList:Array<ArrayBuffer> = null):Void
	{
		if (doWork == null)
		{
			doWork = this.doWork;
			if (doWork == null) return;
		}

		cancel();
		canceled = false;

		#if ((target.threaded || cpp || neko) && !force_synchronous)
		__workResult = new Deque();
		__workerThread = Thread.create(function():Void {
			doWork.dispatch(message);
		});

		// TODO: Better way to do this

		if (Application.current != null)
		{
			Application.current.onUpdate.add(__update);
		}
		#elseif (js && !force_synchronous)
		doWork.checkJS();

		__workerURL = URL.createObjectURL(new Blob([
			headerCode.toString(),
			"this.onmessage = function(messageEvent) {\n",
			"    this.onmessage = null;\n",
			'    ($doWork)(messageEvent.data);\n',
			"};"
		], {type: "text/javascript"}));

		__worker = new Worker(__workerURL);
		__worker.onmessage = __handleMessage;
		__worker.postMessage(message, transferList);
		#else
		doWork.dispatch(message);
		#end
	}

	#if (!js || force_synchronous)
	@:inheritDoc
	public override function sendComplete(message:Dynamic = null, transferList:Array<ArrayBuffer> = null):Void
	{
		#if ((target.threaded || cpp || neko) && !force_synchronous)
		if (Thread.current() == __workerThread)
		{
			super.sendComplete(message, transferList);
		}
		#else
		completed = true;

		if (!canceled)
		{
			canceled = true;
			onComplete.dispatch(message);
		}
		#end
	}
	#end

	#if (!js || force_synchronous)
	@:inheritDoc
	public override function sendError(message:Dynamic = null, transferList:Array<ArrayBuffer> = null):Void
	{
		#if ((target.threaded || cpp || neko) && !force_synchronous)
		if (Thread.current() == __workerThread)
		{
			super.sendError(message, transferList);
		}
		#else
		if (!canceled)
		{
			canceled = true;
			onError.dispatch(message);
		}
		#end
	}
	#end

	#if (!js || force_synchronous)
	@:inheritDoc
	public override function sendProgress(message:Dynamic = null, transferList:Array<ArrayBuffer> = null):Void
	{
		#if ((target.threaded || cpp || neko) && !force_synchronous)
		if (Thread.current() != __workerThread)
		{
			super.sendProgress(message, transferList);
		}
		#else
		if (!canceled)
		{
			onProgress.dispatch(message);
		}
		#end
	}
	#end

	#if ((target.threaded || cpp || neko) && !force_synchronous)
	@:noCompletion private function __update(deltaTime:Int):Void
	{
		var threadEvent = __workResult.pop(false);

		if (threadEvent != null)
		{
			switch (threadEvent.event)
			{
				case ERROR:
					cancel();
					onError.dispatch(threadEvent.message);

				case COMPLETE:
					completed = true;
					cancel();
					onComplete.dispatch(threadEvent.message);

				case PROGRESS:
					onProgress.dispatch(threadEvent.message);

				default:
			}
		}
	}
	#end

	#if (js && !force_synchronous)
	@:noCompletion private function __handleMessage(event:MessageEvent):Void
	{
		if (canceled)
		{
			return;
		}

		var threadEvent:ThreadEvent = event.data;

		switch (threadEvent.event)
		{
			case ERROR:
				cancel();
				onError.dispatch(threadEvent.message);

			case COMPLETE:
				completed = true;
				cancel();
				onComplete.dispatch(threadEvent.message);

			case PROGRESS:
				onProgress.dispatch(threadEvent.message);

			default:
		}
	}
	#end
}
