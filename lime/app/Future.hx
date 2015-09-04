package lime.app;


@:allow(lime.app.Promise)


class Future<T> {
	
	
	public var isCompleted (get, null):Bool;
	public var value:T;
	
	private var __completed:Bool;
	private var __completeListeners:Array<T->Void>;
	private var __errored:Bool;
	private var __errorListeners:Array<Dynamic->Void>;
	private var __errorMessage:Dynamic;
	private var __progressListeners:Array<Float->Void>;
	
	
	public function new (work:Void->T = null) {
		
		if (work != null) {
			
			try {
				
				value = work ();
				__completed = true;
				
			} catch (e:Dynamic) {
				
				__errored = true;
				__errorMessage = e;
				
			}
			
		}
		
	}
	
	
	public function onComplete (listener:T->Void):Future<T> {
		
		if (listener != null) {
			
			if (__completed) {
				
				listener (value);
				
			} else if (!__errored) {
				
				if (__completeListeners == null) {
					
					__completeListeners = new Array ();
					
				}
				
				__completeListeners.push (listener);
				
			}
			
		}
		
		return this;
		
	}
	
	
	public function onError (listener:Dynamic->Void):Future<T> {
		
		if (listener != null) {
			
			if (__errored) {
				
				listener (__errorMessage);
				
			} else if (!__completed) {
				
				if (__errorListeners == null) {
					
					__errorListeners = new Array ();
					
				}
				
				__errorListeners.push (listener);
				
			}
			
		}
		
		return this;
		
	}
	
	
	public function onProgress (listener:Float->Void):Future<T> {
		
		if (listener != null) {
			
			if (__progressListeners == null) {
				
				__progressListeners = new Array ();
				
			}
			
			__progressListeners.push (listener);
			
		}
		
		return this;
		
	}
	
	
	public function then<U> (next:T->Future<U>):Future<U> {
		
		if (__completed) {
			
			return next (value);
			
		} else if (__errored) {
			
			var future = new Future<U> ();
			future.onError (__errorMessage);
			return future;
			
		} else {
			
			var promise = new Promise<U> ();
			
			onError (promise.error);
			onProgress (promise.progress);
			
			onComplete (function (val) {
				
				var future = next (val);
				future.onError (promise.error);
				future.onComplete (promise.complete);
				
			});
			
			return promise.future;
			
		}
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_isCompleted ():Bool {
		
		return (__completed || __errored);
		
	}
	
	
}