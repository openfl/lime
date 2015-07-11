package lime.system;


import lime.app.Application;
import lime.app.Event;

#if cpp
import cpp.vm.Deque;
import cpp.vm.Thread;
#elseif neko
import neko.vm.Deque;
import neko.vm.Thread;
#end


class ThreadPool {
	
	
	public var currentThreads (default, null):Int;
	public var doWork = new Event<String->Dynamic->Void> ();
	public var maxThreads:Int;
	public var minThreads:Int;
	public var onComplete = new Event<String->Dynamic->Void> ();
	public var onError = new Event<String->Dynamic->Void> ();
	public var onProgress = new Event<String->Dynamic->Void> ();
	
	#if (cpp || neko)
	private var __workCompleted:Int;
	private var __workIncoming = new Deque<ThreadPoolMessage> ();
	private var __workQueued:Int;
	private var __workResult = new Deque<ThreadPoolMessage> ();
	#end
	
	
	public function new (minThreads:Int = 0, maxThreads:Int = 1) {
		
		this.minThreads = minThreads;
		this.maxThreads = maxThreads;
		
		currentThreads = 0;
		
		#if (cpp || neko)
		__workQueued = 0;
		__workCompleted = 0;
		#end
		
	}
	
	
	//public function cancel (id:String):Void {
		//
		//
		//
	//}
	
	
	//public function isCanceled (id:String):Bool {
		//
		//
		//
	//}
	
	
	public function queue (id:String, message:Dynamic = null):Void {
		
		#if (cpp || neko)
		
		__workIncoming.add (new ThreadPoolMessage (WORK, id, message));
		__workQueued++;
		
		if (currentThreads < maxThreads && currentThreads < (__workQueued - __workCompleted)) {
			
			currentThreads++;
			Thread.create (__doWork);
			
		}
		
		if (!Application.current.onUpdate.has (__update)) {
			
			Application.current.onUpdate.add (__update);
			
		}
		
		#else
		
		doWork.dispatch (id, message);
		
		#end
		
	}
	
	
	public function sendComplete (id:String, message:Dynamic = null):Void {
		
		#if (cpp || neko)
		__workResult.add (new ThreadPoolMessage (COMPLETE, id, message));
		#else
		onComplete.dispatch (id, message);
		#end
		
	}
	
	
	public function sendError (id:String, message:Dynamic = null):Void {
		
		#if (cpp || neko)
		__workResult.add (new ThreadPoolMessage (ERROR, id, message));
		#else
		onError.dispatch (id, message);
		#end
		
	}
	
	
	public function sendProgress (id:String, message:Dynamic = null):Void {
		
		#if (cpp || neko)
		__workResult.add (new ThreadPoolMessage (PROGRESS, id, message));
		#else
		onProgress.dispatch (id, message);
		#end
		
	}
	
	
	#if (cpp || neko)
	
	private function __doWork ():Void {
		
		while (true) {
			
			var message = __workIncoming.pop (true);
			
			if (message.type == WORK) {
				
				doWork.dispatch (message.id, message.message);
				
			} else if (message.type == EXIT) {
				
				break;
				
			}
			
		}
		
	}
	
	
	private function __update (deltaTime:Int):Void {
		
		if (__workQueued > __workCompleted) {
			
			var message = __workResult.pop (false);
			
			while (message != null) {
				
				switch (message.type) {
					
					case PROGRESS:
						
						onProgress.dispatch (message.id, message.message);
					
					case COMPLETE, ERROR:
						
						__workCompleted++;
						
						if (currentThreads > (__workQueued - __workCompleted) || currentThreads > maxThreads) {
							
							currentThreads--;
							__workIncoming.add (new ThreadPoolMessage (EXIT, null, null));
							
						}
						
						if (message.type == COMPLETE) {
							
							onComplete.dispatch (message.id, message.message);
							
						} else {
							
							onError.dispatch (message.id, message.message);
							
						}
					
					default:
					
				}
				
				message = __workResult.pop (false);
				
			}
			
		} else {
			
			// TODO: Add sleep if keeping minThreads running with no work?
			
			if (currentThreads == 0 && minThreads <= 0) {
				
				Application.current.onUpdate.remove (__update);
				
			}
			
		}
		
	}
	
	#end
	
	
}


private enum ThreadPoolMessageType {
	
	COMPLETE;
	ERROR;
	EXIT;
	PROGRESS;
	WORK;
	
}


private class ThreadPoolMessage {
	
	
	public var id:String;
	public var message:Dynamic;
	public var type:ThreadPoolMessageType;
	
	
	public function new (type:ThreadPoolMessageType, id:String, message:Dynamic) {
		
		this.type = type;
		this.id = id;
		this.message = message;
		
	}
	
	
}