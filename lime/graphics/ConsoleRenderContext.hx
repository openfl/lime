package lime.graphics;


import lime.system.System;


class ConsoleRenderContext {
#if lime_console
	
	
	public function new () {
		
		
		
	}


	// setClearRGBA sets the RGBA color of a subsequent clear() call.
	public inline function setClearRGBA (red:Float, green:Float, blue:Float, alpha:Float):Void {
		
		lime_console_render_set_clear_color (red, green, blue, alpha);
		
	}


	// setClearDepthStencil sets the depth and stencil values for a subsequent clear() call.
	public inline function setClearDepthStencil (depth:Float, stencil:Int):Void {
		
		lime_console_render_set_clear_depth_stencil (depth, stencil);
		
	}


	// clear fills the current color and/or depth-stencil values of the buffer,
	// specified by the preceding setClear calls.
	public inline function clear ():Void {
		
		lime_console_render_clear ();
		
	}


	private static var lime_console_render_set_clear_color = System.load ("lime", "lime_console_render_set_clear_color", 4);
	private static var lime_console_render_set_clear_depth_stencil = System.load ("lime", "lime_console_render_set_clear_depth_stencil", 2);
	private static var lime_console_render_clear = System.load ("lime", "lime_console_render_clear", 0);
	
	
#end
}

