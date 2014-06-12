package lime.graphics;


import lime.graphics.canvas.CanvasRenderContext;
import lime.graphics.dom.DOMRenderContext;
import lime.graphics.opengl.GLRenderContext;


enum RenderContext {
	
	OPENGL (gl:GLRenderContext);
	CANVAS (context:CanvasRenderContext);
	DOM (element:DOMRenderContext);
	CUSTOM (context:Dynamic);
	
}