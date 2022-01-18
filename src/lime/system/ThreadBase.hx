package lime.system;

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
import haxe.Json;
import js.Lib;
import js.lib.Function;
import js.lib.Object;
import js.Syntax;
#end
#end

#if macro
import haxe.Json;
import haxe.macro.Compiler;
import haxe.macro.Context;
import sys.FileSystem;
import sys.io.File;
#end

/**
	Common functionality between `BackgroundWorker` and
	`ThreadPool`.

	@see `lime.system.ThreadBase.HeaderCode`
**/
class ThreadBase {
	/**
		(No effect if web workers inactive)

		The default value for `headerCode`, applied when
		creating a new `BackgroundWorker` or `ThreadPool`.
		Modifying this won't affect already-existing
		`BackgroundWorker`s and `ThreadPool`s.
	**/
	public static var defaultHeaderCode(get, default):HeaderCode;
	private static function get_defaultHeaderCode():HeaderCode {
		#if (js && !force_synchronous)
		if(defaultHeaderCode == null) {
			defaultHeaderCode = [
				'"use strict";',
				Syntax.code("$extend.toString()"),
				"var haxe_NativeStackTrace = haxe_NativeStackTrace || {};",
				'var haxe_Log = haxe_Log || { trace: (v, infos) => console.log(infos.fileName + ":" + infos.lineNumber + ": " + v) };',
				"var haxe_Exception = haxe_Exception || { caught: (value) => value, thrown: (value) => (value.get_native) ? value.get_native() : value };"
			];
			defaultHeaderCode.addClass(StringTools);
			defaultHeaderCode.addClass(HxOverrides);
		}
		#end

		return defaultHeaderCode;
	}

	/**
		(No effect if web workers inactive)

		Whenever this `BackgroundWorker` or `ThreadPool`
		creates a new web worker, it will insert this code
		at the beginning of the JavaScript file, making the
		functions available to the worker.

		Starts with the code from `defaultHeaderCode`, and
		can be extended by calling `headerCode.addClass()`.
	**/
	public var headerCode:HeaderCode;

	/**
		Dispatched on the main thread when any background
		thread calls `sendComplete()`. Indicates that the
		thread is done.

		For best results, add all listeners before starting
		the new thread.
	**/
	public var onComplete = new Event<Dynamic->Void>();
	/**
		Dispatched on the main thread when any background
		thread calls `sendError()`. Indicates that the
		thread has failed and won't attempt to continue.

		For best results, add all listeners before starting
		the new thread.
	**/
	public var onError = new Event<Dynamic->Void>();
	/**
		Dispatched on the main thread when any background
		thread calls `sendProgress()`. May be dispatched any
		number of times per thread.

		For best results, add all listeners before starting
		the new thread.
	**/
	public var onProgress = new Event<Dynamic->Void>();

	@:noCompletion @:dox(hide) public var doWork:ThreadFunction<Dynamic->Void>;

	#if ((target.threaded || cpp || neko) && !force_synchronous)
	@:noCompletion private var __synchronous:Bool = false;
	@:noCompletion private var __workResult = new Deque<ThreadEvent>();
	#end

	/**
		@param doWork The function to be run on a background
		thread. Takes a single user-defined argument. Must
		call either `sendComplete()` or `sendError()` (but
		not both) when finished.
	**/
	public function new(doWork:ThreadFunction<Dynamic->Void>)
	{
		headerCode = defaultHeaderCode.copy();

		this.doWork = doWork;
	}

	/**
		[Call this from a background thread.]

		Dispatches `onComplete` on the main thread, with the
		given message. The background function should send
		no further messages after calling this.

		If using web workers, you can call this despite not
		having access to the `BackgroundWorker` or
		`ThreadPool` instance. However, to avoid causing an
		error, you must enable `@:analyzer(optimize)` on the
		function calling this.
		@param transferList (Web workers only) A list of
		buffers in `message` that should be moved rather
		than copied to the main thread. For details, see
		https://developer.mozilla.org/en-US/docs/Glossary/Transferable_objects
	**/
	#if (js && !force_synchronous) inline #end
	public function sendComplete(message:Dynamic = null, transferList:Array<ArrayBuffer> = null):Void
	{
		#if ((target.threaded || cpp || neko) && !force_synchronous)
		if (!__synchronous)
		{
			__workResult.add(new ThreadEvent(COMPLETE, message));
			return;
		}
		#end

		#if (js && !force_synchronous)
		Syntax.code("postMessage({0}, {1})", new ThreadEvent(COMPLETE, message), transferList);
		#else
		onComplete.dispatch(message);
		#end
	}

