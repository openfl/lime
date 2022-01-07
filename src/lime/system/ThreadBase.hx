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

/**
	Common functionality between `BackgroundWorker` and
	`ThreadPool`.

	@see `lime.system.ThreadBase.HeaderCode`
**/
class ThreadBase {
	#if (js && !force_synchronous)
	/**
		(Only available if using web workers.)

		The default value for `headerCode`, applied when
		creating a new `BackgroundWorker` or `ThreadPool`.
		Modifying this won't affect already-existing
		`BackgroundWorker`s and `ThreadPool`s.
	**/
	public static var defaultHeaderCode(get, default):HeaderCode;
	private static function get_defaultHeaderCode():HeaderCode {
		if(defaultHeaderCode == null) {
			defaultHeaderCode = [
				'"use strict";',
				Syntax.code("$extend.toString()"),
				'var haxe_Log = { trace: (v, infos) => console.log(infos.fileName + ":" + infos.lineNumber + ": " + v) };',
				"var haxe_Exception = { caught: (value) => value, thrown: (value) => (value.get_native) ? value.get_native() : value };"
			];
			defaultHeaderCode.addClass(StringTools);
			defaultHeaderCode.addClass(HxOverrides);
		}

		return defaultHeaderCode;
	}

	/**
		(Only available if using web workers.)

		Whenever this `BackgroundWorker` or `ThreadPool`
		creates a new web worker, it will insert this code
		at the beginning of the JavaScript file, making the
		functions available to the worker.

		Starts with the code from `defaultHeaderCode`, and
		can be extended by calling `headerCode.addClass()`.
	**/
	public var headerCode:HeaderCode;
	#end

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
		#if js
		headerCode = defaultHeaderCode.copy();
		#end

		this.doWork = doWork;
	}

	/**
		[Call this from a background thread.]

		Dispatches `onComplete` on the main thread, with the
		given message. The background function should send
		no further messages after calling this.
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

#if (js && !force_synchronous)
/**
	JavaScript code to be run when a web worker starts. The
	variables and functions declared here will be available
	to the `doWork` function.
**/
@:forward
abstract HeaderCode(Array<String>) from Array<String> to Array<String>
{
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

	public inline function pushUnique(value:String):Void
	{
		if (this.indexOf(value) < 0)
			this.push(value);
	}

	/**
		Adds a Haxe class and its superclasses into the
		header. If `cls` refers to any other classes, they
		must be added separately.

		**Caution:** this will fail to initialize most
		static variables, which can cause errors. (Static
		functions and instance variables are both fine.)
		@param cls The class to copy from.
		@param include If not null, only these properties
		will be included.
		@param exclude These properties will be left out.
	**/
	public function addClass(cls:Class<Dynamic>, ?include:Array<String>, ?exclude:Array<String>):Void
	{
		var cls:Function = cast cls;

		var classDef:String = 'var ${cls.name} = ${cls.toString()};\n';

		var superClass:Function = (cast cls).__super__;
		if (superClass != null)
		{
			addClass(cast superClass, include, exclude);
			classDef += '${cls.name}.__super__ = ${superClass.name};\n';
		}

		pushUnique(classDef);

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

			pushUnique('${cls.name}.${entry.key} = $value;\n');

			if (entry.key == "__init__")
			{
				pushUnique('${cls.name}.__init__();\n');
			}
		}

		var prototype:{} = (cast cls).prototype;
		pushUnique('${cls.name}.prototype = '
			+ (superClass != null ? '$$extend(${superClass.name}.prototype,' : "")
			+ stringify(prototype, include, exclude)
			+ (superClass != null ? ");\n" : ";\n"));
	}

	public function contains(cls:Class<Dynamic>):Bool
	{
		var searchString:String = "var " + (cast cls:Function).name + " =";
		for (code in this)
		{
			if (StringTools.startsWith(code, searchString))
				return true;
		}

		return false;
	}

	public inline function toString():String
	{
		return this.join("\n") + "\n";
	}
}
#end
