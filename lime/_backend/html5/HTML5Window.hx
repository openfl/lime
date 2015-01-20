package lime._backend.html5;


import js.html.CanvasElement;
import js.html.DivElement;
import js.html.HtmlElement;
import js.html.MouseEvent;
import js.html.TouchEvent;
import js.Browser;
import lime.app.Application;
import lime.graphics.Image;
import lime.ui.KeyEventManager;
import lime.ui.MouseEventManager;
import lime.ui.TouchEventManager;
import lime.ui.Window;

@:access(lime.ui.KeyEventManager)
@:access(lime.ui.MouseEventManager)
@:access(lime.ui.TouchEventManager)


class HTML5Window {
	
	
	public var canvas:CanvasElement;
	public var div:DivElement;
	public var element:HtmlElement;
	#if stats
	public var stats:Dynamic;
	#end
	
	private var parent:Window;
	private var setHeight:Int;
	private var setWidth:Int;
	
	
	public function new (parent:Window) {
		
		this.parent = parent;
		
	}
	
	
	public function create (application:Application):Void {
		
		setWidth = parent.width;
		setHeight = parent.height;
		
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
		
		if (parent.width == 0 && parent.height == 0) {
			
			if (element != null) {
				
				parent.width = element.clientWidth;
				parent.height = element.clientHeight;
				
			} else {
				
				parent.width = Browser.window.innerWidth;
				parent.height = Browser.window.innerHeight;
				
			}
			
			parent.fullscreen = true;
			
		}
		
		if (canvas != null) {
			
			canvas.width = parent.width;
			canvas.height = parent.height;
			
		} else {
			
			div.style.width = parent.width + "px";
			div.style.height = parent.height + "px";
			
		}
		
		handleResize ();
		
		if (element != null) {
			
			if (canvas != null) {
				
				if (element != cast canvas) {
					
					element.appendChild (canvas);
					
				}
				
			} else {
				
				element.appendChild (div);
				
			}
			
			var events = [ "mousedown", "mousemove", "mouseup", "wheel" ];
			
			for (event in events) {
				
				element.addEventListener (event, handleMouseEvent, true);
				
			}
			
			// Disable image drag on Firefox
			Browser.document.addEventListener ("dragstart", function (e) {
				if (e.target.nodeName.toLowerCase () == "img") {
					e.preventDefault ();
					return false;
				}
				return true;
			}, false);
			
			element.addEventListener ("touchstart", handleTouchEvent, true);
			element.addEventListener ("touchmove", handleTouchEvent, true);
			element.addEventListener ("touchend", handleTouchEvent, true);
			
		}
		
		#if stats
		stats = untyped __js__("new Stats ()");
		stats.domElement.style.position = "absolute";
		stats.domElement.style.top = "0px";
		Browser.document.body.appendChild (stats.domElement);
		#end
		
		Browser.window.addEventListener ("focus", handleEvent, false);
		Browser.window.addEventListener ("blur", handleEvent, false);
		Browser.window.addEventListener ("resize", handleEvent, false);
		Browser.window.addEventListener ("beforeunload", handleEvent, false);
		
	}
	
	
	private function handleEvent (event:js.html.Event):Void {
		
		switch (event.type) {
			
			case "focus":
				
				Window.onWindowFocusIn.dispatch ();
				Window.onWindowActivate.dispatch ();
			
			case "blur":
				
				Window.onWindowFocusOut.dispatch ();
				Window.onWindowDeactivate.dispatch ();
			
			case "resize":
				
				var cacheWidth = parent.width;
				var cacheHeight = parent.height;
				
				handleResize ();
				
				if (parent.width != cacheWidth || parent.height != cacheHeight) {
					
					Window.onWindowResize.dispatch (parent.width, parent.height);
					
				}
			
			case "beforeunload":
				
				Window.onWindowClose.dispatch ();
			
		}
		
	}
	
	
	private function handleMouseEvent (event:MouseEvent):Void {
		
		var x = 0.0;
		var y = 0.0;
		
		if (event.type != "wheel") {
			
			if (element != null) {
				
				if (canvas != null) {
					
					var rect = canvas.getBoundingClientRect ();
					x = (event.clientX - rect.left) * (parent.width / rect.width);
					y = (event.clientY - rect.top) * (parent.height / rect.height);
					
				} else if (div != null) {
					
					var rect = div.getBoundingClientRect ();
					//x = (event.clientX - rect.left) * (window.backend.div.style.width / rect.width);
					x = (event.clientX - rect.left);
					//y = (event.clientY - rect.top) * (window.backend.div.style.height / rect.height);
					y = (event.clientY - rect.top);
					
				} else {
					
					var rect = element.getBoundingClientRect ();
					x = (event.clientX - rect.left) * (parent.width / rect.width);
					y = (event.clientY - rect.top) * (parent.height / rect.height);
					
				}
				
			} else {
				
				x = event.clientX;
				y = event.clientY;
				
			}
			
			switch (event.type) {
				
				case "mousedown":
					
					MouseEventManager.onMouseDown.dispatch (x, y, event.button);
				
				case "mouseup":
					
					MouseEventManager.onMouseUp.dispatch (x, y, event.button);
				
				case "mousemove":
					
					MouseEventManager.onMouseMove.dispatch (x, y, event.button);
				
				default:
				
			}
			
		} else {
			
			MouseEventManager.onMouseWheel.dispatch (untyped event.deltaX, untyped event.deltaY);
			
		}
		
	}
	
	
	private function handleResize ():Void {
		
		var stretch = parent.fullscreen || (setWidth == 0 && setHeight == 0);
		
		if (element != null && (div == null || (div != null && stretch))) {
			
			if (stretch) {
				
				if (parent.width != element.clientWidth || parent.height != element.clientHeight) {
					
					parent.width = element.clientWidth;
					parent.height = element.clientHeight;
					
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
	
	
	private function handleTouchEvent (event:TouchEvent):Void {
		
		event.preventDefault ();
		
		var touch = event.changedTouches[0];
		var id = touch.identifier;
		var x = 0.0;
		var y = 0.0;
		
		if (element != null) {
			
			if (canvas != null) {
				
				var rect = canvas.getBoundingClientRect ();
				x = (touch.clientX - rect.left) * (parent.width / rect.width);
				y = (touch.clientY - rect.top) * (parent.height / rect.height);
				
			} else if (div != null) {
				
				var rect = div.getBoundingClientRect ();
				//eventInfo.x = (event.clientX - rect.left) * (window.div.style.width / rect.width);
				x = (touch.clientX - rect.left);
				//eventInfo.y = (event.clientY - rect.top) * (window.div.style.height / rect.height);
				y = (touch.clientY - rect.top);
				
			} else {
				
				var rect = element.getBoundingClientRect ();
				x = (touch.clientX - rect.left) * (parent.width / rect.width);
				y = (touch.clientY - rect.top) * (parent.height / rect.height);
				
			}
			
		} else {
			
			x = touch.clientX;
			y = touch.clientY;
			
		}
		
		switch (event.type) {
			
			case "touchstart":
				
				TouchEventManager.onTouchStart.dispatch (x, y, id);
			
			case "touchmove":
				
				TouchEventManager.onTouchMove.dispatch (x, y, id);
			
			case "touchend":
				
				TouchEventManager.onTouchEnd.dispatch (x, y, id);
			
			default:
			
		}
		
	}
	
	
	public function move (x:Int, y:Int):Void {
		
		
		
	}
	
	
	public function resize (width:Int, height:Int):Void {
		
		
		
	}
	
	
	public function setIcon (image:Image):Void {
		
		
		
	}
	
	
}