	/**
		[Call this from a background thread.]

		Dispatches `onError` on the main thread, with the
		given message. The background function should
		return promptly after calling this, freeing up the
		thread for more work.

		If using web workers, you can call this despite not
		having access to the `BackgroundWorker` or
		`ThreadPool` instance. However, to avoid causing an
		error, you must enable `@:analyzer(optimize)` on the
		function calling this.
		@param transferList (Web workers only) A list of
		buffers in `message` that should be moved rather
		than copied to the main thread. For details, see
		https://developer.mozilla.org/en-US/docs/Glossary/Transferable_objects
	**/
	#if (js && !force_synchronous) inline #end
	public function sendError(message:Dynamic = null, transferList:Array<ArrayBuffer> = null):Void
	{
		#if ((target.threaded || cpp || neko) && !force_synchronous)
		if (!__synchronous)
		{
			__workResult.add(new ThreadEvent(ERROR, message));
			return;
		}
		#end

		#if (js && !force_synchronous)
		Syntax.code("postMessage({0}, {1})", new ThreadEvent(ERROR, message), transferList);
		#else
		onError.dispatch(message);
		#end
	}

	/**
		[Call this from a background thread.]

		Dispatches `onProgress` on the main thread, with the
		given message.

		If using web workers, you can call this despite not
		having access to the `BackgroundWorker` or
		`ThreadPool` instance. However, to avoid causing an
		error, you must enable `@:analyzer(optimize)` on the
		function calling this.
		@param transferList (Web workers only) A list of
		buffers in `message` that should be moved rather
		than copied to the main thread. For details, see
		https://developer.mozilla.org/en-US/docs/Glossary/Transferable_objects
	**/
	#if (js && !force_synchronous) inline #end
	public function sendProgress(message:Dynamic = null, transferList:Array<ArrayBuffer> = null):Void
	{
		#if ((target.threaded || cpp || neko) && !force_synchronous)
		if (!__synchronous)
		{
			__workResult.add(new ThreadEvent(PROGRESS, message));
			return;
		}
		#end

		#if (js && !force_synchronous)
		Syntax.code("postMessage({0}, {1})", new ThreadEvent(PROGRESS, message), transferList);
		#else
		onProgress.dispatch(message);
		#end
	}

