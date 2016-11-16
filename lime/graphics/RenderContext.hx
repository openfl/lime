package lime.graphics;


import lime.graphics.CanvasRenderContext;
import lime.graphics.ConsoleRenderContext;
import lime.graphics.DOMRenderContext;
import lime.graphics.FlashRenderContext;
import lime.graphics.GLRenderContext;


enum RenderContext {
	
	OPENGL (gl:GLRenderContext);
	CANVAS (context:CanvasRenderContext);
	DOM (element:DOMRenderContext);
	FLASH (stage:FlashRenderContext);
	CAIRO (cairo:CairoRenderContext);
	CONSOLE (context:ConsoleRenderContext);
	CUSTOM (data:Dynamic);
	NONE;
	
}