package lime._internal.macros; #if macro


import haxe.macro.Compiler;
import haxe.macro.Context;


class DefineMacro {
	
	
	public static function run ():Void {
		
		if (!Context.defined ("tools")) {
			
			if (Context.defined ("flash")) {
				
				if (Context.defined ("air")) {
					
					var childPath = Context.resolvePath ("lime/_internal");
					
					var parts = StringTools.replace (childPath, "\\", "/").split ("/");
					parts.pop (); // lime
					parts.pop (); // src
					parts.pop (); // root directory
					
					var externPath = parts.join ("/") + "/externs/air";
					
					Compiler.addClassPath (externPath);
					
				}
				
			} else if (Context.defined ("js")) {
				
				if (!Context.defined ("nodejs") && !Context.defined ("display")) {
					
					Compiler.define ("html5");
					Compiler.define ("web");
					Compiler.define ("lime-opengl");
					
				}
				
			} else {
				
				Compiler.define ("native");
				
				if (!Context.defined ("nocffi")) {
					
					Compiler.define ("lime-cffi");
					Compiler.define ("lime-curl");
					Compiler.define ("lime-harfbuzz");
					Compiler.define ("lime-opengl");
					Compiler.define ("lime-vorbis");
					
				}
				
			}
			
		}
		
	}
	
	
}


#end