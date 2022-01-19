package lime.system;

#if macro
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Printer;
import haxe.macro.Type;
import sys.FileSystem;
import sys.io.File;

using haxe.macro.Context;
using haxe.macro.TypeTools;
#end

/**
	A function to be called on another thread. This behaves
	as a perfectly normal function on most targets, but it
	also provides an `Event`-like API for compatibility,
	offering functions like `add()` and `dispatch()`.
	Unlike `Event`, it can only represent a single function
	at a time; `add()` overwrites the old function.

	In JavaScript, web workers can be enabled in two ways:

	```xml
	<!-- Option 1: before including Lime -->
	<haxedef name="lime-web-workers" />

	<haxelib name="lime" />

	<!-- Option 2: after including Lime -->
	<unset name="force_synchronous" if="html5" />
	```

	If web workers are enabled, `ThreadFunction`s will be
	stored as strings, making it easier to pass them to
	worker threads. You can also print their value at
	runtime to see the JavaScript source code.

	If using web workers, you will also have to call
	`restoreInstanceMethods()` on any class instance that
	gets copied across threads. (At least, if you want to
	use that object's instance methods.)
**/
#if (!js || force_synchronous)
abstract ThreadFunction<T:haxe.Constraints.Function>(T) from T to T
#else
// Excluding "from String" to help `run()` disambiguate.
abstract ThreadFunction<T>(String) to String
#end
{
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
		var syntax:String = TAG + "{0}.toString()" + TAG;
		#if haxe4
		return macro js.Syntax.code($v{syntax}, $func);
		#else
		return macro untyped __js__($v{syntax}, $func);
		#end
	}
	#end

	/**
		(Web workers only; returns harmlessly otherwise)

		If you pass a class instance to a web worker, its
		instance methods will be lost. This function tries
		to restore these methods, relying on the class
		definition in the worker's `headerCode`.

		Sample usage:

		```haxe
		private function myThreadFunction(message:{ sourceImage:Image, destImage:Image, rectangle:Rectangle }):Void
		{
			// Restore needed methods, skipping
			// `message.sourceImage` for performance.
			ThreadFunction.restoreInstanceMethods(message.destImage, message.rectangle);

			if (message.rectangle.isEmpty())
				message.rectangle.setTo(0, 0, message.sourceImage.width, message.sourceImage.height);

			message.destImage.copyPixels(message.sourceImage, rectangle, new Vector2());

			bgWorker.sendComplete(destImage);
		}
		```
	**/
	public static macro function restoreInstanceMethods(objects:Array<Expr>):Expr
	{
		if (!Context.defined("js") || Context.defined("force_synchronous")) return macro null;

		var exprs:Array<Expr> = [];

		for (object in objects)
		{
			var type:Type = Context.typeof(object).followWithAbstracts();
			switch (type)
			{
				case TInst(_, _):
					// All set
				default:
					Context.warning(new Printer().printExpr(object) + " is not a class instance.", Context.currentPos());
					continue;
			}

			switch (type.toComplexType())
			{
				case TPath(p):
					var path:Array<String> = p.pack.copy();
					path.push(p.name);
					if (p.sub != null)
					{
						path.push(p.sub);
					}

					exprs.push(macro cast js.lib.Object.setPrototypeOf(cast $object,  (cast $p{path}).prototype));
				default:
			}
		}

		return macro $b{exprs};
	}

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

		Note: if using web workers, this will first
		recompile the function, which is a slow operation.
		If you plan to run the function many times, call
		`compile()` instead and store the result.
	**/
	public macro function dispatch(self:Expr, args:Array<Expr>):Expr
	{
		var compiled:Expr = compile(self);

		if (!Context.defined("js") || Context.defined("force_synchronous"))
		{
			return macro $self != null ? $compiled($a{args}) : null;
		}
		else
		{
			var jsCode:Expr = #if haxe4 macro js.Syntax.code #else macro untyped __js__ #end;

			// Dispatch using `apply()` because we have the
			// args in array form.
			return macro $self != null
				? $jsCode("{0}.apply(this, {1})", $compiled, $a{args})
				: null;
		}
	}

	/**
		Converts back to type `T`.
	**/
	#if macro static #else macro #end
	public function compile(self:Expr):Expr
	{
		var underlyingType:ComplexType;
		var args:Array<ComplexType>;

		switch (self.typeof().follow().toComplexType())
		{
			case TPath({ name: "ThreadFunction", params: [TPType(t = TFunction(a, _))] }):
				underlyingType = t;
				args = a;
			default:
				throw "Underlying function type not found.";
		}

		if (!Context.defined("js") || Context.defined("force_synchronous"))
		{
			return macro ($self:$underlyingType);
		}
		else
		{
			// The `Function()` constructor is the preferred
			// method of executing strings. It requires
			// parameters and a body, which can be extracted
			// using a regex.
			var regex:String = [for (i in 0...args.length) "(\\w*)"].join(",\\s*");
			regex = 'function\\($regex\\)\\s*\\{\\s*(.+)\\s*\\}';
			regex = '/$regex/s.exec({0})';

			var jsCode:Expr = #if haxe4 macro js.Syntax.code #else macro untyped __js__ #end;

			return macro if ($self != null)
			{
				$self.checkJS();

				var paramsAndBody:Array<String> = $jsCode($v{regex}, $self);
				if (paramsAndBody == null)
					$jsCode('throw "Wrong number of arguments. Attempting to pass " + {0} + " arguments to this function:\\n" + {1}', $v{args.length}, $self);
				paramsAndBody.shift();

				// Construct the function, using `apply()`
				// because we have the params in array form.
				$jsCode("Function.apply(this, {0})", paramsAndBody);
			}
			else null;
		}
	}

	/**
		Acts as `compile()`, but sets the function up so
		that it will access the correct instance variables.
		@param instance The class instance to which this
		instance function belongs.
		@return A function of type `T`.
	**/
	#if macro static #else macro #end
	public function compileInstanceFunction(self:Expr, instance:Expr):Expr
	{
		var compiledFunction:Expr = compile(self);
		if (!Context.defined("js") || Context.defined("force_synchronous"))
		{
			return compiledFunction;
		}
		else
		{
			var jsCode:Expr = #if haxe4 macro js.Syntax.code #else macro untyped __js__ #end;

			return macro $jsCode("{0}.bind({1})", $compiledFunction, $instance);
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
		Makes sure the JS string can be turned back into a
		function, and throws an informative error if not.
	**/
	@:noCompletion @:dox(hide) public inline function checkJS():Void
	{
		// Break the string up so it won't match its own
		// source code.
		if (this.indexOf("[" + "native code" + "]") >= 0)
		{
			#if haxe4 js.Syntax.code #else untyped __js__ #end
			("throw {0}",
				"error: Could not extract function source "
				+ "code. This can have multiple causes:\n"
				+ "1. If you call .bind() on a function, "
				+ "it becomes impossible to extract source "
				+ "code. Try declaring a new function "
				+ "instead.\n"
				+ "2. If you assign an instance function "
				+ "to a variable, it may become impossible "
				+ "to extract source code. To avoid this, "
				+ "the variable must be of type "
				+ "ThreadFunction.\n"
				+ "3. As a last resort, use static "
				+ "functions instead of instance functions."
			);

			// Addendum: explicit casts will NOT work. You
			// have to use implicit casts or type hints.
		}
	}
	#end

	#if (macro && !force_synchronous)
	/**
		[Call this only from `ThreadBase.processOutput()`]

		`fromFunction()` needs to get "`func.toString()`",
		but Haxe may convert this into
		"`$bind(this, func).toString()`", making it
		impossible to extract the source code.

		For multiple reasons, it isn't possible to solve
		this during the code generation step.
	**/
	@:allow(lime.system.ThreadBase)
	private static function cleanAfterGenerate():Void
	{
		// Load the big JavaScript file Haxe generated.
		// Compilation has finished, so Haxe won't make
		// any more changes, and we're free to edit it.
		var outputFile:String = Compiler.getOutput();
		if (!FileSystem.exists(outputFile))
			return;
		var outputContent:String = File.getContent(outputFile);

		// Find and remove tagged `$bind()` calls.
		var escapedTag:String = EReg.escape(ThreadFunction.TAG);
		outputContent = new EReg(escapedTag + "(.+?)" + escapedTag, "gs")
			.map(outputContent, function(match) {
				return ~/\$bind\(.+?,(.+?)\)/s.replace(match.matched(1), "$1");
			});

		File.saveContent(outputFile, outputContent);
	}
	#end
}

/**
	As with functions, if you try to pass an enum to or from
	a web worker, you'll get a "could not be cloned" error.
	Converting to `ThreadEnum` fixes this.

	This only applies to standard enums; abstracts are fine.
**/
abstract ThreadEnum<T:EnumValue>(T) to T
{
	/**
		Permanently deletes this enum value's `toString()`
		function, making it safe to pass to a web worker. If
		you still need to get the name, call `Std.string()`
		instead of `toString()`.
	**/
	@:from public static inline function convert<T:EnumValue>(enumValue:T):ThreadEnum<T>
	{
		#if (js && !force_synchronous)
		js.Syntax.code("delete {0}.toString", enumValue);
		#end
		return cast enumValue;
	}
}
