package lime.system;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import sys.io.File;

using haxe.macro.Context;
using haxe.macro.TypeTools;
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

	#if macro
	private static var SYNTAX:Expr = #if haxe4 macro js.Syntax.code #else macro untyped __js__ #end;
	#end

	// Other macros can call this statically, if needed.
	@:noCompletion @:dox(hide) #if !macro @:from #end
	public static #if !macro macro #end function fromFunction(func:ExprOf<haxe.Constraints.Function>)
	{
		cleanAfterGenerate();
		return macro $SYNTAX($v{TAG + "{0}.toString()" + TAG}, $func);
	}
	#end

	/**
		Adds the given callback function, to be run on the
		other thread. Unlike with `lime.app.Event`, only one
		callback can exist; `add()` overwrites the old one.
	**/
	@:noCompletion @:dox(hide) public inline function add(callback:ThreadFunction<T>):Void
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
			var type = self.typeof().follow().toComplexType();
			switch (type)
			{
				case TPath({ name: "ThreadFunction", params: [TPType(t)] }):
					return macro $self != null ? ($self:$t)($a{args}) : null;
				default:
					throw "Underlying function type not found.";
			}
		}
		else
		{
			// The `Function()` constructor is the preferred
			// method of executing strings. It requires
			// parameters and a body, which can be extracted
			// using a regex.
			var regex:String = [for (i in 0...args.length) "(\\w*)"].join(",\\s*");
			regex = 'function\\($regex\\)\\s*\\{\\s*(.+)\\s*\\}';

			return macro if ($self != null)
			{
				var paramsAndBody:Array<String> = $SYNTAX($v{'/$regex/s.exec({0})'}, $self);
				if (paramsAndBody == null)
					$SYNTAX('throw "Wrong number of arguments. Attempting to pass " + {0} + " arguments to this function:\\n" + {1}', $v{args.length}, $self);
				paramsAndBody.shift();

				// Construct the function and then call it.
				// Use `apply()` because both sets of
				// arguments are in array form.
				$SYNTAX("Function.apply(this, {0}).apply(this, {1})", paramsAndBody, $a{args});
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
		// Break the string up so it won't match its own
		// source code.
		if (this.indexOf("[" + "native code" + "]") >= 0)
		{
			#if haxe4 js.Syntax.code #else untyped __js__ #end
			("throw {0}",
				"Haxe automatically binds some functions, "
				+ "making them incompatible with workers. "
				+ "ThreadFunction tries to undo this, but "
				+ "successfully undoing it requires "
				+ "converting to ThreadFunction as soon as "
				+ "possible. If that isn't an option, try "
				+ "a static function.");

			// Addendum: explicit casts will NOT work. You
			// have to use implicit casts or type hints.
		}

		// Without analyzer-optimize, there's likely to be
		// an unused reference to outside code.
		this = #if haxe4 js.Syntax.code #else untyped __js__ #end
			('{0}.replace(/var _g?this = .+?;\\s*(.+?postMessage)/gs, "$1")', this);
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
			var escapedTag:String = EReg.escape(TAG);

			outputContent = new EReg(escapedTag + "\\$bind\\(\\w*this,(.+?)\\)\\.toString\\(\\)" + escapedTag, "gs")
				.replace(outputContent, "$1.toString()");
			outputContent = new EReg(escapedTag, "g").replace(outputContent, "");

			File.saveContent(outputFile, outputContent);
		});
		#end
	}
	#end
}
