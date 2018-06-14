package lime.app;


import lime.system.System;
import lime.system.ThreadPool;
import lime.utils.Log;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:allow(lime.app.Promise)


/*@:generic*/ class Future<T> {
	
	
	public var error (default, null):Dynamic;
	public var isComplete (default, null):Bool;
	public var isError (default, null):Bool;
	public var value (default, null):T;
	
	private var __completeListeners:Array<T->Void>;
	private var __errorListeners:Array<Dynamic->Void>;
	private var __progressListeners:Array<Int->Int->Void>;
	
	
	public function new (work:Void->T = null, async:Bool = false) {
		
		if (work != null) {
			
			if (async) {
				
				var promise = new Promise<T> ();
				promise.future = this;
				
				FutureWork.queue ({ promise: promise, work: work });
				
			} else {
				
				try {
					
					value = work ();
					isComplete = true;
					
				} catch (e:Dynamic) {
					
					error = e;
					isError = true;
					
				}
				
			}
			
		}
		
	}
	
	
	public static function ofEvents<T> (onComplete:Event<T->Void>, onError:Event<Dynamic->Void> = null, onProgress:Event<Int->Int->Void> = null):Future<T> {
		
		var promise = new Promise<T> ();
		
		onComplete.add (function (data) promise.complete (data), true);
		if (onError != null) onError.add (function (error) promise.error (error), true);
		if (onProgress != null) onProgress.add (function (progress, total) promise.progress (progress, total), true);
		
		return promise.future;
		
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
	
	
	public function onProgress (listener:Int->Int->Void):Future<T> {
		
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
			var end = time + waitTime;
			
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
			future.isError = true;
			future.error = error;
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
	
	
	public static function withError (error:Dynamic):Future<Dynamic> {
		
		var future = new Future<Dynamic> ();
		future.isError = true;
		future.error = error;
		return future;
		
	}
	
	
	public static function withValue<T> (value:T):Future<T> {
		
		var future = new Future<T> ();
		future.isComplete = true;
		future.value = value;
		return future;
		
	}
	
	
}


#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end


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