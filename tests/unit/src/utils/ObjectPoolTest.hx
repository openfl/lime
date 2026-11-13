package utils;

import lime.utils.ObjectPool;
import utest.Assert;
import utest.Test;

/**
	A pool hands out objects with `get()`, which become active, and takes them
	back with `release()`, which leaves them inactive until handed out again.
	Where the docs are silent, an object is taken to be either active, inactive
	or not in the pool at all, so it is never counted, or handed out, twice.
**/
class ObjectPoolTest extends Test
{
	private var created:Int;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		created = 0;
	}

	public function testGetCreatesObjectsThatAreActive():Void
	{
		var pool = newPool();
		var first = pool.get();
		var second = pool.get();

		Assert.notNull(first);
		Assert.notNull(second);
		Assert.notEquals(first, second);
		Assert.equals(2, created);
		Assert.equals(2, pool.activeObjects);
		Assert.equals(0, pool.inactiveObjects);
	}

	public function testReleasedObjectsAreHandedOutAgain():Void
	{
		var pool = newPool();
		var object = pool.get();

		pool.release(object);
		Assert.equals(0, pool.activeObjects);
		Assert.equals(1, pool.inactiveObjects);

		Assert.equals(object, pool.get());
		Assert.equals(1, created, "an inactive object was there to reuse");
		Assert.equals(1, pool.activeObjects);
		Assert.equals(0, pool.inactiveObjects);
	}

	public function testReleaseCleansTheObject():Void
	{
		var cleaned:Array<PooledObject> = [];
		var pool = new ObjectPool<PooledObject>(createObject, function(object) cleaned.push(object));
		var object = pool.get();

		Assert.same([], cleaned, "an object was cleaned before it was released");
		pool.release(object);
		Assert.equals(1, cleaned.length);
		Assert.equals(object, cleaned[0]);
	}

	public function testCreateAndCleanCanBeReplaced():Void
	{
		var pool = new ObjectPool<PooledObject>();
		var cleaned = 0;

		pool.create = createObject;
		pool.clean = function(object) cleaned++;

		var object = pool.get();
		Assert.notNull(object);
		Assert.equals(1, created);

		pool.release(object);
		Assert.equals(1, cleaned);
	}

	public function testSizeLimitsTheObjectsHandedOut():Void
	{
		var pool = newPool(2);
		var first = pool.get();
		var second = pool.get();

		Assert.equals(2, pool.size);
		Assert.isNull(pool.get(), "a full pool handed out a third object");
		Assert.equals(2, created);
		Assert.equals(2, pool.activeObjects);

		pool.release(first);
		Assert.equals(first, pool.get());
		Assert.equals(2, created);
	}

	public function testRaisingTheSizeAllowsMoreObjects():Void
	{
		var pool = newPool(1);
		pool.get();
		Assert.isNull(pool.get());

		pool.size = 2;
		Assert.equals(2, pool.size);
		Assert.notNull(pool.get());
		Assert.equals(2, pool.activeObjects);
	}

	public function testLoweringTheSizeDropsInactiveObjects():Void
	{
		var pool = newPool();
		var objects = [pool.get(), pool.get(), pool.get()];

		for (object in objects)
		{
			pool.release(object);
		}

		Assert.equals(3, pool.inactiveObjects);

		pool.size = 1;
		Assert.equals(1, pool.size);
		Assert.equals(1, pool.inactiveObjects);
		Assert.equals(0, pool.activeObjects);
	}

	public function testAddedObjectsAreHandedOutWithoutCreatingAny():Void
	{
		var pool = newPool();
		var object = new PooledObject(-1);

		pool.add(object);
		Assert.equals(0, pool.activeObjects);
		Assert.equals(1, pool.inactiveObjects);

		Assert.equals(object, pool.get());
		Assert.equals(0, created);
		Assert.equals(1, pool.activeObjects);
	}

	public function testAddingAnObjectTwiceCountsItOnce():Void
	{
		var pool = newPool();
		var object = new PooledObject(-1);

		pool.add(object);
		pool.add(object);
		Assert.equals(1, pool.inactiveObjects);

		Assert.equals(object, pool.get());
		Assert.notEquals(object, pool.get(), "an object added twice was handed out twice");
	}

	public function testRemovedInactiveObjectsAreNotHandedOut():Void
	{
		var pool = newPool();
		var object = pool.get();
		pool.release(object);

		pool.remove(object);
		Assert.equals(0, pool.activeObjects);
		Assert.equals(0, pool.inactiveObjects);

		var next = pool.get();
		Assert.notEquals(object, next);
		Assert.equals(2, created);
	}

	@Ignored("Waiting on #2149")
	public function testRemovedActiveObjectsAreNoLongerCounted():Void
	{
		var pool = newPool();
		var object = pool.get();

		pool.remove(object);
		Assert.equals(0, pool.activeObjects);
		Assert.equals(0, pool.inactiveObjects);

		// It no longer belongs to the pool, so it can't be released back
		pool.release(object);
		Assert.equals(0, pool.activeObjects);
		Assert.equals(0, pool.inactiveObjects);
	}

	public function testRemovingFreesRoomInAFullPool():Void
	{
		var pool = newPool(1);
		var object = pool.get();

		pool.remove(object);
		Assert.notNull(pool.get(), "a pool of one stayed full after its object was removed");
	}

	public function testClearEmptiesThePool():Void
	{
		var pool = newPool();
		var active = pool.get();
		var inactive = pool.get();
		pool.release(inactive);

		pool.clear();
		Assert.equals(0, pool.activeObjects);
		Assert.equals(0, pool.inactiveObjects);

		var next = pool.get();
		Assert.notEquals(active, next);
		Assert.notEquals(inactive, next);
		Assert.equals(3, created);
	}

	@Ignored("Waiting on #2149")
	public function testReleasingTwiceCountsTheObjectOnce():Void
	{
		var pool = newPool();
		var object = pool.get();

		pool.release(object);
		pool.release(object);
		Assert.equals(0, pool.activeObjects);
		Assert.equals(1, pool.inactiveObjects);

		var first = pool.get();
		var second = pool.get();
		Assert.notEquals(first, second, "an object released twice was handed out twice");
	}

	@Ignored("Waiting on #2149")
	public function testReleasingTwiceCleansOnce():Void
	{
		var cleaned = 0;
		var pool = new ObjectPool<PooledObject>(createObject, function(object) cleaned++);
		var object = pool.get();

		pool.release(object);
		pool.release(object);
		Assert.equals(1, cleaned);
	}

	@Ignored("Waiting on #2149")
	public function testReleasingAnObjectFromElsewhereIsIgnored():Void
	{
		var pool = newPool();
		var stranger = new PooledObject(-1);

		pool.release(stranger);
		Assert.equals(0, pool.activeObjects);
		Assert.equals(0, pool.inactiveObjects);
		Assert.notEquals(stranger, pool.get());
	}

	private function newPool(size:Null<Int> = null):ObjectPool<PooledObject>
	{
		return new ObjectPool<PooledObject>(createObject, null, size);
	}

	private function createObject():PooledObject
	{
		return new PooledObject(created++);
	}
}

private class PooledObject
{
	public var id:Int;

	public function new(id:Int)
	{
		this.id = id;
	}

	public function toString():String
	{
		return "PooledObject " + id;
	}
}
