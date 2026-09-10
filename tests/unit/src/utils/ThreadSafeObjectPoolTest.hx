package utils;

#if target.threaded
import lime.utils.ThreadSafeObjectPool;
import sys.thread.Mutex;
import sys.thread.Thread;
import utest.Assert;
import utest.Test;

private class Item {
	public var inUse:Bool = false;
	public function new() {}
}

class ThreadSafeObjectPoolTest extends Test {
	public function new() {
		super();
	}

	public function testConcurrentGetReleaseDoesNotDriftCounters():Void {
		final THREADS = 8;
		final ITERS = 1000;
		final POOL_SIZE = 4;
		final TIMEOUT_SEC = 5.0;
		var pool = new ThreadSafeObjectPool<Item>(function() return new Item(), null, POOL_SIZE);
		var doneMutex = new Mutex();
		var done = 0;
		var duplicates = 0;
		for (i in 0...THREADS) {
			Thread.create(function() {
				for (j in 0...ITERS) {
					var a = pool.get();
					if (a == null) continue;
					if (a.inUse) duplicates++;
					a.inUse = true;
					a.inUse = false;
					pool.release(a);
				}
				doneMutex.acquire();
				done++;
				doneMutex.release();
			});
		}
		var deadline = haxe.Timer.stamp() + TIMEOUT_SEC;
		var timedOut = false;
		while (true) {
			doneMutex.acquire();
			var d = done;
			doneMutex.release();
			if (d >= THREADS) break;
			if (haxe.Timer.stamp() > deadline) { timedOut = true; break; }
			Sys.sleep(0.01);
		}
		Assert.isFalse(timedOut, "worker threads did not finish within " + TIMEOUT_SEC + "s — likely pool state corruption");
		Assert.equals(0, duplicates);
		Assert.equals(0, pool.activeObjects);
		Assert.equals(POOL_SIZE, pool.inactiveObjects);
	}
}
#end
