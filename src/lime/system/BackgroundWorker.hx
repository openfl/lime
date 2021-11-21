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
import haxe.Template;
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
		return if it's ever true.

		While this is not technically thread-safe, canceled
		workers have effectively no impact on anything, so
		thread safety is unlikely to matter.
	**/
	public var canceled(default, null):Bool;

	/**
		Indicates that `sendComplete()` has been called
		at least once.
	**/
	public var completed(default, null):Bool;

	/**
		This function will be executed on the background
		thread when the main thread calls `run()`. It must
		take a single argument - the value passed to
		`run()`. Instead of returning a value, it should
		call `sendComplete()`, `sendError()`, and/or
		`sendProgress()` to communicate.

		On most targets, it's possible for the background
		function to access all memory, just like any other
		code. However, this may be less safe than using the
		provided "send" functions.

		HTML5 imposes some extra restrictions. The function
		can't access outside memory, such as class variables
		and static functions. Inline variables and functions
		still work, including the three "send" functions.
		Using a bound function will not work.

		DCE is highly recommended on HTML5, as it will
		inline standard functions such as `trace()`.
	**/
	@:noCompletion public var doWork(default, null):DoWork;

	/**
		Dispatched on the main thread when the background
		thread calls `sendComplete()`.
	**/
	public var onComplete = new Event<Dynamic->Void>();

	/**
		Dispatched on the main thread when the background
		thread calls `sendError()`.
	**/
	public var onError = new Event<Dynamic->Void>();

	/**
		Dispatched on the main thread when the background
		thread calls `sendProgress()`.
	**/
	public var onProgress = new Event<Dynamic->Void>();

	@:noCompletion private var __runMessage:Dynamic;
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
		}
		#end
	}

	@:noCompletion @:dox(hide) public function __run(doWork:Dynamic -> Void, message:Dynamic):Void
	{
		if (doWork != null)
		{
			this.doWork = doWork;
		}

		if (this.doWork == null)
		{
			return;
		}

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
		var stringListener:String = Syntax.code("{0}.toString()", this.doWork);

		// It is actually possible to unbind a function, but
		// this requires calling it, and the whole point is
		// not to call it on the main thread.
		// https://www.quora.com/In-Javascript-how-would-I-extract-the-actual-function-when-provided-only-a-bound-function-Or-is-this-not-possible/answer/Andrew-Smith-1766
		/* if (stringListener.indexOf("[native code]") >= 0)
		{
			stringListener = Syntax.code("new {0}().constructor.toString()", doWork);
		} */

		// Unless `@:analyzer(optimize)` was enabled,
		// `postMessage` likely still includes an unneeded
		// reference to outside code.
		stringListener = ~/var _this = .+?;\s*postMessage/g
			.replace(stringListener, "postMessage");

		var workerJS:String =
			"this.onmessage = function(messageEvent) {\n"
			+ "    this.onmessage = null;\n"
			+ '    (async $stringListener)(messageEvent.data);\n'
			+ "};";
		// Compile with -verbose to view.
		Log.verbose("Generated script:\n" + workerJS);

		if (stringListener.indexOf("[native code]") >= 0)
		{
			throw "BackgroundWorker doesn't support bound functions. Try a static function instead.";
		}

		__workerURL = URL.createObjectURL(new Blob([workerJS]));

		__worker = new Worker(__workerURL);
		__worker.onmessage = __handleMessage;
		__worker.postMessage(__runMessage);
		#else
		__doWork();
		#end
	}

	/**
		[Call this from the background thread.]

		Dispatches `onComplete` on the main thread, with
		the given argument.
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

		Dispatches `onError` on the main thread, with
		the given argument.
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

		Dispatches `onProgress` on the main thread,
		with the given argument.
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

	@:noCompletion private function __doWork():Void
	{
		doWork.dispatch(__runMessage);
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
	#end // !macro

	/**
		[Call this from the main thread.]

		Creates a new thread and calls `doWork` on that
		thread. Can only be called once, to avoid having
		old threads interfere with new ones.

		@param doWork The code to run in the background.

		Optional only for backwards compatibility. New code
		should always supply this.

		Caution: in HTML5, this will be almost completely
		isolated from the main thread. Closures will be
		lost, external variables and functions (even from
		Haxe's standard library) will be undefined, "`this`"
		will refer to a `DedicatedWorkerGlobalScope`, and
		even `trace()` will only work with DCE enabled.
		`doWork` will still have access to `message`,
		built-in JS functions, inline variables, and inline
		functions (including all three "send" functions).

		@param message Data to pass to `doWork`. This is
		especially important in HTML5, as it will be the
		only data available to the function.

		Optional.
	**/
	public macro function run(self:Expr, ?doWork:Expr, ?message:Expr):Expr
	{
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
					// The one argument is indeed `doWork`.
					message = macro null;
				default:
					// The one argument was supposed to be
					// `message`.
					message = doWork;
					return macro $self.__run(null, $message);
			}
		}

		return macro {
			var doWork;

			// Assign the function to the local variable
			// without binding it.
			${DoWork.add(macro doWork, doWork)};

			$self.__run(doWork, $message);
		}
	}
}

/**
	A single function that offers the same interface as
	`lime.app.Event`, for backwards compatibility.
**/
private abstract DoWork(Dynamic -> Void) from Dynamic -> Void to Dynamic -> Void {
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

		// On JS targets, Haxe automatically calls `bind(this)`
		// for instance functions. This allows them to access
		// `this`, which is usually good. However,
		// `BackgroundWorker` can't use bound functions.

		// To combat this, generate an `Expr` that refers to
		// the callback without invoking `bind()`.

		var unboundCallback = null;

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
					// Potentially an instance function.
					var syntax = 'this.$ident';
					unboundCallback = macro js.Syntax.code($v{syntax});
				}
			case EField(e, field):
				// Field access could refer to a static or
				// instance function.
				switch (Context.typeof(e))
				{
					case TType(_):
						// Static function - fine as-is.
					default:
						// Likely an instance function.
						var syntax = '{0}.$field';
						unboundCallback = macro js.Syntax.code($v{syntax}, $e);
				}
			default:
				// Other cases aren't likely to matter.
		}

		if (unboundCallback != null)
		{
			// Note that DCE can't parse `unboundCallback`,
			// and may delete the function. Unfortunately
			// `Compiler.keep()` does nothing, possibly
			// because it's too late in the compile process.
			return macro {
				// Refer directly to the callback. This will
				// invoke `bind()`.
				$self = $callback;
				// Immediately overwrite the bound callback.
				$self = $unboundCallback;
			};
		}
		else
		{
			return macro $self = $callback;
		}
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
}
