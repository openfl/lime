package lime._internal.backend.flash;

import flash.display.BitmapData;
import flash.display.Stage;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.events.Event;
import flash.events.FocusEvent;
import flash.events.KeyboardEvent;
import flash.events.MouseEvent;
import flash.events.TouchEvent;
import flash.geom.Matrix;
import flash.system.Capabilities;
import flash.ui.Mouse;
import flash.ui.MouseCursor as FlashMouseCursor;
import flash.Lib;
import lime.app.Application;
import lime.graphics.Image;
import lime.graphics.RenderContext;
import lime.graphics.RenderContextAttributes;
import lime.math.Rectangle;
import lime.ui.KeyCode;
import lime.ui.KeyModifier;
import lime.ui.MouseButton;
import lime.ui.MouseCursor;
import lime.ui.MouseWheelMode;
import lime.ui.Touch;
import lime.system.Display;
import lime.system.DisplayMode;
import lime.system.System;
import lime.ui.Window;

@:access(lime._internal.backend.flash.FlashApplication)
@:access(lime.app.Application)
@:access(lime.graphics.RenderContext)
@:access(lime.ui.Window)
class FlashWindow
{
	private static var windowID = 0;

	private var cacheMouseX:Float;
	private var cacheMouseY:Float;
	private var cacheTime:Int;
	private var currentTouches = new Map<Int, Touch>();
	private var cursor:MouseCursor;
	private var frameRate:Float;
	private var mouseLeft:Bool;
	private var parent:Window;
	private var textInputEnabled:Bool;
	private var textInputRect:Rectangle;
	private var unusedTouchesPool = new List<Touch>();

	public function new(parent:Window)
	{
		this.parent = parent;

		cacheMouseX = 0;
		cacheMouseY = 0;
		cursor = DEFAULT;

		create();
	}

	public function alert(message:String, title:String):Void {}

	public function close():Void
	{
		parent.application.__removeWindow(parent);
	}

	private function convertKeyCode(keyCode:Int):KeyCode
	{
		if (keyCode >= 65 && keyCode <= 90)
		{
			return keyCode + 32;
		}

		switch (keyCode)
		{
			case 16:
				return KeyCode.LEFT_SHIFT;
			case 17:
				return KeyCode.LEFT_CTRL;
			case 18:
				return KeyCode.LEFT_ALT;
			case 20:
				return KeyCode.CAPS_LOCK;
			case 33:
				return KeyCode.PAGE_UP;
			case 34:
				return KeyCode.PAGE_DOWN;
			case 35:
				return KeyCode.END;
			case 36:
				return KeyCode.HOME;
			case 37:
				return KeyCode.LEFT;
			case 38:
				return KeyCode.UP;
			case 39:
				return KeyCode.RIGHT;
			case 40:
				return KeyCode.DOWN;
			case 45:
				return KeyCode.INSERT;
			case 46:
				return KeyCode.DELETE;
			case 96:
				return KeyCode.NUMPAD_0;
			case 97:
				return KeyCode.NUMPAD_1;
			case 98:
				return KeyCode.NUMPAD_2;
			case 99:
				return KeyCode.NUMPAD_3;
			case 100:
				return KeyCode.NUMPAD_4;
			case 101:
				return KeyCode.NUMPAD_5;
			case 102:
				return KeyCode.NUMPAD_6;
			case 103:
				return KeyCode.NUMPAD_7;
			case 104:
				return KeyCode.NUMPAD_8;
			case 105:
				return KeyCode.NUMPAD_9;
			case 106:
				return KeyCode.NUMPAD_MULTIPLY;
			case 107:
				return KeyCode.NUMPAD_PLUS;
			case 108:
				return KeyCode.NUMPAD_ENTER;
			case 109:
				return KeyCode.NUMPAD_MINUS;
			case 110:
				return KeyCode.NUMPAD_PERIOD;
			case 111:
				return KeyCode.NUMPAD_DIVIDE;
			case 112:
				return KeyCode.F1;
			case 113:
				return KeyCode.F2;
			case 114:
				return KeyCode.F3;
			case 115:
				return KeyCode.F4;
			case 116:
				return KeyCode.F5;
			case 117:
				return KeyCode.F6;
			case 118:
				return KeyCode.F7;
			case 119:
				return KeyCode.F8;
			case 120:
				return KeyCode.F9;
			case 121:
				return KeyCode.F10;
			case 122:
				return KeyCode.F11;
			case 123:
				return KeyCode.F12;
			case 124:
				return KeyCode.F13;
			case 125:
				return KeyCode.F14;
			case 126:
				return KeyCode.F15;
			case 144:
				return KeyCode.NUM_LOCK;
			case 186:
				return KeyCode.SEMICOLON;
			case 187:
				return KeyCode.EQUALS;
			case 188:
				return KeyCode.COMMA;
			case 189:
				return KeyCode.MINUS;
			case 190:
				return KeyCode.PERIOD;
			case 191:
				return KeyCode.SLASH;
			case 192:
				return KeyCode.GRAVE;
			case 219:
				return KeyCode.LEFT_BRACKET;
			case 220:
				return KeyCode.BACKSLASH;
			case 221:
				return KeyCode.RIGHT_BRACKET;
			case 222:
				return KeyCode.SINGLE_QUOTE;
		}

		return keyCode;
	}

