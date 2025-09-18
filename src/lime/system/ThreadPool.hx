package lime.system;

import lime.app.Application;
import lime.app.Event;
import lime.system.WorkOutput;
import lime.utils.Log;
#if target.threaded
import sys.thread.Deque;
import sys.thread.Thread;
#elseif cpp
import cpp.vm.Deque;
import cpp.vm.Thread;
#elseif neko
import neko.vm.Deque;
import neko.vm.Thread;
#elseif html5
import lime._internal.backend.html5.HTML5Thread as Thread;
import lime._internal.backend.html5.HTML5Thread.Transferable;

#if lime_threads_deque
#error "lime_threads_deque is not yet supported in HTML5"
#end
#end
#if (haxe_ver >= 4.1)
import haxe.Exception;
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
	#if (haxe4 && lime_threads && !html5)
	/**
		A reference to the app's main thread, for use in `isMainThread()`.
	**/
	private static var __mainThread:Thread = Thread.current();
	#end

	/**
		A rough estimate of how much of the app's time should be spent on
		single-threaded jobs, across all active `ThreadPool`s. For instance, the
		default value of 1/2 means `ThreadPool`s will attempt to use about half
		the app's available time every frame.

		The accuracy of this estimate depends on how often your work functions
		return. If you find that a `ThreadPool` is taking longer than scheduled,
		try making the work function return more often.
	**/
	public static var workLoad:Float = 1 / 2;

	/**
		__Access this only from the main thread.__

		The sum of `workPriority` values from all pools with an ongoing
		single-threaded job.
	**/
	private static var __totalWorkPriority:Float = 0;

	/**
		Returns whether the caller called this function from the main thread.
	**/
	public static inline function isMainThread():Bool
	{
		#if (html5 && lime_threads)
		return !Thread.current().isWorker();
		#elseif (haxe4 && lime_threads)
		return Thread.current() == __mainThread;
		#else
		return true;
		#end
	}

	/**
		The number of jobs actively being executed.
	**/
	public var activeJobs(get, never):Int;

	/**
		The number of jobs currently running on a background thread.
	**/
	public var activeThreads(default, null):Int = 0;

	/**
		The number of background threads in this pool, including both active and
		idle threads. Does not include threads that are shutting down.
	**/
	public var currentThreads(get, never):Int;

	/**
		The number of background threads in this pool that are currently idle,
		neither working on a job nor shutting down.
	**/
	public var idleThreads(get, never):Int;

	/**
		`idleThreads + __queuedExitEvents`
	**/
	private var __idleThreads:Int = 0;

	/**
		__Set this only from the main thread.__

		The maximum number of background threads this pool can have at once. If
		this value decreases, active jobs will still be allowed to finish.
	**/
	public var maxThreads:Int;

	/**
		__Set this only from the main thread.__

		The number of background threads that will be kept alive at all times,
		even if there's no work to do. Setting this won't immediately spin up
		new threads; you must still call `run()` to get them started.
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

	#if (haxe_ver >= 4.1)
	/**
		Dispatched on the main thread when `doWork` throws an error. Dispatched
		at most once per job.

		If no listeners have been added, instead the error will be rethrown.
	**/
	public var onUncaughtError(default, null) = new Event<Exception->Void>();
	#end

	/**
		How important this pool's single-threaded jobs are, relative to other
		pools. Pools will be allocated a share of the time per frame (see
		`workLoad`) based on their importance.

		For instance, if all pools use the default priority of 1, they will all
		run for an approximately equal amount of time each frame. If one has a
		value of 2, it will run approximately twice as long as the others.
	**/
	public var workPriority(default, set):Float = 1;

	@:deprecated("Instead pass the callback to ThreadPool.run().")
	@:noCompletion @:dox(hide) public var doWork(get, never):PseudoEvent;

	private var __doWork:WorkFunction<State->WorkOutput->Void>;

	#if lime_threads
	/**
		Jobs running or queued to run on a background thread.
	**/
	private var __multiThreadedJobs:JobArray = new JobArray();

	#if lime_threads_deque
	private var __multiThreadedQueue:JobQueue = new JobQueue();
	private var __queuedWorkEvents:Int = 0;
	#end

	private var __queuedExitEvents:Int = 0;

	private var __threads:Array<ThreadData> = [];
	#end

	/**
		Whether a job is running on the main thread, or will run during the next
		update. As long as this is true, this pool's `workPriority` will be
		included in `__totalWorkPriority`.
	**/
	private var __singleThreadedJobRunning(default, set):Bool = false;

	/**
		Jobs running or queued to run on the main thread.
	**/
	private var __singleThreadedJobs:JobArray = new JobArray();

	/**
		__Call this only from the main thread.__

		@param minThreads The number of threads that will be kept alive at all
		times, even if there's no work to do. The threads won't spin up
		immediately; only after enough calls to `run()`.
		@param maxThreads The maximum number of threads that will run at once.
		@param mode The mode jobs will run in by default. Defaults to
		`SINGLE_THREADED` in HTML5 for backwards compatibility.
	**/
	public function new(minThreads:Int = 0, maxThreads:Int = 1, mode:ThreadMode = null)
	{
		if (!isMainThread())
		{
			throw "Call new ThreadPool() only from the main thread.";
		}

		super(mode);

		this.minThreads = minThreads;
		this.maxThreads = maxThreads;
	}

	/**
		Cancels all active and queued jobs.

		Note: It isn't possible to terminate a job from the outside, so canceled
		jobs may continue to run for some time. However, any events they send
		will be ignored.
		@param error If not null, this error will be dispatched for each active
		or queued job.
	**/
	public function cancel(error:Dynamic = null):Void
	{
		if (!isMainThread())
		{
			throw "Call cancel() only from the main thread.";
		}

		#if lime_threads
		// Dispatch error events.
		if (error != null)
		{
			for (job in __multiThreadedJobs)
			{
				if (job.started)
				{
					job.duration = timestamp() - job.startTime;
				}

				activeJob = job;
				onError.dispatch(error);
				activeJob = null;
			}
		}
		__multiThreadedJobs.clear();

		#if lime_threads_deque
		// Clear the queue, then replace the `EXIT` events.
		var queuedEvent:ThreadEvent = null;
		while ((queuedEvent = __multiThreadedQueue.pop(false)) != null)
		{
			if (queuedEvent.event == EXIT)
			{
				__queuedExitEvents--;
			}
		}
		__queuedWorkEvents = 0;

		while (currentThreads > minThreads)
		{
			__multiThreadedQueue.add({event: EXIT});
			__queuedExitEvents++;
		}
		#end

		// Make all threads go idle. In `lime_threads_deque` mode, this will
		// make them check the queue. Otherwise, `__onThreadIdle()` will decide
		// which should be exited.
		for (threadID in 0...__threads.length)
		{
			var threadData:ThreadData = __threads[threadID];
			if (threadData != null && threadData.jobID != null)
			{
				threadData.thread.sendMessage({event: IDLE});
			}
		}
		#end

		// Clear single-threaded jobs.
		if (error != null)
		{
			for (job in __singleThreadedJobs)
			{
				activeJob = job;
				onError.dispatch(error);
			}
		}

		__singleThreadedJobs.clear();
		__singleThreadedJobRunning = false;

		__jobComplete.value = false;
		activeJob = null;
	}

	/**
		Cancels one active or queued job. Does not dispatch an error event.

		Note: It isn't possible to terminate a job from the outside, so the job
		may continue to run for some time. However, any events it sends will be
		ignored.
		@return Whether a job was canceled.
	**/
	public function cancelJob(jobID:Int):Bool
	{
		if (__singleThreadedJobs.removeJob(jobID) != null)
		{
			__singleThreadedJobRunning = __singleThreadedJobs.length > 0;
			return true;
		}

		#if lime_threads
		var job:JobData = __multiThreadedJobs.removeJob(jobID);
		if (job != null)
		{
			for (threadData in __threads)
			{
				if (threadData != null && threadData.jobID == jobID)
				{
					threadData.thread.sendMessage({event: IDLE});
					break;
				}
			}
			return true;
		}
		#end

		return false;
	}

	/**
		Alias for `ThreadPool.run()`.
	**/
	@:noCompletion public inline function queue(doWork:WorkFunction<State->WorkOutput->Void> = null, state:State = null):Int
	{
		return run(doWork, state);
	}

	/**
		Runs the given function asynchronously, or queues it for later if no
		more threads are available.
		@param doWork The function to run. For best results, see the guidelines
		in the `ThreadPool` class overview. In brief: `doWork` should be static,
		only access its arguments, and return often.
		@param state An object to pass to `doWork`. Consider passing a mutable
		object so that `doWork` can save its progress.
		@param mode Which mode to run the job in. If omitted, the pool's default
		mode will be used.
		@return The job's unique ID.
	**/
	public function run(doWork:WorkFunction<State->WorkOutput->Void> = null, state:State = null, ?mode:ThreadMode = null):Int
	{
		if (!isMainThread())
		{
			throw "Call run() only from the main thread.";
		}

		if (mode == null)
		{
			mode = this.mode;
		}

		if (doWork == null)
		{
			if (__doWork == null #if html5 || mode == MULTI_THREADED #end)
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
		#if lime_threads
		if (mode == MULTI_THREADED)
		{
			__multiThreadedJobs.push(job);
			__runMultiThreadedJob(job);
		}
		else
		#end
		{
			__singleThreadedJobs.push(job);
			__singleThreadedJobRunning = true;
		}

		if (!Application.current.onUpdate.has(__update))
		{
			Application.current.onUpdate.add(__update);
		}

		return job.id;
	}

	/**
		__Call this only from the main thread.__

		Dispatches the given event immediately.
	**/
	private function __dispatchJobOutput(event:ThreadEvent):Void
	{
		var oldActiveJob:Null<JobData> = activeJob;
		activeJob = null;

		if (__singleThreadedJobs.length > 0 && event.jobID == __singleThreadedJobs.first().id)
		{
			activeJob = __singleThreadedJobs.first();
		}
		#if lime_threads
		else if ((activeJob = __multiThreadedJobs.getJob(event.jobID)) != null)
		{
			if (activeJob.started)
			{
				activeJob.duration = timestamp() - activeJob.startTime;
			}

			if (event.event == COMPLETE || event.event == ERROR || event.event == UNCAUGHT_ERROR)
			{
				__multiThreadedJobs.removeJob(activeJob.id);
			}
		}
		#end
		else if (event.jobID != null)
		{
			#if (lime_threads && lime_threads_deque)
			// `cancelJob()` can't remove the job from the queue, so instead it
			// marks it to be canceled later. (And "later" is now.)
			if (event.event == WORK && event.threadID != null)
			{
				__threads[event.threadID].thread.sendMessage({event: IDLE});
				__queuedWorkEvents--;
			}
			#end

			activeJob = oldActiveJob;
			return;
		}

		switch (event.event)
		{
			case PROGRESS:
				onProgress.dispatch(event.message);

			case COMPLETE:
				onComplete.dispatch(event.message);

			case ERROR:
				onError.dispatch(event.message);

			case UNCAUGHT_ERROR:
				var message:String;

				#if (haxe_ver >= 4.1)
				if (Std.isOfType(event.message, Exception))
				{
					if (onUncaughtError.__listeners.length > 0)
					{
						onUncaughtError.dispatch(event.message);
						message = null;
					}
					else
					{
						message = (event.message:Exception).details();
					}
				}
				else
				#end
				{
					message = Std.string(event.message);
				}

				if (message != null)
				{
					activeJob = null;
					Log.error(message);
				}

			case WORK:
				activeJob.startTime = timestamp();
				onRun.dispatch(activeJob.state);

				#if lime_threads
				var threadData = __threads[event.threadID];
				if (threadData.jobID == null)
				{
					__idleThreads--;
					activeThreads++;
				}
				threadData.jobID = event.jobID;

				#if lime_threads_deque
				__queuedWorkEvents--;
				#end
				#end

			#if lime_threads
			case IDLE:
				__onThreadIdle(event.threadID);

			case EXIT:
				var threadData:ThreadData = __threads[event.threadID];
				if (threadData.jobID != null)
					activeThreads--;
				else
					__idleThreads--;

				__threads[event.threadID] = null;
				__queuedExitEvents--;
			#end

			default:
		}

		activeJob = oldActiveJob;
	}

	public override function sendComplete(message:Dynamic = null, transferList:Array<Transferable> = null)
	{
		if (__jobComplete.value)
		{
			return;
		}
		else if (isMainThread() && activeJob == __singleThreadedJobs.first())
		{
			__jobComplete.value = true;
			__dispatchJobOutput({event: COMPLETE, message: message, jobID: activeJob.id});
		}
		else
		{
			super.sendComplete(message, transferList);
		}
	}

	public override function sendError(message:Dynamic = null, transferList:Array<Transferable> = null)
	{
		if (__jobComplete.value)
		{
			return;
		}
		else if (isMainThread() && activeJob == __singleThreadedJobs.first())
		{
			__jobComplete.value = true;
			__dispatchJobOutput({event: ERROR, message: message, jobID: activeJob.id});
		}
		else
		{
			super.sendError(message, transferList);
		}
	}

	public override function sendProgress(message:Dynamic = null, transferList:Array<Transferable> = null)
	{
		if (__jobComplete.value)
		{
			return;
		}
		else if (isMainThread() && activeJob == __singleThreadedJobs.first())
		{
			__dispatchJobOutput({event: PROGRESS, message: message, jobID: activeJob.id});
		}
		else
		{
			super.sendProgress(message, transferList);
		}
	}

	#if lime_threads
	/**
		__Run this only on a background thread.__

		Retrieves jobs using `Thread.readMessage()`, runs them until complete,
		and repeats. The first message must be `ThreadArguments`, and the rest
		must be `ThreadEvent`s.
	**/
	private static function __executeThread():Void
	{
		// @formatter:off
		JSAsync.async({
			var args:ThreadArguments = Thread.readMessage(true);
			var output:WorkOutput = #if html5 new WorkOutput(MULTI_THREADED) #else args.output #end;
			#if lime_threads_deque
			var jobQueue:JobQueue = args.queue;
			#end
			var event:ThreadEvent = null;
			var firstLoop:Bool = true;

			while (true)
			{
				// Get a job.
				if (event == null)
				{
					#if lime_threads_deque
					event = jobQueue.pop(false);
					#else
					event = Thread.readMessage(false);
					#end

					if (event == null && !firstLoop)
					{
						// Let the main thread know this thread is awaiting
						// work. Threads start out idle, so there's no need
						// during the first loop.
						output.sendThreadEvent({event: IDLE, threadID: args.threadID});
					}

					while (event == null) {
						#if lime_threads_deque
						event = jobQueue.pop(true);
						#else
						event = Thread.readMessage(true);
						#end
					}

					#if lime_threads_deque
					// Any interruptions sent in `lime_threads_deque` mode are
					// simply to make the thread check `jobQueue`. If they
					// arrive while the thread is waiting for `jobQueue.pop()`,
					// then their job is already done and they can be ignored.
					while (Thread.readMessage(false) != null) {}
					#end

					output.resetJobProgress();

					firstLoop = false;
				}

				if (event.event == EXIT)
				{
					// Quit working.
					output.sendThreadEvent({event: EXIT, threadID: args.threadID});
					#if html5
					Thread.current().destroy();
					#end
					return;
				}

				if (event.event != WORK || event.doWork == null || event.jobID == null)
				{
					// Go idle.
					event = null;
					continue;
				}

				// Get to work.
				output.activeJob = new JobData(event.doWork, event.state, event.jobID);

				var interruption:ThreadEvent = null;
				try
				{
					while (!output.__jobComplete.value && (interruption = Thread.readMessage(false)) == null)
					{
						if (output.workIterations.value == 0)
						{
							output.sendThreadEvent({event: WORK, jobID: event.jobID, threadID: args.threadID});
						}
						output.workIterations.value = output.workIterations.value + 1;
						event.doWork.dispatch(event.state, output);
					}
				}
				catch (e:#if (haxe_ver >= 4.1) Exception #else Dynamic #end)
				{
					output.sendUncaughtError(e);
				}

				output.activeJob = null;

				if (interruption == null || output.__jobComplete.value)
				{
					// Work is done; wait for more.
					event = interruption;
				}
				else
				{
					// Work on the new job.
					event = interruption;
					output.resetJobProgress();
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
		Processes the job queues, then processes incoming events.
	**/
	private function __update(deltaTime:Int):Void
	{
		if (!isMainThread())
		{
			return;
		}

		// Run single-threaded jobs.
		var endTime:Float = timestamp();
		if (__totalWorkPriority > 0)
		{
			// Lime may be run without a window.
			var frameRate:Float = 60;
			if (Application.current.window != null)
			{
				frameRate = Application.current.window.frameRate;
			}

			// `workLoad / frameRate` is the total time that pools may use per frame.
			// `workPriority / __totalWorkPriority` is this pool's fraction of that total.
			// Multiply together to get how much time this pool can spend.
			endTime += workLoad * workPriority / (frameRate * __totalWorkPriority);
		}

		var jobStartTime:Float;
		while (__singleThreadedJobs.length > 0 && (jobStartTime = timestamp()) < endTime)
		{
			activeJob = __singleThreadedJobs.first();

			if (!activeJob.started)
			{
				activeJob.startTime = jobStartTime;
				onRun.dispatch(activeJob.state);
			}

			__jobComplete.value = false;
			workIterations.value = 0;

			try
			{
				do
				{
					workIterations.value = workIterations.value + 1;
					activeJob.doWork.dispatch(activeJob.state, this);
				}
				while (!__jobComplete.value && timestamp() < endTime);
			}
			catch (e:#if (haxe_ver >= 4.1) Exception #else Dynamic #end)
			{
				__jobComplete.value = true;
				__dispatchJobOutput({event: UNCAUGHT_ERROR, message: e, jobID: activeJob.id});
			}

			var jobEndTime:Float = timestamp();

			activeJob.duration += jobEndTime - jobStartTime;

			activeJob = null;

			if (__jobComplete.value)
			{
				__singleThreadedJobs.shift();
				__singleThreadedJobRunning = __singleThreadedJobs.length > 0;
			}
		}

		#if (lime_threads && !lime_threads_deque)
		__runMultiThreadedJobs();
		#end

		// Process events.
		var threadEvent:ThreadEvent;
		while ((threadEvent = __jobOutput.pop(false)) != null)
		{
			__dispatchJobOutput(threadEvent);
		}

		if (activeJobs #if lime_threads + __queuedExitEvents #if lime_threads_deque + __queuedWorkEvents #end #end
			<= 0)
		{
			Application.current.onUpdate.remove(__update);
		}
	}

	#if lime_threads

	/**
		Handles a thread that just became idle. Depending on the circumstances,
		this may do one of three things:

		- Start the next queued job, adding it to `__multiThreadedJobs`.
		- Marks the thread as idle.
		- Exit the thread if it doesn't need to be kept.
	**/
	private function __onThreadIdle(threadID:Int):Void
	{
		if (!isMainThread())
		{
			throw "Call __onThreadIdle() only from the main thread.";
		}

		var threadData:ThreadData = __threads[threadID];
		if (threadData == null)
		{
			return;
		}

		if (threadData.jobID != null)
		{
			threadData.jobID = null;
			activeThreads--;
			__idleThreads++;
		}

		#if lime_threads_deque
		if (idleThreads - __queuedWorkEvents > minThreads)
		{
			__multiThreadedQueue.add({event: EXIT});
			__queuedExitEvents++;
		}
		#else
		__runMultiThreadedJobs();

		if (idleThreads > minThreads)
		{
			#if html5
			threadData.thread.destroy();
			__threads[threadID] = null;
			__idleThreads--;
			#else
			threadData.thread.sendMessage({event: EXIT});
			__queuedExitEvents++;
			#end
		}
		#end
	}

	private function __runMultiThreadedJob(job:JobData):Void
	{
		if (job.started)
		{
			throw "Job " + job.id + " was already started!";
		}

		#if html5
		job.doWork.makePortable();
		#end

		var threadEvent:ThreadEvent = {
			event: WORK,
			jobID: job.id,
			doWork: job.doWork,
			state: job.state
		};

		#if lime_threads_deque
		__multiThreadedQueue.add(threadEvent);
		__queuedWorkEvents++;
		if (idleThreads <= __queuedWorkEvents && currentThreads < maxThreads)
		{
			createThread(__executeThread);
		}
		#else
		var threadData:ThreadData = null;
		if (idleThreads > 0)
		{
			for (data in __threads)
			{
				if (data != null && data.jobID == null)
				{
					threadData = data;
					break;
				}
			}
		}
		if (threadData == null)
		{
			if (currentThreads >= maxThreads)
			{
				return;
			}

			var thread:Thread = createThread(__executeThread);
			for (data in __threads)
			{
				if (data.thread == thread)
				{
					threadData = data;
					break;
				}
			}
			if (threadData == null)
			{
				return;
			}
		}

		threadData.jobID = job.id;
		threadData.thread.sendMessage(threadEvent);
		__idleThreads--;
		activeThreads++;
		#end

		// Mark the job as started, even if it's only queued, to prevent
		// queueing it again. `startTime` will be updated again later, when
		// confirmation is received.
		job.startTime = 0;
	}

	#if !lime_threads_deque
	private function __runMultiThreadedJobs():Void
	{
		if (activeThreads >= maxThreads)
		{
			return;
		}
		for (job in __multiThreadedJobs)
		{
			if (!job.started)
			{
				__runMultiThreadedJob(job);
				if (activeThreads >= maxThreads)
				{
					break;
				}
			}
		}
	}
	#end

	private override function createThread(executeThread:WorkFunction<Void->Void>):Thread
	{
		var thread:Thread = super.createThread(executeThread);

		var index:Int = __threads.indexOf(null);
		if (index < 0)
		{
			index = __threads.length;
		}
		__threads[index] = {thread: thread, jobID: null};
		__idleThreads++;

		thread.sendMessage({
			#if !html5
			output: this,
			#end
			#if lime_threads_deque
			queue: __multiThreadedQueue,
			#end
			threadID: index
		});

		return thread;
	}

	#end

	// Getters & Setters

	private inline function get_activeJobs():Int
	{
		return activeThreads + (__singleThreadedJobs.length > 0 ? 1 : 0);
	}

	private inline function get_currentThreads():Int
	{
		return activeThreads + idleThreads;
	}

	private function get_doWork():PseudoEvent
	{
		return this;
	}

	private inline function get_idleThreads():Int
	{
		return __idleThreads
			#if lime_threads - __queuedExitEvents #end;
	}

	private inline function set___singleThreadedJobRunning(value:Bool):Bool
	{
		if (value != __singleThreadedJobRunning)
		{
			if (value)
			{
				__totalWorkPriority += workPriority;
			}
			else
			{
				__totalWorkPriority -= workPriority;
			}
		}
		return __singleThreadedJobRunning = value;
	}

	private function set_workPriority(value:Float):Float
	{
		if (__singleThreadedJobRunning)
		{
			__totalWorkPriority += value - workPriority;
		}
		return workPriority = value;
	}
}

@:access(lime.system.ThreadPool)
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

private class JobArray
{
	private var jobs:Array<JobData> = [];

	public var length(get, never):Int;

	/**
		The first non-null index in `jobs`.
	**/
	private var startIndex:Int = 0;

	public inline function new() {}

	public inline function clear():Void
	{
		#if haxe4
		jobs.resize(0);
		#else
		jobs.splice(0, jobs.length);
		#end
		startIndex = 0;
	}

	public inline function first():JobData
	{
		return jobs[startIndex];
	}

	public function getJob(id:Int):JobData
	{
		for (i in startIndex...jobs.length)
		{
			if (jobs[i].id == id)
			{
				return jobs[i];
			}
		}
		return null;
	}

	private inline function get_length():Int
	{
		return jobs.length - startIndex;
	}

	public inline function iterator():JobArrayIterator
	{
		return new JobArrayIterator(jobs, startIndex);
	}

	public inline function push(job:JobData):Int
	{
		return jobs.push(job);
	}

	public function removeJob(id:Int):JobData
	{
		for (i in startIndex...jobs.length)
		{
			var job:JobData = jobs[i];
			if (job.id != id)
			{
				continue;
			}

			if ((i - startIndex) * 2 <= length)
			{
				// Closer to the start; shift earlier entries +1.
				var j:Int = i;
				while (j > startIndex)
				{
					jobs[j] = jobs[j - 1];
					j--;
				}

				shift();
			}
			else
			{
				// Closer to the end; shift later entries -1.
				jobs.splice(i, 1);
			}

			return job;
		}

		return null;
	}

	public function shift():JobData
	{
		var job:JobData = jobs[startIndex];

		jobs[startIndex] = null;
		startIndex++;

		if (startIndex >= jobs.length)
		{
			clear();
		}
		else if (startIndex >= 100)
		{
			jobs.splice(0, startIndex);
			startIndex = 0;
		}

		return job;
	}
}

private class JobArrayIterator
{
	private var index:Int;
	private var jobs:Array<JobData>;

	public inline function new(jobs:Array<JobData>, startIndex:Int)
	{
		this.jobs = jobs;
		index = startIndex;
	}

	public inline function hasNext():Bool
	{
		return index < jobs.length;
	}

	public inline function next():JobData
	{
		return jobs[index++];
	}
}

#if lime_threads_deque
@:forward
private abstract JobQueue(Deque<ThreadEvent>) from Deque<ThreadEvent>
{
	public inline function new()
	{
		this = new Deque<ThreadEvent>();
	}

	// Only allow adding to the end.
	public inline function push(event:ThreadEvent):Void
	{
		this.add(event);
	}
}
#end

private typedef ThreadArguments = {
	#if !html5
	var output:WorkOutput;
	#end

	#if lime_threads_deque
	var queue:JobQueue;
	#end

	var threadID:Int;
};

#if lime_threads
private typedef ThreadData = {
	var thread:Thread;
	@:optional var jobID:Int;
};
#end
