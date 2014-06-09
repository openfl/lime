package lime.app;


class UpdateEvent {
	
	
	public var deltaTime:Int;
	public var type:UpdateEventType;
	
	
	public function new (type:UpdateEventType = null, deltaTime:Int = 0) {
		
		this.type = type;
		this.deltaTime = deltaTime;
		
	}
	
	
	public function clone ():UpdateEvent {
		
		return new UpdateEvent (type, deltaTime);
		
	}
	
	
}


@:enum abstract UpdateEventType(Int) {
	
	var UPDATE = 0;
	
}