	private function create():Void
	{
		if (#if air true #else FlashApplication.createFirstWindow #end)
		{
			var attributes = parent.__attributes;

			parent.id = windowID++;

			if (parent.stage == null) parent.stage = Lib.current.stage;
			var stage = parent.stage;

			parent.__width = stage.stageWidth;
			parent.__height = stage.stageHeight;

			stage.align = StageAlign.TOP_LEFT;
			stage.scaleMode = StageScaleMode.NO_SCALE;

			stage.addEventListener(KeyboardEvent.KEY_DOWN, handleKeyEvent);
			stage.addEventListener(KeyboardEvent.KEY_UP, handleKeyEvent);

			var events = [
				"mouseDown",
				"mouseMove",
				"mouseUp",
				"mouseWheel",
				"middleMouseDown",
				"middleMouseMove",
				"middleMouseUp"
				#if ((!openfl && !disable_flash_right_click)
					|| enable_flash_right_click), "rightMouseDown", "rightMouseMove", "rightMouseUp"
				#end
			];

			for (event in events)
			{
				stage.addEventListener(event, handleMouseEvent);
			}

			stage.addEventListener(TouchEvent.TOUCH_BEGIN, handleTouchEvent);
			stage.addEventListener(TouchEvent.TOUCH_MOVE, handleTouchEvent);
			stage.addEventListener(TouchEvent.TOUCH_END, handleTouchEvent);
			stage.addEventListener(Event.ACTIVATE, handleWindowEvent);
			stage.addEventListener(Event.DEACTIVATE, handleWindowEvent);
			stage.addEventListener(FocusEvent.FOCUS_IN, handleWindowEvent);
			stage.addEventListener(FocusEvent.FOCUS_OUT, handleWindowEvent);
			stage.addEventListener(Event.MOUSE_LEAVE, handleWindowEvent);

			// #if !air
			stage.addEventListener(Event.RESIZE, handleWindowEvent);
			// #end

			var context = new RenderContext();
			context.flash = Lib.current;
			context.type = FLASH;
			context.version = Capabilities.version;
			context.window = parent;

			var contextAttributes:RenderContextAttributes =
				{
					antialiasing: 0,
					background: null,
					colorDepth: 32,
					depth: false,
					hardware: false,
					stencil: false,
					type: FLASH,
					version: Capabilities.version,
					vsync: false,
				};

			if (Reflect.hasField(attributes, "context")
				&& Reflect.hasField(attributes.context, "background")
				&& attributes.context.background != null)
			{
				stage.color = attributes.context.background;
				contextAttributes.background = stage.color;
			}

			setFrameRate(Reflect.hasField(attributes, "frameRate") ? attributes.frameRate : 60);

			context.attributes = contextAttributes;
			parent.context = context;

			// TODO: Wait for application.exec?

			cacheTime = Lib.getTimer();
			// handleApplicationEvent (null);

			stage.addEventListener(Event.ENTER_FRAME, handleApplicationEvent);
		}
	}

	public function focus():Void {}

	public function getCursor():MouseCursor
	{
		return cursor;
	}

	public function getDisplay():Display
	{
		return System.getDisplay(0);
	}

	public function getDisplayMode():DisplayMode
	{
		return System.getDisplay(0).currentMode;
	}

