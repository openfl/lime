package lime._backend.html5;


import haxe.Timer;
import js.html.CanvasElement;
import js.html.DivElement;
#if (haxe_ver >= 3.2)
import js.html.Element;
import js.html.FocusEvent;
import js.html.InputElement;
import js.html.InputEvent;
#else
import js.html.HtmlElement;
#end
import js.html.MouseEvent;
import js.html.TouchEvent;
import js.Browser;
import lime.app.Application;
import lime.graphics.Image;
import lime.system.Display;
import lime.system.System;
import lime.ui.Gamepad;
import lime.ui.Joystick;
import lime.ui.Touch;
import lime.ui.Window;

#if (haxe_ver < 3.2)
typedef FocusEvent = js.html.Event;
typedef InputElement = Dynamic;
typedef InputEvent = js.html.Event;
#end

import openfl.display.StageScaleMode;

@:access(lime.app.Application)
@:access(lime.ui.Gamepad)
@:access(lime.ui.Joystick)
@:access(lime.ui.Window)


class HTML5Window {


	private static var textInput:InputElement;
	private static var windowID:Int = 0;

	public var canvas:CanvasElement;
	public var canvasBoundingClientRect:Dynamic;
	public var div:DivElement;
	public var element:#if (haxe_ver >= "3.2") Element #else HtmlElement #end;
	#if stats
	public var stats:Dynamic;
	#end

	private var currentTouches = new Map<Int, Touch> ();
	private var enableTextEvents:Bool;
	private var parent:Window;
	private var primaryTouch:Touch;
	private var setHeight:Int;
	private var setWidth:Int;
	private var unusedTouchesPool = new List<Touch> ();


	public function new (parent:Window) {

		this.parent = parent;

		if (parent.config != null && Reflect.hasField (parent.config, "element")) {

			element = parent.config.element;

		}

		parent.onFocusIn.add (focus);
	}


	public function alert (message:String, title:String):Void {

		if (message != null) {

			#if (haxe_ver >= 3.2)
			Browser.alert (message);
			#else
			js.Lib.alert (message);
			#end

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

		if ( parent.resizable ) {

			parent.__displayWidth = parent.width;
			parent.__displayHeight = parent.height;
			#if duell_container
				// :NOTE: account for menu bar
				parent.resize(Browser.window.innerWidth, Std.int(Browser.window.innerHeight - 25));
			#else
				parent.resize(Browser.window.innerWidth, Browser.window.innerHeight);
			#end

		} else if (parent.width == 0 && parent.height == 0) {

			if (element != null && element.clientWidth != 0 && element.clientHeight != 0 ) {

				parent.resize(element.clientWidth, element.clientHeight);

			} else {

				parent.resize(Browser.window.innerWidth, Browser.window.innerHeight);

			}

			// :NOTE: Can't start fullscreen.
			// parent.fullscreen = true;

		}

		if (canvas != null) {

			canvas.width = parent.width;
			canvas.height = parent.height;

		} else {

			div.style.width = parent.width + "px";
			div.style.height = parent.height + "px";

		}

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

			element.addEventListener ("touchstart", handleTouchEvent, true);
			element.addEventListener ("touchmove", handleTouchEvent, true);
			element.addEventListener ("touchend", handleTouchEvent, true);

			element.addEventListener ("gamepadconnected", handleGamepadEvent, true);
			element.addEventListener ("gamepaddisconnected", handleGamepadEvent, true);

		}

	}


	public function focus ():Void {
		if (canvas != null)
		{
			canvasBoundingClientRect = canvas.getBoundingClientRect();
		}
	}


	public function getDisplay ():Display {

		return System.getDisplay (0);

	}


	public function getEnableTextEvents ():Bool {

		return enableTextEvents;

	}


