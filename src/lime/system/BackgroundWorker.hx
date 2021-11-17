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
	private static inline var MESSAGE_CANCEL = "__CANCEL__";

	public var canceled(default, null):Bool;
	public var completed(default, null):Bool;
	@:noCompletion public var doWork(default, null):DoWork;
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
		if (__alreadyRun)
		{
			return;
		}

		if (doWork != null)
		{
			this.doWork = doWork;
		}

		if (this.doWork == null)
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
			return macro $self.__run();
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

abstract DoWork(Dynamic -> Void) from Dynamic -> Void to Dynamic -> Void {
	#if (!js && !macro)
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
