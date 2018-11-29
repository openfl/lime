package lime.tools.helpers;


import haxe.ds.IntMap;
import haxe.ds.StringMap;


@:generic class ObjectHelper {
	
	
	public static function copyFields<T> (source:T, destination:T):T {
		
		for (field in Reflect.fields (source)) {
			
			Reflect.setField (destination, field, Reflect.field (source, field));
			
		}
		
		return destination;
		
	}
	
	
	public static function copyMissingFields<T> (source:T, destination:T):T {
		
		for (field in Reflect.fields (source)) {
			
			if (!Reflect.hasField (destination, field)) {
				
				Reflect.setField (destination, field, Reflect.field (source, field));
				
			}
			
		}
		
		return destination;
		
	}
	
	
	public static function copyUniqueFields<T> (source:T, destination:T, defaultInstance:T):T {
		
		for (field in Reflect.fields (source)) {
			
			var value = Reflect.field (source, field);
			
			if (value != Reflect.field (defaultInstance, field)) {
				
				Reflect.setField (destination, field, value);
				
			}
			
		}
		
		return destination;
		
	}
	
	
	public static function deepCopy<T> (v:T):T {
		
		if (!Reflect.isObject (v)) { // simple type
			
			return v;
			
		} else if (Std.is (v, String)) { // string
			
			return v;
			
		} else if (Std.is (v, Array)) { // array
			
			var result = Type.createInstance (Type.getClass (v), []);
			
			untyped {
				var copy:Dynamic;
				for (ii in 0...v.length) {
					copy = deepCopy (v[ii]);
					result.push (copy);
				}
			}
			
			return result;
			
		} else if (Std.is (v, StringMap)) { // hashmap
			
			var result = Type.createInstance (Type.getClass(v), []);
			
			untyped {
				var keys:Iterator<String> = v.keys ();
				for (key in keys) {
					result.set (key, deepCopy (v.get (key)));
				}
			}
			
			return result;
			
		} else if (Std.is (v, IntMap)) { // integer-indexed hashmap
			
			var result = Type.createInstance (Type.getClass (v), []);
			
			untyped {
				var keys:Iterator<Int> = v.keys ();
				for (key in keys) {
					result.set (key, deepCopy (v.get (key)));
				}
			}
			 
			return result;
			
		} else if (Std.is (v, List)) { // list
			
			//List would be copied just fine without this special case, but I want to avoid going recursive
			var result = Type.createInstance (Type.getClass (v), []);
			
			untyped {
				var iter:Iterator<Dynamic> = v.iterator ();
				for (ii in iter) {
					result.add (ii);
				}
			}
			
			return result;
			
		} else if (Type.getClass(v) == null) { // anonymous object
			
			var obj:Dynamic = {};
			
			for (ff in Reflect.fields (v)) { 
				Reflect.setField (obj, ff, deepCopy (Reflect.field (v, ff))); 
			}
			
			return obj;
			
		} else { // class
			
			var obj = Type.createEmptyInstance (Type.getClass (v));
			 
			for (ff in Reflect.fields (v)) {
				Reflect.setField (obj, ff, deepCopy (Reflect.field (v, ff))); 
			}
			
			return obj;
			
		}
		
		return null;
		
	}
	
	
}