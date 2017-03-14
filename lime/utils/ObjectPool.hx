package lime.utils;


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


@:generic class ObjectPool<T> {
	
	
	public var activeObjects (get, never):Int;
	public var inactiveObjects (get, never):Int;
	public var size (get, set):Null<Int>;
	
	private var __activeObjects:List<T>;
	private var __inactiveObjects:List<T>;
	private var __size:Null<Int>;
	
	
	public function new (create:Void->T = null, clean:T->Void = null, size:Null<Int> = null) {
		
		if (create != null) {
			
			this.create = create;
			
		}
		
		if (clean != null) {
			
			this.clean = clean;
			
		}
		
		if (size != null) {
			
			this.size = size;
			
		}
		
		__activeObjects = new List<T> ();
		__inactiveObjects = new List<T> ();
		
	}
	
	
	public function add (object:Null<T>):Void {
		
		if (object != null) {
			
			__activeObjects.remove (object);
			__inactiveObjects.remove (object);
			
			clean (object);
			
			__inactiveObjects.add (object);
			
		}
		
	}
	
	
	public dynamic function clean (object:T):Void {
		
		
		
	}
	
	
	public function clear ():Void {
		
		__inactiveObjects.clear ();
		__activeObjects.clear ();
		
	}
	
	
	public dynamic function create ():Null<T> {
		
		return null;
		
	}
	
	
	public function get ():Null<T> {
		
		var object = null;
		
		if (__inactiveObjects.length > 0) {
			
			object = __inactiveObjects.pop ();
			__activeObjects.add (object);
			
		} else if (__size == null || __activeObjects.length < __size) {
			
			object = create ();
			
			if (object != null) {
				
				__activeObjects.add (object);
				
			}
			
		}
		
		return object;
		
	}
	
	
	public function release (object:T):Void {
		
		if (__activeObjects.remove (object)) {
			
			clean (object);
			
			if (__size == null || __activeObjects.length + __inactiveObjects.length < __size) {
				
				__inactiveObjects.add (object);
				
			}
			
		}
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_activeObjects ():Int {
		
		return __activeObjects.length;
		
	}
	
	
	private function get_inactiveObjects ():Int {
		
		return __inactiveObjects.length;
		
	}
	
	
	private function get_size ():Null<Int> {
		
		return __size;
		
	}
	
	
	private function set_size (value:Null<Int>):Null<Int> {
		
		if (value == null) {
			
			__size = null;
			
		} else {
			
			var current = __inactiveObjects.length + __activeObjects.length;
			__size = value;
			
			while (current > value) {
				
				if (__inactiveObjects.length > 0) {
					
					__inactiveObjects.pop ();
					current--;
					
				} else if (__activeObjects.length > 0) {
					
					__activeObjects.pop ();
					current--;
					
				} else {
					
					break;
					
				}
				
			}
			
			var object;
			
			while (value > current) {
				
				object = create ();
				
				if (object != null) {
					
					__inactiveObjects.add (object);
					current++;
					
				} else {
					
					break;
					
				}
				
			}
			
		}
		
		return value;
		
	}
	
	
}