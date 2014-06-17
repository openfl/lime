package lime.ui;


class MouseEventInfo {
	
	
	public var id:Int;
	public var type:MouseEventType;
	public var x:Float;
	public var y:Float;
	
	
	
	public function new (type:MouseEventType = null, id:Int = 0, x:Float = 0, y:Float = 0) {
		
		this.id = id;
		this.type = type;
		this.x = x;
		this.y = y;
		
	}
	
	
	public function clone ():MouseEventInfo {
		
		return new MouseEventInfo (type, id, x, y);
		
	}
	
	
}


@:enum abstract MouseEventType(Int) {
	
	var MOUSE_DOWN = 0;
	var MOUSE_UP = 1;
	var MOUSE_MOVE = 2;
	var MOUSE_WHEEL = 3;
	
}