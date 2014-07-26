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
	
	
	public static var onWindowActivate = new Event<Void->Void> ();
	public static var onWindowClose = new Event<Void->Void> ();
	public static var onWindowDeactivate = new Event<Void->Void> ();
	public static var onWindowFocusIn = new Event<Void->Void> ();
	public static var onWindowFocusOut = new Event<Void->Void> ();
	public static var onWindowMove = new Event<Float->Float->Void> ();
	public static var onWindowResize = new Event<Int->Int->Void> ();
	
	private static var eventInfo = new WindowEventInfo ();
	private static var registered:Bool;
	
	public var currentRenderer:Renderer;
	public var config:Config;
	public var fullscreen:Bool;
	public var height:Int;
	public var width:Int;
	public var x:Int;
	public var y:Int;
	
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
	
	private var setHeight:Int;
	private var setWidth:Int;
	
	
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
		
		setWidth = width;
		setHeight = height;
		
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
		
		if (canvas != null) {
			
			canvas.width = width;
			canvas.height = height;
			
		} else {
			
			div.style.width = width + "px";
			div.style.height = height + "px";
			
		}
		
		handleDOMResize ();
		
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
		
		var flags = 0;
		
		if (config.antialiasing >= 4) {
			
			flags |= cast WindowFlags.WINDOW_FLAG_HW_AA_HIRES;
			
		} else if (config.antialiasing >= 2) {
			
			flags |= cast WindowFlags.WINDOW_FLAG_HW_AA;
			
		}
		
		if (config.borderless) flags |= cast WindowFlags.WINDOW_FLAG_BORDERLESS;
		if (config.depthBuffer) flags |= cast WindowFlags.WINDOW_FLAG_DEPTH_BUFFER;
		if (config.fullscreen) flags |= cast WindowFlags.WINDOW_FLAG_FULLSCREEN;
		if (config.resizable) flags |= cast WindowFlags.WINDOW_FLAG_RESIZABLE;
		if (config.stencilBuffer) flags |= cast WindowFlags.WINDOW_FLAG_STENCIL_BUFFER;
		if (config.vsync) flags |= cast WindowFlags.WINDOW_FLAG_VSYNC;
		
		handle = lime_window_create (application.__handle, width, height, flags, config.title);
		
		#end
		
		MouseEventManager.registerWindow (this);
		TouchEventManager.registerWindow (this);
		
		#if js
		Browser.window.addEventListener ("focus", handleDOMEvent, false);
		Browser.window.addEventListener ("blur", handleDOMEvent, false);
		Browser.window.addEventListener ("resize", handleDOMEvent, false);
		Browser.window.addEventListener ("beforeunload", handleDOMEvent, false);
		#elseif flash
		Lib.current.stage.addEventListener (flash.events.Event.ACTIVATE, handleFlashEvent);
		Lib.current.stage.addEventListener (flash.events.Event.DEACTIVATE, handleFlashEvent);
		Lib.current.stage.addEventListener (flash.events.FocusEvent.FOCUS_IN, handleFlashEvent);
		Lib.current.stage.addEventListener (flash.events.FocusEvent.FOCUS_OUT, handleFlashEvent);
		Lib.current.stage.addEventListener (flash.events.Event.RESIZE, handleFlashEvent);
		#end
		
		if (currentRenderer != null) {
			
			currentRenderer.create ();
			
		}
		
	}
	
	
	private function dispatch ():Void {
		
		switch (eventInfo.type) {
			
			case WINDOW_ACTIVATE:
				
				onWindowActivate.dispatch ();
			
			case WINDOW_CLOSE:
				
				onWindowClose.dispatch ();
			
			case WINDOW_DEACTIVATE:
				
				onWindowDeactivate.dispatch ();
			
			case WINDOW_FOCUS_IN:
				
				onWindowFocusIn.dispatch ();
			
			case WINDOW_FOCUS_OUT:
				
				onWindowFocusOut.dispatch ();
			
			case WINDOW_MOVE:
				
				x = eventInfo.x;
				y = eventInfo.y;
				
				onWindowMove.dispatch (eventInfo.x, eventInfo.y);
			
			case WINDOW_RESIZE:
				
				width = eventInfo.width;
				height = eventInfo.height;
				
				onWindowResize.dispatch (eventInfo.width, eventInfo.height);
			
		}
		
	}
	
	
	#if js
	private function handleDOMEvent (event:js.html.Event):Void {
		
		switch (event.type) {
			
			case "focus":
				
				eventInfo.type = WINDOW_FOCUS_IN;
				dispatch ();
				
				eventInfo.type = WINDOW_ACTIVATE;
				dispatch ();
			
			case "blur":
				
				eventInfo.type = WINDOW_FOCUS_OUT;
				dispatch ();
				
				eventInfo.type = WINDOW_DEACTIVATE;
				dispatch ();
			
			case "resize":
				
				var cacheWidth = width;
				var cacheHeight = height;
				
				handleDOMResize ();
				
				if (width != cacheWidth || height != cacheHeight) {
					
					eventInfo.type = WINDOW_RESIZE;
					eventInfo.width = width;
					eventInfo.height = height;
					dispatch ();
					
				}
			
			case "beforeunload":
				
				eventInfo.type = WINDOW_CLOSE;
				dispatch ();
			
		}
		
	}
	
	
	private function handleDOMResize ():Void {
		
		var stretch = fullscreen || (setWidth == 0 && setHeight == 0);
		
		if (element != null && (div == null || (div != null && stretch))) {
			
			if (stretch) {
				
				if (width != element.clientWidth || height != element.clientHeight) {
					
					width = element.clientWidth;
					height = element.clientHeight;
					
					if (canvas != null) {
						
						if (element != cast canvas) {
							
							canvas.width = element.clientWidth;
							canvas.height = element.clientHeight;
							
						}
						
					} else {
						
						div.style.width = element.clientWidth + "px";
						div.style.height = element.clientHeight + "px";
						
					}
					
				}
				
			} else {
				
				var scaleX = element.clientWidth / setWidth;
				var scaleY = element.clientHeight / setHeight;
				
				var currentRatio = scaleX / scaleY;
				var targetRatio = Math.min (scaleX, scaleY);
				
				if (canvas != null) {
					
					if (element != cast canvas) {
						
						canvas.style.width = setWidth * targetRatio + "px";
						canvas.style.height = setHeight * targetRatio + "px";
						canvas.style.marginLeft = ((element.clientWidth - (setWidth * targetRatio)) / 2) + "px";
						canvas.style.marginTop = ((element.clientHeight - (setHeight * targetRatio)) / 2) + "px";
						
					}
					
				} else {
					
					div.style.width = setWidth * targetRatio + "px";
					div.style.height = setHeight * targetRatio + "px";
					div.style.marginLeft = ((element.clientWidth - (setWidth * targetRatio)) / 2) + "px";
					div.style.marginTop = ((element.clientHeight - (setHeight * targetRatio)) / 2) + "px";
					
				}
				
			}
			
		}
		
	}
	#end
	
	
	#if flash
	private function handleFlashEvent (event:flash.events.Event):Void {
		
		eventInfo.type = switch (event.type) {
			
			case flash.events.Event.ACTIVATE: WINDOW_ACTIVATE;
			case flash.events.Event.DEACTIVATE: WINDOW_DEACTIVATE;
			case flash.events.FocusEvent.FOCUS_IN: WINDOW_FOCUS_IN;
			case flash.events.FocusEvent.FOCUS_OUT: WINDOW_FOCUS_OUT;
			default: WINDOW_RESIZE;
			
		}
		
		if (eventInfo.type == WINDOW_RESIZE) {
			
			eventInfo.width = Lib.current.stage.stageWidth;
			eventInfo.height = Lib.current.stage.stageHeight;
			
		}
		
		dispatch ();
		
	}
	#end
	
	
	public function move (x:Int, y:Int):Void {
		
		#if (cpp || neko)
		lime_window_move (handle, x, y);
		#end
		
	}
	
	
	public function resize (width:Int, height:Int):Void {
		
		setWidth = width;
		setHeight = height;
		
		#if (cpp || neko)
		lime_window_resize (handle, width, height);
		#end
		
	}
	
	
	#if (cpp || neko)
	private static var lime_window_create = System.load ("lime", "lime_window_create", 5);
	private static var lime_window_event_manager_register = System.load ("lime", "lime_window_event_manager_register", 2);
	private static var lime_window_move = System.load ("lime", "lime_window_move", 3);
	private static var lime_window_resize = System.load ("lime", "lime_window_resize", 3);
	#end
	
	
}


