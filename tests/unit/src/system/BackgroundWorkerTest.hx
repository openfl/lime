package system;

import lime.app.Application;
import lime.system.BackgroundWorker;
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	`BackgroundWorker` hands its worker's messages to the main thread as the application updates. Every
	message has to arrive, in the order it was sent, with completion last. On C++, Neko and HashLink one
	message is taken each frame, so a worker that reports progress often finishes long before its
	completion is heard. Elsewhere the worker runs on the calling thread.
**/
class BackgroundWorkerTest extends Test
{
	public function new()
	{
		super();
	}

	#if (sys && target.threaded)
	@:timeout(30000)
	public function testEveryProgressMessageArrivesInOrderBeforeCompletion(async:Async):Void
	{
		var worker = new BackgroundWorker();
		var heard = [];

		worker.doWork.add(function(message:Dynamic)
		{
			for (i in 0...20)
			{
				worker.sendProgress(message + i);
			}
			worker.sendComplete("done");
		});
		worker.onProgress.add(function(message:Dynamic) heard.push(Std.string(message)));
		worker.onError.add(function(message:Dynamic) heard.push("error " + message));
		worker.onComplete.add(function(message:Dynamic)
		{
			heard.push("complete " + message);
			Assert.equals([for (i in 0...20) Std.string(100 + i)].concat(["complete done"]).join(","), heard.join(","));
			async.done();
		});

		worker.run(100);
	}

	@:timeout(30000)
	public function testAnErrorEndsTheWork(async:Async):Void
	{
		var worker = new BackgroundWorker();
		var heard = [];

		worker.doWork.add(function(_)
		{
			worker.sendProgress(1);
			worker.sendError("broken");
			worker.sendProgress(2);
			worker.sendComplete("too late");
		});
		worker.onProgress.add(function(message:Dynamic) heard.push(Std.string(message)));
		worker.onComplete.add(function(message:Dynamic) heard.push("complete " + message));
		worker.onError.add(function(message:Dynamic) heard.push("error " + message));
		worker.run();

		waitFrames(30, function()
		{
			Assert.equals("1,error broken", heard.join(","));
			async.done();
		});
	}

	@:timeout(30000)
	public function testACanceledWorkerIsHeardNoMore(async:Async):Void
	{
		var worker = new BackgroundWorker();
		var heard = [];
		var release = new sys.thread.Lock();

		worker.doWork.add(function(_)
		{
			release.wait(10);
			worker.sendProgress(1);
			worker.sendComplete("done");
		});
		worker.onProgress.add(function(message:Dynamic) heard.push(Std.string(message)));
		worker.onComplete.add(function(message:Dynamic) heard.push("complete " + message));
		worker.run();
		worker.cancel();
		release.release();

		waitFrames(30, function()
		{
			Assert.isTrue(worker.canceled);
			Assert.equals("", heard.join(","));
			async.done();
		});
	}

	@Ignored("Waiting on #2240")
	@:timeout(30000)
	public function testMessagesSentTogetherArriveWithinAFewFrames(async:Async):Void
	{
		// 200 progress messages, which at one a frame take more than three seconds at 60 frames a second
		var worker = new BackgroundWorker();
		var progress = 0;
		var frames = 0;
		var finished = false;
		var counting = function(_:Int) if (finished) frames++;

		worker.doWork.add(function(_)
		{
			for (i in 0...200)
			{
				worker.sendProgress(i);
			}
			worker.sendComplete(null);
			finished = true;
		});
		worker.onProgress.add(function(_) progress++);
		worker.onComplete.add(function(_)
		{
			Application.current.onUpdate.remove(counting);
			Assert.equals(200, progress);
			Assert.isTrue(frames <= 5, "completion was heard " + frames + " frames after the worker finished");
			async.done();
		});

		Application.current.onUpdate.add(counting);
		worker.run();
	}

	// Helpers

	private static function waitFrames(count:Int, done:Void->Void):Void
	{
		var frames = 0;
		var listener:Int->Void = null;
		listener = function(_:Int)
		{
			if (++frames >= count)
			{
				Application.current.onUpdate.remove(listener);
				done();
			}
		};
		Application.current.onUpdate.add(listener);
	}
	#end
}
