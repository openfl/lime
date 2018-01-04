package lime._backend.html5;


import haxe.Timer;
import js.html.CanvasElement;
import js.html.DivElement;
import js.html.Element;
import js.html.FocusEvent;
import js.html.InputElement;
import js.html.InputEvent;
import js.html.LinkElement;
import js.html.MouseEvent;
import js.html.TouchEvent;
import js.html.ClipboardEvent;
import js.Browser;
import lime.app.Application;
import lime.graphics.utils.ImageCanvasUtil;
import lime.graphics.Image;
import lime.system.Display;
import lime.system.DisplayMode;
import lime.system.System;
import lime.system.Clipboard;
import lime.ui.Gamepad;
import lime.ui.Joystick;
import lime.ui.Touch;
import lime.ui.Window;


@:access(lime.app.Application)
@:access(lime.ui.Gamepad)
@:access(lime.ui.Joystick)
@:access(lime.ui.Window)


class HTML5Window {
	
	
	private static var dummyCharacter = String.fromCharCode (127);
	private static var textInput:InputElement;
	private static var windowID:Int = 0;
	
	public var canvas:CanvasElement;
	public var div:DivElement;
	public var element:Element;
	#if stats
	public var stats:Dynamic;
	#end
	
	private var cacheElementHeight:Float;
	private var cacheElementWidth:Float;
	private var cacheMouseX:Float;
	private var cacheMouseY:Float;
	private var currentTouches = new Map<Int, Touch> ();
	private var enableTextEvents:Bool;
	private var isFullscreen:Bool;
	private var parent:Window;
	private var primaryTouch:Touch;
	private var renderType:String;
	private var requestedFullscreen:Bool;
	private var resizeElement:Bool;
	private var scale = 1.0;
	private var setHeight:Int;
	private var setWidth:Int;
	private var unusedTouchesPool = new List<Touch> ();
	
	
	public function new (parent:Window) {
		
		this.parent = parent;
		
		if (parent.config != null && Reflect.hasField (parent.config, "element")) {
			
			element = parent.config.element;
			
		}
		
		if (parent.config != null && Reflect.hasField (parent.config, "renderer")) {
			
			renderType = parent.config.renderer;
			
		}
		
		#if dom
		renderType = "dom";
		#end
		
		if (parent.config != null && Reflect.hasField (parent.config, "allowHighDPI") && parent.config.allowHighDPI && renderType != "dom") {
			
			scale = Browser.window.devicePixelRatio;
			
		}
		
		parent.__scale = scale;
		
		cacheMouseX = 0;
		cacheMouseY = 0;
		
	}
	
	
	public function alert (message:String, title:String):Void {
		
		if (message != null) {
			
			Browser.alert (message);
			
		}
		
	}
	
	
	public function close ():Void {
		
		parent.application.removeWindow (parent);
		
	}
	
	
	public function create (application:Application):Void {
		
		setWidth = parent.width;
		setHeight = parent.height;
		
		parent.id = windowID++;
		
		if (Std.is (element, CanvasElement)) {
			
			canvas = cast element;
			
		} else {
			
			if (renderType == "dom") {
				
				div = cast Browser.document.createElement ("div");
				
			} else {
				
				canvas = cast Browser.document.createElement ("canvas");
				
			}
			
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
			
			cacheElementWidth = parent.width;
			cacheElementHeight = parent.height;
			
			resizeElement = true;
			
		}
		
		if (canvas != null) {
			
			canvas.width = Math.round (parent.width * scale);
			canvas.height = Math.round (parent.height * scale);
			
			canvas.style.width = parent.width + "px";
			canvas.style.height = parent.height + "px";
			
		} else {
			
			div.style.width = parent.width + "px";
			div.style.height = parent.height + "px";
			
		}
		
		updateSize ();
		
		if (element != null) {
			
			if (canvas != null) {
				
				if (element != cast canvas) {
					
					element.appendChild (canvas);
					
				}
				
			} else {
				
				element.appendChild (div);
				
			}
			
			var events = [ "mousedown", "mouseenter", "mouseleave", "mousemove", "mouseup", "wheel" ];
			
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
			
			element.addEventListener ("contextmenu", handleContextMenuEvent, true);
			
			element.addEventListener ("touchstart", handleTouchEvent, true);
			element.addEventListener ("touchmove", handleTouchEvent, true);
			element.addEventListener ("touchend", handleTouchEvent, true);
			element.addEventListener ("touchcancel", handleTouchEvent, true);
			
			element.addEventListener ("gamepadconnected", handleGamepadEvent, true);
			element.addEventListener ("gamepaddisconnected", handleGamepadEvent, true);
			
		}
		
	}
	
	
	public function focus ():Void {
		
		
		
	}
	
	
	public function getDisplay ():Display {
		
		return System.getDisplay (0);
		
	}
	
	
	public function getDisplayMode ():DisplayMode {
		
		return System.getDisplay (0).currentMode;
		
	}
	
	
	public function setDisplayMode (value:DisplayMode):DisplayMode {
		
		return value;
		
	}
	
	
	public function getEnableTextEvents ():Bool {
		
		return enableTextEvents;
		
	}
	
	
	private function handleContextMenuEvent (event:MouseEvent):Void {
		
		if (parent.onMouseUp.canceled) {
			
			event.preventDefault ();
			
		}
		
	}
	
	
	private function handleCutOrCopyEvent (event:ClipboardEvent):Void {
		
		event.clipboardData.setData ("text/plain", Clipboard.text);
		event.preventDefault ();
		
	}
	
	
	private function handleFocusEvent (event:FocusEvent):Void {
		
		if (enableTextEvents) {
			
			Timer.delay (function () { textInput.focus (); }, 20);
			
		}
		
	}
	
	
	private function handleFullscreenEvent (event:Dynamic):Void {
		
		var fullscreenElement = untyped (document.fullscreenElement || document.mozFullScreenElement || document.webkitFullscreenElement || document.msFullscreenElement);
		
		if (fullscreenElement != null) {
			
			isFullscreen = true;
			parent.__fullscreen = true;
			
			if (requestedFullscreen) {
				
				requestedFullscreen = false;
				parent.onFullscreen.dispatch ();
				
			}
			
		} else {
			
			isFullscreen = false;
			parent.__fullscreen = false;
			
			var changeEvents = [ "fullscreenchange", "mozfullscreenchange", "webkitfullscreenchange", "MSFullscreenChange" ];
			var errorEvents = [ "fullscreenerror", "mozfullscreenerror", "webkitfullscreenerror", "MSFullscreenError" ];
			
			for (i in 0...changeEvents.length) {
				
				Browser.document.removeEventListener (changeEvents[i], handleFullscreenEvent, false);
				Browser.document.removeEventListener (errorEvents[i], handleFullscreenEvent, false);
				
			}
			
		}
		
	}
	
	
	private function handleGamepadEvent (event:Dynamic):Void {
		
		switch (event.type) {
			
			case "gamepadconnected":
				
				Joystick.__connect (event.gamepad.index);
				
				if (event.gamepad.mapping == "standard") {
					
					Gamepad.__connect (event.gamepad.index);
					
				}
			
			case "gamepaddisconnected":
				
				Joystick.__disconnect (event.gamepad.index);
				Gamepad.__disconnect (event.gamepad.index);
			
			default:
				
		}
		
	}
	
	
	private function handleInputEvent (event:InputEvent):Void {
		
		// In order to ensure that the browser will fire clipboard events, we always need to have something selected.
		// Therefore, `value` cannot be "".
		
		if (textInput.value != dummyCharacter) {
			
			if (textInput.value.charAt (0) == dummyCharacter) {
				
				parent.onTextInput.dispatch (textInput.value.substr (1));
				
			} else {
				
				parent.onTextInput.dispatch (textInput.value);
				
			}
			
			textInput.value = dummyCharacter;
			
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
					
					parent.onMouseDown.dispatch (x, y, event.button);
					
					if (parent.onMouseDown.canceled) {
						
						event.preventDefault ();
						
					}
				
				case "mouseenter":
					
					if (event.target == element) {
						
						parent.onEnter.dispatch ();
						
						if (parent.onEnter.canceled) {
							
							event.preventDefault ();
							
						}
						
					}
				
				case "mouseleave":
					
					if (event.target == element) {
						
						parent.onLeave.dispatch ();
						
						if (parent.onLeave.canceled) {
							
							event.preventDefault ();
							
						}
						
					}
				
				case "mouseup":
					
					parent.onMouseUp.dispatch (x, y, event.button);
					
					if (parent.onMouseUp.canceled) {
						
						event.preventDefault ();
						
					}
				
				case "mousemove":
					
					if (x != cacheMouseX || y != cacheMouseY) {
						
						parent.onMouseMove.dispatch (x, y);
						parent.onMouseMoveRelative.dispatch (x - cacheMouseX, y - cacheMouseY);
						
						if (parent.onMouseMove.canceled || parent.onMouseMoveRelative.canceled) {
							
							event.preventDefault ();
							
						}
						
					}
				
				default:
				
			}
			
			cacheMouseX = x;
			cacheMouseY = y;
			
		} else {
			
			parent.onMouseWheel.dispatch (untyped event.deltaX, -untyped event.deltaY);
			
			if (parent.onMouseWheel.canceled) {
				
				event.preventDefault ();
				
			}
			
		}
		
	}
	
	
	private function handlePasteEvent (event:ClipboardEvent):Void {
		
		if (untyped event.clipboardData.types.indexOf ("text/plain") > -1) {
			
			var text = event.clipboardData.getData ("text/plain");
			Clipboard.text = text;
			
			if (enableTextEvents) {
				
				parent.onTextInput.dispatch (text);
				
			}
			
			event.preventDefault ();
			
		}
		
	}
	
	
	private function handleResizeEvent (event:js.html.Event):Void {
		
		primaryTouch = null;
		updateSize ();
		
	}
	
	
	private function handleTouchEvent (event:TouchEvent):Void {
		
		event.preventDefault ();
		
		var rect = null;
		
		if (element != null) {
			
			if (canvas != null) {
				
				rect = canvas.getBoundingClientRect ();
				
			} else if (div != null) {
				
				rect = div.getBoundingClientRect ();
				
			} else {
				
				rect = element.getBoundingClientRect ();
				
			}
			
		}
		
		var windowWidth:Float = setWidth;
		var windowHeight:Float = setHeight;
		
		if (windowWidth == 0 || windowHeight == 0) {
			
			if (rect != null) {
				
				windowWidth = rect.width;
				windowHeight = rect.height;
				
			} else {
				
				windowWidth = 1;
				windowHeight = 1;
				
			}
			
		}
		
		var touch, x, y, cacheX, cacheY;
		
		for (data in event.changedTouches) {
			
			x = 0.0;
			y = 0.0;
			
			if (rect != null) {
				
				x = (data.clientX - rect.left) * (windowWidth / rect.width);
				y = (data.clientY - rect.top) * (windowHeight / rect.height);
				
			} else {
				
				x = data.clientX;
				y = data.clientY;
				
			}
			
			if (event.type == "touchstart") {
				
				touch = unusedTouchesPool.pop ();
				
				if (touch == null) {
					
					touch = new Touch (x / windowWidth, y / windowHeight, data.identifier, 0, 0, data.force, parent.id);
					
				} else {
					
					touch.x = x / windowWidth;
					touch.y = y / windowHeight;
					touch.id = data.identifier;
					touch.dx = 0;
					touch.dy = 0;
					touch.pressure = data.force;
					touch.device = parent.id;
					
				}
				
				currentTouches.set (data.identifier, touch);
				
				Touch.onStart.dispatch (touch);
				
				if (primaryTouch == null) {
					
					primaryTouch = touch;
					
				}
				
				if (touch == primaryTouch) {
					
					parent.onMouseDown.dispatch (x, y, 0);
					
				}
				
			} else {
				
				touch = currentTouches.get (data.identifier);
				
				if (touch != null) {
					
					cacheX = touch.x;
					cacheY = touch.y;
					
					touch.x = x / windowWidth;
					touch.y = y / windowHeight;
					touch.dx = touch.x - cacheX;
					touch.dy = touch.y - cacheY;
					touch.pressure = data.force;
					
					switch (event.type) {
						
						case "touchmove":
							
							Touch.onMove.dispatch (touch);
							
							if (touch == primaryTouch) {
								
								parent.onMouseMove.dispatch (x, y);
								
							}
						
						case "touchend":
							
							Touch.onEnd.dispatch (touch);
							
							currentTouches.remove (data.identifier);
							unusedTouchesPool.add (touch);
							
							if (touch == primaryTouch) {
								
								parent.onMouseUp.dispatch (x, y, 0);
								primaryTouch = null;
								
							}
						
						case "touchcancel":
							
							Touch.onCancel.dispatch (touch);
							
							currentTouches.remove (data.identifier);
							unusedTouchesPool.add (touch);
							
							if (touch == primaryTouch) {
								
								//parent.onMouseUp.dispatch (x, y, 0);
								primaryTouch = null;
								
							}
						
						default:
						
					}
					
				}
				
			}
			
		}
		
	}
	
	
	public function move (x:Int, y:Int):Void {
		
		
		
	}
	
	
	public function resize (width:Int, height:Int):Void {
		
		
		
	}
	
	
	public function setBorderless (value:Bool):Bool {
		
		return value;
		
	}
	
	
	public function setClipboard (value:String):Void {
		
		var inputEnabled = enableTextEvents;
		
		setEnableTextEvents (true); // create textInput if necessary
		
		var cacheText = textInput.value;
		textInput.value = value;
		textInput.select ();
		
		if (Browser.document.queryCommandEnabled ("copy")) {
			
			Browser.document.execCommand ("copy");
			
		}
		
		textInput.value = cacheText;
		
		setEnableTextEvents (inputEnabled);
		
	}
	
	
	public function setEnableTextEvents (value:Bool):Bool {
		
		if (value) {
			
			if (textInput == null) {
				
				textInput = cast Browser.document.createElement ('input');
				textInput.type = 'text';
				textInput.style.position = 'absolute';
				textInput.style.opacity = "0";
				textInput.style.color = "transparent";
				textInput.value = dummyCharacter; // See: handleInputEvent()
				
				untyped textInput.autocapitalize = "off";
				untyped textInput.autocorrect = "off";
				textInput.autocomplete = "off";
				
				// TODO: Position for mobile browsers better
				
				textInput.style.left = "0px";
				textInput.style.top = "50%";
				
				if (~/(iPad|iPhone|iPod).*OS 8_/gi.match (Browser.window.navigator.userAgent)) {
					
					textInput.style.fontSize = "0px";
					textInput.style.width = '0px';
					textInput.style.height = '0px';
					
				} else {
					
					textInput.style.width = '1px';
					textInput.style.height = '1px';
					
				}
				
				untyped (textInput.style).pointerEvents = 'none';
				textInput.style.zIndex = "-10000000";
				
				Browser.document.body.appendChild (textInput);
				
			}
			
			if (!enableTextEvents) {
				
				textInput.addEventListener ('input', handleInputEvent, true);
				textInput.addEventListener ('blur', handleFocusEvent, true);
				textInput.addEventListener ('cut', handleCutOrCopyEvent, true);
				textInput.addEventListener ('copy', handleCutOrCopyEvent, true);
				textInput.addEventListener ('paste', handlePasteEvent, true);
				
			}
			
			textInput.focus ();
			textInput.select ();
			
		} else {
			
			if (textInput != null) {
				
				textInput.removeEventListener ('input', handleInputEvent, true);
				textInput.removeEventListener ('blur', handleFocusEvent, true);
				textInput.removeEventListener ('cut', handleCutOrCopyEvent, true);
				textInput.removeEventListener ('copy', handleCutOrCopyEvent, true);
				textInput.removeEventListener ('paste', handlePasteEvent, true);
				
				textInput.blur ();
				
			}
			
		}
		
		return enableTextEvents = value;
		
	}
	
	
	public function setFullscreen (value:Bool):Bool {
		
		if (value) {
			
			if (!requestedFullscreen && !isFullscreen) {
				
				requestedFullscreen = true;
				
				untyped {
					
					if (element.requestFullscreen) {
						
						document.addEventListener ("fullscreenchange", handleFullscreenEvent, false);
						document.addEventListener ("fullscreenerror", handleFullscreenEvent, false);
						element.requestFullscreen ();
						
					} else if (element.mozRequestFullScreen) {
						
						document.addEventListener ("mozfullscreenchange", handleFullscreenEvent, false);
						document.addEventListener ("mozfullscreenerror", handleFullscreenEvent, false);
						element.mozRequestFullScreen ();
						
					} else if (element.webkitRequestFullscreen) {
						
						document.addEventListener ("webkitfullscreenchange", handleFullscreenEvent, false);
						document.addEventListener ("webkitfullscreenerror", handleFullscreenEvent, false);
						element.webkitRequestFullscreen ();
						
					} else if (element.msRequestFullscreen) {
						
						document.addEventListener ("MSFullscreenChange", handleFullscreenEvent, false);
						document.addEventListener ("MSFullscreenError", handleFullscreenEvent, false);
						element.msRequestFullscreen ();
						
					}
					
				}
				
			}
			
		} else if (isFullscreen) {
			
			requestedFullscreen = false;
			
			untyped {
				
				if (document.exitFullscreen) document.exitFullscreen ();
				else if (document.mozCancelFullScreen) document.mozCancelFullScreen ();
				else if (document.webkitExitFullscreen) document.webkitExitFullscreen ();
				else if (document.msExitFullscreen) document.msExitFullscreen ();
				
			}
			
		}
		
		return value;
		
	}
	
	
	public function setIcon (image:Image):Void {
		
		//var iconWidth = 16;
		//var iconHeight = 16;
		
		//image = image.clone ();
		
		//if (image.width != iconWidth || image.height != iconHeight) {
			//
			//image.resize (iconWidth, iconHeight);
			//
		//}
		
		ImageCanvasUtil.convertToCanvas (image);
		
		var link:LinkElement = cast Browser.document.querySelector ("link[rel*='icon']");
		
		if (link == null) {
			
			link = cast Browser.document.createElement ("link");
			
		}
		
		link.type = "image/x-icon";
		link.rel = "shortcut icon";
		link.href = image.buffer.src.toDataURL ("image/x-icon");
		
		Browser.document.getElementsByTagName ("head")[0].appendChild (link);
		
	}
	
	
	public function setMaximized (value:Bool):Bool {
		
		return false;
		
	}
	
	
	public function setMinimized (value:Bool):Bool {
		
		return false;
		
	}
	
	
	public function setResizable (value:Bool):Bool {
		
		return value;
		
	}
	
	
	public function setTitle (value:String):String {
		
		if (value != null) {
			
			Browser.document.title = value;
			
		}
		
		return value;
		
	}
	
	
	private function updateSize ():Void {
		
		if (!parent.__resizable) return;
		
		var elementWidth, elementHeight;
		
		if (element != null) {
			
			elementWidth = element.clientWidth;
			elementHeight = element.clientHeight;
			
		} else {
			
			elementWidth = Browser.window.innerWidth;
			elementHeight = Browser.window.innerHeight;
			
		}
		
		if (elementWidth != cacheElementWidth || elementHeight != cacheElementHeight) {
			
			cacheElementWidth = elementWidth;
			cacheElementHeight = elementHeight;
			
			var stretch = resizeElement || (setWidth == 0 && setHeight == 0);
			
			if (element != null && (div == null || (div != null && stretch))) {
				
				if (stretch) {
					
					if (parent.width != elementWidth || parent.height != elementHeight) {
						
						parent.width = elementWidth;
						parent.height = elementHeight;
						
						if (canvas != null) {
							
							if (element != cast canvas) {
								
								canvas.width = Math.round (elementWidth * scale);
								canvas.height = Math.round (elementHeight * scale);
								
								canvas.style.width = elementWidth + "px";
								canvas.style.height = elementHeight + "px";
								
							}
							
						} else {
							
							div.style.width = elementWidth + "px";
							div.style.height = elementHeight + "px";
							
						}
						
						parent.onResize.dispatch (elementWidth, elementHeight);
						
					}
					
				} else {
					
					var scaleX = (setWidth != 0) ? (elementWidth / setWidth) : 1;
					var scaleY = (setHeight != 0) ? (elementHeight / setHeight) : 1;
					
					var targetWidth = elementWidth;
					var targetHeight = elementHeight;
					var marginLeft = 0;
					var marginTop = 0;
					
					if (scaleX < scaleY) {
						
						targetHeight = Math.floor (setHeight * scaleX);
						marginTop = Math.floor ((elementHeight - targetHeight) / 2);
						
					} else {
						
						targetWidth = Math.floor (setWidth * scaleY);
						marginLeft = Math.floor ((elementWidth - targetWidth) / 2);
						
					}
					
					if (canvas != null) {
						
						if (element != cast canvas) {
							
							canvas.style.width = targetWidth + "px";
							canvas.style.height = targetHeight + "px";
							canvas.style.marginLeft = marginLeft + "px";
							canvas.style.marginTop = marginTop + "px";
							
						}
						
					} else {
						
						div.style.width = targetWidth + "px";
						div.style.height = targetHeight + "px";
						div.style.marginLeft = marginLeft + "px";
						div.style.marginTop = marginTop + "px";
						
					}
					
				}
				
			}
			
		}
		
	}
	
	
}