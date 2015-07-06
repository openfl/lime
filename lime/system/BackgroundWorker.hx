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


class BackgroundWorker {
	
	
	public var canceled (default, null):Bool;
	public var doWork = new Event<Dynamic->Void> ();
	public var onComplete = new Event<Dynamic->Void> ();
	public var onProgress = new Event<Dynamic->Void> ();
	
	private var __runMessage:Dynamic;
	
	#if (cpp || neko)
	private var __messageQueue:Deque<Dynamic>;
	private var __workerThread:Thread;
	#end
	
	
	public function new () {
		
		
		
	}
	
	
	public function cancel ():Void {
		
		canceled = true;
		
		#if (cpp || neko)
		
		__workerThread = null;
		
		#end
		
	}
	
	
	public function run (message:Dynamic = null):Void {
		
		canceled = false;
		__runMessage = message;
		
		#if (cpp || neko)
		
		__messageQueue = new Deque<Dynamic> ();
		__workerThread = Thread.create (__doWork);
		
		Application.current.onUpdate.add (__update);
		
		#else
		
		__doWork ();
		
		#end
		
	}
	
	
	public function sendComplete (message:Dynamic):Void {
		
		#if (cpp || neko)
		
		__messageQueue.add ("__DONE__");
		__messageQueue.add (message);
		
		#else
		
		if (!canceled) {
			
			canceled = true;
			onComplete.dispatch (message);
			
		}
		
		#end
		
	}
	
	
	public function sendProgress (message:Dynamic):Void {
		
		#if (cpp || neko)
		
		__messageQueue.add (message);
		
		#else
		
		if (!canceled) {
			
			onProgress.dispatch (message);
			
		}
		
		#end
		
	}
	
	
	private function __doWork ():Void {
		
		doWork.dispatch (__runMessage);
		
		#if (cpp || neko)
		
		__messageQueue.add ("__DONE__");
		
		#else
		
		if (!canceled) {
			
			canceled = true;
			onComplete.dispatch (null);
			
		}
		
		#end
		
	}
	
	
	private function __update (deltaTime:Int):Void {
		
		#if (cpp || neko)
		
		var message = __messageQueue.pop (false);
		
		if (message != null) {
			
			if (message != "__DONE__") {
				
				if (!canceled) {
					
					onProgress.dispatch (message);
					
				}
				
			} else {
				
				Application.current.onUpdate.remove (__update);
				
				if (!canceled) {
					
					canceled = true;
					onComplete.dispatch (__messageQueue.pop (false));
					
				}
				
			}
			
		}
		
		#end
		
	}
	
	
}