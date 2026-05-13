package lime.utils;

#if target.threaded
import sys.thread.Mutex;

/**
	A thread-safe variant of `ObjectPool`. Wraps every mutating method
	(`add`, `clear`, `get`, `release`, `remove`, `size` setter) with an
	internal `sys.thread.Mutex` so concurrent access from multiple threads
	cannot drift the `activeObjects` / `inactiveObjects` counters or hand
	out the same instance twice.

	On threaded targets (`#if target.threaded`) the class extends
	`ObjectPool` and routes mutating calls through the mutex. On
	non-threaded targets (`js`, `flash`) this name resolves to a `typedef`
	alias of `ObjectPool` — same compile-time API, zero runtime cost, and
	no thread-safety code in the output.

	Caveats:

	- The supplied `create` and `clean` callbacks are invoked while the
	  internal mutex is held. They must not call back into the same pool,
	  or `Mutex.acquire()` will deadlock on non-reentrant platforms.
	- Reading the `activeObjects`, `inactiveObjects`, or `size` properties
	  from a different thread than the one currently mutating the pool is
	  not memory-safe. Use external synchronization if a consistent
	  cross-thread snapshot is required.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
#if !js @:generic #end class ThreadSafeObjectPool<T> extends ObjectPool<T>
{
	@:noCompletion private final __mutex:Mutex = new Mutex();

	/**
		Creates a new ThreadSafeObjectPool instance.

		@param create A function that creates a new instance of type T.
		@param clean A function that cleans up an instance of type T before it is reused.
		@param size The maximum size of the object pool.
	**/
	public function new(create:Void->T = null, clean:T->Void = null, size:Null<Int> = null)
	{
		super(create, clean, size);
	}

	override public function add(object:T):Void
	{
		__mutex.acquire();
		super.add(object);
		__mutex.release();
	}

	override public function clear():Void
	{
		__mutex.acquire();
		super.clear();
		__mutex.release();
	}

	override public function get():T
	{
		__mutex.acquire();
		final object:T = super.get();
		__mutex.release();
		return object;
	}

	override public function release(object:T):Void
	{
		__mutex.acquire();
		super.release(object);
		__mutex.release();
	}

	override public function remove(object:T):Void
	{
		__mutex.acquire();
		super.remove(object);
		__mutex.release();
	}

	@:noCompletion override private function set_size(value:Null<Int>):Null<Int>
	{
		__mutex.acquire();
		final result:Null<Int> = super.set_size(value);
		__mutex.release();
		return result;
	}
}
#else
typedef ThreadSafeObjectPool<T> = ObjectPool<T>;
#end
