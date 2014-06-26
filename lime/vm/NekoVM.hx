package lime.vm;


import lime.system.System;


class NekoVM {
	
	
	public static function loadModule (path:String):Void {
		
		lime_neko_execute (path);
		
	}
	
	
	private static var lime_neko_execute = System.load ("lime", "lime_neko_execute", 1);
	
	
}