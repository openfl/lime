package lime.system;


import lime.app.Application;
import lime.app.Event;

#if cpp
import cpp.vm.Deque;
import cpp.vm.Mutex;
import cpp.vm.Thread;
#elseif neko
import neko.vm.Deque;
import neko.vm.Mutex;
import neko.vm.Thread;
#end


class WorkerThread {
	
	
	public var active (default, null):Bool;
	public var doWork:Void->Void;
	public var onComplete = new Event<Void->Void> ();
	public var onUpdate = new Event<Dynamic->Void> ();
	
	#if (cpp || neko)
	private var messageQueue:Deque<Dynamic>;
	private var mutex:Mutex;
	private var workerThread:Thread;
	#end
	
	
	public function new () {
		
		
		
	}
	
	
	public function run ():Void {
		
		active = true;
		
		#if (cpp || neko)
		
		messageQueue = new Deque<Dynamic> ();
		mutex = new Mutex ();
		workerThread = Thread.create (__doWork);
		
		Application.current.onUpdate.add (__update);
		
		#else
		
		__doWork ();
		
		#end
		
	}
	
	
	public function sendUpdate (message:Dynamic):Void {
		
		#if (cpp || neko)
		
		messageQueue.add (message);
		
		#else
		
		if (active) {
			
			onUpdate.dispatch (message);
			
		}
		
		#end
		
	}
	
	
	public function stop ():Void {
		
		active = false;
		
		#if (cpp || neko)
		
		workerThread = null;
		
		#end
		
	}
	
	
	private function __doWork ():Void {
		
		if (doWork != null) {
			
			doWork ();
			
		}
		
		#if (cpp || neko)
		
		messageQueue.add ("__DONE");
		
		#else
		
		active = false;
		onComplete.dispatch ();
		
		#end
		
	}
	
	
	private function __update (deltaTime:Int):Void {
		
		#if (cpp || neko)
		
		var message = messageQueue.pop (false);
		
		if (message != null) {
			
			if (message != "__DONE") {
				
				if (active) {
					
					onUpdate.dispatch (message);
					
				}
				
			} else {
				
				Application.current.onUpdate.remove (__update);
				
				if (active) {
					
					active = false;
					onComplete.dispatch ();
					
				}
				
			}
			
		}
		
		#end
		
	}
	
	
}