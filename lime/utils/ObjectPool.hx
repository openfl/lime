package lime.utils;


@:generic class ObjectPool<T> {
	
	
	public var allocator:Void->T;
	public var size (get, set):Int;
	
	private var __activeObjects:List<T>;
	private var __inactiveObjects:List<T>;
	private var __size:Null<Int>;
	
	
	public function new (allocator:Void->T, size:Null<Int> = null) {
		
		this.allocator = allocator;
		
		__activeObjects = new List<T> ();
		__inactiveObjects = new List<T> ();
		
		if (size != null) {
			
			this.size = size;
			
		}
		
	}
	
	
	public function create ():T {
		
		if (__inactiveObjects.length > 0) {
			
			var object = __inactiveObjects.first ();
			__activeObjects.add (object);
			return object;
			
		} else {
			
			var object = Reflect.callMethod (allocator, allocator, []);
			__activeObjects.add (object);
			size = __size;
			return object;
			
		}
		
	}
	
	
	public function get ():Null<T> {
		
		var object = null;
		
		if (__inactiveObjects.length > 0) {
			
			object = __inactiveObjects.first ();
			__activeObjects.add (object);
			
		} else if (__size == null) {
			
			object = Reflect.callMethod (allocator, allocator, []);
			__activeObjects.add (object);
			
		}
		
		return object;
		
	}
	
	
	public function release (object:T):Void {
		
		if (__activeObjects.remove (object)) {
			
			__inactiveObjects.add (object);
			
		}
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_size ():Int {
		
		if (__size != null) return __size;
		return __inactiveObjects.length + __activeObjects.length;
		
	}
	
	
	private function set_size (value:Int):Int {
		
		var current = __inactiveObjects.length + __activeObjects.length;
		
		if (value <= 0) {
			
			__size = null;
			
		} else {
			
			__size = value;
			
			while (current > value) {
				
				if (__inactiveObjects.length > 0) {
					
					__inactiveObjects.first ();
					current--;
					
				} else if (__activeObjects.length > 0) {
					
					__activeObjects.first ();
					current--;
					
				} else {
					
					break;
					
				}
				
			}
			
			while (value > current) {
				
				__inactiveObjects.add (Reflect.callMethod (allocator, allocator, []));
				current++;
				
			}
			
		}
		
		return current;
		
	}
	
	
}