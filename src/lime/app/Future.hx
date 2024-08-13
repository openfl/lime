package lime.app;

import lime.system.System;
import lime.system.ThreadPool;
import lime.system.WorkOutput;
import lime.utils.Log;

/**
	`Future` is an implementation of Futures and Promises, with the exception that
	in addition to "success" and "failure" states (represented as "complete" and "error"),
	Lime `Future` introduces "progress" feedback as well to increase the value of
	`Future` values.

	```haxe
	var future = Image.loadFromFile ("image.png");
	future.onComplete (function (image) { trace ("Image loaded"); });
	future.onProgress (function (loaded, total) { trace ("Loading: " + loaded + ", " + total); });
	future.onError (function (error) { trace (error); });

	Image.loadFromFile ("image.png").then (function (image) {

		return Future.withValue (image.width);

	}).onComplete (function (width) { trace (width); })
	```

	`Future` values can be chained together for asynchronous processing of values.

	If an error occurs earlier in the chain, the error is propagated to all `onError` callbacks.

	`Future` will call `onComplete` callbacks, even if completion occurred before registering the
	callback. This resolves race conditions, so even functions that return immediately can return
	values using `Future`.

	`Future` values are meant to be immutable, if you wish to update a `Future`, you should create one
	using a `Promise`, and use the `Promise` interface to influence the error, complete or progress state
	of a `Future`.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:allow(lime.app.Promise) /*@:generic*/ class Future<T>
{
	/**
		If the `Future` has finished with an error state, the `error` value
	**/
	public var error(default, null):Dynamic;

	/**
		Whether the `Future` finished with a completion state
	**/
	public var isComplete(default, null):Bool;

	/**
		Whether the `Future` finished with an error state
	**/
	public var isError(default, null):Bool;

	/**
		If the `Future` has finished with a completion state, the completion `value`
	**/
	public var value(default, null):T;

	@:noCompletion private var __completeListeners:Array<T->Void>;
	@:noCompletion private var __errorListeners:Array<Dynamic->Void>;
	@:noCompletion private var __progressListeners:Array<Int->Int->Void>;

	/**
		@param doWork 	Deprecated; use `Future.withEventualValue()` instead.
		@param useThreads 	Deprecated; use `Future.withEventualValue()` instead.
	**/
	public function new(doWork:WorkFunction<Void->T> = null, useThreads:Bool = false)
	{
		if (doWork != null)
		{
			var promise = new Promise<T>();
			promise.future = this;

			#if (lime_threads && html5)
			if (useThreads)
			{
				doWork.makePortable();
			}
			#end

			FutureWork.forMode(useThreads ? MULTI_THREADED : SINGLE_THREADED).run(dispatchWorkFunction, doWork, promise);
		}
	}

	/**
		Create a new `Future` instance based on complete and (optionally) error and/or progress `Event` instances
	**/
	public static function ofEvents<T>(onComplete:Event<T->Void>, onError:Event<Dynamic->Void> = null, onProgress:Event<Int->Int->Void> = null):Future<T>
	{
		var promise = new Promise<T>();

		onComplete.add(promise.complete, true);
		if (onError != null) onError.add(promise.error, true);
		if (onProgress != null) onProgress.add(promise.progress, true);

		return promise.future;
	}

	/**
		Register a listener for when the `Future` completes.

		If the `Future` has already completed, this is called immediately with the result
		@param	listener	A callback method to receive the result value
		@return	The current `Future`
	**/
	public function onComplete(listener:T->Void):Future<T>
	{
		if (listener != null)
		{
			if (isComplete)
			{
				listener(value);
			}
			else if (!isError)
			{
				if (__completeListeners == null)
				{
					__completeListeners = new Array();
				}

				__completeListeners.push(listener);
			}
		}

		return this;
	}

	/**
		Register a listener for when the `Future` ends with an error state.

		If the `Future` has already ended with an error, this is called immediately with the error value
		@param	listener	A callback method to receive the error value
		@return	The current `Future`
	**/
	public function onError(listener:Dynamic->Void):Future<T>
	{
		if (listener != null)
		{
			if (isError)
			{
				listener(error);
			}
			else if (!isComplete)
			{
				if (__errorListeners == null)
				{
					__errorListeners = new Array();
				}

				__errorListeners.push(listener);
			}
		}

		return this;
	}

	/**
		Register a listener for when the `Future` updates progress.

		If the `Future` is already completed, this will not be called.
		@param	listener	A callback method to receive the progress value
		@return	The current `Future`
	**/
	public function onProgress(listener:Int->Int->Void):Future<T>
	{
		if (listener != null)
		{
			if (__progressListeners == null)
			{
				__progressListeners = new Array();
			}

			__progressListeners.push(listener);
		}

		return this;
	}

	/**
		Attempts to block on an asynchronous `Future`, returning when it is completed.
		@param	waitTime	(Optional) A timeout before this call will stop blocking
		@return	This current `Future`
	**/
	public function ready(waitTime:Int = -1):Future<T>
	{
		if (isComplete || isError)
		{
			return this;
		}
		else
		{
			var time = System.getTimer();
			var prevTime = time;
			var end = time + waitTime;

			while (!isComplete && !isError && time <= end)
			{
				if (FutureWork.totalActiveJobs < 1)
				{
					Log.error('Cannot block for a Future without a "doWork" function.');
					return this;
				}

				if (FutureWork.singleThread.activeJobs > 0)
				{
					@:privateAccess FutureWork.singleThread.threadPool.__update(time - prevTime);
				}
				else
				{
					#if sys
					Sys.sleep(0.01);
					#end
				}

				prevTime = time;
				time = System.getTimer();
			}

			return this;
		}
	}

	/**
		Attempts to block on an asynchronous `Future`, returning the completion value when it is finished.
		@param	waitTime	(Optional) A timeout before this call will stop blocking
		@return	The completion value, or `null` if the request timed out or blocking is not possible
	**/
	public function result(waitTime:Int = -1):Null<T>
	{
		ready(waitTime);

		if (isComplete)
		{
			return value;
		}
		else
		{
			return null;
		}
	}

	/**
		Chains two `Future` instances together, passing the result from the first
		as input for creating/returning a new `Future` instance of a new or the same type
	**/
	public function then<U>(next:T->Future<U>):Future<U>
	{
		if (isComplete)
		{
			return next(value);
		}
		else if (isError)
		{
			var future = new Future<U>();
			future.isError = true;
			future.error = error;
			return future;
		}
		else
		{
			var promise = new Promise<U>();

			onError(promise.error);
			onProgress(promise.progress);

			onComplete(function(val)
			{
				var future = next(val);
				future.onError(promise.error);
				future.onComplete(promise.complete);
			});

			return promise.future;
		}
	}

	/**
		Creates a `Future` instance which has finished with an error value
		@param	error	The error value to set
		@return	A new `Future` instance
	**/
	public static function withError(error:Dynamic):Future<Dynamic>
	{
		var future = new Future<Dynamic>();
		future.isError = true;
		future.error = error;
		return future;
	}

	/**
		Creates a `Future` instance which has finished with a completion value
		@param	value	The completion value to set
		@return	A new `Future` instance
	**/
	public static function withValue<T>(value:T):Future<T>
	{
		var future = new Future<T>();
		future.isComplete = true;
		future.value = value;
		return future;
	}

	/**
		Creates a `Future` instance which will asynchronously compute a value.

		The provided `doWork` function is the same as as a `ThreadPool` work function.
		It will run repeatedly until it calls `sendComplete()` or `sendError()`, and
		should aim to do a small fraction of the work each time. This is important in
		single-threaded mode to avoid blocking the main thread.

		The three output functions:

		- `sendComplete()` requires a value of type `T` and resolves the `Future` as complete.
		  Passing the wrong value causes unspecified behavior.
		- `sendError()` takes any value and resolves the `Future` with that error.
		- `sendProgress()` requires a `{progress:Int, total:Int}` value. This information will
		  be sent to any `onProgress` listeners. Any other values will be ignored.
		@param	doWork 	The function that performs the work.
		@param  state   An argument to pass to `doWork`. Defaults to `{}`. The same instance will
		be passed each time `doWork` is called, allowing it to store data between calls. To avoid
		race conditions, the main thread should not access or modify `state` until all work finishes.
		@param  mode 	Whether to use real threads (`MULTI_THREADED`) as opposed to green threads (`SINGLE_THREADED`).
		In single-threaded mode, it's especially important for `doWork` to return often.
		@return	A new `Future` instance.
		@see lime.system.ThreadPool
	**/
	public static function withEventualValue<T>(doWork:WorkFunction<State->WorkOutput->Void>, ?state:State,
			mode:ThreadMode = #if html5 SINGLE_THREADED #else MULTI_THREADED #end):Future<T>
	{
		var future = new Future<T>();
		var promise = new Promise<T>();
		promise.future = future;

		FutureWork.forMode(mode).run(doWork, state, promise);

		return future;
	}

	/**
		(For backwards compatibility.) Dispatches the given zero-argument function.
	**/
	@:noCompletion private static function dispatchWorkFunction<T>(doWork:WorkFunction<Void->T>, output:WorkOutput):Void
	{
		output.sendComplete(doWork.dispatch());
	}
}

/**
	Return values for work functions used with `Future.withEventualValue()`,
	used to describe the state of the work.
**/
enum FutureStatus<T>
{
	/**
		Resolves the `Future` with a completion state. The work function won't be called again.
	**/
	Complete(value:T);

	/**
		Resolves the `Future` with an error state. The work function won't be called again.
	**/
	Error(error:Dynamic);

	/**
		Re-runs the work function without dispatching an event. This is particularly important
		in single-threaded mode, to avoid blocking the main thread.
	**/
	Incomplete;

	/**
		Dispatches a progress event before re-running the work function.
	**/
	Progress(progress:Int, total:Int);
}

/**
	The class that handles asynchronous `doWork` functions passed to `Future.withEventualValue()`.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:dox(hide) class FutureWork
{
	public static var singleThread(get, null):FutureWork;

	private static inline function get_singleThread():FutureWork
	{
		if (singleThread == null)
		{
			singleThread = new FutureWork(SINGLE_THREADED);
		}
		return singleThread;
	}

	#if lime_threads
	public static var multiThread(get, null):FutureWork;

	private static inline function get_multiThread():FutureWork
	{
		if (multiThread == null)
		{
			multiThread = new FutureWork(MULTI_THREADED);
		}
		return multiThread;
	}
	#end

	public static var totalActiveJobs(get, never):Int;

	private static inline function get_totalActiveJobs():Int
	{
		return singleThread.activeJobs #if lime_threads + multiThread.activeJobs #end;
	}

	@:allow(lime.app.Future)
	private static function forMode(mode:ThreadMode):FutureWork
	{
		#if lime_threads
		if (mode == MULTI_THREADED)
		{
			return multiThread;
		}
		#end
		return singleThread;
	}

	private var threadPool:ThreadPool;

	// Because `Promise` is `@:generic`, we can't always store it as `Promise<Dynamic>`.
	// Instead, we'll store the specific methods we need.
	private var promises:Map<Int, {complete:Dynamic->Dynamic, error:Dynamic->Dynamic, progress:Int->Int->Dynamic}> = new Map();

	public var minThreads(get, set):Int;
	public var maxThreads(get, set):Int;
	public var activeJobs(get, never):Int;

	private function new(mode:ThreadMode)
	{
		threadPool = new ThreadPool(mode);
		threadPool.onComplete.add(threadPool_onComplete);
		threadPool.onError.add(threadPool_onError);
		threadPool.onProgress.add(threadPool_onProgress);
	}

	@:allow(lime.app.Future)
	private function run<T>(doWork:WorkFunction<State->WorkOutput->Void>, state:State, promise:Promise<T>):Void
	{
		var jobID:Int = threadPool.run(doWork, state);
		promises[jobID] = {complete: promise.complete, error: promise.error, progress: promise.progress};
	}

	// Event Handlers
	private function threadPool_onComplete(result:Dynamic):Void
	{
		var promise = promises[threadPool.activeJob.id];
		promises.remove(threadPool.activeJob.id);
		promise.complete(result);
	}

	private function threadPool_onError(error:Dynamic):Void
	{
		var promise = promises[threadPool.activeJob.id];
		promises.remove(threadPool.activeJob.id);
		promise.error(error);
	}

	private function threadPool_onProgress(progress:Dynamic):Void
	{
		if (Type.typeof(progress) == TObject && Type.typeof(progress.progress) == TInt && Type.typeof(progress.total) == TInt)
		{
			promises[threadPool.activeJob.id].progress(progress.progress, progress.total);
		}
	}

	// Getters & Setters
	private inline function get_minThreads():Int
	{
		return threadPool.minThreads;
	}

	private inline function set_minThreads(value:Int):Int
	{
		return threadPool.minThreads = value;
	}

	private inline function get_maxThreads():Int
	{
		return threadPool.maxThreads;
	}

	private inline function set_maxThreads(value:Int):Int
	{
		return threadPool.maxThreads = value;
	}

	private inline function get_activeJobs():Int
	{
		return threadPool.activeJobs;
	}
}
