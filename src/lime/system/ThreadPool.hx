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
		means they'll use about half the app's available time every frame.

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
		#if (haxe4 && lime_threads)
		return Thread.current() == __mainThread;
		#else
		return true;
		#end
	}

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
	**/
	public var maxThreads:Int;

	/**
		__Set this only from the main thread.__

		The number of threads that will be kept alive at all times, even if
		there's no work to do. Setting this won't immediately spin up new
		threads; you must still call `run()` to get them started.
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

	#if lime_threads
	/**
		A list of idle threads. Not to be confused with `idleThreads`, a public
		variable equal to `__idleThreads.length`.
	**/
	private var __idleThreads:Array<Thread> = [];

	private var __multiThreadedJobs:JobArray = [];
	private var __multiThreadedQueue:JobArray = [];
	#end

	private var __singleThreadedJob(default, set):JobData;
	private var __singleThreadedQueue:JobArray = [];

	/**
		__Call this only from the main thread.__

		@param minThreads The number of threads that will be kept alive at all
		times, even if there's no work to do. The threads won't spin up
		immediately; only after enough calls to `run()`. Only applies in
		multi-threaded mode.
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

		#if lime_threads
		// Cancel active jobs, leaving `minThreads` idle threads.
		for (job in __multiThreadedJobs)
		{
			if (mode == MULTI_THREADED)
			{
				var thread:Thread = job.thread;
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
		__multiThreadedJobs.clear();

		// Exit idle threads if there are more than the minimum.
		while (idleThreads > minThreads)
		{
			__idleThreads.pop().sendMessage({event: EXIT});
		}
		#end

		if (__singleThreadedJob != null && error != null)
		{
			activeJob = __singleThreadedJob;
			onError.dispatch(error);
			activeJob = null;
		}
		__singleThreadedJob = null;

		// Clear the job queues.
		if (error != null)
		{
			for (job in __singleThreadedQueue)
			{
				activeJob = job;
				onError.dispatch(error);
			}
			#if lime_threads
			for (job in __multiThreadedQueue)
			{
				activeJob = job;
				onError.dispatch(error);
			}
			#end
		}
		__singleThreadedQueue.clear();
		#if lime_threads
		__multiThreadedQueue.clear();
		#end

		__jobComplete.value = false;
		activeJob = null;
	}

	/**
		Cancels one active or queued job. Does not dispatch an error event.
		@return Whether a job was canceled.
	**/
	public function cancelJob(jobID:Int):Bool
	{
		if (__singleThreadedJob != null && __singleThreadedJob.id == jobID)
		{
			__singleThreadedJob = null;
			return true;
		}
		else if (__singleThreadedQueue.removeJob(jobID) != null)
		{
			return true;
		}

		#if lime_threads
		var job:JobData = __multiThreadedJobs.removeJob(jobID);
		if (job != null)
		{
			if (job.thread != null)
			{
				job.thread.sendMessage({event: CANCEL});
				__idleThreads.push(job.thread);
			}
			return true;
		}

		return __multiThreadedQueue.removeJob(jobID) != null;
		#else
		return false;
		#end
	}

	/**
		Alias for `ThreadPool.run()`.
	**/
	@:noCompletion public inline function queue(doWork:WorkFunction<State->WorkOutput->Void> = null, state:State = null):Int
	{
		return run(doWork, state);
	}

	/**
		Runs the given function asynchronously, or queues it for later if all
		threads are busy.
		@param doWork The function to run. For best results, see the guidelines
		in the `ThreadPool` class overview. In brief: `doWork` should be static,
		only access its arguments, and return often.
		@param state An object to pass to `doWork`, ideally a mutable object so
		that `doWork` can save its progress.
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
		#if lime_threads
		if (mode == MULTI_THREADED || mode == null && this.mode == MULTI_THREADED)
		{
			__multiThreadedQueue.push(job);
		}
		else
		#end
		{
			__singleThreadedQueue.push(job);
		}

		if (!Application.current.onUpdate.has(__update))
		{
			Application.current.onUpdate.add(__update);
		}

		__startJobs();

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

				if (event.event != WORK || event.doWork == null || event.jobID == null)
				{
					// Go idle.
					event = null;
					continue;
				}

				// Get to work.
				output.activeJob = new JobData(event.doWork, event.state, event.jobID);

				var interruption:Dynamic = null;
				try
				{
					while (!output.__jobComplete.value && (interruption = Thread.readMessage(false)) == null)
					{
						output.workIterations.value++;
						event.doWork.dispatch(event.state, output);
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
		Processes the job queues, starting any jobs that can be started.
	**/
	private function __startJobs():Void
	{
		if (!isMainThread())
		{
			return;
		}

		if (__singleThreadedJob == null && __singleThreadedQueue.length > 0)
		{
			__singleThreadedJob = __singleThreadedQueue.shift();
			__singleThreadedJob.startTime = timestamp();
		}

		#if lime_threads
		for (job in __multiThreadedQueue)
		{
			if (__multiThreadedJobs.length >= maxThreads)
			{
				break;
			}

			#if html5
			job.doWork.makePortable();
			#end

			job.thread = __idleThreads.length == 0 ? createThread(__executeThread) : __idleThreads.pop();
			job.thread.sendMessage({event: WORK, jobID: job.id, doWork: job.doWork, state: job.state});
			job.startTime = timestamp();

			__multiThreadedJobs.push(job);
			__multiThreadedQueue.remove(job);
		}
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

		__startJobs();

		// Run the single-threaded job.
		if (__singleThreadedJob != null)
		{
			activeJob = __singleThreadedJob;
			var state:State = activeJob.state;

			__jobComplete.value = false;
			workIterations.value = 0;

			// `workLoad / frameRate` is the total time that pools may use per frame.
			// `workPriority / __totalWorkPriority` is this pool's fraction of that total.
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
			var activeJobMode:ThreadMode = SINGLE_THREADED;
			if (__singleThreadedJob != null && threadEvent.jobID == __singleThreadedJob.id)
			{
				activeJob = __singleThreadedJob;
			}
			else
			{
				#if lime_threads
				activeJob = __multiThreadedJobs.getJob(threadEvent.jobID);
				activeJobMode = MULTI_THREADED;
				#else
				continue;
				#end
			}

			if (activeJob == null)
			{
				continue;
			}

			#if lime_threads
			if (activeJobMode == MULTI_THREADED)
			{
				activeJob.duration = timestamp() - activeJob.startTime;
			}
			#end

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

					#if lime_threads
					if (activeJobMode == MULTI_THREADED)
					{
						__multiThreadedJobs.remove(activeJob);

						if (currentThreads > maxThreads || currentThreads - __multiThreadedQueue.length > minThreads)
						{
							activeJob.thread.sendMessage({event: EXIT});
						}
						else
						{
							__idleThreads.push(activeJob.thread);
						}
					}
					else
					#end
					{
						__singleThreadedJob = null;
					}

				default:
			}

			activeJob = null;
		}

		if (0 == activeJobs + __singleThreadedQueue.length #if lime_threads + __multiThreadedQueue.length #end)
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
		return #if lime_threads __multiThreadedJobs.length + #end
			(__singleThreadedJob != null ? 1 : 0);
	}

	private inline function get_idleThreads():Int
	{
		return #if lime_threads __idleThreads.length #else 0 #end;
	}

	private inline function get_currentThreads():Int
	{
		return activeJobs + idleThreads;
	}

	private function get_doWork():PseudoEvent
	{
		return this;
	}

	private inline function set___singleThreadedJob(value:JobData):JobData
	{
		if (value != null && __singleThreadedJob == null)
		{
			__totalWorkPriority += workPriority;
		}
		else if (value == null && __singleThreadedJob != null)
		{
			__totalWorkPriority -= workPriority;
		}
		return __singleThreadedJob = value;
	}

	private function set_workPriority(value:Float):Float
	{
		if (__singleThreadedJob != null)
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

@:forward.new @:forward
private abstract JobArray(Array<JobData>) from Array<JobData>
{
	public inline function clear():Void
	{
		#if haxe4
		this.resize(0);
		#else
		this.splice(0, this.length);
		#end
	}

	public function getJob(id:Int):JobData
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

	public function removeJob(id:Int):JobData
	{
		for (i in 0...this.length)
		{
			var job:JobData = this[i];
			if (job.id == id)
			{
				this.splice(i, 1);
				return job;
			}
		}
		return null;
	}
}
