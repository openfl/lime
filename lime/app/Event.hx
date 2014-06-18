package lime.app;


import haxe.macro.Context;
import haxe.macro.Expr;


class Event<T> {
	
	
	@:noCompletion public var listeners:Array<T>;
	@:noCompletion public var repeat:Array<Bool>;
	
	private var priorities:Array<Int>;
	
	
	public function new () {
		
		listeners = new Array<T> ();
		priorities = new Array<Int> ();
		repeat = new Array<Bool> ();
		
	}
	
	
	public function add (listener:T, once:Bool = false, priority:Int = 0):Void {
		
		for (i in 0...priorities.length) {
			
			if (priority > priorities[i]) {
				
				listeners.insert (i, listener);
				priorities.insert (i, priority);
				repeat.insert (i, !once);
				return;
				
			}
			
		}
		
		listeners.push (listener);
		priorities.push (priority);
		repeat.push (!once);
		
	}
	
	
	macro public function dispatch (ethis:Expr, args:Array<Expr>) {
		
		return macro {
			
			var listeners = $ethis.listeners;
			var repeat = $ethis.repeat;
			var length = listeners.length;
			var i = 0;
			
			while (i < length) {
				
				listeners[i] ($a{args});
				
				if (!repeat[i]) {
					
					$ethis.remove (listeners[i]);
					length--;
					
				} else {
					
					i++;
					
				}
				
			}
			
		}
		
	}
	
	
	public function remove (listener:T):Void {
		
		var index = listeners.indexOf (listener);
		
		if (index > -1) {
			
			listeners.splice (index, 1);
			priorities.splice (index, 1);
			repeat.splice (index, 1);
			
		}
		
	}
	
	
}