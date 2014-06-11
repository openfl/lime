package lime.ui;


import lime.app.Application;
import lime.app.Config;
import lime.app.UpdateEventManager;
import lime.graphics.Renderer;
import lime.graphics.RenderEvent;
import lime.graphics.RenderEventManager;
import lime.system.System;

#if js
import lime.graphics.opengl.GL;
import js.html.webgl.RenderingContext;
import js.html.CanvasElement;
import js.html.HtmlElement;
import js.Browser;
#end


class Window {
	
	
	public static var instance:Window;
	
	public var currentRenderer:Renderer;
	#if js
	public var element:HtmlElement;
	#end
	public var handle:Dynamic;
	public var height:Int;
	#if (js && stats)
	public var stats:Dynamic;
	#end
	public var width:Int;
	
	private var application:Application;
	#if js
	private var canvas:CanvasElement;
	#end
	
	
	public function new (application:Application) {
		
		instance = this;
		
		this.application = application;
		
	}
	
	
	public function create ():Void {
		
		#if js
		
		if (Std.is (element, CanvasElement)) {
			
			canvas = cast element;
			
		} else {
			
			canvas = cast Browser.document.createElement ("canvas");
			
		}
		
		var context:RenderingContext = cast canvas.getContext ("webgl");
		
		if (context == null) {
			
			context = cast canvas.getContext ("experimental-webgl");
			
		}
		
		#if debug
		context = untyped WebGLDebugUtils.makeDebugContext (context);
		#end
		
		GL.context = context;
		
		var style = canvas.style;
		style.setProperty ("-webkit-transform", "translateZ(0)", null);
		style.setProperty ("transform", "translateZ(0)", null);
		
		//__originalWidth = width;
		//__originalHeight = height;
		
		if (width == 0 && height == 0) {
			
			if (element != null) {
				
				width = element.clientWidth;
				height = element.clientHeight;
				
			} else {
				
				width = Browser.window.innerWidth;
				height = Browser.window.innerHeight;
				
			}
			
			//__fullscreen = true;
			
		}
		
		//stageWidth = width;
		//stageHeight = height;
		
		if (canvas != null) {
			
			canvas.width = width;
			canvas.height = height;
			
		/*} else {
			
			__div.style.width = width + "px";
			__div.style.height = height + "px";
		*/
		}
		
		//__resize ();
		
		//Browser.window.addEventListener ("resize", window_onResize);
		//Browser.window.addEventListener ("focus", window_onFocus);
		//Browser.window.addEventListener ("blur", window_onBlur);
		
		if (element != null) {
			
			if (canvas != null) {
				
				if (element != cast canvas) {
					
					element.appendChild (canvas);
					
				}
				
			} else {
				
				//element.appendChild (__div);
				
			}
			
		}
		
		#if stats
		stats = untyped __js__("new Stats ()");
		stats.domElement.style.position = "absolute";
		stats.domElement.style.top = "0px";
		Browser.document.body.appendChild (stats.domElement);
		#end
		
		/*var keyEvents = [ "keydown", "keyup" ];
		var touchEvents = [ "touchstart", "touchmove", "touchend" ];
		var mouseEvents = [ "mousedown", "mousemove", "mouseup", "click", "dblclick", "mousewheel" ];
		var focusEvents = [ "focus", "blur" ];
		
		var element = __canvas != null ? __canvas : __div;
		
		for (type in keyEvents) {
			
			Browser.window.addEventListener (type, window_onKey, false);
			
		}
		
		for (type in touchEvents) {
			
			element.addEventListener (type, element_onTouch, true);
			
		}
		
		for (type in mouseEvents) {
			
			element.addEventListener (type, element_onMouse, true);
			
		}
		
		for (type in focusEvents) {
			
			element.addEventListener (type, element_onFocus, true);
			
		}
		
		Browser.window.requestAnimationFrame (cast __render);
		*/
		
		#elseif (cpp || neko)
		handle = lime_window_create (application.handle);
		#end
		
		KeyEventManager.registerWindow (this);
		MouseEventManager.registerWindow (this);
		RenderEventManager.registerWindow (this);
		TouchEventManager.registerWindow (this);
		UpdateEventManager.registerWindow (this);
		WindowEventManager.registerWindow (this);
		
		if (currentRenderer != null) {
			
			currentRenderer.create ();
			
		}
		
	}
	
	
	#if (cpp || neko)
	private static var lime_window_create = System.load ("lime", "lime_window_create", 1);
	#end
	
	
}