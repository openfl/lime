package utils;

import lime.utils.ObjectPool;
import utest.Assert;
import utest.Test;

private class Item {
	public function new() {}
}

class ObjectPoolTest extends Test {
	public function new() {
		super();
	}

	public function testGetReturnsFromCreate():Void {
		var pool = new ObjectPool<Item>(function() return new Item());
		var a = pool.get();
		Assert.notNull(a);
		Assert.equals(1, pool.activeObjects);
		Assert.equals(0, pool.inactiveObjects);
	}

	public function testReleaseReturnsObjectToPool():Void {
		var pool = new ObjectPool<Item>(function() return new Item());
		var a = pool.get();
		pool.release(a);
		Assert.equals(0, pool.activeObjects);
		Assert.equals(1, pool.inactiveObjects);
	}

	public function testGetReusesReleasedObject():Void {
		var pool = new ObjectPool<Item>(function() return new Item());
		var a = pool.get();
		pool.release(a);
		var b = pool.get();
		Assert.equals(a, b);
		Assert.equals(1, pool.activeObjects);
		Assert.equals(0, pool.inactiveObjects);
	}

	public function testSizeCapLimitsCreation():Void {
		var pool = new ObjectPool<Item>(function() return new Item(), null, 2);
		var a = pool.get();
		var b = pool.get();
		var c = pool.get();
		Assert.notNull(a);
		Assert.notNull(b);
		Assert.isNull(c);
		Assert.equals(2, pool.activeObjects);
	}

	public function testCleanIsCalledOnRelease():Void {
		var cleaned = 0;
		var pool = new ObjectPool<Item>(function() return new Item(), function(_) cleaned++);
		var a = pool.get();
		pool.release(a);
		Assert.equals(1, cleaned);
	}

	public function testClearResetsCounters():Void {
		var pool = new ObjectPool<Item>(function() return new Item());
		pool.get();
		pool.release(pool.get());
		pool.clear();
		Assert.equals(0, pool.activeObjects);
		Assert.equals(0, pool.inactiveObjects);
	}

	public function testRemoveDecrementsCorrectCounter():Void {
		var pool = new ObjectPool<Item>(function() return new Item());
		var a = pool.get();
		pool.remove(a);
		Assert.equals(0, pool.activeObjects);
		Assert.equals(0, pool.inactiveObjects);
	}

	public function testSetSizePrefillsInactive():Void {
		var pool = new ObjectPool<Item>(function() return new Item());
		pool.size = 3;
		Assert.equals(0, pool.activeObjects);
		Assert.equals(3, pool.inactiveObjects);
	}
}
