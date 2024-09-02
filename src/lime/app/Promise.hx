package lime.app;

import lime.app.Future;
import lime.system.ThreadPool;
import lime.system.WorkOutput;

/**
	`Promise` is an implementation of Futures and Promises, with the exception that
	in addition to "success" and "failure" states (represented as "complete" and "error"),
	Lime `Future` introduces "progress" feedback as well to increase the value of
	`Future` values.

	While `Future` is meant to be read-only, `Promise` can be used to set the state of a future
	for recipients of it's `Future` object. For example:

	```haxe
	function examplePromise():Future<String>
	{
		var promise = new Promise<String>();

		var progress = 0, total = 10;
		var timer = new Timer(100);
		timer.run = function()
		{

			promise.progress (progress, total);
			progress++;

			if (progress == total)
			{

				promise.complete ("Done!");
				timer.stop ();

			}

		};

		return promise.future;
	}

	var future = examplePromise();
	future.onComplete(function(message) { trace(message); });
	future.onProgress(function(loaded, total) { trace("Progress: " + loaded + ", " + total); });
	```
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:allow(lime.app.Future)
#if (!hl && !js && !macro)
@:generic
#end
class Promise<T>
{
	/**
		The `Future` associated with this `Promise`.

		All subsequent calls to set an error, completion or progress state
		will update the status and notify listeners to this `Future`
	**/
	public var future(default, null):Future<T>;

	/**
		Whether the `Promise` (and related `Future`) has finished with a completion state.
		This will be `false` if the `Promise` has not been resolved with a completion or error state.
	**/
	public var isComplete(get, null):Bool;

	/**
		Whether the `Promise` (and related `Future`) has finished with an error state.
		This will be `false` if the `Promise` has not been resolved with a completion or error state.
	**/
	public var isError(get, null):Bool;

	private var jobID:Int = -1;

	#if commonjs
	private static function __init__()
	{
		var p = untyped Promise.prototype;
		untyped Object.defineProperties(p,
			{
				"isComplete": {get: p.get_isComplete},
				"isError": {get: p.get_isError}
			});
	}
	#end

	/**
		Create a new `Promise` instance
	**/
	public function new()
	{
		future = new Future<T>();
	}

	/**
		Resolves this `Promise` with a completion state
		@param	data	The completion value
		@return	The current `Promise`
	**/
	public function complete(data:T):Promise<T>
	{
		if (!ThreadPool.isMainThread())
		{
			haxe.MainLoop.runInMainThread(complete.bind(data));
			return this;
		}

		if (!future.isError)
		{
			future.isComplete = true;
			future.value = data;

			if (jobID != -1)
			{
				FutureWork.cancelJob(jobID);
				jobID = -1;
			}

			if (future.__completeListeners != null)
			{
				for (listener in future.__completeListeners)
				{
					listener(data);
				}

				future.__completeListeners = null;
			}
		}

		return this;
	}

	/**
		Runs the given function asynchronously, and resolves this `Promise` with
		the complete, error, and/or progress events sent by that function.
		Sample usage:

		```haxe
		function examplePromise():Future<String>
		{
			var promise = new Promise<String>();
			promise.completeAsync(function(state:State, output:WorkOutput):Void
				{
					output.sendProgress({progress:state.progress, total:10});
					state.progress++;

					if (state.progress == 10)
					{
						output.sendComplete("Done!");
					}
				},
				{progress: 0}, MULTI_THREADED);

			return promise.future;
		}

		var future = examplePromise();
		future.onComplete(function(message) { trace(message); });
		future.onProgress(function(loaded, total) { trace("Progress: " + loaded + ", " + total); });
		```

		@param doWork A function to perform work asynchronously. For best results,
		see the guidelines in the `ThreadPool` class overview.
		@param state The value to pass to `doWork`.
		@param mode Which mode to run the job in: `SINGLE_THREADED` or `MULTI_THREADED`.
	**/
	public function completeAsync(doWork:WorkFunction<State->WorkOutput->Void>, ?state:State, ?mode:ThreadMode = MULTI_THREADED):Void
	{
		jobID = FutureWork.run(doWork, this, state, mode);
	}

	/**
		Resolves this `Promise` with the complete, error and/or progress state
		of another `Future`
		@param	future	The `Future` to use to resolve this `Promise`
		@return	The current `Promise`
	**/
	public function completeWith(future:Future<T>):Promise<T>
	{
		future.onComplete(complete);
		future.onError(error);
		future.onProgress(progress);

		return this;
	}

	/**
		Resolves this `Promise` with an error state
		@param	msg	The error value
		@return	The current `Promise`
	**/
	public function error(msg:Dynamic):Promise<T>
	{
		if (!ThreadPool.isMainThread())
		{
			haxe.MainLoop.runInMainThread(error.bind(msg));
			return this;
		}

		if (!future.isComplete)
		{
			future.isError = true;
			future.error = msg;

			if (jobID != -1)
			{
				FutureWork.cancelJob(jobID);
				jobID = -1;
			}

			if (future.__errorListeners != null)
			{
				for (listener in future.__errorListeners)
				{
					listener(msg);
				}

				future.__errorListeners = null;
			}
		}

		return this;
	}

	/**
		Sends progress updates to the related `Future`
		@param	progress	A progress value
		@param	total	A total value. This should be equal or greater to the `progress` value
		@return	The current `Promise`
	**/
	public function progress(progress:Int, total:Int):Promise<T>
	{
		if (!ThreadPool.isMainThread())
		{
			haxe.MainLoop.runInMainThread(this.progress.bind(progress, total));
			return this;
		}

		if (!future.isError && !future.isComplete)
		{
			if (future.__progressListeners != null)
			{
				for (listener in future.__progressListeners)
				{
					listener(progress, total);
				}
			}
		}

		return this;
	}

	// Get & Set Methods
	@:noCompletion private inline function get_isComplete():Bool
	{
		return future.isComplete;
	}

	@:noCompletion private inline function get_isError():Bool
	{
		return future.isError;
	}
}
