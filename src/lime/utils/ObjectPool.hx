package lime.utils;

import haxe.ds.ObjectMap;

/**
	A generic object pool for reusing objects.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
#if !js @:generic #end class ObjectPool<T>
{
	/**
		The number of active objects in the pool.
	**/
	public var activeObjects(default, null):Int;

	/**
		The number of inactive objects in the pool.
	**/
	public var inactiveObjects(default, null):Int;

	/**
		The total size of the object pool (both active and inactive objects).
	**/
	public var size(get, set):Null<Int>;

	@:noCompletion private var __inactiveObject0:T;
	@:noCompletion private var __inactiveObject1:T;
	@:noCompletion private var __inactiveObjectList:List<T>;
	@:noCompletion private var __pool:Map<T, Bool>;
	@:noCompletion private var __size:Null<Int>;

	/**
				Creates a new ObjectPool instance.

				@param create A function that creates a new instance of type T.
				@param clean A function that cleans up an instance of type T before it is reused.
				@param size The maximum size of the object pool.
	**/
	public function new(create:Void->T = null, clean:T->Void = null, size:Null<Int> = null)
	{
		__pool = cast new ObjectMap();

		activeObjects = 0;
		inactiveObjects = 0;

		__inactiveObject0 = null;
		__inactiveObject1 = null;
		__inactiveObjectList = new List<T>();

		if (create != null)
		{
			this.create = create;
		}
		if (clean != null)
		{
			this.clean = clean;
		}
		if (size != null)
		{
			this.size = size;
		}
	}

	/**
				Adds an object to the object pool.

				@param object The object to add to the pool.
	**/
	public function add(object:T):Void
	{
		if (object != null && !__pool.exists(object))
		{
			__pool.set(object, false);
			clean(object);
			__addInactive(object);
		}
	}

	/**
		Dynamic function.

		   		Cleans up an object before returning it to the pool.
		   
		   		@param object The object to clean up.
	**/
	public dynamic function clean(object:T):Void {}

	/**
		Clears the object pool, removing all objects.
	**/
	public function clear():Void
	{
		__pool = cast new ObjectMap();

		activeObjects = 0;
		inactiveObjects = 0;

		__inactiveObject0 = null;
		__inactiveObject1 = null;
		__inactiveObjectList.clear();
	}

	/**
		Dynamic function.

		   		Creates a new Object.
	**/
	public dynamic function create():T
	{
		return null;
	}

	/**
				Creates a new object and adds it to the pool, or returns an existing inactive object from the pool.

				@return The object retrieved from the pool, or null if the pool is full and no new objects can be created.
	**/
	public function get():T
	{
		var object = null;

		if (inactiveObjects > 0)
		{
			object = __getInactive();
		}
		else if (__size == null || activeObjects < __size)
		{
			object = create();

			if (object != null)
			{
				__pool.set(object, true);
				activeObjects++;
			}
		}

		return object;
	}

	/**
				Releases an active object back into the pool.

				@param object The object to release.
	**/
	public function release(object:T):Void
	{
		#if debug
		if (object == null || !__pool.exists(object))
		{
			Log.error("Object is not a member of the pool");
		}
		else if (!__pool.get(object))
		{
			Log.error("Object has already been released");
		}
		#end

		activeObjects--;

		if (__size == null || activeObjects + inactiveObjects < __size)
		{
			clean(object);
			__addInactive(object);
		}
		else
		{
			__pool.remove(object);
		}
	}

	/**
		   		Removes an object from the pool.

		   		@param object The object to remove from the pool.
	**/
	public function remove(object:T):Void
	{
		if (object != null && __pool.exists(object))
		{
			__pool.remove(object);

			if (__inactiveObject0 == object)
			{
				__inactiveObject0 = null;
				inactiveObjects--;
			}
			else if (__inactiveObject1 == object)
			{
				__inactiveObject1 = null;
				inactiveObjects--;
			}
			else if (__inactiveObjectList.remove(object))
			{
				inactiveObjects--;
			}
			else
			{
				activeObjects--;
			}
		}
	}

	@:noCompletion private inline function __addInactive(object:T):Void
	{
		#if debug
		__pool.set(object, false);
		#end

		if (__inactiveObject0 == null)
		{
			__inactiveObject0 = object;
		}
		else if (__inactiveObject1 == null)
		{
			__inactiveObject1 = object;
		}
		else
		{
			__inactiveObjectList.add(object);
		}

		inactiveObjects++;
	}

	@:noCompletion private inline function __getInactive():T
	{
		var object = null;

		if (__inactiveObject0 != null)
		{
			object = __inactiveObject0;
			__inactiveObject0 = null;
		}
		else if (__inactiveObject1 != null)
		{
			object = __inactiveObject1;
			__inactiveObject1 = null;
		}
		else
		{
			object = __inactiveObjectList.pop();

			if (__inactiveObjectList.length > 0)
			{
				__inactiveObject0 = __inactiveObjectList.pop();
			}

			if (__inactiveObjectList.length > 0)
			{
				__inactiveObject1 = __inactiveObjectList.pop();
			}
		}

		#if debug
		__pool.set(object, true);
		#end

		inactiveObjects--;
		activeObjects++;

		return object;
	}

	@:noCompletion private function __removeInactive(count:Int):Void
	{
		if (count <= 0 || inactiveObjects == 0) return;

		if (__inactiveObject0 != null)
		{
			__pool.remove(__inactiveObject0);
			__inactiveObject0 = null;
			inactiveObjects--;
			count--;
		}

		if (count == 0 || inactiveObjects == 0) return;

		if (__inactiveObject1 != null)
		{
			__pool.remove(__inactiveObject1);
			__inactiveObject1 = null;
			inactiveObjects--;
			count--;
		}

		if (count == 0 || inactiveObjects == 0) return;

		for (object in __inactiveObjectList)
		{
			__pool.remove(object);
			__inactiveObjectList.remove(object);
			inactiveObjects--;
			count--;

			if (count == 0 || inactiveObjects == 0) return;
		}
	}

	// Get & Set Methods
	@:noCompletion private function get_size():Null<Int>
	{
		return __size;
	}

	@:noCompletion private function set_size(value:Null<Int>):Null<Int>
	{
		if (value == null)
		{
			__size = null;
		}
		else
		{
			var current = inactiveObjects + activeObjects;
			__size = value;

			if (current > value)
			{
				__removeInactive(current - value);
			}
			else if (value > current)
			{
				var object;

				for (i in 0...(value - current))
				{
					object = create();

					if (object != null)
					{
						__pool.set(object, false);
						__inactiveObjectList.add(object);
						inactiveObjects++;
					}
					else
					{
						break;
					}
				}
			}
		}

		return value;
	}
}
