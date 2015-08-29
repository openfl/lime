package lime.vm;


import lime.system.System;


class NekoVM {
	
	
	public static function loadModule (path:String):Void {
		
		lime_neko_execute.call (path);
		
	}
	
	
	private static var lime_neko_execute = System.loadPrime ("lime", "lime_neko_execute", "sv");
	
	
}