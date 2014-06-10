package lime.graphics;


class RenderEvent {
	
	
	public var type:RenderEventType;
	
	
	public function new (type:RenderEventType = null) {
		
		this.type = type;
		
	}
	
	
	public function clone ():RenderEvent {
		
		return new RenderEvent (type);
		
	}
	
	
}


@:enum abstract RenderEventType(Int) {
	
	var RENDER = 0;
	
}