	private function handleApplicationEvent(event:Event):Void
	{
		var currentTime = Lib.getTimer();
		var deltaTime = currentTime - cacheTime;
		cacheTime = currentTime;

		parent.application.onUpdate.dispatch(deltaTime);
		parent.onRender.dispatch(parent.context);
	}

	private function handleKeyEvent(event:KeyboardEvent):Void
	{
		var keyCode = convertKeyCode(event.keyCode);
		var modifier = (event.shiftKey ? (KeyModifier.SHIFT) : 0) | (event.ctrlKey ? (KeyModifier.CTRL) : 0) | (event.altKey ? (KeyModifier.ALT) : 0);

		if (event.type == KeyboardEvent.KEY_DOWN)
		{
			parent.onKeyDown.dispatch(keyCode, modifier);

			if (parent.textInputEnabled)
			{
				parent.onTextInput.dispatch(String.fromCharCode(event.charCode));
			}
		}
		else
		{
			parent.onKeyUp.dispatch(keyCode, modifier);
		}
	}

	private function handleMouseEvent(event:MouseEvent):Void
	{
		var button:MouseButton = switch (event.type)
		{
			case "middleMouseDown", "middleMouseUp": MIDDLE;
			case "rightMouseDown", "rightMouseUp": RIGHT;
			default: LEFT;
		}

		switch (event.type)
		{
			case "mouseDown", "middleMouseDown", "rightMouseDown":
				parent.onMouseDown.dispatch(event.stageX, event.stageY, button);

			case "mouseMove":
				if (mouseLeft)
				{
					mouseLeft = false;
					parent.onEnter.dispatch();
				}

				var mouseX = event.stageX;
				var mouseY = event.stageY;

				parent.onMouseMove.dispatch(mouseX, mouseY);
				parent.onMouseMoveRelative.dispatch(mouseX - cacheMouseX, mouseY - cacheMouseY);

				cacheMouseX = mouseX;
				cacheMouseY = mouseY;

			case "mouseUp", "middleMouseUp", "rightMouseUp":
				parent.onMouseUp.dispatch(event.stageX, event.stageY, button);

			case "mouseWheel":
				parent.onMouseWheel.dispatch(0, event.delta, MouseWheelMode.LINES);

			default:
		}
	}

	private function handleTouchEvent(event:TouchEvent):Void
	{
		var x = event.stageX;
		var y = event.stageY;

		switch (event.type)
		{
			case TouchEvent.TOUCH_BEGIN:
				var touch = unusedTouchesPool.pop();

				if (touch == null)
				{
					touch = new Touch(x / parent.__width, y / parent.__height, event.touchPointID, 0, 0, event.pressure, parent.id);
				}
				else
				{
					touch.x = x / parent.__width;
					touch.y = y / parent.__height;
					touch.id = event.touchPointID;
					touch.dx = 0;
					touch.dy = 0;
					touch.pressure = event.pressure;
					touch.device = parent.id;
				}

				currentTouches.set(event.touchPointID, touch);

				Touch.onStart.dispatch(touch);

				if (event.isPrimaryTouchPoint)
				{
					parent.onMouseDown.dispatch(x, y, LEFT);
				}

			case TouchEvent.TOUCH_END:
				var touch = currentTouches.get(event.touchPointID);

				if (touch != null)
				{
					var cacheX = touch.x;
					var cacheY = touch.y;

					touch.x = x / parent.__width;
					touch.y = y / parent.__height;
					touch.dx = touch.x - cacheX;
					touch.dy = touch.y - cacheY;
					touch.pressure = event.pressure;

					Touch.onEnd.dispatch(touch);

					currentTouches.remove(event.touchPointID);
					unusedTouchesPool.add(touch);

					if (event.isPrimaryTouchPoint)
					{
						parent.onMouseUp.dispatch(x, y, 0);
					}
				}

			case TouchEvent.TOUCH_MOVE:
				var touch = currentTouches.get(event.touchPointID);

				if (touch != null)
				{
					var cacheX = touch.x;
					var cacheY = touch.y;

					touch.x = x / parent.__width;
					touch.y = y / parent.__height;
					touch.dx = touch.x - cacheX;
					touch.dy = touch.y - cacheY;
					touch.pressure = event.pressure;

					Touch.onMove.dispatch(touch);

					if (event.isPrimaryTouchPoint)
					{
						parent.onMouseMove.dispatch(x, y);
					}
				}
		}
	}

