package lime.app;


import lime.system.System;
import lime.system.ThreadPool;
import lime.utils.Log;

@:allow(lime.app.Promise)


/*@:generic*/ class Future<T> {
	
	
	public var error (default, null):Dynamic;
	public var isComplete (default, null):Bool;
	public var isError (default, null):Bool;
	public var value (default, null):T;
	
	private var __completeListeners:Array<T->Void>;
	private var __errorListeners:Array<Dynamic->Void>;
	private var __progressListeners:Array<Float->Void>;
	
	
	public function new (work:Void->T = null) {
		
		if (work != null) {
			
			var promise = new Promise<T> ();
			promise.future = this;
			
			FutureWork.queue ({ promise: promise, work: work });
			
		}
		
	}
	
	
	public function onComplete (listener:T->Void):Future<T> {
		
		if (listener != null) {
			
			if (isComplete) {
				
				listener (value);
				
			} else if (!isError) {
				
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
			
			if (isError) {
				
				listener (error);
				
			} else if (!isComplete) {
				
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
	
	
	public function ready (waitTime:Int = -1):Future<T> {
		
		#if js
		
		if (isComplete || isError) {
			
			return this;
			
		} else {
			
			Log.warn ("Cannot block thread in JavaScript");
			return this;
			
		}
		
		#else
		
		if (isComplete || isError) {
			
			return this;
			
		} else {
			
			var time = System.getTimer ();
			var end = (waitTime > -1) ? time + waitTime : time;
			
			while (!isComplete && !isError && time <= end) {
				
				#if sys
				Sys.sleep (0.01);
				#end
				
				time = System.getTimer ();
				
			}
			
			return this;
			
		}
		
		#end
		
	}
	
	
	public function result (waitTime:Int = -1):Null<T> {
		
		ready (waitTime);
		
		if (isComplete) {
			
			return value;
			
		} else {
			
			return null;
			
		}
		
	}
	
	
	public function then<U> (next:T->Future<U>):Future<U> {
		
		if (isComplete) {
			
			return next (value);
			
		} else if (isError) {
			
			var future = new Future<U> ();
			future.onError (error);
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
	
	
}


@:dox(hide) private class FutureWork {
	
	
	private static var threadPool:ThreadPool;
	
	
	public static function queue (state:Dynamic = null):Void {
		
		if (threadPool == null) {
			
			threadPool = new ThreadPool ();
			threadPool.doWork.add (threadPool_doWork);
			threadPool.onComplete.add (threadPool_onComplete);
			threadPool.onError.add (threadPool_onError);
			
		}
		
		threadPool.queue (state);
		
	}
	
	
	
	
	// Event Handlers
	
	
	
	
	private static function threadPool_doWork (state:Dynamic):Void {
		
		try {
			
			var result = state.work ();
			threadPool.sendComplete ({ promise: state.promise, result: result } );
			
		} catch (e:Dynamic) {
			
			threadPool.sendError ({ promise: state.promise, error: e } );
			
		}
		
	}
	
	
	private static function threadPool_onComplete (state:Dynamic):Void {
		
		state.promise.complete (state.result);
		
	}
	
	
	private static function threadPool_onError (state:Dynamic):Void {
		
		state.promise.error (state.error);
		
	}
	
	
}