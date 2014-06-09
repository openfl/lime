package lime.ui;


class TouchEvent {
	
	
	public var id:Int;
	public var type:TouchEventType;
	public var x:Float;
	public var y:Float;
	
	
	
	public function new (type:TouchEventType = null, id:Int = 0, x:Float = 0, y:Float = 0) {
		
		this.type = type;
		this.id = id;
		this.x = x;
		this.y = y;
		
	}
	
	
	public function clone ():TouchEvent {
		
		return new TouchEvent (type, id, x, y);
		
	}
	
	
}


@:enum abstract TouchEventType(Int) {
	
	var TOUCH_START = 0;
	var TOUCH_END = 1;
	var TOUCH_MOVE = 2;
	
}