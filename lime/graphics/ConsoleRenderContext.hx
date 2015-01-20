package lime.graphics; #if lime_console


import lime.system.System;


class ConsoleRenderContext {
	
	
	private var depth = 0.0;
	private var stencil = 0;
	
	
	public function new () {
		
		
		
	}
	
	
	public inline function clear ():Void {
		
		lime_console_render_clear ();
		
	}
	
	
	public inline function clearColor (r:Float, g:Float, b:Float, a:Float):Void {
		
		lime_console_render_set_clear_color (r, g, b, a);
		
	}
	
	
	public inline function clearDepth (depth:Float):Void {
		
		this.depth = depth;
		
		lime_console_render_set_clear_depth_stencil (depth, stencil);
		
	}
	
	
	public inline function clearStencil (stencil:Int):Void {
		
		this.stencil = stencil;
		
		lime_console_render_set_clear_depth_stencil (depth, stencil);
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private static var lime_console_render_set_clear_color = System.load ("lime", "lime_console_render_set_clear_color", 4);
	private static var lime_console_render_set_clear_depth_stencil = System.load ("lime", "lime_console_render_set_clear_depth_stencil", 2);
	private static var lime_console_render_clear = System.load ("lime", "lime_console_render_clear", 0);
	
	
}


#else


class ConsoleRenderContext {
	
	
	public function new () {
		
		
		
	}
	
	
	public function clear ():Void {}
	public function clearColor (r:Float, g:Float, b:Float, a:Float):Void {}
	public function clearDepth (depth:Float):Void {}
	public function clearStencil (stencil:Int):Void {}
	
	
}


#end