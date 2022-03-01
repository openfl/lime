package lime.system;

import lime.app.Application;
import lime.app.Event;
import lime.system.BackgroundWorker;
import lime.system.WorkOutput;
import lime.utils.Log;
#if target.threaded
import sys.thread.Thread;
#elseif cpp
import cpp.vm.Thread;
#elseif neko
import neko.vm.Thread;
#elseif html5
import lime._internal.backend.html5.HTML5Thread as Thread;
#end
/**
	A simple and thread-safe way to run a one or more asynchronous jobs. It runs
	the same function for each job, so the only difference between jobs is the
	argument passed to the function. It also manages a queue of jobs, starting
	new ones once the old ones are done.

	It can also keep a certain number of threads (configurable via `minThreads`)
	running in the background even when no jobs are available. This avoids the
	not-insignificant overhead of stopping and restarting threads.

	Sample usage:

		var threadPool:ThreadPool = new ThreadPool(processFile);
		threadPool.onComplete.add(onFileProcessed);

		threadPool.maxThreads = 3;
		for(url in urls)
		{
			threadPool.queue(url);
		}

	For thread safety, the worker function should only give output through the
	`WorkOutput` object it receives. Calling `output.sendComplete()` will
	trigger an `onComplete` event on the main thread.

	@see `lime.system.WorkOutput.WorkFunction` for important information about
	     `doWork`.
	@see https://player03.com/openfl/threads-guide/ for a tutorial.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:allow(lime.system.BackgroundWorker)
class ThreadPool extends WorkOutput
{
	#if (lime_threads && !html5)
	private static var __mainThread:Thread = Thread.current();
	#end

	/**
		Indicates that no further events will be dispatched.
	**/
	public var canceled(default, null):Bool = false;

	/**
		Indicates that the latest job finished successfully, and no other job
		has been started/is ongoing.
	**/
	public var completed(default, null):Bool = false;

	/**
		The number of live threads in this pool, including both active and idle
		threads. Does not count threads that have been instructed to shut down.

		In single-threaded mode, this will equal `activeJobs`.
	**/
	public var currentThreads(get, never):Int;

	/**
		The number of jobs actively being executed.
	**/
	public var activeJobs(get, never):Int;

	/**
		The number of live threads in this pool that aren't currently working on
		anything. In single-threaded mode, this will always be 0.
	**/
	public var idleThreads(get, never):Int;

	/**
		__Set this only from the main thread.__

		The maximum number of live threads this pool can have at once. If this
		value decreases, active jobs will still be allowed to finish.

		You can set this in single-threaded mode, but it's rarely useful. For
		instance, suppose you have six jobs, each of which takes about a second.
		If you leave `maxThreads` at 1, then one will finish every second for
		six seconds. If you set `maxThreads = 6`, then none will finish for five
		seconds, and then they'll all finish at once. The total duration is
		unchanged, but none of them finish early.
	**/
	public var maxThreads:Int;

	/**
		__Set this only from the main thread.__

		The number of threads that will be kept alive at all times, even if
		there's no work to do. Setting this won't add new threads, it'll just
		keep existing ones running.

		Has no effect in single-threaded mode.
	**/
	public var minThreads:Int;

	/**
		Dispatched on the main thread when `doWork` calls `sendComplete()`.
		Dispatched at most once per job.
	**/
	public var onComplete(default, null) = new Event<Dynamic->Void>();
	/**
		Dispatched on the main thread when `doWork` calls `sendError()`.
		Dispatched at most once per job.
	**/
	public var onError(default, null) = new Event<Dynamic->Void>();
	/**
		Dispatched on the main thread when `doWork` calls `sendProgress()`. May
		be dispatched any number of times per job.
	**/
	public var onProgress(default, null) = new Event<Dynamic->Void>();
	/**
		Dispatched on the main thread when a new job begins. Dispatched exactly
		once per job.
	**/
	public var onRun(default, null) = new Event<State->Void>();

	/**
		The `state` representing the job that triggered the active `onComplete`,
		`onError`, or `onProgress` event. Will be null if no event is active.
	**/
	public var eventSource(default, null):Null<State> = null;

	@:deprecated("Instead pass the callback to ThreadPool's constructor.")
	@:noCompletion @:dox(hide) public var doWork(get, never):{ add: (Dynamic->Void) -> Void };
	private var __doWork(default, set):WorkFunction<State->WorkOutput->Void>;

	#if lime_threads
	/**
		A list of idle threads. Not to be confused with `idleThreads`, which is
		`__idleThreads.length`.
	**/
	private var __idleThreads:List<Thread> = new List();
	#end

	private var __jobQueue:List<ThreadEvent> = new List();

	private var __workPerFrame:Float;

	/**
		__Call this only from the main thread.__

		@param doWork A single function capable of performing all of this pool's
		jobs. Always provide this function, even though it's marked as optional.
		@param mode Defaults to `MULTI_THREAEDED` on most targets, but
		`SINGLE_THREADED` in HTML5. In HTML5, `MULTI_THREADED` mode uses web
		workers, which impose additional restrictions.
		@param workLoad (Single-threaded mode only) A rough estimate of how much
		of the app's time should be spent on this `ThreadPool`. For instance,
		the default value of 1/2 means this worker will take up about half the
		app's available time every frame. See `workIterations` for instructions
		to improve the accuracy of this estimate.
	**/
	public function new(?doWork:WorkFunction<State->WorkOutput->Void>, ?minThreads:Int = 0, ?maxThreads:Int = 1, mode:ThreadMode = null, ?workLoad:Float = 1/2)
	{
		super(mode);

		__workPerFrame = workLoad / Application.current.window.frameRate;

		__doWork = doWork;

		this.minThreads = minThreads;
		this.maxThreads = maxThreads;
	}

	/**
		Cancels all active and queued jobs.
		@param error If not null, this error will be dispatched for each.
	**/
	public function cancel(error:Dynamic = null):Void
	{
		#if (lime_threads && !html5)
		if (Thread.current() != __mainThread)
		{
			throw "Call cancel() only from the main thread.";
		}
		#end

		Application.current.onUpdate.remove(__update);

		for (job in __activeJobs)
		{
			#if lime_threads
			if (job.thread != null)
			{
				if (idleThreads < minThreads)
				{
					job.thread.sendMessage(new ThreadEvent(WORK, null));
					__idleThreads.push(job.thread);
				}
				else
				{
					job.thread.sendMessage(new ThreadEvent(EXIT, null));
				}
			}
			#end

			if (error != null)
			{
				eventSource = job.workEvent.state;
				onError.dispatch(error);
			}
		}
		__activeJobs.clear();

		if (error != null)
		{
			for (job in __jobQueue)
			{
				eventSource = job.state;
				onError.dispatch(error);
			}
		}
		__jobQueue.clear();

		__jobComplete.value = false;
		eventSource = null;
		completed = false;
		canceled = true;
	}

	/**
		Cancels one active or queued job.
	**/
	// Be sure to keep this synchronized with
	// `BackgroundWorker.cancelJob()`.
	public function cancelJob(state:State):Bool
	{
		for (job in __activeJobs)
		{
			if (job.workEvent.state == state)
			{
				#if lime_threads
				if (job.thread != null)
				{
					job.thread.sendMessage(new ThreadEvent(WORK, null));
					__idleThreads.push(job.thread);
				}
				#end

				return __activeJobs.remove(job);
			}
		}
		for (job in __jobQueue)
		{
			if (job.state.state == state)
			{
				return __jobQueue.remove(job);
			}
		}

		return false;
	}

	/**
		Queues a new job, to be run once a thread becomes available.
	**/
	public function queue(state:Dynamic = null):Void
	{
		#if (lime_threads && !html5)
		if (Thread.current() != __mainThread)
		{
			throw "Call queue() only from the main thread.";
		}
		#end

		if (__doWork == null)
		{
			throw "ThreadPool constructor requires doWork argument.";
		}

		__jobQueue.add(new ThreadEvent(WORK, state != null ? state : {}));
		completed = false;
		canceled = false;

		if (!Application.current.onUpdate.has(__update))
		{
			Application.current.onUpdate.add(__update);
		}
	}

	#if lime_threads
	/**
		__Run this only on a background thread.__

		Retrieves jobs using `Thread.readMessage()`, runs them until complete,
		and repeats.

		Before any jobs, this function requires, in order:

		1. A `WorkOutput` instance. (Omit this message in HTML5.)
		2. The `doWork` function.
	**/
	private static function __executeThread():Void
	{
		JSAsync.async({
			var output:WorkOutput = #if html5 new WorkOutput(MULTI_THREADED) #else cast(Thread.readMessage(true), WorkOutput) #end;
			var doWork:WorkFunction<State->WorkOutput->Void> = Thread.readMessage(true);
			var job:ThreadEvent = null;

			while (true)
			{
				// Get a job.
				if (job == null)
				{
					do
					{
						job = Thread.readMessage(true);
					}
					while (!Std.isOfType(job, ThreadEvent));

					output.resetJobProgress();
				}

				if (job.event == EXIT)
				{
					return;
				}

				if (job.event != WORK || job.state == null)
				{
					job = null;
					continue;
				}

				// Get to work.
				var interruption:Dynamic = null;
				try
				{
					while (!output.__jobComplete.value && (interruption = Thread.readMessage(false)) == null)
					{
						output.workIterations.value++;
						doWork.dispatch(job.state, output);
					}
				}
				catch (e)
				{
					output.sendError(e);
				}

				if (interruption == null || output.__jobComplete.value)
				{
					job = null;
				}
				else if(Std.isOfType(interruption, ThreadEvent))
				{
					job = interruption;
					output.resetJobProgress();
				}
				else
				{
					// Ignore interruption and keep working.
				}

				// Do it all again.
			}
		});
	}
	#end

	private inline function timestamp():Float
	{
		#if sys
		return Sys.cpuTime();
		#else
		return haxe.Timer.stamp();
		#end
	}

	/**
		Schedules (in multi-threaded mode) or runs (in single-threaded mode) the
		job queue, then processes incoming events.
	**/
	private function __update(deltaTime:Int):Void
	{
		#if (lime_threads && !html5)
		if (Thread.current() != __mainThread)
		{
			return;
		}
		#end

		// Process the queue.
		while (!__jobQueue.isEmpty() && activeJobs < maxThreads)
		{
			var job:ThreadEvent = __jobQueue.pop();
			if (job.event != WORK)
			{
				continue;
			}

			var activeJob:ActiveJob = new ActiveJob(job);
			__activeJobs.push(activeJob);

			#if lime_threads
			if (mode == MULTI_THREADED)
			{
				var thread:Thread = __idleThreads.isEmpty() ? createThread(__executeThread) : __idleThreads.pop();
				thread.sendMessage(job);
				activeJob.thread = thread;
			}
			#end
		}

		// Run the next single-threaded job.
		if (mode == SINGLE_THREADED && activeJobs > 0)
		{
			__activeJob = __activeJobs.pop();

			__jobComplete.value = false;
			workIterations.value = 0;

			try
			{
				var endTime:Float = timestamp() + __workPerFrame;
				do
				{
					workIterations.value++;
					__doWork.dispatch(__activeJob.workEvent.state, this);
				}
				while (!__jobComplete.value && timestamp() < endTime);
			}
			catch (e)
			{
				sendError(e);
			}

			// Add this job to the end of the list, to cycle through. (Not
			// optimal for performance, but the user might have a reason for
			// scheduling multiple at once.)
			if (!__jobComplete.value)
			{
				__activeJobs.add(__activeJob);
			}

			__activeJob = null;
		}

		var threadEvent:ThreadEvent;
		while ((threadEvent = __jobOutput.pop(false)) != null)
		{
			#if (lime_threads && !html5)
			if (threadEvent.associatedJob == null && threadEvent.sourceThread != null)
			{
				threadEvent.associatedJob = __activeJobs.getByThread(threadEvent.sourceThread);
			}
			#end

			if (threadEvent.associatedJob == null)
			{
				// Assume that the job was canceled.
				continue;
			}

			eventSource = threadEvent.associatedJob.workEvent.state;

			switch (threadEvent.event)
			{
				case WORK:
					onRun.dispatch(threadEvent.state);

				case PROGRESS:
					onProgress.dispatch(threadEvent.state);

				case COMPLETE, ERROR:
					// Remember that the listener could queue a new job.
					if (threadEvent.event == COMPLETE)
					{
						onComplete.dispatch(threadEvent.state);

						completed = activeJobs == 0 && __jobQueue.isEmpty();
					}
					else
					{
						onError.dispatch(threadEvent.state);
					}

					// The single-threaded code removes from `__activeJobs`, so
					// we only have to address multi-threaded here.
					#if lime_threads
					if (mode == MULTI_THREADED)
					{
						if (currentThreads > maxThreads || __jobQueue.isEmpty() && currentThreads > minThreads)
						{
							threadEvent.associatedJob.thread.sendMessage(new ThreadEvent(EXIT, null));
						}
						else
						{
							__idleThreads.push(threadEvent.associatedJob.thread);
						}

						__activeJobs.removeThread(threadEvent.associatedJob.thread);
					}
					#end

				default:
			}

			eventSource = null;
		}

		if (completed)
		{
			Application.current.onUpdate.remove(__update);
		}
	}

	#if lime_threads
	private override function createThread(executeThread:WorkFunction<Void->Void>):Thread
	{
		var thread:Thread = super.createThread(executeThread);
		#if !html5
		thread.sendMessage(this);
		#end
		thread.sendMessage(__doWork);

		return thread;
	}
	#end

	// Getters & Setters

	private inline function get_activeJobs():Int
	{
		return __activeJobs.length;
	}

	private inline function get_idleThreads():Int
	{
		return #if lime_threads __idleThreads.length #else 0 #end;
	}

	private inline function get_currentThreads():Int
	{
		return activeJobs + idleThreads;
	}

	// Note the distinction between `doWork` and `__doWork`: the former is for
	// backwards compatibility, while the latter is always used.
	private function get_doWork():{ add: (Dynamic->Void) -> Void }
	{
		return {
			add: function(callback:Dynamic->Void)
			{
				#if html5
				if (mode == MULTI_THREADED)
					throw "Unsupported operation; instead pass the callback to ThreadPool's constructor.";
				#end
				__doWork = #if (lime_threads && html5) { func: #end
					function(state:State, output:WorkOutput):Void
					{
						callback(state);
					}
				#if (lime_threads && html5) } #end;
			}
		};
	}

	private inline function set___doWork(value:WorkFunction<State->WorkOutput->Void>):WorkFunction<State->WorkOutput->Void>
	{
		if (currentThreads == 0)
		{
			#if (lime_threads && html5)
			if (mode == MULTI_THREADED)
			{
				value.makePortable();
			}
			#end

			return __doWork = value;
		}
		else
		{
			throw "Cannot change doWork function " + (activeJobs > 0 ? "with jobs active." : "while threads exist.");
		}
	}
}
