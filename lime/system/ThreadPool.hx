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
	public var doWork = new Event<Dynamic->Void> ();
	public var maxThreads:Int;
	public var minThreads:Int;
	public var onComplete = new Event<Dynamic->Void> ();
	public var onError = new Event<Dynamic->Void> ();
	public var onProgress = new Event<Dynamic->Void> ();
	
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
	
	
	public function queue (state:Dynamic = null):Void {
		
		#if (cpp || neko)
		
		__workIncoming.add (new ThreadPoolMessage (WORK, state));
		__workQueued++;
		
		if (currentThreads < maxThreads && currentThreads < (__workQueued - __workCompleted)) {
			
			currentThreads++;
			Thread.create (__doWork);
			
		}
		
		if (!Application.current.onUpdate.has (__update)) {
			
			Application.current.onUpdate.add (__update);
			
		}
		
		#else
		
		doWork.dispatch (state);
		
		#end
		
	}
	
	
	public function sendComplete (state:Dynamic = null):Void {
		
		#if (cpp || neko)
		__workResult.add (new ThreadPoolMessage (COMPLETE, state));
		#else
		onComplete.dispatch (state);
		#end
		
	}
	
	
	public function sendError (state:Dynamic = null):Void {
		
		#if (cpp || neko)
		__workResult.add (new ThreadPoolMessage (ERROR, state));
		#else
		onError.dispatch (state);
		#end
		
	}
	
	
	public function sendProgress (state:Dynamic = null):Void {
		
		#if (cpp || neko)
		__workResult.add (new ThreadPoolMessage (PROGRESS, state));
		#else
		onProgress.dispatch (state);
		#end
		
	}
	
	
	#if (cpp || neko)
	
	private function __doWork ():Void {
		
		while (true) {
			
			var message = __workIncoming.pop (true);
			
			if (message.type == WORK) {
				
				doWork.dispatch (message.state);
				
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
						
						onProgress.dispatch (message.state);
					
					case COMPLETE, ERROR:
						
						__workCompleted++;
						
						if (currentThreads > (__workQueued - __workCompleted) || currentThreads > maxThreads) {
							
							currentThreads--;
							__workIncoming.add (new ThreadPoolMessage (EXIT, null));
							
						}
						
						if (message.type == COMPLETE) {
							
							onComplete.dispatch (message.state);
							
						} else {
							
							onError.dispatch (message.state);
							
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
	
	
	public var state:Dynamic;
	public var type:ThreadPoolMessageType;
	
	
	public function new (type:ThreadPoolMessageType, state:Dynamic) {
		
		this.type = type;
		this.state = state;
		
	}
	
	
}