private class WindowEventInfo {
	
	
	public var height:Int;
	public var type:WindowEventType;
	public var width:Int;
	public var x:Int;
	public var y:Int;
	
	
	public function new (type:WindowEventType = null, width:Int = 0, height:Int = 0, x:Int = 0, y:Int = 0) {
		
		this.type = type;
		this.width = width;
		this.height = height;
		this.x = x;
		this.y = y;
		
	}
	
	
	public function clone ():WindowEventInfo {
		
		return new WindowEventInfo (type, width, height, x, y);
		
	}
	
	
}


@:enum private abstract WindowFlags(Int) {
	
	var WINDOW_FLAG_FULLSCREEN = 0x00000001;
	var WINDOW_FLAG_BORDERLESS = 0x00000002;
	var WINDOW_FLAG_RESIZABLE = 0x00000004;
	var WINDOW_FLAG_HARDWARE = 0x00000008;
	var WINDOW_FLAG_VSYNC = 0x00000010;
	var WINDOW_FLAG_HW_AA = 0x00000020;
	var WINDOW_FLAG_HW_AA_HIRES = 0x00000060;
	var WINDOW_FLAG_ALLOW_SHADERS = 0x00000080;
	var WINDOW_FLAG_REQUIRE_SHADERS = 0x00000100;
	var WINDOW_FLAG_DEPTH_BUFFER = 0x00000200;
	var WINDOW_FLAG_STENCIL_BUFFER = 0x00000400;
	
}


@:enum private abstract WindowEventType(Int) {
	
	var WINDOW_ACTIVATE = 0;
	var WINDOW_CLOSE = 1;
	var WINDOW_DEACTIVATE = 2;
	var WINDOW_FOCUS_IN = 3;
	var WINDOW_FOCUS_OUT = 4;
	var WINDOW_MOVE = 5;
	var WINDOW_RESIZE = 6;
	
}