	private function handleFocusEvent (event:FocusEvent):Void {

		if (enableTextEvents) {

			Timer.delay (function () { textInput.focus (); }, 20);

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

		if (textInput.value != "") {

			parent.onTextInput.dispatch (textInput.value);
			textInput.value = "";

		}

	}


	private function handleMouseEvent (event:MouseEvent):Void {

		var x = 0.0;
		var y = 0.0;

		if (event.type != "wheel") {

			if (element != null) {

				if (canvas != null) {

					var rect = canvasBoundingClientRect;

					if(rect == null || rect.left == rect.right) { // The first getBoundingClientRect call is too realy, rect is degenerated.
						canvasBoundingClientRect = canvas.getBoundingClientRect();
						rect = canvasBoundingClientRect;
					}

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

				case "mouseenter":

					parent.onEnter.dispatch ();

				case "mouseleave":

					parent.onLeave.dispatch ();

				case "mouseup":

					parent.onMouseUp.dispatch (x, y, event.button);

				case "mousemove":

					parent.onMouseMove.dispatch (x, y);

				default:

			}

		} else {

			parent.onMouseWheel.dispatch (untyped event.deltaX, - untyped event.deltaY);

		}
	}


	private function handleTouchEvent (event:TouchEvent):Void {

		event.preventDefault ();

		var rect = null;

		if (element != null) {

			if (canvas != null) {

				rect = canvasBoundingClientRect;

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

		for (data in event.changedTouches) {

			var x = 0.0;
			var y = 0.0;

			if (rect != null) {

				x = (data.clientX - rect.left) * (windowWidth / rect.width);
				y = (data.clientY - rect.top) * (windowHeight / rect.height);

			} else {

				x = data.clientX;
				y = data.clientY;

			}

			switch (event.type) {

				case "touchstart":

					var touch = unusedTouchesPool.pop ();

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

				case "touchend":

					var touch = currentTouches.get (data.identifier);

					if (touch != null) {

						var cacheX = touch.x;
						var cacheY = touch.y;

						touch.x = x / windowWidth;
						touch.y = y / windowHeight;
						touch.dx = touch.x - cacheX;
						touch.dy = touch.y - cacheY;
						touch.pressure = data.force;

						Touch.onEnd.dispatch (touch);

						currentTouches.remove (data.identifier);
						unusedTouchesPool.add (touch);

						if (touch == primaryTouch) {

							parent.onMouseUp.dispatch (x, y, 0);
							primaryTouch = null;

						}

					}

				case "touchmove":

					var touch = currentTouches.get (data.identifier);

					if (touch != null) {

						var cacheX = touch.x;
						var cacheY = touch.y;

						touch.x = x / windowWidth;
						touch.y = y / windowHeight;
						touch.dx = touch.x - cacheX;
						touch.dy = touch.y - cacheY;
						touch.pressure = data.force;

						Touch.onMove.dispatch (touch);

						if (touch == primaryTouch) {

							parent.onMouseMove.dispatch (x, y);

						}

					}

				default:

			}

		}

	}


	public function move (x:Int, y:Int):Void {



	}


	public function resize (width:Int, height:Int):Void {
		if ( parent.resizable ) {
			if (element != null) {

					parent.__width = width;
					parent.__height = height;

					if (canvas != null) {

						if (element != cast canvas) {

							var margin_left : Float = 0;
							var margin_top : Float = 0;
							var stage = this.parent.stage;
							if ( stage != null  ) {
								if( stage.scaleMode != StageScaleMode.NO_SCALE ) {
									width = Std.int(stage.stageWidth * stage.scaleX);
									height = Std.int(stage.stageHeight * stage.scaleY);
									parent.__width = width;
									parent.__height = height;
								}
								margin_left = ( Browser.window.innerWidth - width ) / 2.0;
								#if duell_container
									margin_top = ( Browser.window.innerHeight - 25 - height ) / 2.0;
								#else
									margin_top = ( Browser.window.innerHeight - height ) / 2.0;
								#end
							}

							canvas.width = width;
							canvas.style.width = width + "px";
							canvas.style.marginLeft = margin_left + "px";
							canvas.style.marginTop = margin_top + "px";
							canvas.height = height;
							canvas.style.height = height + "px";
							if ( canvas.parentElement != null ) {
								canvas.parentElement.style.width = width + 2 * margin_left + "px";
								canvas.parentElement.style.height = height + 2 * margin_top + "px";
							}
						}

					}

			}
		}

		canvasBoundingClientRect = canvas.getBoundingClientRect();

	}


	public function setBorderless (value:Bool):Bool {

		return value;

	}


	public function setEnableTextEvents (value:Bool):Bool {

		if (value) {

			if (textInput == null) {

				textInput = cast Browser.document.createElement ('input');
				textInput.type = 'text';
				textInput.style.position = 'absolute';
				textInput.style.opacity = "0";
				textInput.style.color = "transparent";
				textInput.value = "";

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

			}

			textInput.focus ();

		} else {

			if (textInput != null) {

				textInput.removeEventListener ('input', handleInputEvent, true);
				textInput.removeEventListener ('blur', handleFocusEvent, true);

				textInput.blur ();

			}

		}

		return enableTextEvents = value;

	}


	public function setFullscreen (value:Bool):Bool {

		return false;

	}


	public function setIcon (image:Image):Void {



	}


	public function setMinimized (value:Bool):Bool {

		return false;

	}


	public function setResizable (value:Bool):Bool {

		return value;

	}


	public function setTitle (value:String):String {

		return value;

	}


}
