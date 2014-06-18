package lime.ui;


class MouseEventInfo {
	
	
	public var button:MouseEventButton;
	public var type:MouseEventType;
	public var x:Float;
	public var y:Float;
	
	
	
	public function new (type:MouseEventType = null, x:Float = 0, y:Float = 0, button:MouseEventButton = null) {
		
		this.type = type;
		this.x = x;
		this.y = y;
		this.button = button;
		
	}
	
	
	public function clone ():MouseEventInfo {
		
		return new MouseEventInfo (type, x, y, button);
		
	}
	
	
}


@:enum abstract MouseEventButton(Int) {
	
	var MOUSE_BUTTON_LEFT = 0;
	var MOUSE_BUTTON_MIDDLE = 1;
	var MOUSE_BUTTON_RIGHT = 2;
	
}


@:enum abstract MouseEventType(Int) {
	
	var MOUSE_DOWN = 0;
	var MOUSE_UP = 1;
	var MOUSE_MOVE = 2;
	var MOUSE_WHEEL = 3;
	
}