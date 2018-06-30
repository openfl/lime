package lime._internal.backend.air;


import flash.desktop.NotificationType;
import flash.display.NativeWindow;
import flash.display.NativeWindowInitOptions;
import flash.display.NativeWindowRenderMode;
import flash.display.NativeWindowSystemChrome;
import flash.events.Event;
import flash.html.HTMLLoader;
import flash.Lib;
import lime._internal.backend.flash.FlashWindow;
import lime.app.Application;
import lime.ui.Window;

@:access(lime.ui.Window)


class AIRWindow extends FlashWindow {
	
	
	private var closing:Bool;
	private var nativeWindow:NativeWindow;
	
	
	public function new (parent:Window) {
		
		super (parent);
		
	}
	
	
	public override function alert (message:String, title:String):Void {
		
		if (nativeWindow != null) {
			
			nativeWindow.notifyUser (NotificationType.INFORMATIONAL);
			
			if (message != null) {
				
				var htmlLoader = new HTMLLoader ();
				htmlLoader.loadString ("<!DOCTYPE html><html lang='en'><head><meta charset='utf-8'><title></title><script></script></head><body></body></html>");
				htmlLoader.window.alert (message);
				
			}
			
		}
		
	}
	
	
	public override function close ():Void {
		
		if (!closing) {
			
			closing = true;
			parent.onClose.dispatch ();
			
			if (!parent.onClose.canceled) {
				
				nativeWindow.close ();
				
			} else {
				
				closing = false;
				
			}
			
		}
		
	}
	
	
	public override function create (application:Application):Void {
		
		var title = (parent.__title != null && parent.__title != "") ? parent.__title : "Lime Application";
		var attributes = parent.__contextAttributes;
		
		var alwaysOnTop = false;
		var borderless = false;
		var fullscreen = false;
		var hardware = false;
		var hidden = false;
		var maximized = false;
		var minimized = false;
		var resizable = false;
		
		var width = 0;
		var height = 0;
		
		if (parent.alwaysOnTop) alwaysOnTop = true;
		if (parent.__borderless) borderless = true;
		if (parent.__fullscreen) fullscreen;
		if (Reflect.hasField (attributes, "hardware") && attributes.hardware) hardware = true;
		if (parent.hidden) hidden = true;
		if (parent.maximized) maximized = true;
		if (parent.minimized) minimized = true;
		if (parent.__resizable) resizable;
		
		// if (parent.config != null && (parent.config == application.config.windows[0])) {
			
			nativeWindow = Lib.current.stage.nativeWindow;
			
			// TODO
		// } else {
			
		// 	var options = new NativeWindowInitOptions ();
		// 	options.systemChrome = borderless ? NativeWindowSystemChrome.NONE : NativeWindowSystemChrome.STANDARD; 
		// 	options.renderMode = hardware ? NativeWindowRenderMode.DIRECT : NativeWindowRenderMode.CPU;
		// 	options.transparent = false;
		// 	options.maximizable = true;
		// 	options.minimizable = true;
		// 	options.resizable = resizable;
			
		// 	nativeWindow = new NativeWindow (options);
		// 	nativeWindow.stage.frameRate = application.frameRate;
			
		// 	if (parent.width > 0) nativeWindow.width = parent.width;
		// 	if (parent.height > 0) nativeWindow.height = parent.height;
			
		// }
		
		if (nativeWindow != null) {
			
			nativeWindow.addEventListener (Event.CLOSING, handleNativeWindowEvent);
			nativeWindow.addEventListener (Event.CLOSE, handleNativeWindowEvent);
			
			nativeWindow.visible = !hidden;
			//nativeWindow.activate ();
			nativeWindow.alwaysInFront = alwaysOnTop;
			nativeWindow.title = title;
			
			if (maximized) {
				
				nativeWindow.maximize ();
				
			} else if (minimized) {
				
				nativeWindow.minimize ();
				
			}
			
		}
		
		if (fullscreen) {
			
			setFullscreen (true);
			
		}
		
		if (nativeWindow != null) {
			
			parent.__width = Std.int (nativeWindow.width);
			parent.__height = Std.int (nativeWindow.height);
			parent.__x = Math.round (nativeWindow.x);
			parent.__y = Math.round (nativeWindow.y);
			stage = nativeWindow.stage;
			
		}
		
		super.create (application);
		
	}
	
	
	public override function focus ():Void {
		
		if (nativeWindow != null) {
			
			nativeWindow.activate ();
			
		}
		
	}
	
	
	private function handleNativeWindowEvent (event:Event):Void {
		
		switch (event.type) {
			
			case Event.CLOSING:
				
				parent.close ();
				
				if (parent.onClose.canceled) {
					
					event.preventDefault ();
					event.stopImmediatePropagation ();
					
				}
			
			case Event.CLOSE:
				
				closing = true;
				parent.onClose.dispatch ();
			
			default:
			
		}
		
	}
	
	
	public override function move (x:Int, y:Int):Void {
		
		if (nativeWindow != null) {
			
			nativeWindow.x = x;
			nativeWindow.y = y;
			
		}
		
	}
	
	
	public override function resize (width:Int, height:Int):Void {
		
		if (nativeWindow != null) {
			
			nativeWindow.width = width;
			nativeWindow.height = height;
			
		}
		
	}
	
	
	public override function setMaximized (value:Bool):Bool {
		
		if (nativeWindow != null) {
			
			if (value) {
				
				nativeWindow.maximize ();
				
			} else {
				
				nativeWindow.restore ();
				
			}
			
		}
		
		return value;
		
	}
	
	
	public override function setMinimized (value:Bool):Bool {
		
		if (nativeWindow != null) {
			
			if (value) {
				
				nativeWindow.minimize ();
				
			} else {
				
				nativeWindow.restore ();
				
			}
			
		}
		
		return value;
		
	}
	
	
	public override function setTitle (value:String):String {
		
		if (nativeWindow != null) {
			
			nativeWindow.title = value;
			
		}
		
		return value;
		
	}
	
	
}
