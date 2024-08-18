package lime.system;

import lime.app.Application;
import lime.app.Event;
import lime.system.WorkOutput;
import lime.utils.Log;
#if target.threaded
import sys.thread.Thread;
#elseif (cpp || webassembly)
import cpp.vm.Thread;
#elseif neko
import neko.vm.Thread;
#elseif html5
import lime._internal.backend.html5.HTML5Thread as Thread;
#end

/**
	A thread pool executes one or more functions asynchronously.

	In multi-threaded mode, jobs run on background threads. In HTML5, this means
	using web workers, which impose additional restrictions (see below). In
	single-threaded mode, jobs run between frames on the main thread. To avoid
	blocking, these jobs should only do a small amount of work at a time.

	In multi-threaded mode, the pool spins up new threads as jobs arrive (up to
	`maxThreads`). If too many jobs arrive at once, it places them in a queue to
	run when threads open up. If you run jobs frequently but not constantly, you
	can also set `minThreads` to keep a certain number of threads alive,
	avoiding the overhead of repeatedly spinning them up.

	Sample usage:

		var threadPool:ThreadPool = new ThreadPool();
		threadPool.onComplete.add(onFileProcessed);

		threadPool.maxThreads = 3;
		for(url in urls)
		{
			threadPool.run(processFile, url);
		}

	If upgrading from `BackgroundWorker`, you can use `ThreadPool` as a drop-in
	replacement. It will then display some deprecation warnings indicating which
	steps to take next.

	---

	Guidelines to make your code work on all targets and configurations:

	- For thread safety and web worker compatibility, your work function should
	  only return data through the `WorkOutput` object it receives.
	- For web worker compatibility, you should only send data to your work
	  function via the `State` object. But since this can be any object, you can
	  put an arbitrary amount of data there.
	- For web worker compatibility, your work function must be static, and you
	  can't `bind()` any extra arguments.
	- For single-threaded performance, your function should only do a small
	  amount of work at a time. Store progress in the `State` object so you can
	  pick up where you left off. You don't have to worry about timing: just aim
	  to take a small fraction of the frame's time, and `ThreadPool` will keep
	  running the function until enough time passes.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class ThreadPool extends WorkOutput
{
	#if (haxe4 && lime_threads)
	/**
		A thread or null value to be compared against `Thread.current()`. Don't
		do anything with this other than check for equality.

		Unavailable in Haxe 3 as thread equality checking doesn't work there.
	**/
	private static var __mainThread:Thread =
		#if html5
		!Thread.current().isWorker() ? Thread.current() : null;
		#else
		Thread.current();
		#end
	#end

	/**
		A rough estimate of how much of the app's time should be spent on
		single-threaded `ThreadPool`s. For instance, the default value of 1/2
		means they will aim to take up about half the app's available time every
		frame. See `workIterations` for instructions to improve the accuracy of
		this estimate.
	**/
	public static var workLoad:Float = 1 / 2;

	/**
		__Access this only from the main thread.__

		The sum of all active single-threaded pools' `workPriority` values.
	**/
	@:allow(lime.system.JobList)
	private static var __totalWorkPriority:Float = 0;

	/**
		Returns whether the caller called this function from the main thread.
	**/
	public static inline function isMainThread():Bool
	{
		#if (haxe4 && lime_threads)
		return Thread.current() == __mainThread;
		#else
		return true;
		#end
	}

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
		(Single-threaded mode only.) How important this pool's jobs are relative
		to other single-threaded pools.

		For instance, if all pools use the default priority of 1, they will all
		run for an approximately equal amount of time each frame. If one has a
		value of 2, it will run approximately twice as long as the others.
	**/
	public var workPriority(default, set):Float = 1;

	@:deprecated("Instead pass the callback to ThreadPool.run().")
	@:noCompletion @:dox(hide) public var doWork(get, never):PseudoEvent;

	private var __doWork:WorkFunction<State->WorkOutput->Void>;

	private var __activeJobs:JobList;

	#if lime_threads
	/**
		The set of threads actively running a job.
	**/
	private var __activeThreads:Map<Int, Thread>;

	/**
		A list of idle threads. Not to be confused with `idleThreads`, a public
		variable equal to `__idleThreads.length`.
	**/
	private var __idleThreads:Array<Thread>;
	#end

	private var __jobQueue:JobList = new JobList();

	/**
		__Call this only from the main thread.__

		@param minThreads The number of threads that will be kept alive at all
		times, even if there's no work to do. The threads won't spin up
		immediately; only after enough calls to `run()`. Only applies in
		multi-threaded mode.
		@param maxThreads The maximum number of threads that will run at once.
		@param mode Defaults to `MULTI_THREADED` on most targets, but
		`SINGLE_THREADED` in HTML5. In HTML5, `MULTI_THREADED` mode uses web
		workers, which impose additional restrictions.
	**/
	public function new(minThreads:Int = 0, maxThreads:Int = 1, mode:ThreadMode = null)
	{
		super(mode);

		__activeJobs = new JobList(this);

		this.minThreads = minThreads;
		this.maxThreads = maxThreads;

		#if lime_threads
		if (this.mode == MULTI_THREADED)
		{
			__activeThreads = new Map();
			__idleThreads = [];
		}
		#end
	}

	/**
		Cancels all active and queued jobs. In multi-threaded mode, leaves
		`minThreads` idle threads running.
		@param error If not null, this error will be dispatched for each active
		or queued job.
	**/
	public function cancel(error:Dynamic = null):Void
	{
		if (!isMainThread())
		{
			throw "Call cancel() only from the main thread.";
		}

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
					thread.sendMessage({event: CANCEL});
					__idleThreads.push(thread);
				}
				else
				{
					thread.sendMessage({event: EXIT});
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
		// Exit idle threads if there are more than the minimum.
		while (idleThreads > minThreads)
		{
			__idleThreads.pop().sendMessage({event: EXIT});
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
				thread.sendMessage({event: CANCEL});
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
		if (!isMainThread())
		{
			throw "Call run() only from the main thread.";
		}

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
		__jobQueue.push(job);
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
		// @formatter:off
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
					while (event == null || !Reflect.hasField(event, "event"));

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
				catch (e:#if (haxe_ver >= 4.1) haxe.Exception #else Dynamic #end)
				{
					output.sendError(e);
				}

				output.activeJob = null;

				if (interruption == null || output.__jobComplete.value)
				{
					// Work is done; wait for more.
					event = interruption;
				}
				else if (Reflect.hasField(interruption, "event"))
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
		// @formatter:on
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
		if (!isMainThread())
		{
			return;
		}

		// Process the queue.
		while (__jobQueue.length > 0 && activeJobs < maxThreads)
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

				var thread:Thread = __idleThreads.length == 0 ? createThread(__executeThread) : __idleThreads.pop();
				__activeThreads[job.id] = thread;
				thread.sendMessage({event: WORK, job: job});
			}
			#end
		}

		// Run the next single-threaded job, if any.
		if (mode == SINGLE_THREADED && __activeJobs.hasNext())
		{
			activeJob = __activeJobs.next();
			var state:State = activeJob.state;

			__jobComplete.value = false;
			workIterations.value = 0;

			// `workLoad / frameRate` is the total time that pools may use per
			// frame. `workPriority / __totalWorkPriority` is this pool's
			// fraction of that total.
			var maxTimeElapsed:Float = workPriority * workLoad / (__totalWorkPriority * Application.current.window.frameRate);

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
				while (!__jobComplete.value && timeElapsed < maxTimeElapsed);
			}
			catch (e:#if (haxe_ver >= 4.1) haxe.Exception #else Dynamic #end)
			{
				sendError(e);
			}

			activeJob.duration += timeElapsed;

			activeJob = null;
		}

		var threadEvent:ThreadEvent;
		while ((threadEvent = __jobOutput.pop(false)) != null)
		{
			if (threadEvent.jobID != null)
			{
				activeJob = __activeJobs.getByID(threadEvent.jobID);
			}
			else
			{
				activeJob = threadEvent.job;
			}

			if (activeJob == null || !__activeJobs.exists(activeJob))
			{
				continue;
			}

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

						if (currentThreads > maxThreads || __jobQueue.length == 0 && currentThreads > minThreads)
						{
							thread.sendMessage({event: EXIT});
						}
						else
						{
							__idleThreads.push(thread);
						}
					}
					#end

					completed = threadEvent.event == COMPLETE && activeJobs == 0 && __jobQueue.length == 0;

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
	private function get_doWork():PseudoEvent
	{
		return this;
	}

	private function set_workPriority(value:Float):Float
	{
		if (mode == SINGLE_THREADED && activeJobs > 0)
		{
			__totalWorkPriority += value - workPriority;
		}
		return workPriority = value;
	}
}

