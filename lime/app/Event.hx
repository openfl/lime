package lime.app;


import haxe.macro.Context;
import haxe.macro.Expr;


class Event<T> {
	
	
	@:noCompletion public var listeners:Array<T>;
	
	private var priorities:Array<Int>;
	
	
	public function new () {
		
		listeners = new Array<T> ();
		priorities = new Array<Int> ();
		
	}
	
	
	public function add (listener:T, priority:Int = 0):Void {
		
		for (i in 0...priorities.length) {
			
			if (priority > priorities[i]) {
				
				listeners.insert (i, listener);
				priorities.insert (i, priority);
				return;
				
			}
			
		}
		
		listeners.push (listener);
		priorities.push (priority);
		
	}
	
	
	macro public function dispatch (ethis:Expr, args:Array<Expr>) {
		
		return macro {
			
			for (listener in $ethis.listeners) {
				
				listener ($a{args});
				
			}
			
		}
		
	}
	
	public function remove (listener:T):Void {
		
		var index = listeners.indexOf (listener);
		
		if (index > -1) {
			
			listeners.splice (index, 1);
			priorities.splice (index, 1);
			
		}
		
	}
	
	
}