package lime.ui;


class KeyEvent {
	
	
	public var altKey:Bool;
	public var code:Int;
	public var ctrlKey:Bool;
	public var key:Int;
	public var location:KeyEventLocation;
	public var metaKey:Bool;
	public var shiftKey:Bool;
	public var type:KeyEventType;
	
	
	public function new (type:KeyEventType = null, code:Int = 0, key:Int = 0, location:KeyEventLocation = null, ctrlKey:Bool = false, altKey:Bool = false, shiftKey:Bool = false, metaKey:Bool = false) {
		
		this.type = type;
		this.code = code;
		this.key = key;
		this.location = location;
		this.ctrlKey = ctrlKey;
		this.altKey = altKey;
		this.shiftKey = shiftKey;
		this.metaKey = metaKey;
		
	}
	
	
	public function clone ():KeyEvent {
		
		return new KeyEvent (type, code, key, location, ctrlKey, altKey, shiftKey, metaKey);
		
	}
	
	
}


@:enum abstract KeyEventLocation(Int) {
	
	var KEY_LOCATION_STANDARD = 0;
	var KEY_LOCATION_LEFT = 1;
	var KEY_LOCATION_RIGHT = 2;
	var KEY_LOCATION_NUMPAD = 3;
	
}


@:enum abstract KeyEventType(Int) {
	
	var KEY_DOWN = 0;
	var KEY_UP = 1;
	
}