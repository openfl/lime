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

	Since it is stored as a string in JavaScript, you can
	print the value at runtime to see the JavaScript code.

	`ThreadFunction` also provides an `Event`-like API for
	backwards compatibility. Unlike `Event`, it can only
	represent a single function at a time; `add()`
	overwrites the old function.
**/
#if (!js || force_synchronous)
abstract ThreadFunction<T:haxe.Constraints.Function>(T) from T to T
#else
// Excluding "from String" to help `run()` disambiguate.
abstract ThreadFunction<T>(String) to String
#end
{
	#if macro
	/**
		An `Expr` of `js.Syntax.code` (not including
		parentheses) or its Haxe 3 equivalent.
	**/
	private static var SYNTAX:Expr = #if haxe4 macro js.Syntax.code #else macro untyped __js__ #end;
	#end

	#if ((js || macro) && !force_synchronous)
	/**
		A distinctive comment used to mark sections of the
		output code for `cleanAfterGenerate()`. Because it's
		a comment, it won't break anything if not cleaned.
	**/
	private static inline var TAG:String = "/* lime.system.ThreadFunction */";

	/**
		Calls `func.toString()`, converting the JavaScript
		function back into JavaScript source code.

		However, Haxe may turn "`func.toString()`" into
		"`$bind(this, func).toString()`", and `$bind()`
		makes it impossible to extract the source code.

		For multiple reasons, it isn't possible to solve
		this during the code generation step. However, it
		is possible to modify the generated JavaScript file,
		which is what `cleanAfterGenerate()` does.

		`cleanAfterGenerate()` needs to know which calls to
		`$bind()` to remove, so `fromFunction()` also adds a
		comment that `cleanAfterGenerate()` will recognize.
	**/
	// `@:from` would cause errors during the macro phase.
	// Disabling `macro` during the macro phase allows other
	// macros to call this statically.
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

		Note: the JavaScript implementation has multiple
		limitations.

		- The function can only access the global scope,
		even if run on the main thread.
		- On background threads, it's further limited to
		inline variables and whatever arguments it receives.
		- You must supply all arguments, even optional ones.
	**/
	public macro function dispatch(self:Expr, args:Array<Expr>):Expr
	{
		if (!Context.defined("js") || Context.defined("force_synchronous"))
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
				$self.checkJS();

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

	/**
		Backwards compatibility function
	**/
	@:noCompletion @:dox(hide) public inline function has(callback:ThreadFunction<T>):Bool
	{
		#if (!js || force_synchronous)
		return Reflect.compareMethods(this, callback);
		#else
		return this == callback;
		#end
	}

	/**
		Backwards compatibility function
	**/
	@:noCompletion @:dox(hide) public inline function remove(callback:ThreadFunction<T>):Void
	{
		if (has(callback))
		{
			this = null;
		}
	}

	/**
		Backwards compatibility function
	**/
	@:noCompletion @:dox(hide) public inline function removeAll():Void
	{
		this = null;
	}

	#if (js && !force_synchronous)
	/**
		Makes sure the JS string is suitable for making a
		`Worker`. Fixes issues when possible and throws
		errors if not.

		This is automatically called by `dispatch()`, so
		you typically don't need to call it yourself.
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

		this = #if haxe4 js.Syntax.code #else untyped __js__ #end
			('{0}.replace(/haxe_NativeStackTrace\\.lastError = \\w+;\\s*var (\\w+) = haxe_Exception\\.caught\\((\\w+)\\)\\.unwrap\\(\\);/gs, "var $1 = \'\' + $2;")', this);
	}
	#end

	#if (macro && !force_synchronous)
	private static var callbacksRegistered:Bool = false;

	// Haxe 4 automatically resets static variables, but in
	// Haxe 3 it requires a callback.
	#if !haxe4
	private static function resetCallbacksRegistered():Bool
	{
		callbacksRegistered = false;
		return true;
	}
	#end

	/**
		Adds a listener to read the generated JS file and
		remove tagged `$bind()` operations.

		`fromFunction()` needs to get "`func.toString()`",
		but Haxe may convert this into
		"`$bind(this, func).toString()`", making it
		impossible to extract the source code.

		For multiple reasons, it isn't possible to solve
		this during the code generation step, which is why
		we add a listener for the `onAfterGenerate()` step.
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
			// Load the big JavaScript file Haxe generated.
			// Compilation has finished, so Haxe won't make
			// any more changes, and we're free to edit it.
			var outputFile:String = Compiler.getOutput();
			var outputContent:String = File.getContent(outputFile);

			// Find and remove tagged `$bind()` calls.
			var escapedTag:String = EReg.escape(TAG);
			outputContent = new EReg(escapedTag + "\\$bind\\(\\w*this,(.+?)\\)\\.toString\\(\\)" + escapedTag, "gs")
				.replace(outputContent, "$1.toString()");

			// Clean up any remaining tags.
			outputContent = new EReg(escapedTag, "g").replace(outputContent, "");

			File.saveContent(outputFile, outputContent);
		});
		#end
	}
	#end
}
