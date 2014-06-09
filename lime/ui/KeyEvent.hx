package lime.ui;


class KeyEvent {
	
	
	public var code:Int;
	public var type:KeyEventType;
	
	
	public function new (type:KeyEventType = null, code:Int = -1) {
		
		this.type = type;
		this.code = code;
		
	}
	
	
	public function clone ():KeyEvent {
		
		return new KeyEvent (type, code);
		
	}
	
	
}


@:enum abstract KeyEventType(Int) {
	
	var KEY_DOWN = 0;
	var KEY_UP = 1;
	
}