package lime.system;

#if !macro
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
import js.html.Blob;
import js.html.DedicatedWorkerGlobalScope;
import js.html.MessageEvent;
import js.html.URL;
import js.html.Worker;
import js.Syntax;
import lime.utils.Log;
#end
#else
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
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
	#if !macro
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

	@:noCompletion public var doWork(default, null):ThreadFunction;

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

	#if (target.threaded || cpp || neko)
	@:noCompletion private var __messageQueue:Deque<{ ?event:String, message:Dynamic }>;
	@:noCompletion private var __workerThread:Thread;
	#elseif js
	@:noCompletion private var __worker:Worker;
	@:noCompletion private var __workerURL:String;
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
	}

	@:noCompletion @:dox(hide) public function __run(doWork:ThreadFunction, message:Dynamic):Void
	{
		if (doWork == null)
		{
			doWork = this.doWork;
			if (doWork == null) return;
		}

		cancel();
		canceled = false;

		#if (target.threaded || cpp || neko)
		__messageQueue = new Deque();
		__workerThread = Thread.create(doWork.bind(message));

		// TODO: Better way to do this

		if (Application.current != null)
		{
			Application.current.onUpdate.add(__update);
		}
		#elseif js
		var workerJS:String =
			"this.onmessage = function(messageEvent) {\n"
			+ "    this.onmessage = null;\n"
			+ '    (async ${doWork.toString()})(messageEvent.data);\n'
			+ "    this.close();\n"
			+ "};";

		__workerURL = URL.createObjectURL(new Blob([workerJS]));

		__worker = new Worker(__workerURL);
		__worker.onmessage = __handleMessage;
		__worker.postMessage(message);
		#else
		doWork(message);
		#end
	}

	/**
		[Call this from the background thread.]

		Dispatches `onComplete` on the main thread, with the
		given argument. After completion, all further
		messages will be ignored.
	**/
	#if js inline #end
	public function sendComplete(message:Dynamic = null):Void
	{
		#if (target.threaded || cpp || neko)
		if (Thread.current() != __workerThread) return;

		if (__messageQueue != null)
		{
			__messageQueue.add({
				event: MESSAGE_COMPLETE,
				message: message
			});
		}
		#elseif js
		Syntax.code("postMessage({0})", {
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

	/**
		[Call this from the background thread.]

		Dispatches `onError` on the main thread, with the
		given argument. After an error, all further messages
		will be ignored.
	**/
	#if js inline #end
	public function sendError(message:Dynamic = null):Void
	{
		#if (target.threaded || cpp || neko)
		if (Thread.current() != __workerThread) return;

		if (__messageQueue != null)
		{
			__messageQueue.add({
				event: MESSAGE_ERROR,
				message: message
			});
		}
		#elseif js
		Syntax.code("postMessage({0})", {
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

	/**
		[Call this from the background thread.]

		Dispatches `onProgress` on the main thread, with the
		given argument.
	**/
	#if js inline #end
	public function sendProgress(message:Dynamic = null):Void
	{
		#if (target.threaded || cpp || neko)
		if (Thread.current() != __workerThread) return;

		if (__messageQueue != null)
		{
			__messageQueue.add({
				message: message
			});
		}
		#elseif js
		Syntax.code("postMessage({0})", {
			message: message
		});
		#else
		if (!canceled)
		{
			onProgress.dispatch(message);
		}
		#end
	}

	@:noCompletion private function __update(deltaTime:Int):Void
	{
		#if (target.threaded || cpp || neko)
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
		#end
	}

	#if js
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
	#end // !macro

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
		@param message Data to pass to `doWork`.
	**/
	public macro function run(self:Expr, ?doWork:ExprOf<Dynamic -> Void>, ?message:Expr):Expr
	{
		#if display
		return macro null;
		#else
		function isNull(expr:Expr)
		{
			switch(expr.expr)
			{
				case EConst(CIdent("null")):
					return true;
				default:
					return false;
			}
		}

		if (isNull(doWork))
		{
			return macro $self.__run(null, null);
		}

		if (isNull(message))
		{
			switch (Context.typeof(doWork))
			{
				case TFun(_):
					// The one argument is `doWork`.
					message = macro null;
				default:
					// The one argument is `message`.
					message = doWork;
					return macro $self.__run(null, $message);
			}
		}

		return macro {
			var doWork;

			// Set `doWork = $doWork`, with some extra
			// JS-specific checks.
			${ThreadFunction.add(macro doWork, doWork)};

			$self.__run(doWork, $message);
		}
		#end
	}
}

/**
	A function that can be called on another thread. In
	JavaScript, calling a function on another thread
	requires extra work, which is performed automatically.

	`ThreadFunction` also provides an `Event`-like API for
	backwards compatibility. However, it can only store one
	function at once; `add()` overwrites the old function.
**/
abstract ThreadFunction(Dynamic -> Void) from Dynamic -> Void to Dynamic -> Void
{
	/**
		Adds the given callback function, to be run on the
		other thread. Unlike with `lime.app.Event`, only one
		callback can exist; `add()` overwrites the old one.
	**/
	#if (display || !js && !macro)
	public inline function add(callback:Dynamic -> Void):Void
	{
		this = callback;
	}
	#else
	// Other macros can call this statically to generate
	// `$self = $callback` with anti-binding measures.
	#if macro static #else macro #end
	public function add(self:Expr, callback:ExprOf<Dynamic -> Void>):Expr
	{
		if (!Context.defined("js"))
		{
			return macro $self = $callback;
		}

		// On JS targets, Haxe automatically calls
		// `bind(this)` for instance functions. This allows
		// the functions to access `this`, which is usually
		// good. However, `BackgroundWorker` can't use bound
		// functions, so a workaround is required.

		switch (callback.expr)
		{
			case EConst(CIdent(ident)):
				// Raw identifiers could be local, static,
				// or instance functions.
				if (Lambda.exists(Context.getLocalTVars(),
					function(tVar) return tVar.name == ident))
				{
					// Local function - either fine as-is or
					// infeasible to fix.
				}
				else
				{
					// Potentially an instance function, but
					// allow Haxe to generate a fallback.
					var syntax = 'this.$ident || {0}';
					return macro $self = js.Syntax.code($v{syntax}, $callback);
				}
			case EField(e, field):
				// Field access could refer to a static or
				// instance function. Check what comes
				// before the dot.
				switch (Context.typeof(e))
				{
					case TType(_):
						// Static function - fine as-is.
					default:
						// Likely an instance function.
						var syntax = '{0}.$field';

						// Refer to `callback` so that DCE
						// knows to keep the function. This
						// reference won't make it into the
						// final JavaScript.
						return macro $self = js.Syntax.code($v{syntax}, $e, $callback);
				}
			default:
				// Other cases aren't likely to matter.
		}

		return macro $self = $callback;
	}
	#end

	/**
		Executes this function on the current thread.
	**/
	public inline function dispatch(message:Dynamic):Void
	{
		if (this != null)
		{
			this(message);
		}
	}

	@:noCompletion @:dox(hide) public inline function has(callback:Dynamic -> Void):Bool
	{
		// Not fully compatible with JS.
		return Reflect.compareMethods(this, callback);
	}

	@:noCompletion @:dox(hide) public inline function remove(callback:Dynamic -> Void):Void
	{
		if (has(callback))
		{
			this = null;
		}
	}

	@:noCompletion @:dox(hide) public inline function removeAll():Void
	{
		this = null;
	}

	public inline function bind(arg)
	{
		return this.bind(arg);
	}

	#if js
	@:noCompletion @:to public function toString():String
	{
		var script:String = Syntax.code("{0}.toString()", this);

		// It is actually possible to unbind a function, but
		// this requires calling it, and the whole point is
		// not to call it on the main thread.
		// https://www.quora.com/In-Javascript-how-would-I-extract-the-actual-function-when-provided-only-a-bound-function-Or-is-this-not-possible/answer/Andrew-Smith-1766
		/* if (string.indexOf("[native code]") >= 0)
		{
			string = Syntax.code("new {0}().constructor.toString()", doWork);
		} */

		// Unless `@:analyzer(optimize)` was enabled,
		// `postMessage` likely still includes an unneeded
		// reference to outside code.
		script = ~/var _this = .+?;\s*postMessage/g
			.replace(script, "postMessage");

		// Compile with -verbose to view.
		Log.verbose("Generated script:\n" + script);

		if (script.indexOf("[native code]") >= 0)
		{
			throw "Haxe automatically binds instance functions in JS, making them incompatible with js.html.Worker. Try a static function instead.";
		}

		return script;
	}
	#end
}
