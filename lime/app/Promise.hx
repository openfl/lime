package lime.app;


@:allow(lime.app.Future)


class Promise<T> {
	
	
	public var future (default, null):Future<T>;
	public var isCompleted (get, null):Bool;
	
	
	public function new () {
		
		future = new Future ();
		
	}
	
	
	public function complete (data:T):Promise<T> {
		
		if (!future.__errored) {
			
			future.__completed = true;
			future.value = data;
			
			if (future.__completeListeners != null) {
				
				for (listener in future.__completeListeners) {
					
					listener (data);
					
				}
				
				future.__completeListeners = null;
				
			}
			
		}
		
		return this;
		
	}
	
	
	public function completeWith (future:Future<T>):Promise<T> {
		
		future.onComplete (complete);
		future.onError (error);
		future.onProgress (progress);
		
		return this;
		
	}
	
	
	
	public function error (msg:Dynamic):Promise<T> {
		
		if (!future.__completed) {
			
			future.__errored = true;
			future.__errorMessage = msg;
			
			if (future.__errorListeners != null) {
				
				for (listener in future.__errorListeners) {
					
					listener (msg);
					
				}
				
				future.__errorListeners = null;
				
			}
			
		}
		
		return this;
		
	}
	
	
	public function progress (progress:Float):Promise<T> {
		
		if (!future.__errored && !future.__completed) {
			
			if (future.__progressListeners != null) {
				
				for (listener in future.__progressListeners) {
					
					listener (progress);
					
				}
				
			}
			
		}
		
		return this;
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_isCompleted ():Bool {
		
		return future.isCompleted;
		
	}
	
	
}