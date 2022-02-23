package lime._internal.backend.html5;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Printer;
import haxe.macro.Type;

using haxe.macro.Context;
using haxe.macro.TypeTools;
#else
import js.Browser;
import js.html.URL;
import js.html.Worker;
import js.Lib;
import js.lib.Function;
import js.lib.Object;
import js.Syntax;
import lime.app.Application;
import lime.app.Event;
#end

/**
	Emulates much of the `sys.thread.Thread` API using web workers.
**/
class HTML5Thread {
	#if !macro
	private static var __current:HTML5Thread = new HTML5Thread(Lib.global.location.href);
	private static var __isWorker:Bool = Browser.window == null;
	private static var __messages:List<Dynamic> = new List();
	private static var __resolveMethods:List<Dynamic->Void> = new List();
	private static var __workerCount:Int = 0;

	private static function __init__():Void
	{
		if (__isWorker)
		{
			Lib.global.onmessage = onJobReceived;
		}
	}

	private static function onJobReceived(job:WorkFunction<Void->Void>):Void
	{
		try
		{
			job.dispatch();
		}
		catch (e:Dynamic)
		{
			Lib.global.close();
		}

		Lib.global.onmessage = __current.dispatchMessage;
	}

	public static inline function current():HTML5Thread
	{
		return __current;
	}

	public static function create(job:WorkFunction<Void->Void>):HTML5Thread
	{
		var url:URL = new URL(__current.__href);
		url.pathname = Application.current.meta["file"];
		if (url.hash.length > 0)
		{
			url.hash += "_";
		}
		url.hash += __workerCount;
		__workerCount++;

		var thread:HTML5Thread = new HTML5Thread(url.href, new Worker(url.href, {name: url.hash}));
		thread.sendMessage(job);
		return thread;
	}

	/**
		Sends a message back to the thread that spawned this worker. Has no
		effect if called from the main thread.

		@param preserveClasses Whether to call `preserveClasses()` first.
	**/
	public static function returnMessage(message:Message, transferList:Array<Dynamic> = null, preserveClasses:Bool = true):Void
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
		__href = href;

		if (worker != null)
		{
			__worker = worker;
			__worker.onmessage = dispatchMessage;
			onMessage = new Event<Dynamic->Void>();
		}
		else
		{
			// `HTML5Thread`'s instance functions all assume they're being
			// called on the thread where this instance was created. Therefore,
			// it isn't safe for `preserveClasses()` to actually preserve this
			// class. (But if `worker` is defined it's already a lost cause.)
			Reflect.setField(this, Message.PROTOTYPE_FIELD, null);
		}
	}

	/**
		Send a message to the thread queue. This message can be read by
		listening for the `onMessage` event.

		@param preserveClasses Whether to call `preserveClasses()` first.
	**/
	public function sendMessage(message:Message, transferList:Array<Dynamic> = null, preserveClasses:Bool = true):Void
	{
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
	}

	private function dispatchMessage(message:Message):Void
	{
		message.restoreClasses();

		onMessage.dispatch(message);

		if (__resolveMethods.isEmpty())
		{
			__messages.add(message);
		}
		else
		{
			__resolveMethods.pop()(message);
		}
	}

	/**
		Closes this thread unless it's the main thread.
	**/
	public function destroy():Void
	{
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
	}
	#end

	/**
		Reads a message from the thread queue. Returns `null` if no argument is
		available.

		@param block If true, uses the `await` keyword to wait for the next
		message. Requires the calling function to be `async`.
	**/
	public static macro function readMessage(block:ExprOf<Bool>):Dynamic
	{
		var blockFalseExpr:Expr = macro @:privateAccess lime._internal.backend.html5.HTML5Thread.__messages.pop();
		switch (block.expr)
		{
			case EConst(CIdent("false")):
				return blockFalseExpr;
			default:
				return macro if ($block && @:privateAccess lime._internal.backend.html5.HTML5Thread.__messages.isEmpty())
				{
					js.Syntax.code("await {0}", new js.lib.Promise(function(resolve, _)
						{
							@:privateAccess lime._internal.backend.html5.HTML5Thread.__resolveMethods.add(resolve);
						}
					));
				}
				else
				{
					$blockFalseExpr;
				};
		}
	}
}

