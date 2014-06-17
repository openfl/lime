package lime.ui;


class WindowEventInfo {
	
	
	public var type:WindowEventType;
	
	
	public function new (type:WindowEventType = null) {
		
		this.type = type;
		
	}
	
	
	public function clone ():WindowEventInfo {
		
		return new WindowEventInfo (type);
		
	}
	
	
}


@:enum abstract WindowEventType(Int) {
	
	var WINDOW_ACTIVATE = 0;
	var WINDOW_DEACTIVATE = 1;
	
}