@:access(lime.system.ThreadPool) @:forward(canceled)
private abstract PseudoEvent(ThreadPool) from ThreadPool
{
	@:noCompletion @:dox(hide) public var __listeners(get, never):Array<Dynamic>;

	private inline function get___listeners():Array<Dynamic>
	{
		return [];
	};

	@:noCompletion @:dox(hide) public var __repeat(get, never):Array<Bool>;

	private inline function get___repeat():Array<Bool>
	{
		return [];
	};

	public function add(callback:Dynamic->Void):Void
	{
		function callCallback(state:State, output:WorkOutput):Void
		{
			callback(state);
		}

		#if (lime_threads && html5)
		if (this.mode == MULTI_THREADED) throw "Unsupported operation; instead pass the callback to ThreadPool's constructor.";
		else
			this.__doWork = {func: callCallback};
		#else
		this.__doWork = callCallback;
		#end
	}

	public inline function cancel():Void {}

	public inline function dispatch():Void {}

	public inline function has(callback:Dynamic->Void):Bool
	{
		return this.__doWork != null;
	}

	public inline function remove(callback:Dynamic->Void):Void
	{
		this.__doWork = null;
	}

	public inline function removeAll():Void
	{
		this.__doWork = null;
	}
}

class JobList
{
	/**
	 * Whether `pool.workPriority` is being added to
	 * `ThreadPool.__totalWorkPriority`. Set this to true when `length > 0` and
	 * false when `length == 0`. The setter will ensure it is only added once.
	 */
	@:allow(lime.system.ThreadPool)
	private var __addingWorkPriority(default, set):Bool;