abstract WorkFunction<T:haxe.Constraints.Function>(WorkFunctionData<T>) from WorkFunctionData<T>
{
	/**
		Whether this function is ready to copy across threads. If not, call
		`makePortable()` before sending it.
	**/
	public var portable(get, never):Bool;

	// `@:from` would cause errors during the macro phase. Disabling `macro`
	// during the macro phase allows other macros to call this statically.
	@:noCompletion @:dox(hide) #if !macro @:from #end
	public static #if !macro macro #end function fromFunction(func:ExprOf<haxe.Constraints.Function>)
	{
		#if !force_synchronous
		return macro {
			func: $func
		};
		#else
		trace(func);
		#if haxe3
		trace("haxe3");
		#end
		#if haxe4
		trace("haxe4");
		#end
		#if haxe5
		trace("haxe5");
		#end
		//trace(Context.resolveType());
		var parts:Array<String> = new Printer().printExpr(func).split(".");
		var functionName:String = parts.pop();

		var classPath:String;
		if (parts.length > 0)
		{
			classPath = parts.join(".");
		}
		else
		{
			var classType:ClassType = Context.getLocalClass().get();
			classPath = classType.pack.join(".") + "." + classType.name;
		}

		return macro {
			classPath: $v{classPath},
			functionName: $v{functionName}
		};
		#end
	}

	/**
		Executes this function on the current thread.
	**/
	public macro function dispatch(self:ExprOf<WorkFunction<Dynamic>>, args:Array<Expr>):Expr
	{
		var underlyingType:ComplexType;
		switch (self.typeof().follow().toComplexType())
		{
			case TPath({ sub: "WorkFunction", params: [TPType(t = TFunction(_, _))] }):
				underlyingType = t;
			default:
				throw "Underlying function type not found.";
		}

		return macro ($self:$underlyingType)($a{args});
	}

	@:to private function toFunction():T
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
		else if (this.sourceCode != null)
		{
			var parser:EReg = ~/^function\(((?:\w+,\s*)*)\)\s*\{(.+)\s*\}$/s;
			if (parser.match(this.sourceCode))
			{
				var paramsAndBody:Array<String> = ~/,\s*/.split(parser.matched(1));
				paramsAndBody.push(parser.matched(2));

				#if !macro
				// Compile, binding an arbitrary `this` value. Yet another
				// reason instance methods don't work.
				this.func = #if haxe4 Syntax.code #else untyped __js__ #end
					("Function.apply({0}, {1})", Lib.global, paramsAndBody);
				#end
				return this.func;
			}
			else
			{
				throw 'Could not parse function source code: ${this.sourceCode}';
			}
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
		if ((this.classPath == null || this.functionName == null)
			&& this.sourceCode == null && this.func != null)
		{
			#if !macro
				this.sourceCode = (cast this.func:Function).toString();
			#end
		}

		if (this.classPath != null && this.functionName != null
			// The main reason instance methods don't work.
			|| this.sourceCode != null && this.sourceCode.indexOf("[native code]") < 0)
		{
			this.func = null;
		}

		return portable;
	}

	// Getters & Setters

	private inline function get_portable():Bool
	{
		return this.func == null;
	}
}

@:forward
@:allow(lime._internal.backend.html5.HTML5Thread)
abstract Message(Dynamic) from Dynamic to Dynamic
{
	#if !macro
	private static inline var PROTOTYPE_FIELD:String = "__prototype__";
	private static inline var RESTORE_FIELD:String = "__restoreFlag__";

	/**
		Adds class information to this message and all children, so that it will
		survive being passed across threads. "Children" are the values returned
		by `Object.values()`.
	**/
	public function preserveClasses():Void
	{
		// Avoid looping.
		if (Reflect.hasField(this, PROTOTYPE_FIELD)
			// Skip primitive types.
			|| !Std.isOfType(this, Object))
		{
			return;
		}

		// Preserve this object's class.
		if (!Std.isOfType(this, Array))
		{
			try
			{
				Reflect.setField(this, PROTOTYPE_FIELD, this.__class__ != null ? this.__class__.__name__ : null);
			}
			catch (e:Dynamic)
			{
				// Probably a frozen object; no need to recurse.
				return;
			}
		}

		// Recurse.
		for (sub in Object.values(this))
		{
			(sub:Message).preserveClasses();
		}
	}

	/**
		Restores the class information preserved by `preserveClasses()`.

		@param flag Leave this `null`.
	**/
	private function restoreClasses(flag:Int = null):Void
	{
		// Attempt to choose a unique flag.
		if (flag == null)
		{
			// Stay well below 2^53.
			flag = Std.int(Math.random() * 0xFFFFFFFF);
			if (Reflect.field(this, RESTORE_FIELD) == flag)
			{
				flag++;
			}
		}

		// Avoid looping.
		if (Reflect.field(this, RESTORE_FIELD) == flag
			// Skip primitive types.
			|| !Std.isOfType(this, Object))
		{
			return;
		}

		// Restore this object's class.
		if (Reflect.field(this, PROTOTYPE_FIELD) != null)
		{
			Reflect.setField(this, RESTORE_FIELD, flag);

			try
			{
				Object.setPrototypeOf(this,
					#if haxe4 Syntax.code #else untyped __js__ #end
						("$hxClasses[{0}].prototype", Reflect.field(this, PROTOTYPE_FIELD)));
			}
			catch (e:Dynamic) {}
		}

		// Recurse.
		for (sub in Object.values(this))
		{
			(sub:Message).restoreClasses(flag);
		}
	}
	#end
}

private typedef WorkFunctionData<T:haxe.Constraints.Function> = {
	@:optional var classPath:String;
	@:optional var functionName:String;
	@:optional var sourceCode:String;
	@:optional var func:T;
};
