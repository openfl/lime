package lime.system;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.io.File;
#end

/**
	A function to be called on another thread. This behaves
	as a perfectly normal function on most targets, but in
	JavaScript it will convert to string and back.

	`ThreadFunction` also provides an `Event`-like API for
	backwards compatibility. Unlike `Event`, it can only
	represent a single function at a time; `add()`
	overwrites the old function.
**/
#if !js
abstract ThreadFunction<T:haxe.Constraints.Function>(T) from T to T
#else
// Excluding "from String" to help `run()` disambiguate.
abstract ThreadFunction<T>(String) to String
#end
{
	#if (js || macro)
	private static inline var TAG:String = "/* lime.system.ThreadFunction */";
	private static var TAG_ESCAPED:String = EReg.escape(TAG);

	// Other macros can call this statically, if needed.
	@:noCompletion @:dox(hide) #if !macro @:from #end
	public static #if !macro macro #end function fromFunction(func:ExprOf<haxe.Constraints.Function>)
	{
		cleanAfterGenerate();
		return macro js.Syntax.code($v{TAG + "{0}.toString()" + TAG}, $func);
	}
	#end

	/**
		Adds the given callback function, to be run on the
		other thread. Unlike with `lime.app.Event`, only one
		callback can exist; `add()` overwrites the old one.
	**/
	public inline function add(callback:ThreadFunction<T>):Void
	{
		this = callback;
	}

	/**
		Executes this function on the current thread.
	**/
	public macro function dispatch(self:Expr, args:Array<Expr>):Expr
	{
		if (!Context.defined("js"))
		{
			return macro $self != null ? (cast $self:haxe.Constraints.Function)($a{args}) : null;
		}
		else
		{
			var argSyntax:Array<String> = [for (i in 1...(args.length + 1)) '{$i}'];
			var syntax:String = 'Function.apply(this, {0})(${argSyntax.join(", ")})';
			args = [macro $v{syntax}, macro paramsAndBody].concat(args);

			return macro if ($self != null)
			{
				var paramsAndBody:Array<String> = js.Syntax.code("/function\\((.+?)\\)\\s*\\{\\s*(.+)\\s*\\}/.exec({0})", $self);
				if (paramsAndBody == null)
					js.Syntax.code('throw "Malformatted ThreadFunction: " + {0}', $self);

				var body = paramsAndBody.pop();
				paramsAndBody = paramsAndBody[1].split(js.Syntax.code("/, */"));
				paramsAndBody.push(body);

				js.Syntax.code($a{args});
			}
			else null;
		}
	}

	@:noCompletion @:dox(hide) public inline function has(callback:ThreadFunction<T>):Bool
	{
		#if !js
		return Reflect.compareMethods(this, callback);
		#else
		return this == callback;
		#end
	}

	@:noCompletion @:dox(hide) public inline function remove(callback:ThreadFunction<T>):Void
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

	#if js
	/**
		Makes sure the JS string is suitable for making a
		`Worker`. Fixes issues when possible and throws
		errors if not.
	**/
	@:noCompletion @:dox(hide) public inline function checkJS():Void
	{
		if (this.indexOf("[native code]") >= 0)
		{
			throw "Haxe automatically binds instance functions in JS, making them incompatible with js.html.Worker. ThreadFunction tries to remove this binding; the sooner you convert to ThreadFunction, the more likely it will work. Failing that, try a static function.";
			// Addendum: explicit casts will NOT work. You
			// have to use implicit casts or type hints.
		}

		// Without analyzer-optimize, there's likely to be
		// an unused reference to outside code.
		this = cast ~/var _g?this = .+?;\s*(.+?postMessage)/gs
			.replace(this, "$1");
	}
	#end

	#if macro
	private static var callbacksRegistered:Bool = false;

	#if !haxe4
	private static function resetCallbacksRegistered():Bool
	{
		callbacksRegistered = false;
		return true;
	}
	#end

	/**
		Adds an `onAfterGenerate()` listener to read the JS
		file and clean up any bound functions.
	**/
	private static function cleanAfterGenerate():Void
	{
		if (callbacksRegistered || !Context.defined("js") || Context.defined("display"))
		{
			return;
		}
		callbacksRegistered = true;

		#if !haxe4
		Context.onMacroContextReused(resetCallbacksRegistered);
		#end

		#if !lime_suppress_onAfterGenerate
		Context.onAfterGenerate(function():Void
		{
			var outputFile:String = Compiler.getOutput();
			var outputContent:String = File.getContent(outputFile);

			outputContent = new EReg(TAG_ESCAPED + "\\$bind\\(this,(.+?)\\)\\.toString\\(\\)" + TAG_ESCAPED, "gm")
				.replace(outputContent, "$1.toString()");
			outputContent = new EReg(TAG_ESCAPED, "g").replace(outputContent, "");

			File.saveContent(outputFile, outputContent);
		});
		#end
	}
	#end
}