	private var __index:Int = 0;

	private var __jobs:Array<JobData> = [];

	public var length(get, never):Int;

	public var pool(default, null):ThreadPool;

	public inline function new(?pool:ThreadPool)
	{
		this.pool = pool;
		@:bypassAccessor __addingWorkPriority = false;
	}

	public inline function clear():Void
	{
		#if haxe4
		__jobs.resize(0);
		#else
		__jobs = [];
		#end
		__addingWorkPriority = false;
	}

	public inline function exists(job:JobData):Bool
	{
		return getByID(job.id) != null;
	}

	public inline function hasNext():Bool
	{
		return __jobs.length > 0;
	}

	/**
		Iterates in an endless loop, starting over upon reaching the end.
	**/
	public inline function next():JobData
	{
		__index++;
		if (__index >= length)
		{
			__index = 0;
		}

		return __jobs[__index];
	}

	public inline function pop():JobData
	{
		var job:JobData = __jobs.pop();
		__addingWorkPriority = length > 0;
		return job;
	}

	public function remove(job:JobData):Bool
	{
		if (__jobs.remove(job))
		{
			__addingWorkPriority = length > 0;
			return true;
		}
		else if (removeByID(job.id))
		{
			return true;
		}
		else
		{
			return false;
		}
	}

	public inline function removeByID(id:Int):Bool
	{
		if (__jobs.remove(getByID(id)))
		{
			__addingWorkPriority = length > 0;
			return true;
		}
		else
		{
			return false;
		}
	}

	public function getByID(id:Int):JobData
	{
		for (job in __jobs)
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
				for (job in __jobs)
				{
					if (job.doWork == doWork)
					{
						return job;
					}
				}
			case STATE(state):
				for (job in __jobs)
				{
					if (job.state == state)
					{
						return job;
					}
				}
		}
		return null;
	}

	public inline function push(job:JobData):Void
	{
		__jobs.push(job);
		__addingWorkPriority = true;
	}

	// Getters & Setters

	private inline function set___addingWorkPriority(value:Bool):Bool
	{
		if (pool != null && __addingWorkPriority != value && ThreadPool.isMainThread())
		{
			if (value)
			{
				ThreadPool.__totalWorkPriority += pool.workPriority;
			}
			else
			{
				ThreadPool.__totalWorkPriority -= pool.workPriority;
			}
			return __addingWorkPriority = value;
		}
		else
		{
			return __addingWorkPriority;
		}
	}

	private inline function get_length():Int
	{
		return __jobs.length;
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
abstract JobIdentifier(JobIdentifierImpl) from JobIdentifierImpl
{
	@:from private static inline function fromJob(job:JobData):JobIdentifier
	{
		return ID(job.id);
	}

	@:from private static inline function fromID(id:Int):JobIdentifier
	{
		return ID(id);
	}

	@:from private static inline function fromFunction(doWork:WorkFunction<State->WorkOutput->Void>):JobIdentifier
	{
		return FUNCTION(doWork);
	}

	@:from private static inline function fromState(state:State):JobIdentifier
	{
		return STATE(state);
	}
}

private enum JobIdentifierImpl
{
	ID(id:Int);
	FUNCTION(doWork:WorkFunction<State->WorkOutput->Void>);
	STATE(state:State);
}
