package lime.app;


class Future<T> {
	
	
	private var __completeData:T;
	private var __completed:Bool;
	private var __completeListeners:Array<T->Void>;
	private var __errored:Bool;
	private var __errorListeners:Array<String->Void>;
	private var __errorMessage:String;
	private var __progressListeners:Array<Float->Void>;
	
	
	public function new () {
		
		
		
	}
	
	
	public function onComplete (listener:T->Void):Future<T> {
		
		if (__completed) {
			
			listener (__completeData);
			
		} else if (!__errored) {
			
			if (__completeListeners == null) {
				
				__completeListeners = new Array ();
				
			}
			
			__completeListeners.push (listener);
			
		}
		
		return this;
		
	}
	
	
	public function onError (listener:String->Void):Future<T> {
		
		if (__errored) {
			
			listener (__errorMessage);
			
		} else if (!__completed) {
			
			if (__errorListeners == null) {
				
				__errorListeners = new Array ();
				
			}
			
			__errorListeners.push (listener);
			
		}
		
		return this;
		
	}
	
	
	public function onProgress (listener:Float->Void):Future<T> {
		
		if (__progressListeners == null) {
			
			__progressListeners = new Array ();
			
		}
		
		__progressListeners.push (listener);
		
		return this;
		
	}
	
	
	public function sendComplete (data:T):Void {
		
		if (!__errored) {
			
			__completed = true;
			__completeData = data;
			
			if (__completeListeners != null) {
				
				for (listener in __completeListeners) {
					
					listener (data);
					
				}
				
				__completeListeners = null;
				
			}
			
		}
		
	}
	
	
	public function sendError (msg:String):Void {
		
		if (!__completed) {
			
			__errored = true;
			__errorMessage = msg;
			
			if (__errorListeners != null) {
				
				for (listener in __errorListeners) {
					
					listener (msg);
					
				}
				
				__errorListeners = null;
				
			}
			
		}
		
	}
	
	
	public function sendProgress (progress:Float):Void {
		
		if (!__errored && !__completed) {
			
			if (__progressListeners != null) {
				
				for (listener in __progressListeners) {
					
					listener (progress);
					
				}
				
			}
			
		}
		
	}
	
	
}