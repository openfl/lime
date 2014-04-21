package project;


import helpers.ObjectHelper;


class ConfigData implements Dynamic {
	
	
	public function new () {
		
		
		
	}
	
	
	public function clone ():ConfigData {
		
		return ObjectHelper.deepCopy (this);
		
	}
	
	
	public function get (type:String, id:String):Dynamic {
		
		var object = getObject (type, id);
		var propertyName = getPropertyName (id);
		
		return Reflect.field (object, propertyName);
		
	}
	
	
	private function getObject (type:String, id:String):Dynamic {
		
		var split = id.split (".");
		var path = [ type ];
		
		if (split.length > 1) {
			
			path = path.concat (split.slice (0, split.length - 1));
			
		}
		
		var object = this;
		
		for (element in path) {
			
			if (!Reflect.hasField (object, element)) {
				
				return null;
				
			}
			
			object = Reflect.field (object, element);
			
		}
		
		return object;
		
	}
	
	
	public function getPropertyName (id:String):String {
		
		if (id == null) return null;
		
		var split = id.split (".");
		return split[split.length - 1];
		
	}
	
	
	public function exists (type:String, id:String):Bool {
		
		var object = getObject (type, id);
		var propertyName = getPropertyName (id);
		
		if (object != null && propertyName != null) {
			
			return Reflect.hasField (object, propertyName);
			
		}
		
		return false;
		
	}
	
	
	public function merge (config:ConfigData):Void {
		
		
		
	}
	
	
	public function set (type:String, id:String, value:Dynamic):Void {
		
		var object = getObject (type, id);
		var propertyName = getPropertyName (id);
		
		Reflect.setField (object, propertyName, value);
		
	}
	
	
}