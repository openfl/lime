package lime.system;

import lime.app.Application;
import lime.app.Event;
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
	A simple and thread-safe way to run a one or more asynchronous jobs. It
	manages a queue of jobs, starting new ones once the old ones are done.

	It can also keep a certain number of threads (configurable via `minThreads`)
	running in the background even when no jobs are available. This avoids the
	not-insignificant overhead of stopping and restarting threads.

	Sample usage:

		var threadPool:ThreadPool = new ThreadPool();
		threadPool.onComplete.add(onFileProcessed);

		threadPool.maxThreads = 3;
		for(url in urls)
		{
			threadPool.run(processFile, url);
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
class ThreadPool extends WorkOutput
{
	#if lime_threads
	/**
		A thread or null value to be compared against `Thread.current()`. Don't
		do anything with this other than check for equality.
	**/
	private static var __mainThread:Thread =
		#if html5
		!Thread.current().isWorker() ? Thread.current() : null;
		#else
		Thread.current();
		#end
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

	@:deprecated("Instead pass the callback to ThreadPool.run().")
	@:noCompletion @:dox(hide) public var doWork(get, never):{ add: (Dynamic->Void)->Void };
	private var __doWork:WorkFunction<State->WorkOutput->Void>;

	private var __activeJobs:JobList = new JobList();

	#if lime_threads
	/**
		The set of threads actively running a job.
	**/
	private var __activeThreads:Map<Int, Thread> = new Map();

	/**
		A list of idle threads. Not to be confused with `idleThreads`, a public
		variable equal to `__idleThreads.length`.
	**/
	private var __idleThreads:List<Thread> = new List();
	#end

	private var __jobQueue:JobList = new JobList();

	private var __workPerFrame:Float;

	/**
		__Call this only from the main thread.__

		@param doWork A single function capable of performing all of this pool's
		jobs. Always provide `doWork`, even though it's marked as optional.
		@param mode Defaults to `MULTI_THREADED` on most targets, but
		`SINGLE_THREADED` in HTML5. In HTML5, `MULTI_THREADED` mode uses web
		workers, which impose additional restrictions.
		@param workLoad (Single-threaded mode only) A rough estimate of how much
		of the app's time should be spent on this `ThreadPool`. For instance,
		the default value of 1/2 means this worker will take up about half the
		app's available time every frame. See `workIterations` for instructions
		to improve the accuracy of this estimate.
	**/
	public function new(minThreads:Int = 0, maxThreads:Int = 1, mode:ThreadMode = null, workLoad:Float = 1/2)
	{
		super(mode);

		__workPerFrame = workLoad / Application.current.window.frameRate;

		this.minThreads = minThreads;
		this.maxThreads = maxThreads;
	}

	/**
		Cancels all active and queued jobs. In multi-threaded mode, leaves
		`minThreads` idle threads running.
		@param error If not null, this error will be dispatched for each active
		or queued job.
	**/
	public function cancel(error:Dynamic = null):Void
	{
		#if lime_threads
		if (Thread.current() != __mainThread)
		{
			throw "Call cancel() only from the main thread.";
		}
		#end

		Application.current.onUpdate.remove(__update);

		// Cancel active jobs, leaving `minThreads` idle threads.
		for (job in __activeJobs)
		{
			#if lime_threads
			if (mode == MULTI_THREADED)
			{
				var thread:Thread = __activeThreads[job.id];
				if (idleThreads < minThreads)
				{
					thread.sendMessage(new ThreadEvent(WORK, null, null));
					__idleThreads.push(thread);
				}
				else
				{
					thread.sendMessage(new ThreadEvent(EXIT, null, null));
				}
			}
			#end

			if (error != null)
			{
				if (job.duration == 0)
				{
					job.duration = timestamp() - job.startTime;
				}

				activeJob = job;
				onError.dispatch(error);
				activeJob = null;
			}
		}
		__activeJobs.clear();

		#if lime_threads
		// Cancel idle threads if there are more than the minimum.
		while (idleThreads > minThreads)
		{
			__idleThreads.pop().sendMessage(new ThreadEvent(EXIT, null, null));
		}
		#end

		// Clear the job queue.
		if (error != null)
		{
			for (job in __jobQueue)
			{
				activeJob = job;
				onError.dispatch(error);
			}
		}
		__jobQueue.clear();

		__jobComplete.value = false;
		activeJob = null;
		completed = false;
		canceled = true;
	}

	/**
		Cancels one active or queued job. Does not dispatch an error event.
		@param job A `JobData` object, or a job's unique `id`, `state`, or
		`doWork` function.
		@return Whether a job was canceled.
	**/
	public function cancelJob(job:JobIdentifier):Bool
	{
		var data:JobData = __activeJobs.get(job);

		if (data != null)
		{
			#if lime_threads
			var thread:Thread = __activeThreads[data.id];
			if (thread != null)
			{
				thread.sendMessage(new ThreadEvent(WORK, null, null));
				__activeThreads.remove(data.id);
				__idleThreads.push(thread);
			}
			#end

			return __activeJobs.remove(data);
		}

		return __jobQueue.remove(__jobQueue.get(job));
	}

	/**
		Alias for `ThreadPool.run()`.
	**/
	@:noCompletion public inline function queue(doWork:WorkFunction<State->WorkOutput->Void> = null, state:State = null):Int
	{
		return run(doWork, state);
	}

	/**
		Queues a new job, to be run once a thread becomes available.
		@return The job's unique ID.
	**/
	public function run(doWork:WorkFunction<State->WorkOutput->Void> = null, state:State = null):Int
	{
		#if lime_threads
		if (Thread.current() != __mainThread)
		{
			throw "Call run() only from the main thread.";
		}
		#end

		if (doWork == null)
		{
			if (__doWork == null)
			{
				throw "run() requires doWork argument.";
			}
			else
			{
				doWork = __doWork;
			}
		}

		if (state == null)
		{
			state = {};
		}

		var job:JobData = new JobData(doWork, state);
		__jobQueue.add(job);
		completed = false;
		canceled = false;

		if (!Application.current.onUpdate.has(__update))
		{
			Application.current.onUpdate.add(__update);
		}

		return job.id;
	}

	#if lime_threads
	/**
		__Run this only on a background thread.__

		Retrieves jobs using `Thread.readMessage()`, runs them until complete,
		and repeats.

		On all targets besides HTML5, the first message must be a `WorkOutput`.
	**/
	private static function __executeThread():Void
	{
		JSAsync.async({
			var output:WorkOutput = #if html5 new WorkOutput(MULTI_THREADED) #else cast(Thread.readMessage(true), WorkOutput) #end;
			var event:ThreadEvent = null;

			while (true)
			{
				// Get a job.
				if (event == null)
				{
					do
					{
						event = Thread.readMessage(true);
					}
					while (!Std.isOfType(event, ThreadEvent));

					output.resetJobProgress();
				}

				if (event.event == EXIT)
				{
					// Quit working.
					#if html5
					Thread.current().destroy();
					#end
					return;
				}

				if (event.event != WORK || event.job == null)
				{
					// Go idle.
					event = null;
					continue;
				}

				// Get to work.
				output.activeJob = event.job;

				var interruption:Dynamic = null;
				try
				{
					while (!output.__jobComplete.value && (interruption = Thread.readMessage(false)) == null)
					{
						output.workIterations.value++;
						event.job.doWork.dispatch(event.job.state, output);
					}
				}
				catch (e)
				{
					output.sendError(e);
				}

				output.activeJob = null;

				if (interruption == null || output.__jobComplete.value)
				{
					// Work is done; wait for more.
					event = null;
				}
				else if(Std.isOfType(interruption, ThreadEvent))
				{
					// Work on the new job.
					event = interruption;
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

	private static inline function timestamp():Float
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
		#if lime_threads
		if (Thread.current() != __mainThread)
		{
			return;
		}
		#end

		// Process the queue.
		while (!__jobQueue.isEmpty() && activeJobs < maxThreads)
		{
			var job:JobData = __jobQueue.pop();

			job.startTime = timestamp();
			__activeJobs.push(job);

			#if lime_threads
			if (mode == MULTI_THREADED)
			{
				#if html5
				job.doWork.makePortable();
				#end

				var thread:Thread = __idleThreads.isEmpty() ? createThread(__executeThread) : __idleThreads.pop();
				__activeThreads[job.id] = thread;
				thread.sendMessage(new ThreadEvent(WORK, null, job));
			}
			#end
		}

		// Run the next single-threaded job.
		if (mode == SINGLE_THREADED && activeJobs > 0)
		{
			activeJob = __activeJobs.pop();
			var state:State = activeJob.state;

			__jobComplete.value = false;
			workIterations.value = 0;

			var startTime:Float = timestamp();
			var timeElapsed:Float = 0;
			try
			{
				do
				{
					workIterations.value++;
					activeJob.doWork.dispatch(state, this);
					timeElapsed = timestamp() - startTime;
				}
				while (!__jobComplete.value && timeElapsed < __workPerFrame);
			}
			catch (e)
			{
				sendError(e);
			}

			activeJob.duration += timeElapsed;

			// Add this job to the end of the list, to cycle through.
			__activeJobs.add(activeJob);

			activeJob = null;
		}

		var threadEvent:ThreadEvent;
		while ((threadEvent = __jobOutput.pop(false)) != null)
		{
			if (!__activeJobs.exists(threadEvent.job))
			{
				// Ignore events from canceled jobs.
				continue;
			}

			// Get by ID because in HTML5, the object will have been cloned,
			// which will interfere with attempts to test equality.
			activeJob = __activeJobs.getByID(threadEvent.job.id);

			if (mode == MULTI_THREADED)
			{
				activeJob.duration = timestamp() - activeJob.startTime;
			}

			switch (threadEvent.event)
			{
				case WORK:
					onRun.dispatch(threadEvent.message);

				case PROGRESS:
					onProgress.dispatch(threadEvent.message);

				case COMPLETE, ERROR:
					if (threadEvent.event == COMPLETE)
					{
						onComplete.dispatch(threadEvent.message);
					}
					else
					{
						onError.dispatch(threadEvent.message);
					}

					__activeJobs.remove(activeJob);

					#if lime_threads
					if (mode == MULTI_THREADED)
					{
						var thread:Thread = __activeThreads[activeJob.id];
						__activeThreads.remove(activeJob.id);

						if (currentThreads > maxThreads || __jobQueue.isEmpty() && currentThreads > minThreads)
						{
							thread.sendMessage(new ThreadEvent(EXIT, null, null));
						}
						else
						{
							__idleThreads.push(thread);
						}
					}
					#end

					completed = threadEvent.event == COMPLETE && activeJobs == 0 && __jobQueue.isEmpty();

				default:
			}

			activeJob = null;
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
}

@:forward @:forward.new
abstract JobList(List<JobData>)
{
	public inline function exists(job:JobData):Bool
	{
		return getByID(job.id) != null;
	}

	public inline function remove(job:JobData):Bool
	{
		return this.remove(job) || removeByID(job.id);
	}

	public inline function removeByID(id:Int):Bool
	{
		return this.remove(getByID(id));
	}

	public function getByID(id:Int):JobData
	{
		for (job in this)
		{
			if (job.id == id)
			{
				return job;
			}
		}
		return null;
	}

	public function get(jobIdentifier:JobIdentifier):JobData
	{
		switch (jobIdentifier)
		{
			case ID(id):
				return getByID(id);
			case FUNCTION(doWork):
				for (job in this)
				{
					if (job.doWork == doWork)
					{
						return job;
					}
				}
			case STATE(state):
				for (job in this)
				{
					if (job.state == state)
					{
						return job;
					}
				}
		}
		return null;
	}
}

/**
	A piece of data that uniquely represents a job. This can be the integer ID
	(and integers will be assumed to be such), the `doWork` function, or the
	`JobData` object itself. Failing any of those, a value will be assumed to be
	the job's `state`.

	Caution: if the provided data isn't unique, such as a `doWork` function
	that's in use by multiple jobs, the wrong job may be selected or canceled.
**/
@:forward
abstract JobIdentifier(JobIdentifierImpl) from JobIdentifierImpl {
	@:from private static inline function fromJob(job:JobData):JobIdentifier {
		return ID(job.id);
	}
	@:from private static inline function fromID(id:Int):JobIdentifier {
		return ID(id);
	}
	@:from private static inline function fromFunction(doWork:WorkFunction<State->WorkOutput->Void>):JobIdentifier {
		return FUNCTION(doWork);
	}
	@:from private static inline function fromState(state:State):JobIdentifier {
		return STATE(state);
	}
}

private enum JobIdentifierImpl
{
	ID(id:Int);
	FUNCTION(doWork:WorkFunction<State->WorkOutput->Void>);
	STATE(state:State);
}
