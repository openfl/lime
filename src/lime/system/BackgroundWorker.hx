package lime.system;

import lime.system.WorkOutput;

/**
	A simple and thread-safe way to run a one or more asynchronous jobs. Unlike
	`ThreadPool`, each job in the queue can use a different function.

	Sample usage:

		var bgWorker:BackgroundWorker = new BackgroundWorker();
		bgWorker.onComplete.add(onDataProcessed);

		bgWorker.run(processFile, url);
		for (text in textStrings)
		{
			bgWorker.run(processText, text);
		}
		bgWorker.run(processImage, image);

	For thread safety, each worker function should only give output through the
	`WorkOutput` object it receives. Calling `output.sendComplete()` will
	trigger an `onComplete` event on the main thread.

	@see https://player03.com/openfl/threads-guide/ for a tutorial.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:forward
abstract BackgroundWorker(ThreadPool)
{
	private static var doWorkWrapper:WorkFunction<State->WorkOutput->Void>;

	@:deprecated("Instead pass the callback to BackgroundWorker.run().")
	@:noCompletion @:dox(hide) public var doWork(get, never):{ add: (Dynamic->Void) -> Void };

	public var eventSource(get, never):Dynamic;

	/**
		__Call this only from the main thread.__

		@param mode Defaults to `MULTI_THREAEDED` on most targets, but
		`SINGLE_THREADED` in HTML5. In HTML5, `MULTI_THREADED` mode uses web
		workers, which impose additional restrictions.
		@param workLoad (Single-threaded mode only) A rough estimate of how much
		of the app's time should be spent on this `BackgroundWorker`. For
		instance, the default value of 1/2 means this worker will take up about
		half the app's available time every frame. See `workIterations` for
		instructions to improve the accuracy of this estimate.
	**/
	public function new(mode:ThreadMode = null, workLoad:Float = 1/2)
	{
		if (doWorkWrapper == null)
		{
			doWorkWrapper = BackgroundWorkerFunctions.__doWork;
		}
		this = new ThreadPool(doWorkWrapper, mode, workLoad);
	}

	/**
		Cancels one active or queued job.
	**/
	// A copy of `ThreadPool.cancelJob()` with replacements:
	// - Find "__activeJobs", replace with "this.__activeJobs".
	// - Find "__idleThreads", replace with "this.__idleThreads".
	// - Find "__jobQueue", replace with "this.__jobQueue".
	// - Find ".state", replace with ".state.state".
	// Other than that, keep the functions exactly in sync.
	public function cancelJob(state:State):Bool
	{
		for (job in this.__activeJobs)
		{
			if (job.workEvent.state.state == state)
			{
				#if lime_threads
				if (job.thread != null)
				{
					job.thread.sendMessage(new ThreadEvent(WORK, null));
					this.__idleThreads.push(job.thread);
				}
				#end

				return this.__activeJobs.remove(job);
			}
		}
		for (job in this.__jobQueue)
		{
			if (job.state.state == state)
			{
				return this.__jobQueue.remove(job);
			}
		}

		return false;
	}

	/**
		Adds the given job to the queue.

		In multi-threaded mode, the main thread should avoid modifying `state`
		until the job completes.

		@param doWork The function to execute. Treat this parameter as though it
		was required.
		@param state The argument to pass to `doWork`. Defaults to `{}`.
	**/
	public function run(doWork:WorkFunction<State->WorkOutput->Void> = null, state:State = null):Void
	{
		// Undo the below hack, if possible.
		if (doWork != null && this.__doWork != doWorkWrapper)
		{
			this.__doWork = doWorkWrapper;
		}

		#if (lime_threads && html5)
		if (this.mode == MULTI_THREADED)
		{
			doWork.makePortable();
		}
		#end

		this.queue({
			state: state,
			doWork: doWork
		});
	}

	// Getters & Setters

	private inline function get_eventSource():Dynamic
	{
		return this.eventSource != null ? this.eventSource.state : null;
	}

	private function get_doWork()
	{
		return {
			add: function(callback:Dynamic->Void)
			{
				#if html5
				if (this.mode == MULTI_THREADED)
					throw "Unsupported operation; instead pass the callback to BackgroundWorker.run().";
				#end
				// Hack: overwrite `__doWork` just for this one function. Hope
				// it wasn't in use!
				this.__doWork = #if (lime_threads && html5) { func: #end
					function(state:State, output:WorkOutput):Void
					{
						callback(state.state);
					}
					#if (lime_threads && html5) } #end;
			}
		};
	}
}

@:allow(lime.system.BackgroundWorker)
private class BackgroundWorkerFunctions
{
	private static function __doWork(state:State, output:WorkOutput):Void
	{
		// `dispatch()` will check if it's really a `WorkFunction`.
		(state.doWork:WorkFunction<State->WorkOutput->Void>).dispatch(state.state, output);
	}
}
