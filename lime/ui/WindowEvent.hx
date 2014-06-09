package lime.ui;


class WindowEvent {
	
	
	public var type:WindowEventType;
	
	
	public function new (type:WindowEventType = null) {
		
		this.type = type;
		
	}
	
	
	public function clone ():WindowEvent {
		
		return new WindowEvent (type);
		
	}
	
	
}


@:enum abstract WindowEventType(Int) {
	
	var WINDOW_ACTIVATE = 0;
	var WINDOW_DEACTIVATE = 1;
	
}