package lime.app;


/*@:generic*/ class EventManager<T> {
	
	
	private var listeners:Array<T>;
	private var priorities:Array<Int>;
	
	
	private function new () {
		
		listeners = new Array ();
		priorities = new Array ();
		
	}
	
	
	private function _addEventListener (listener:T, priority:Int):Void {
		
		for (i in 0...priorities.length) {
			
			if (priority > priorities[i]) {
				
				listeners.insert (i, listener);
				priorities.insert (i, priority);
				return;
				
			}
			
		}
		
		listeners.push (listener);
		priorities.push (priority);
		
	}
	
	
	private function _removeEventListener (listener:T):Void {
		
		var index = listeners.indexOf (listener);
		
		if (index > -1) {
			
			listeners.splice (index, 1);
			priorities.splice (index, 1);
			
		}
		
	}
	
	
}