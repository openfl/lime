package lime.graphics; #if lime_console

import cpp.Float32;
import cpp.UInt8;
import cpp.UInt32;
import lime.ConsoleIncludePaths;
import lime.system.System;


@:headerCode("#include <ConsoleRenderContext.h>")
class ConsoleRenderContext {


	public function new() {



	}
	
	
	public inline function clear (a:UInt8, r:UInt8, g:UInt8, b:UInt8, depth:Float32 = 1.0, stencil:UInt8 = 0):Void {
		
		untyped __cpp__ ("lime::console_render_clear ({0}, {1}, {2}, {3}, {4}, {5})",
			a, r, g, b, depth, stencil);
		
	}
	
	
}


#else


class ConsoleRenderContext {
	
	
	public function new () {
		
		
		
	}
	
	
	public function clear (a:Int, r:Int, g:Int, b:Int, depth:Float = 1.0, stencil:Int = 0):Void {}
	
	
}


#end