	private function handleWindowEvent(event:Event):Void
	{
		switch (event.type)
		{
			case Event.ACTIVATE:
				parent.onActivate.dispatch();

			case Event.DEACTIVATE:
				parent.onDeactivate.dispatch();

			case FocusEvent.FOCUS_IN:
				parent.onFocusIn.dispatch();

			case FocusEvent.FOCUS_OUT:
				parent.onFocusOut.dispatch();

			case Event.MOUSE_LEAVE:
				mouseLeft = true;
				parent.onLeave.dispatch();

			case Event.RESIZE:
				parent.__width = parent.stage.stageWidth;
				parent.__height = parent.stage.stageHeight;

				parent.onResize.dispatch(parent.__width, parent.__height);

			default:
		}
	}

	public function readPixels(rect:Rectangle):Image
	{
		var stageRect = new Rectangle(0, 0, parent.stage.stageWidth, parent.stage.stageHeight);

		if (rect == null)
		{
			rect = stageRect;
		}
		else
		{
			var rect = rect.intersection(stageRect);
		}

		if (rect.width > 0 && rect.height > 0)
		{
			var bitmapData = new BitmapData(Std.int(rect.width), Std.int(rect.height));

			var matrix = new Matrix();
			matrix.tx = -rect.x;
			matrix.ty = -rect.y;

			bitmapData.draw(parent.stage, matrix);

			return Image.fromBitmapData(bitmapData);
		}
		else
		{
			return null;
		}
	}

	public function setCursor(value:MouseCursor):MouseCursor
	{
		if (cursor != value)
		{
			if (value == null)
			{
				Mouse.hide();
			}
			else
			{
				if (cursor == null)
				{
					Mouse.show();
				}

				Mouse.cursor = switch (value)
				{
					case ARROW: FlashMouseCursor.ARROW;
					case CROSSHAIR: FlashMouseCursor.ARROW;
					case MOVE: FlashMouseCursor.HAND;
					case POINTER: FlashMouseCursor.BUTTON;
					case RESIZE_NESW: FlashMouseCursor.HAND;
					case RESIZE_NS: FlashMouseCursor.HAND;
					case RESIZE_NWSE: FlashMouseCursor.HAND;
					case RESIZE_WE: FlashMouseCursor.HAND;
					case TEXT: FlashMouseCursor.IBEAM;
					case WAIT: FlashMouseCursor.ARROW;
					case WAIT_ARROW: FlashMouseCursor.ARROW;
					default: FlashMouseCursor.AUTO;
				}
			}

			cursor = value;
		}

		return cursor;
	}

	public function setDisplayMode(value:DisplayMode):DisplayMode
	{
		return value;
	}

	public function getFrameRate():Float
	{
		return frameRate;
	}

	public function getMouseLock():Bool
	{
		return false;
	}

	public function getTextInputEnabled():Bool
	{
		return textInputEnabled;
	}

	public function move(x:Int, y:Int):Void {}

	public function resize(width:Int, height:Int):Void {}

	public function setBorderless(value:Bool):Bool
	{
		return value;
	}

	public function setFrameRate(value:Float):Float
	{
		frameRate = value;
		if (parent.stage != null) parent.stage.frameRate = value;
		return value;
	}

	public function setFullscreen(value:Bool):Bool
	{
		parent.stage.displayState = (value ? FULL_SCREEN_INTERACTIVE : NORMAL);
		return value;
	}

	public function setIcon(image:Image):Void {}

	public function setMaximized(value:Bool):Bool
	{
		return false;
	}

	public function setMinimized(value:Bool):Bool
	{
		return false;
	}

	public function setMouseLock(value:Bool):Void {}

	public function setResizable(value:Bool):Bool
	{
		return value;
	}

	public function setTextInputEnabled(value:Bool):Bool
	{
		return textInputEnabled = value;
	}

	public function setTextInputRect(value:Rectangle):Rectangle
	{
		return textInputRect = value;
	}

	public function setTitle(value:String):String
	{
		return value;
	}

	public function warpMouse(x:Int, y:Int):Void {}
}
