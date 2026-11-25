package system;

#if (js && html5 && lime_threads)
import lime.system.ThreadPool;
import lime.system.WorkOutput;
#end
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	Thread pool jobs in web workers, with `lime-threads` on HTML5.

	A worker calls its job's work function again and again, and reads its messages in between. It waits
	on a zero-delay timer before each call, and browsers hold nested zero-delay timers to about 4 ms, so a
	work function is called at most about 250 times a second however little it does. The job's progress
	and completion still have to arrive in order.

	These run only in a browser, built with `-Dlime-threads`, which CI doesn't do.

	An application can start a job in its constructor, which runs before `ApplicationMain` sets the
	application's meta, `file` included, and the worker's script is found from that name, so such a job
	never completes today (#2453). TestMain starts one there, as such an application would, before the
	tests run. utest runs the first test in TestMain's constructor too, so until #2453 is fixed each test
	sends a job that it doesn't wait for first.
**/
class HTML5ThreadPoolTest extends Test
{
	public function new()
	{
		super();
	}

	#if (js && html5 && lime_threads)
	private static var constructorJob:lime.app.Future<Dynamic>;

	/** Starts a job as TestMain is constructed, as an application may in its own constructor **/
	public static function startAJobInTheConstructor():Void
	{
		var promise = new lime.app.Promise<Dynamic>();
		var pool = new ThreadPool(0, 1, MULTI_THREADED);
		pool.onComplete.add(function(message) promise.complete(message));
		pool.onError.add(function(error) promise.error(error));
		pool.run(countToFive, {count: 0});
		constructorJob = promise.future;
	}

	@Ignored("Waiting on #2453")
	@:timeout(10000)
	public function testAJobStartedInTheApplicationsConstructorCompletes(async:Async):Void
	{
		if (constructorJob == null)
		{
			Assert.fail("TestMain started no job in its constructor");
			async.done();
			return;
		}

		constructorJob.onComplete(function(message)
		{
			Assert.equals("5", Std.string(message), "the job's completion");
			async.done();
		}).onError(function(error)
		{
			Assert.fail("the job failed: " + error);
			async.done();
		});
	}

	@:timeout(10000)
	public function testAWorkerJobsProgressAndCompletionArriveInOrder(async:Async):Void
	{
		afterAFirstJob(function() inOrder(async));
	}

	private static function inOrder(async:Async):Void
	{
		var pool = new ThreadPool(0, 1, MULTI_THREADED);
		var heard = [];

		pool.onProgress.add(function(message) heard.push(Std.string(message)));
		pool.onError.add(function(error)
		{
			Assert.fail("the job failed: " + error);
			async.done();
		});
		pool.onComplete.add(function(message)
		{
			heard.push("complete " + message);
			Assert.equals("1,2,3,4,complete 5", heard.join(","));
			async.done();
		});

		pool.run(countToFive, {count: 0});
	}

	@Ignored("Waiting on #2243")
	@:timeout(10000)
	public function testAWorkerCallsItsWorkFunctionMoreOftenThanATimerAllows(async:Async):Void
	{
		afterAFirstJob(function() callsOften(async));
	}

	private static function callsOften(async:Async):Void
	{
		var pool = new ThreadPool(0, 1, MULTI_THREADED);

		pool.onError.add(function(error)
		{
			Assert.fail("the job failed: " + error);
			async.done();
		});
		pool.onComplete.add(function(calls:Int)
		{
			// A clamped timer allows about 250 a second
			Assert.isTrue(calls > 1000, "the work function was called " + calls + " times in a second");
			async.done();
		});

		pool.run(countCallsForASecond, {calls: 0, start: -1.0});
	}

	// Helpers

	private static var firstJobSent = false;

	private static function afterAFirstJob(next:Void->Void):Void
	{
		if (firstJobSent)
		{
			next();
			return;
		}

		firstJobSent = true;
		new ThreadPool(0, 1, MULTI_THREADED).run(countToFive, {count: 0});
		haxe.Timer.delay(next, 1000);
	}

	private static function countToFive(state:Dynamic, output:WorkOutput):Void
	{
		state.count++;
		if (state.count < 5) output.sendProgress(state.count);
		else output.sendComplete(state.count);
	}

	private static function countCallsForASecond(state:Dynamic, output:WorkOutput):Void
	{
		var now:Float = js.Syntax.code("performance.now()");
		if (state.start < 0) state.start = now;
		state.calls++;
		if (now - state.start >= 1000) output.sendComplete(state.calls);
	}
	#end
}
