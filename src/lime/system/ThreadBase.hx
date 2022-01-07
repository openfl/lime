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
				"var haxe_Exception = { caught: (value) => value, thrown: (value) => (value.get_native) ? value.get_native() : value };",
				"var StringTools = { startsWith: (s, start) => s.startsWith(start), endsWith: (s, end) => s.endsWith(end), trim: s => s.trim() };",
				"var HxOverrides = { substr: (s, pos, len) => s.substr(pos, len) };"
			];
		}

		return defaultHeaderCode;
	}

	/**
		(Only available if using web workers.)

		Whenever this `BackgroundWorker` or `ThreadPool`
		creates a new web worker, it will insert this code
		at the beginning of the JavaScript file, making the
		functions available to the worker.
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
	#if js inline #end
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
	#if js inline #end
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
	#if js inline #end
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
	public inline function toString():String
	{
		return this.join("\n") + "\n";
	}
}
#end
