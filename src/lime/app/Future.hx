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
		@param work 	Deprecated; use `Future.withEventualValue()` instead.
		@param useThreads 	Deprecated; use `Future.withEventualValue()` instead.
	**/
	public function new(work:WorkFunction<Void->T> = null, useThreads:Bool = false)
	{
		if (work != null)
		{
			var promise = new Promise<T>();
			promise.future = this;

			#if (lime_threads && html5)
			if (useThreads)
			{
				work.makePortable();
			}
			#end

			FutureWork.run(dispatchWorkFunction, work, promise, useThreads ? MULTI_THREADED : SINGLE_THREADED, true);
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
				if (FutureWork.activeJobs < 1)
				{
					Log.error('Cannot block for a Future without a "work" function.');
					return this;
				}

				if (FutureWork.singleThreadPool != null && FutureWork.singleThreadPool.activeJobs > 0)
				{
					@:privateAccess FutureWork.singleThreadPool.__update(time - prevTime);
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

		Once `work()` returns a non-null value, the `Future` will finish with that value.
		If `work()` throws an error, the `Future` will finish with that error instead.
		@param	work 	A function that computes a value of type `T`.
		@param  state   An argument to pass to `work()`. As this may be used on another thread, the
		main thread must not access or modify `state` until the `Future` finishes.
		@param  mode 	Whether to use real threads as opposed to virtual threads. Virtual threads rely
		on cooperative multitasking, meaning `work()` must return periodically to allow other code
		enough time to run. In these cases, `work()` should return null to signal that it isn't finished.
		@return	A new `Future` instance.
		@see https://en.wikipedia.org/wiki/Cooperative_multitasking
	**/
	public static function withEventualValue<T>(work:WorkFunction<State -> Null<T>>, state:State, mode:ThreadMode = #if html5 SINGLE_THREADED #else MULTI_THREADED #end):Future<T>
	{
		var future = new Future<T>();
		var promise = new Promise<T>();
		promise.future = future;

		FutureWork.run(work, state, promise, mode);

		return future;
	}

	/**
		(For backwards compatibility.) Dispatches the given zero-argument function.
	**/
	@:noCompletion private static function dispatchWorkFunction<T>(work:WorkFunction<Void -> T>):Null<T>
	{
		return work.dispatch();
	}
}

/**
	The class that handles asynchronous `work` functions passed to `new Future()`.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:dox(hide) class FutureWork
{
	@:allow(lime.app.Future)
	private static var singleThreadPool:ThreadPool;
	#if lime_threads
	private static var multiThreadPool:ThreadPool;
	// It isn't safe to pass a promise object to a web worker.
	private static var promises:Map<Int, Promise<Dynamic>> = new Map();
	#end
	public static var minThreads(default, set):Int = 0;
	public static var maxThreads(default, set):Int = 1;
	public static var activeJobs(get, never):Int;

	private static function getPool(mode:ThreadMode):ThreadPool
	{
		#if lime_threads
		if (mode == MULTI_THREADED) {
			if(multiThreadPool == null) {
				multiThreadPool = new ThreadPool(minThreads, maxThreads, MULTI_THREADED);
				multiThreadPool.onComplete.add(multiThreadPool_onComplete);
				multiThreadPool.onError.add(multiThreadPool_onError);
			}
			return multiThreadPool;
		}
		#end
		if(singleThreadPool == null) {
			singleThreadPool = new ThreadPool(minThreads, maxThreads, SINGLE_THREADED);
			singleThreadPool.onComplete.add(singleThreadPool_onComplete);
			singleThreadPool.onError.add(singleThreadPool_onError);
		}
		return singleThreadPool;
	}

	@:allow(lime.app.Future)
	private static function run<T>(work:WorkFunction<State->Null<T>>, state:State, promise:Promise<T>, mode:ThreadMode = MULTI_THREADED, legacyCode:Bool = false):Void
	{
		var bundle = {work: work, state: state, promise: promise, legacyCode: legacyCode};

		#if lime_threads
		if (mode == MULTI_THREADED)
		{
			#if html5
			work.makePortable();
			#end

			bundle.promise = null;
		}
		#end

		var jobID:Int = getPool(mode).run(threadPool_doWork, bundle);

		#if lime_threads
		if (mode == MULTI_THREADED)
		{
			promises[jobID] = (cast promise:Promise<Dynamic>);
		}
		#end
	}

	// Event Handlers
	private static function threadPool_doWork(bundle:{work:WorkFunction<State->Dynamic>, state:State, legacyCode:Bool}, output:WorkOutput):Void
	{
		try
		{
			var result = bundle.work.dispatch(bundle.state);
			if (result != null || bundle.legacyCode)
			{
				#if (lime_threads && html5)
				bundle.work.makePortable();
				#end
				output.sendComplete(result);
			}
		}
		catch (e:Dynamic)
		{
			#if (lime_threads && html5)
			bundle.work.makePortable();
			#end
			output.sendError(e);
		}
	}

	private static function singleThreadPool_onComplete(result:Dynamic):Void
	{
		singleThreadPool.activeJob.state.promise.complete(result);
	}

	private static function singleThreadPool_onError(error:Dynamic):Void
	{
		singleThreadPool.activeJob.state.promise.error(error);
	}

	#if lime_threads
	private static function multiThreadPool_onComplete(result:Dynamic):Void
	{
		var promise:Promise<Dynamic> = promises[multiThreadPool.activeJob.id];
		promises.remove(multiThreadPool.activeJob.id);
		promise.complete(result);
	}

	private static function multiThreadPool_onError(error:Dynamic):Void
	{
		var promise:Promise<Dynamic> = promises[multiThreadPool.activeJob.id];
		promises.remove(multiThreadPool.activeJob.id);
		promise.error(error);
	}
	#end

	// Getters & Setters
	@:noCompletion private static inline function set_minThreads(value:Int):Int
	{
		if (singleThreadPool != null)
		{
			singleThreadPool.minThreads = value;
		}
		#if lime_threads
		if (multiThreadPool != null)
		{
			multiThreadPool.minThreads = value;
		}
		#end
		return minThreads = value;
	}

	@:noCompletion private static inline function set_maxThreads(value:Int):Int
	{
		if (singleThreadPool != null)
		{
			singleThreadPool.maxThreads = value;
		}
		#if lime_threads
		if (multiThreadPool != null)
		{
			multiThreadPool.maxThreads = value;
		}
		#end
		return maxThreads = value;
	}

	@:noCompletion private static function get_activeJobs():Int
	{
		var sum:Int = 0;
		if (singleThreadPool != null)
		{
			sum += singleThreadPool.activeJobs;
		}
		#if lime_threads
		if (multiThreadPool != null)
		{
			sum += multiThreadPool.activeJobs;
		}
		#end
		return sum;
	}
}
