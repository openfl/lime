package lime.vm;


#if !macro
@:build(lime.system.CFFI.build())
#end


class NekoVM {
	
	
	public static function loadModule (path:String):Void {
		
		lime_neko_execute (path);
		
	}
	
	
	@:cffi private static function lime_neko_execute (module:String):Void;
	
	
}