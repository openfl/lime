package lime.system;

import lime.app.Application;
import lime.app.Event;
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
class BackgroundWorker
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

	@:noCompletion public var doWork:ThreadFunction<Dynamic->Void>;

	/**
		Dispatched on the main thread when the background
		thread calls `sendComplete()`. For best results, add
		all listeners before calling `run()`.
	**/
	public var onComplete = new Event<Dynamic->Void>();

	/**
		Dispatched on the main thread when the background
		thread calls `sendError()`. For best results, add
		all listeners before calling `run()`.
	**/
	public var onError = new Event<Dynamic->Void>();

	/**
		Dispatched on the main thread when the background
		thread calls `sendProgress()`. For best results, add
		all listeners before calling `run()`.
	**/
	public var onProgress = new Event<Dynamic->Void>();

	#if !force_synchronous
	#if (target.threaded || cpp || neko)
	@:noCompletion private var __messageQueue:Deque<{ ?event:String, message:Dynamic }>;
	@:noCompletion private var __workerThread:Thread;
	#elseif js
	/**
		Any `Worker` created by `BackgroundWorker` or
		`ThreadPool` will run this JavaScript code first.

		This is intended to declare functions that workers
		might try to access, such as `trace()`, that are
		normally only available on the main thread.
	**/
	@:noCompletion @:dox(hide) public static var initializeWorker:String =
		"'use strict';\n"
		+ 'var haxe_Log = { trace: (v, infos) => console.log(infos.fileName + ":" + infos.lineNumber + ": " + v) };\n'
		+ "var StringTools = { startsWith: (s, start) => s.startsWith(start), endsWith: (s, end) => s.endsWith(end), trim: s => s.trim() };\n"
		+ "var HxOverrides = { substr: (s, pos, len) => s.substr(pos, len) };\n";

	@:noCompletion private var __worker:Worker;
	@:noCompletion private var __workerURL:String;
	#end
	#end

	public function new() {}

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
			__messageQueue = null;
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

		**Caution:** in HTML5, workers are almost completely
		isolated from the main thread. They will have
		access to three main things: (1) certain JavaScript
		functions (see `DedicatedWorkerGlobalScope`), (2)
		inline Haxe functions (including all three "send"
		functions), and (3) the contents of `message`. To
		inline as much as possible, turn on DCE and tag the
		function with `@:analyzer(optimize)`.
		@param doWork A `Dynamic -> Void` function to run in
		the background. (Optional only for backwards
		compatibility. Treat this as a required argument.)
		@param message Data to pass to `doWork`. HTML5
		imposes several restrictions on this data:
		https://developer.mozilla.org/en-US/docs/Web/API/Web_Workers_API/Structured_clone_algorithm
		@param transferList (JavaScript only) Zero or more
		buffers to transfer using an efficient zero-copy
		operation. The worker thread will only receive these
		if they're also included in `message`.
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
		__messageQueue = new Deque();
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
			initializeWorker,
			"this.onmessage = function(messageEvent) {\n",
			"    this.onmessage = null;\n",
			'    ($doWork)(messageEvent.data);\n',
			"    this.close();\n",
			"};"
		]));

		__worker = new Worker(__workerURL);
		__worker.onmessage = __handleMessage;
		__worker.postMessage(message, transferList);
		#else
		doWork.dispatch(message);
		#end
	}

	/**
		[Call this from the background thread.]

		Dispatches `onComplete` on the main thread, passing
		`message` along. After completion, all further
		messages will be ignored.
		@param transferList (JavaScript only) Zero or more
		buffers to transfer using an efficient zero-copy
		operation. The main thread will only receive these
		if they're also included in `message`.
	**/
	#if js inline #end
	public function sendComplete(message:Dynamic = null, transferList:Array<ArrayBuffer> = null):Void
	{
		#if ((target.threaded || cpp || neko) && !force_synchronous)
		if (Thread.current() != __workerThread) return;

		if (__messageQueue != null)
		{
			__messageQueue.add({
				event: MESSAGE_COMPLETE,
				message: message
			});
		}
		#elseif (js && !force_synchronous)
		Syntax.code("postMessage({0}, {1})", {
			event: MESSAGE_COMPLETE,
			message: message
		}, transferList);
		#else
		completed = true;

		if (!canceled)
		{
			canceled = true;
			onComplete.dispatch(message);
		}
		#end
	}

	/**
		[Call this from the background thread.]

		Dispatches `onError` on the main thread, passing
		`message` along. After an error, all further
		messages will be ignored.
		@param transferList (JavaScript only) Zero or more
		buffers to transfer using an efficient zero-copy
		operation. The main thread will only receive these
		if they're also included in `message`.
	**/
	#if js inline #end
	public function sendError(message:Dynamic = null, transferList:Array<ArrayBuffer> = null):Void
	{
		#if ((target.threaded || cpp || neko) && !force_synchronous)
		if (Thread.current() != __workerThread) return;

		if (__messageQueue != null)
		{
			__messageQueue.add({
				event: MESSAGE_ERROR,
				message: message
			});
		}
		#elseif (js && !force_synchronous)
		Syntax.code("postMessage({0}, {1})", {
			event: MESSAGE_ERROR,
			message: message
		}, transferList);
		#else
		if (!canceled)
		{
			canceled = true;
			onError.dispatch(message);
		}
		#end
	}

	/**
		[Call this from the background thread.]

		Dispatches `onProgress` on the main thread, passing
		`message` along.
		@param transferList (JavaScript only) Zero or more
		buffers to transfer using an efficient zero-copy
		operation. The main thread will only receive these
		if they're also included in `message`. Once
		transferred, they will become inaccessible to the
		background thread.
	**/
	#if js inline #end
	public function sendProgress(message:Dynamic = null, transferList:Array<ArrayBuffer> = null):Void
	{
		#if ((target.threaded || cpp || neko) && !force_synchronous)
		if (Thread.current() != __workerThread) return;

		if (__messageQueue != null)
		{
			__messageQueue.add({
				message: message
			});
		}
		#elseif (js && !force_synchronous)
		Syntax.code("postMessage({0}, {1})", {
			message: message
		}, transferList);
		#else
		if (!canceled)
		{
			onProgress.dispatch(message);
		}
		#end
	}

	#if ((target.threaded || cpp || neko) && !force_synchronous)
	@:noCompletion private function __update(deltaTime:Int):Void
	{
		var data = __messageQueue.pop(false);

		if (data != null)
		{
			if (data.event == MESSAGE_ERROR)
			{
				cancel();
				onError.dispatch(data.message);
			}
			else if (data.event == MESSAGE_COMPLETE)
			{
				completed = true;
				cancel();
				onComplete.dispatch(data.message);
			}
			else
			{
				onProgress.dispatch(data.message);
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
		else if (event.data.event == MESSAGE_ERROR)
		{
			canceled = true;
			onError.dispatch(event.data.message);

			URL.revokeObjectURL(__workerURL);
			__workerURL = null;
		}
		else if (event.data.event == MESSAGE_COMPLETE)
		{
			completed = true;
			canceled = true;
			onComplete.dispatch(event.data.message);

			URL.revokeObjectURL(__workerURL);
			__workerURL = null;
		}
		else
		{
			onProgress.dispatch(event.data.message);
		}
	}
	#end
}
