package lime.graphics;


import lime.graphics.CanvasRenderContext;
import lime.graphics.DOMRenderContext;
import lime.graphics.FlashRenderContext;
import lime.graphics.GLRenderContext;


enum RenderContext {
	
	OPENGL (gl:GLRenderContext);
	CANVAS (context:CanvasRenderContext);
	DOM (element:DOMRenderContext);
	FLASH (stage:FlashRenderContext);
	CUSTOM (data:Dynamic);
	
}