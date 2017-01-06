package lime.vm;


import lime._backend.native.NativeCFFI;

@:access(lime._backend.native.NativeCFFI)


class NekoVM {
	
	
	public static function loadModule (path:String):Void {
		
		#if (lime_cffi && !macro)
		NativeCFFI.lime_neko_execute (path);
		#end
		
	}
	
	
}