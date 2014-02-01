package helpers;


class ArrayHelper {
	
	
	public static function addUnique<T> (array:Array<T>, value:T):T {
		
		var exists = false;
		
		for (arrayValue in array) {
			
			if (arrayValue == value) {
				
				exists = true;
				break;
			}
			
		}
		
		if (!exists) {
			
			array.push (value);
			
		}
		
		return value;
		
	}
	
	
	public static function concatUnique<T> (a:Array<T>, b:Array<T>, adjustOrder:Bool = false, key:String = null):Array<T> {
		
		if (a == null && b == null) {
			
			return new Array<T> ();
			
		} else if (a == null && b != null) {
			
			return b;
			
		}
		
		var concat = a.copy ();
		
		for (bValue in b) {
			
			var hasValue = false;
			
			for (aValue in a) {
				
				if (key != null) {
					
					if (Reflect.field (aValue, key) == Reflect.field (bValue, key)) {
						
						if (adjustOrder) {
							
							concat.remove (aValue);
							
						} else {
							
							hasValue = true;
							
						}
						
					}
					
				} else if (aValue == bValue) {
					
					hasValue = true;
					
				}
				
			}
			
			if (adjustOrder && hasValue) {
				
				concat.remove (bValue);
				hasValue = false;
				
			}
			
			if (!hasValue) {
				
				concat.push (bValue);
				
			}
			
		}
		
		return concat;
		
	}
	
	
	public static function containsValue<T> (array:Array < T > , value:T):Bool {
		
		for (arrayValue in array) {
			
			if (arrayValue == value) {
				
				return true;
				
			}
			
		}
		
		return false;
		
	}
	
	
}
