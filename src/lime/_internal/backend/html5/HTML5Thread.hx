package lime._internal.backend.html5;

import lime.app.Event;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Context;
using haxe.macro.TypeTools;
using haxe.macro.TypedExprTools;
#else
// Not safe to import js package during macros.
import js.Browser;
import js.html.*;
import js.Lib;
#if haxe4
import js.lib.Function;
import js.lib.Object;
import js.lib.Promise;
import js.Syntax;
#else
import js.Promise;
#end
// Same with classes that import lots of other things.
import lime.app.Application;
#end

/**
	Emulates much of the `sys.thread.Thread` API using web workers.
**/
class HTML5Thread {
	private static var __current:HTML5Thread = new HTML5Thread(Lib.global.location.href);
	private static var __isWorker:Bool #if !macro = #if !haxe4 untyped __js__ #else Syntax.code #end ('typeof window == "undefined"') #end;
	private static var __messages:List<Dynamic> = new List();
	private static var __resolveMethods:List<Dynamic->Void> = new List();
	private static var __workerCount:Int = 0;

	/**
		The entry point into a worker script.

		Lime's output JS file normally does not begin on its own. Instead it
		registers a `lime.embed()` callback for index.html to use.

		When this JS file is run as a web worker, it isn't running within
		index.html, so `embed()` never gets called. Instead, `__init__()`
		registers a message listener.
	**/
	private static function __init__():Void
	{
		#if !macro
		if (#if !haxe4 untyped __js__ #else Syntax.code #end ('typeof window == "undefined"'))
		{
			Lib.global.onmessage = function(event:MessageEvent):Void
			{
				var job:WorkFunction<Void->Void> = event.data;

				try
				{
					Lib.global.onmessage = __current.dispatchMessage;
					job.dispatch();
				}
				catch (e:Dynamic)
				{
					__current.destroy();
				}
			};
		}
		#end
	}

	public static inline function current():HTML5Thread
	{
		return __current;
	}

	public static function create(job:WorkFunction<Void->Void>):HTML5Thread
	{
		#if !macro
		// Find the URL of the primary JS file.
		var url:URL = new URL(__current.__href);
		url.pathname = url.pathname.substr(0, url.pathname.lastIndexOf("/") + 1)
			+ Application.current.meta["file"] + ".js";

		// Use the hash to distinguish workers.
		if (url.hash.length > 0) url.hash += "_";
		url.hash += __workerCount;
		__workerCount++;


		// Prepare to send the job.
		job.makePortable();


		// Create the worker. Because the worker's scope will not include a
		// `window`, `HTML5Thread.__init__()` will add a listener.
		var thread:HTML5Thread = new HTML5Thread(url.href, new Worker(url.href));

		// Send a message to the listener.
		thread.sendMessage(job);

		return thread;
		#else
		return null;
		#end
	}

	#if !macro
	private static inline function zeroDelay():Promise<Dynamic>
	{
		return new Promise<Dynamic>(function(resolve, _):Void
			{
				js.Lib.global.setTimeout(resolve);
			});
	}
	#end

	/**
		Reads a message from the thread queue. Returns `null` if no message is
		available. This may only be called inside an `async` function.
		@param block If true, waits for the next message before returning.
		@see `lime.system.WorkOutput.JSAsync.async()`
	**/
	public static macro function readMessage(block:ExprOf<Bool>):Dynamic
	{
		var jsCode:Expr = macro #if haxe4 js.Syntax.code #else untyped __js__ #end;

		// `onmessage` events are only received when the main function is
		// suspended, so we must insert `await` even if `block` is false.
		// TODO: find a more efficient way to read messages.
		var zeroDelayExpr:Expr = macro @:privateAccess
			$jsCode("await {0}", lime._internal.backend.html5.HTML5Thread.zeroDelay())
			.then(function(_) return lime._internal.backend.html5.HTML5Thread.__messages.pop());

		switch (block.expr)
		{
			case EConst(CIdent("false")):
				return zeroDelayExpr;
			default:
				return macro if ($block && @:privateAccess lime._internal.backend.html5.HTML5Thread.__messages.isEmpty())
				{
					$jsCode("await {0}", new #if haxe4 js.lib.Promise #else js.Promise #end
						(function(resolve, _):Void
						{
							@:privateAccess lime._internal.backend.html5.HTML5Thread.__resolveMethods.add(resolve);
						}
					));
				}
				else
					$zeroDelayExpr;
		}
	}

	/**
		Sends a message back to the thread that spawned this worker. Has no
		effect if called from the main thread.

		@param preserveClasses Whether to call `preserveClasses()` first.
	**/
	public static function returnMessage(message:Message, transferList:Array<Transferable> = null, preserveClasses:Bool = true):Void
	{
		if (__isWorker)
		{
			if (preserveClasses)
			{
				message.preserveClasses();
			}

			Lib.global.postMessage(message, transferList);
		}
	}

	@:op(A == B) private static inline function equals(a:HTML5Thread, b:HTML5Thread):Bool
	{
		return a.__href == b.__href;
	}

	/**
		Dispatches only messages coming from this `HTML5Thread`. Only available
		in the case of `HTML5Thread.create()`; never available via `current()`.
	**/
	public var onMessage(default, null):Null<Event<Dynamic->Void>>;

	private var __href:String;
	private var __worker:Null<Worker>;

	private function new(href:String, worker:Worker = null)
	{
		#if !macro
		__href = href;

		if (worker != null)
		{
			__worker = worker;
			__worker.onmessage = dispatchMessage;
			onMessage = new Event<Dynamic->Void>();
		}

		// If an `HTML5Thread` instance is passed to a different thread than
		// where it was created, all of its instance methods will behave
		// incorrectly. You can still check equality, but that's it. Therefore,
		// it's best to make `preserveClasses()` skip this class.
		Message.disablePreserveClasses(this);
		#end
	}

	/**
		Send a message to the thread queue. This message can be read using
		`readMessage()` or by listening for the `onMessage` event.

		@param preserveClasses Whether to call `preserveClasses()` first.
	**/
	public function sendMessage(message:Message, transferList:Array<Transferable> = null, preserveClasses:Bool = true):Void
	{
		#if !macro
		if (__worker != null)
		{
			if (preserveClasses)
			{
				message.preserveClasses();
			}

			__worker.postMessage(message, transferList);
		}
		else
		{
			// No need for `restoreClasses()` because it came from this thread.
			__messages.add(message);
		}
		#end
	}

	#if !macro
	private function dispatchMessage(event:MessageEvent):Void
	{
		var message:Message = event.data;
		message.restoreClasses();

		if (onMessage != null)
		{
			onMessage.dispatch(message);
		}

		if (__resolveMethods.isEmpty())
		{
			__messages.add(message);
		}
		else
		{
			__resolveMethods.pop()(message);
		}
	}
	#end

	/**
		Closes this thread unless it's the main thread.
	**/
	public function destroy():Void
	{
		#if !macro
		if (__worker != null)
		{
			__worker.terminate();
		}
		else if (__isWorker)
		{
			try
			{
				Lib.global.close();
			}
			catch (e:Dynamic) {}
		}
		#end
	}

	public inline function isWorker():Bool
	{
		return __worker != null || __isWorker;
	}
}

abstract WorkFunction<T:haxe.Constraints.Function>(WorkFunctionData<T>) from WorkFunctionData<T>
{
	/**
		Whether this function is ready to copy across threads. If not, call
		`makePortable()` before sending it.
	**/
	public var portable(get, never):Bool;

	#if macro
	/**
		Parses a chain of nested `EField` expressions.
		@return An array of all identifiers in the chain, as strings. If the
		chain began with something other than an identifier, it will be returned
		as the `initialExpr`. For instance, `array[i].foo.bar` will result in
		`chain == ["foo", "bar"]` and `initialExpr == array[i]`.
	**/
	private static function parseFieldChain(chain:Expr):{ chain:Array<String>, ?initialExpr:Expr }
	{
		switch(chain.expr)
		{
			case EConst(CIdent(ident)):
				return { chain: [ident] };
			case EField(e, field):
				var out = parseFieldChain(e);
				out.chain.push(field);
				return out;
			default:
				return { chain: [], initialExpr: chain };
		}
	}
	#end

	// `@:from` would cause errors during the macro phase.
	@:noCompletion @:dox(hide) #if !macro @:from #end
	public static #if !macro macro #end function fromFunction(func:ExprOf<haxe.Constraints.Function>)
	{
		var defaultOutput:Expr = macro {
			func: $func
		};

		if (!Context.defined("lime-threads"))
		{
			return defaultOutput;
		}
		else
		{
			// Haxe likes to pass `@:this this` instead of the actual
			// expression, so use a roundabout method to convert back. As a
			// happy side-effect, it fully qualifies the expression.
			var qualifiedFunc:String = func.typeExpr().toString(true);

			// Match the package, class name, and field name.
			var matcher:EReg = ~/^((?:_?\w+\.)*[A-Z]\w*)\.(_*[a-z]\w*)$/;
			if (!matcher.match(qualifiedFunc))
			{
				if (Context.defined("lime-warn-portability"))
				{
					Context.warning("Value doesn't appear to be a static function.", func.pos);
				}
				return defaultOutput;
			}

			var classPath:String = matcher.matched(1);
			var functionName:String = matcher.matched(2);

			return macro {
				func: $func,
				classPath: $v{classPath},
				functionName: $v{functionName}
			};
		}
	}

	/**
		Executes this function on the current thread.
	**/
	public macro function dispatch(self:ExprOf<WorkFunction<Dynamic>>, args:Array<Expr>):Expr
	{
		return macro $self.toFunction()($a{args});
	}

	#if haxe4 @:to #end
	public function toFunction():T
	{
		if (this.func != null)
		{
			return this.func;
		}
		else if (this.classPath != null && this.functionName != null)
		{
			#if !macro
			this.func = #if !haxe4 untyped __js__ #else Syntax.code #end
				("$hxClasses[{0}][{1}]", this.classPath, this.functionName);
			#end
			return this.func;
		}

		throw 'Object is not a valid WorkFunction: $this';
	}

	/**
		Attempts to make this function safe for passing across threads.
		@return Whether this function is now portable. If false, try a static
		function instead, and make sure you aren't using `bind()`.
	**/
	public function makePortable(throwError:Bool = true):Bool
	{
		if (this.func != null)
		{
			// Make sure `classPath.functionName` points to the actual function.
			if (this.classPath != null || this.functionName != null)
			{
				#if !macro
				var func = #if !haxe4 untyped __js__ #else Syntax.code #end
					("$hxClasses[{0}] && $hxClasses[{0}][{1}]", this.classPath, this.functionName);
				if (func != this.func)
				{
					throw 'Could not make ${this.functionName} portable. Either ${this.functionName} isn\'t static, or ${this.classPath} is something other than a class.';
				}
				else
				{
					// All set.
					this.func = null;
				}
				#end
			}
			else
			{
				// If you aren't sure why you got this message, make sure your
				// variables are of type `WorkFunction`.
				// This won't work:
				//     var f = MyClass.staticFunction;
				//     bgWorker.run(f);
				// ...but this will:
				//     var f:WorkFunction<Dynamic->Void> = MyClass.staticFunction;
				//     bgWorker.run(f);
				throw "Only static class functions can be made portable. Set -Dlime-warn-portability to see which line caused this.";
			}
		}

		return portable;
	}

	// Getters & Setters

	private inline function get_portable():Bool
	{
		return this.func == null;
	}
}

/**
	Stores the class path and function name of a function, so that it can be
	found again in the background thread.
**/
typedef WorkFunctionData<T:haxe.Constraints.Function> = {
	@:optional var classPath:String;
	@:optional var functionName:String;
	@:optional var func:T;
};

@:forward
@:allow(lime._internal.backend.html5.HTML5Thread)
abstract Message(Dynamic) from Dynamic to Dynamic
{
	private static inline var PROTOTYPE_FIELD:String = "__prototype__";
	private static inline var SKIP_FIELD:String = "__skipPrototype__";
	private static inline var RESTORE_FIELD:String = "__restoreFlag__";

	#if !macro
	private static inline function skip(object:Dynamic):Bool
	{
		// Skip `null` for obvious reasons.
		return object == null
			// No need to preserve a primitive type.
			|| !#if (haxe_ver >= 4.2) Std.isOfType #else untyped __js__ #end (object, Object)
			// Objects with this field have been deliberately excluded.
			|| Reflect.field(object, SKIP_FIELD) == true
			// A `Uint8Array` (the type used by `haxe.io.Bytes`) can have
			// thousands or millions of fields, which can take entire seconds to
			// enumerate. This also applies to `Int8Array`, `Float64Array`, etc.
			|| object.byteLength != null && object.byteOffset != null
				&& object.buffer != null
				&& #if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end (object.buffer, #if haxe4 js.lib.ArrayBuffer #else js.html.ArrayBuffer #end);
	}
	#end

	/**
		Prevents `preserveClasses()` from working on the given object.

		Note: if its class isn't preserved, `cast(object, Foo)` will fail with
		the unhelpful message "uncaught exception: Object" and no line number.
	**/
	public static function disablePreserveClasses(object:Dynamic):Void
	{
		#if !macro
		if (skip(object))
		{
			return;
		}

		Reflect.setField(object, Message.SKIP_FIELD, true);
		#end
	}

	/**
		Adds class information to this message and all children, so that it will
		survive being passed across threads. "Children" are the values returned
		by `Object.values()`.
	**/
	public function preserveClasses():Void
	{
		#if !macro
		if (skip(this) || Reflect.hasField(this, PROTOTYPE_FIELD))
		{
			return;
		}

		// Preserve this object's class.
		if (!#if (haxe_ver >= 4.2) Std.isOfType #else Std.is #end (this, Array))
		{
			try
			{
				if (this.__class__ != null)
				{
					#if haxe4
					Reflect.setField(this, PROTOTYPE_FIELD, this.__class__.__name__);
					#else
					Reflect.setField(this, PROTOTYPE_FIELD, this.__class__.__name__.join("."));
					#end
				}
				else
				{
					Reflect.setField(this, PROTOTYPE_FIELD, null);
				}
			}
			catch (e:Dynamic)
			{
				// Probably a frozen object; no need to recurse.
				return;
			}

			// While usually it's the user's job not to include any functions,
			// enums come with a built-in `toString` function that needs to be
			// removed, and it isn't fair to ask the user to know that.
			if (#if haxe4 Syntax.code #else untyped __js__ #end ('typeof {0}.toString == "function"', this))
			{
				Reflect.deleteField(this, "toString");
			}
		}

		// Recurse.
		for (child in Object.values(this))
		{
			(child:Message).preserveClasses();
		}
		#end
	}

	/**
		Restores the class information preserved by `preserveClasses()`.

		@param flag Leave this `null`.
	**/
	private function restoreClasses(flag:Int = null):Void
	{
		#if !macro
		// Attempt to choose a unique flag.
		if (flag == null)
		{
			// JavaScript's limit is 2^53; Haxe 3's limit is much lower.
			flag = Std.int(Math.random() * 0x7FFFFFFF);
			if (Reflect.field(this, RESTORE_FIELD) == flag)
			{
				flag++;
			}
		}

		if (skip(this) || Reflect.field(this, RESTORE_FIELD) == flag)
		{
			return;
		}

		try
		{
			Reflect.setField(this, RESTORE_FIELD, flag);
		}
		catch (e:Dynamic)
		{
			// Probably a frozen object; no need to continue.
			return;
		}

		// Restore this object's class.
		if (Reflect.field(this, PROTOTYPE_FIELD) != null)
		{
			try
			{
				Object.setPrototypeOf(this,
					#if haxe4 Syntax.code #else untyped __js__ #end
						("$hxClasses[{0}].prototype", Reflect.field(this, PROTOTYPE_FIELD)));
			}
			catch (e:Dynamic) {}
		}

		// Recurse.
		for (child in Object.values(this))
		{
			(child:Message).restoreClasses(flag);
		}
		#end
	}
}

#if macro
typedef Worker = Dynamic;
typedef URL = Dynamic;
class Object {}
class Browser
{
	public static var window:Dynamic;
}
class Lib
{
	public static var global:Dynamic = { location: {} };
}
#end

/**
	An object to transfer, rather than copy.

	Abstract types like `lime.utils.Int32Array` and `openfl.utils.ByteArray`
	can be automatically converted. However, extern classes like
	`js.lib.Int32Array` typically can't.

	@see https://developer.mozilla.org/en-US/docs/Glossary/Transferable_objects
**/
// Mozilla uses "transferable" and "transferrable" interchangeably, but the HTML
// specification only uses the former.
@:forward
abstract Transferable(Dynamic) #if macro from Dynamic
	#else from lime.utils.ArrayBuffer from js.html.MessagePort from js.html.ImageBitmap #end
{
}

#if (!haxe4 && !macro)
@:native("Object")
extern class Object {
	static function setPrototypeOf<T:{}>(obj:T, prototype:Null<{}>):T;
	@:pure static function values(obj:{}):Array<Dynamic>;
	static var prototype(default, never):Dynamic;
}
#end