	/**
		[Call this only from Lime's include.xml file]

		Adds a listener to read the generated JS file and
		perform various operations to help facilitate web
		workers. These operations include:

		- Removing `$bind()` from `ThreadFunction`s.
		- Modifying how static variables are initialized.
	**/
	private static function processOutput():Void
	{
		#if (macro && !force_synchronous)
		if (!Context.defined("js") || Context.defined("force_synchronous")
			|| Context.defined("lime_suppress_onAfterGenerate"))
		{
			return;
		}

		// `--macro` flags like the one in include.xml have
		// to refer to classes like `ThreadBase`, not
		// abstracts like `ThreadFunction`. But `ThreadBase`
		// can pass it along.
		Context.onAfterGenerate(ThreadFunction.cleanAfterGenerate);

		Context.onAfterGenerate(function():Void
		{
			// Load the big JavaScript file Haxe generated.
			// Compilation has finished, so Haxe won't make
			// any more changes, and we're free to edit it.
			var outputFile:String = Compiler.getOutput();
			if (!FileSystem.exists(outputFile))
				return;
			var outputContent:String = File.getContent(outputFile);

			var newline:String = outputContent.indexOf("\r\n") >= 0 ? "\r\n" : "\n";

			/**
				Utility function that should have been in
				`EReg` to begin with.
			**/
			function forEach(regex:EReg, string:String, callback:EReg -> Void):Void
			{
				while (regex.match(string))
				{
					callback(regex);
					string = regex.matchedRight();
				}
			}

			// Find each class that will be added to a
			// header, including superclasses.
			var classNames:Array<String> = [];
			var classNameVerifier:EReg = ~/^(?:[a-z][a-zA-Z0-9]*_)*[A-Z][a-zA-Z0-9]*$/;
			function addClassName(classRegex:EReg):Void
			{
				var className:String = classRegex.matched(1);
				if (!classNameVerifier.match(className))
				{
					// Class name wasn't hard-coded, such as
					// in `HeaderCode`'s own recursive call.
					return;
				}
				classNames.push(className);

				// Recursively find superclasses.
				var superRegex:EReg = new EReg('^$className.__super__ = (\\w+?);$$', "m");
				if (superRegex.match(outputContent))
				{
					addClassName(superRegex);
				}
			}
			forEach(~/lime_system_HeaderCode\.addClass\([\w\.]+(?:\([\w\.]*\))*,\s*(\w+)/gs, outputContent, addClassName);

			for (className in classNames)
			{
				// Start constructing the function.
				var __initStatics__:String = '$className.__initStatics__ = function() {$newline';

				var declarations:Int = 0;

				// Search the JS file for this class's
				// static variable declarations.
				var varsToSkip:Array<String> = ["prototype", "__name__", "__super__", "__interfaces__"];
				outputContent = new EReg('^$className\\.(\\w+) = ([^{};]*(?:\\{[^{}]*\\}[^{};]*)*);$$', "gm")
					.map(outputContent, function(staticRegex:EReg):String
					{
						var varName:String = staticRegex.matched(1);
						if (varsToSkip.indexOf(varName) >= 0
							|| StringTools.startsWith(staticRegex.matched(2), "function"))
						{
							// Leave it as-is.
							return staticRegex.matched(0);
						}
						else
						{
							// Move the declaration into the
							// function.
							__initStatics__ += "\t"
								+ StringTools.replace(staticRegex.matched(0), "\n", "\n\t")
								+ newline;

							// Remove the original, leaving
							// a comment for later.
							declarations++;
							return '/* $className.__initStatics__ */';
						}
					});

				__initStatics__ += "};" + newline;

				// Insert the function in place of the final
				// comment, cleaning up the others.
				outputContent = new EReg('^/\\* $className\\.__initStatics__ \\*/\r?\n', "gm")
					.map(outputContent, function(commentRegex:EReg):String
					{
						if (--declarations == 0)
						{
							return __initStatics__
								+ '$className.__initStatics__();$newline';
						}
						else
						{
							return "";
						}
					});
			}

			File.saveContent(outputFile, outputContent);
		});
		#end
	}
}

@:enum abstract ThreadEventType(String)
{
	var COMPLETE = "COMPLETE";
	var ERROR = "ERROR";
	var EXIT = "EXIT";
	var PROGRESS = "PROGRESS";
	var WORK = "WORK";
}

@:forward
abstract ThreadEvent({ message:Dynamic, event:ThreadEventType })
{
	public inline function new(event:ThreadEventType, message:Dynamic)
	{
		this = {
			event: event,
			message: message
		};
	}
}

/**
	JavaScript code to be run when a web worker starts. The
	variables and functions declared here will be available
	to the `doWork` function.

	The simplest way to add code is one class at a time, by
	calling `addClass()`.

	If web workers aren't enabled, all functions will
	perform a no-op.
**/
abstract HeaderCode(Array<String>) from Array<String>
{
	#if (js && !force_synchronous)
	/**
		An extension of `Json.stringify()` that outputs
		JavaScript source code, including function code.
	**/
	private static function stringify(obj:Dynamic, ?include:Array<String>, ?exclude:Array<String>):String
	{
		// A (hopefully) unique substring.
		var marker:String = "[lime.system.ThreadBase]";

		// Convert to JSON, converting functions to string,
		// marking these strings for more processing.
		var objString:String = Json.stringify(obj, function(key:String, value:Dynamic):Dynamic
		{
			if (key == "__class__")
			{
				return marker + (value:Function).name;
			}
			else if (include != null && include.indexOf(key) < 0
				|| exclude != null && exclude.indexOf(key) >= 0)
			{
				return Lib.undefined;
			}
			else if (Syntax.typeof(value) == "function")
			{
				var func:String = marker + cast value;
				if (func.indexOf("[native code]") < 0)
				{
					return func;
				}
				else
				{
					return Lib.undefined;
				}
			}
			else
			{
				return value;
			}
		}, "\t");

		// Not used currently, but prevents an error in
		// cases like `stringify(Std.parseInt.bind("1"))`.
		if (objString == null)
			return null;

		// https://stackoverflow.com/a/5696141/804200
		return new EReg('"' + EReg.escape(marker) + '([^"\\\\]*(?:\\\\.[^"\\\\]*)*)"', "gs")
			.map(objString, function(regex:EReg)
			{
				var markedString:String = regex.matched(1);
				markedString = StringTools.replace(markedString, "\\r", "\r");
				markedString = StringTools.replace(markedString, "\\n", "\n");
				markedString = StringTools.replace(markedString, "\\t", "\t");
				markedString = StringTools.replace(markedString, '\\"', '"');
				markedString = StringTools.replace(markedString, "\\\\", "\\");
				return markedString;
			}
		);
	}
	#end

	/**
		Adds a JavaScript snippet that wasn't already added.
	**/
	public inline function add(code:String):Void
	{
		#if (js && !force_synchronous)
		if (this.indexOf(code) < 0)
			this.push(code);
		#end
	}

	/**
		Adds a Haxe class and its superclasses into the
		header. If `cls` refers to any other classes, they
		must be added separately.
		@param cls The class to copy from. For best results,
		hard-code the class name: `addClass(DisplayObject)`
		will work, but `var x = DisplayObject; addClass(x)`
		could lead to errors.
		@param include If not null, only these properties
		will be included.
		@param exclude These properties will be left out.
	**/
	public function addClass(cls:Class<Dynamic>, ?include:Array<String>, ?exclude:Array<String>):Void
	{
		#if (js && !force_synchronous)
		var cls:Function = cast cls;

		var classDef:String = 'var ${cls.name} = ${cls.toString()};\n';

		var superClass:Function = (cast cls).__super__;
		if (superClass != null)
		{
			addClass(cast superClass, include, exclude);
			classDef += '${cls.name}.__super__ = ${superClass.name};\n';
		}

		add(classDef);

		for (entry in Object.entries(cls))
		{
			if (entry.key == "__super__" || entry.key == "__interfaces__")
				continue;

			var value:String = "" + cast entry.value;
			if (Syntax.typeof(entry.value) == "string")
			{
				value = '"$value"';
			}
			else if (value.indexOf("[native code]") >= 0 || value.indexOf("[object Object]") >= 0)
			{
				continue;
			}

			add('${cls.name}.${entry.key} = $value;\n');

			if (entry.key == "__init__" || entry.key == "__initStatics__")
			{
				add('${cls.name}.${entry.key}();\n');
			}
		}

		var prototype:{} = (cast cls).prototype;
		add('${cls.name}.prototype = '
			+ (superClass != null ? '$$extend(${superClass.name}.prototype,' : "")
			+ stringify(prototype, include, exclude)
			+ (superClass != null ? ");\n" : ";\n"));
		#end
	}

	public function contains(cls:Class<Dynamic>):Bool
	{
		#if (js && !force_synchronous)
		var searchString:String = "var " + (cast cls:Function).name + " =";
		for (code in this)
		{
			if (StringTools.startsWith(code, searchString))
				return true;
		}
		#end

		return false;
	}

	public inline function copy():HeaderCode
	{
		#if (js && !force_synchronous)
		return this.copy();
		#else
		return null;
		#end
	}

	public inline function toString():String
	{
		#if (js && !force_synchronous)
		return this.join("\n") + "\n";
		#else
		return "";
		#end
	}
}
