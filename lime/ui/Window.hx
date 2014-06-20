package lime.ui;


import lime.app.Application;
import lime.app.Config;
import lime.app.Event;
import lime.graphics.Renderer;
import lime.system.System;

#if js
import js.html.CanvasElement;
import js.html.DivElement;
import js.html.HtmlElement;
import js.Browser;
#elseif flash
import flash.Lib;
#end


@:access(lime.app.Application)


class Window {
	
	
	public inline static var DEPTH_BUFFER    = 0x0200;
   	public inline static var STENCIL_BUFFER  = 0x0400;
   	
   	public static var onWindowActivate = new Event<Void->Void> ();
	public static var onWindowDeactivate = new Event<Void->Void> ();
	
	private static var eventInfo = new WindowEventInfo ();
	private static var registered:Bool;
	
	public var currentRenderer:Renderer;
	public var config:Config;
	public var fullscreen:Bool;
	public var height:Int;
	public var width:Int;
	
	#if js
	public var canvas:CanvasElement;
	public var div:DivElement;
	public var element:HtmlElement;
	#if stats
	public var stats:Dynamic;
	#end
	#elseif (cpp || neko)
	public var handle:Dynamic;
	#end
	
	
	public function new (config:Config) {
		
		this.config = config;
		
		if (!registered) {
			
			registered = true;
			
			#if (cpp || neko)
			lime_window_event_manager_register (dispatch, eventInfo);
			#end
			
		}
		
	}
	
	
	public function create (application:Application):Void {
		
		#if js
		
		if (Std.is (element, CanvasElement)) {
			
			canvas = cast element;
			
		} else {
			
			#if dom
			div = cast Browser.document.createElement ("div");
			#else
			canvas = cast Browser.document.createElement ("canvas");
			#end
			
		}
		
		if (canvas != null) {
			
			var style = canvas.style;
			style.setProperty ("-webkit-transform", "translateZ(0)", null);
			style.setProperty ("transform", "translateZ(0)", null);
			
		} else if (div != null) {
			
			var style = div.style;
			style.setProperty ("-webkit-transform", "translate3D(0,0,0)", null);
			style.setProperty ("transform", "translate3D(0,0,0)", null);
			//style.setProperty ("-webkit-transform-style", "preserve-3d", null);
			//style.setProperty ("transform-style", "preserve-3d", null);
			style.position = "relative";
			style.overflow = "hidden";
			style.setProperty ("-webkit-user-select", "none", null);
			style.setProperty ("-moz-user-select", "none", null);
			style.setProperty ("-ms-user-select", "none", null);
			style.setProperty ("-o-user-select", "none", null);
			
		}
		
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
			
			fullscreen = true;
			
		}
		
		//stageWidth = width;
		//stageHeight = height;
		
		if (canvas != null) {
			
			canvas.width = width;
			canvas.height = height;
			
		} else {
			
			div.style.width = width + "px";
			div.style.height = height + "px";
			
		}
		
		//__resize ();
		//Browser.window.addEventListener ("resize", window_onResize);
		
		if (element != null) {
			
			if (canvas != null) {
				
				if (element != cast canvas) {
					
					element.appendChild (canvas);
					
				}
				
			} else {
				
				element.appendChild (div);
				
			}
			
		}
		
		#if stats
		stats = untyped __js__("new Stats ()");
		stats.domElement.style.position = "absolute";
		stats.domElement.style.top = "0px";
		Browser.document.body.appendChild (stats.domElement);
		#end
		
		#elseif (cpp || neko)
		// forward flags
		var flags:Int = 0;

		if (config.depthBuffer)
			flags |= DEPTH_BUFFER;
		
		if (config.stencilBuffer)
			flags |= STENCIL_BUFFER;
		
		handle = lime_window_create (application.__handle, flags);
		#end
		
		MouseEventManager.registerWindow (this);
		TouchEventManager.registerWindow (this);
		
		#if js
		Browser.window.addEventListener ("focus", handleDOMEvent, false);
		Browser.window.addEventListener ("blur", handleDOMEvent, false);
		#elseif flash
		Lib.current.stage.addEventListener (flash.events.Event.ACTIVATE, handleFlashEvent);
		Lib.current.stage.addEventListener (flash.events.Event.DEACTIVATE, handleFlashEvent);
		#end
		
		if (currentRenderer != null) {
			
			currentRenderer.create ();
			
		}
		
	}
	
	
	private static function dispatch ():Void {
		
		switch (eventInfo.type) {
			
			case WINDOW_ACTIVATE:
				
				onWindowActivate.dispatch ();
			
			case WINDOW_DEACTIVATE:
				
				onWindowDeactivate.dispatch ();
			
		}
		
	}
	
	
	#if js
	private static function handleDOMEvent (event:js.html.Event):Void {
		
		eventInfo.type = (event.type == "focus" ? WINDOW_ACTIVATE : WINDOW_DEACTIVATE);
		dispatch ();
		
	}
	#end
	
	
	#if flash
	private static function handleFlashEvent (event:flash.events.Event):Void {
		
		eventInfo.type = (event.type == flash.events.Event.ACTIVATE ? WINDOW_ACTIVATE : WINDOW_DEACTIVATE);
		dispatch ();
		
	}
	#end
	
	
	#if (cpp || neko)
	private static var lime_window_create = System.load ("lime", "lime_window_create", 2);
	private static var lime_window_event_manager_register = System.load ("lime", "lime_window_event_manager_register", 2);
	#end
	
	
}


private class WindowEventInfo {
	
	
	public var type:WindowEventType;
	
	
	public function new (type:WindowEventType = null) {
		
		this.type = type;
		
	}
	
	
	public function clone ():WindowEventInfo {
		
		return new WindowEventInfo (type);
		
	}
	
	
}


@:enum private abstract WindowEventType(Int) {
	
	var WINDOW_ACTIVATE = 0;
	var WINDOW_DEACTIVATE = 1;
	
}