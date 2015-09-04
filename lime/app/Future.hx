package lime.app;
import lime.system.ThreadPool;


@:allow(lime.app.Promise)


class Future<T> {
	
	
	private static var __threadPool:ThreadPool;
	private static var __workID:Int;
	
	public var isCompleted (get, null):Bool;
	public var value (default, null):T;
	
	private var __completed:Bool;
	private var __completeListeners:Array<T->Void>;
	private var __errored:Bool;
	private var __errorListeners:Array<Dynamic->Void>;
	private var __errorMessage:Dynamic;
	private var __progressListeners:Array<Float->Void>;
	
	
	public function new (work:Void->T = null) {
		
		if (work != null) {
			
			if (__threadPool == null) {
				
				__threadPool = new ThreadPool ();
				__threadPool.doWork.add (threadPool_doWork);
				__threadPool.onComplete.add (threadPool_onComplete);
				__threadPool.onError.add (threadPool_onError);
				__workID = 1;
				
			}
			
			var promise = new Promise<T> ();
			promise.future = this;
			
			__threadPool.queue (Std.string (__workID++), { promise: promise, work: work } );
			
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
	
	
	
	
	// Event Handlers
	
	
	
	
	private static function threadPool_doWork (id:String, data:Dynamic):Void {
		
		try {
			
			var result = data.work ();
			__threadPool.sendComplete (id, { promise: data.promise, result: result } );
			
		} catch (e:Dynamic) {
			
			__threadPool.sendError (id, { promise: data.promise, error: e } );
			
		}
		
	}
	
	
	private static function threadPool_onComplete (id:String, data:Dynamic):Void {
		
		data.promise.complete (data.result);
		
	}
	
	
	private static function threadPool_onError (id:String, data:Dynamic):Void {
		
		data.promise.error (data.error);
		
	}
	
	
	
	
	// Get & Set Methods
	
	
	
	
	private function get_isCompleted ():Bool {
		
		return (__completed || __errored);
		
	}
	
	
}