package lime._internal.macros; #if macro


import haxe.macro.Compiler;
import haxe.macro.Context;


class DefineMacro {
	
	
	public static function run ():Void {
		
		if (!Context.defined ("tools") && !Context.defined ("nocffi")) {
			
			if (!Context.defined ("flash") && (!Context.defined ("js") || Context.defined ("nodejs"))) {
				
				Compiler.define ("lime-cffi");
				Compiler.define ("native");
				Compiler.define ("lime-curl");
				Compiler.define ("lime-vorbis");
				
			}
			
			if (Context.defined ("js") && !Context.defined ("nodejs") && !Context.defined ("display")) {
				
				Compiler.define ("html5");
				Compiler.define ("web");
				Compiler.define ("lime-opengl");
				
			}
			
		}
		
	}
	
	
}


#end