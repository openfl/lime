package lime._internal.backend.air;

import flash.desktop.NotificationType;
import flash.display.NativeWindow;
import flash.display.NativeWindowInitOptions;
import flash.display.NativeWindowRenderMode;
import flash.display.NativeWindowSystemChrome;
import flash.events.Event;
import flash.events.NativeWindowBoundsEvent;
import flash.html.HTMLLoader;
import flash.Lib;
import lime._internal.backend.flash.FlashApplication;
import lime._internal.backend.flash.FlashWindow;
import lime.app.Application;
import lime.ui.Window;

@:access(lime._internal.backend.flash.FlashApplication)
@:access(lime.ui.Window)
class AIRWindow extends FlashWindow
{
	private var closing:Bool;
	private var nativeWindow:NativeWindow;

	public function new(parent:Window)
	{
		super(parent);
	}

	public override function alert(message:String, title:String):Void
	{
		if (nativeWindow != null)
		{
			nativeWindow.notifyUser(NotificationType.INFORMATIONAL);

			if (message != null)
			{
				var htmlLoader = new HTMLLoader();
				htmlLoader.loadString("<!DOCTYPE html><html lang='en'><head><meta charset='utf-8'><title></title><script></script></head><body></body></html>");
				htmlLoader.window.alert(message);
			}
		}
	}

	public override function close():Void
	{
		if (!closing)
		{
			closing = true;
			parent.onClose.dispatch();

			if (!parent.onClose.canceled)
			{
				nativeWindow.close();
			}
			else
			{
				closing = false;
			}
		}
	}

	private override function create():Void
	{
		var title = (parent.__title != null && parent.__title != "") ? parent.__title : "Lime Application";
		var attributes = parent.__attributes;

		var alwaysOnTop = false;
		var borderless = false;
		var fullscreen = false;
		var hardware = false;
		var hidden = false;
		var maximized = false;
		var minimized = false;
		var resizable = false;

		var frameRate = 60.0;
		var width = 0;
		var height = 0;

		if (Reflect.hasField(attributes, "alwaysOnTop") && attributes.alwaysOnTop) alwaysOnTop = true;
		if (Reflect.hasField(attributes, "borderless") && attributes.borderless) borderless = true;
		if (Reflect.hasField(attributes, "fullscreen") && attributes.fullscreen) fullscreen = true;
		if (Reflect.hasField(attributes, "context")
			&& Reflect.hasField(attributes.context, "hardware")
			&& attributes.context.hardware) hardware = true;
		if (Reflect.hasField(attributes, "hidden") && attributes.hidden) hidden = true;
		if (Reflect.hasField(attributes, "maximized") && attributes.maximized) maximized = true;
		if (Reflect.hasField(attributes, "minimized") && attributes.minimized) minimized = true;
		if (Reflect.hasField(attributes, "resizable") && attributes.resizable) resizable = true;

		if (Reflect.hasField(attributes, "frameRate")) frameRate = attributes.frameRate;
		if (Reflect.hasField(attributes, "width")) width = attributes.width;
		if (Reflect.hasField(attributes, "height")) height = attributes.height;

		if (FlashApplication.createFirstWindow)
		{
			nativeWindow = Lib.current.stage.nativeWindow;

			#if munit
			hidden = true;
			#end
		}
		else
		{
			var options = new NativeWindowInitOptions();
			options.systemChrome = borderless ? NativeWindowSystemChrome.NONE : NativeWindowSystemChrome.STANDARD;
			options.renderMode = hardware ? NativeWindowRenderMode.DIRECT : NativeWindowRenderMode.CPU;
			options.transparent = false;
			options.maximizable = maximized;
			options.minimizable = minimized;
			options.resizable = resizable;

			nativeWindow = new NativeWindow(options);
			nativeWindow.stage.frameRate = frameRate;

			if (width > 0) nativeWindow.width = width;
			if (height > 0) nativeWindow.height = height;
		}

		if (nativeWindow != null)
		{
			parent.stage = nativeWindow.stage;

			nativeWindow.addEventListener(Event.CLOSING, handleNativeWindowEvent);
			nativeWindow.addEventListener(Event.CLOSE, handleNativeWindowEvent);
			// nativeWindow.addEventListener (Event.RESIZE, handleWindowEvent);
			nativeWindow.addEventListener(NativeWindowBoundsEvent.MOVE, handleNativeWindowEvent);

			if (hidden)
			{
				nativeWindow.visible = false;
			}

			// nativeWindow.activate ();
			nativeWindow.alwaysInFront = alwaysOnTop;
			nativeWindow.title = title;

			if (maximized)
			{
				nativeWindow.maximize();
			}
			else if (minimized)
			{
				nativeWindow.minimize();
			}
		}

		if (fullscreen)
		{
			setFullscreen(true);
		}

		if (nativeWindow != null)
		{
			parent.__width = Std.int(nativeWindow.width);
			parent.__height = Std.int(nativeWindow.height);
			parent.__x = Math.round(nativeWindow.x);
			parent.__y = Math.round(nativeWindow.y);
			parent.stage = nativeWindow.stage;
		}

		super.create();

		if (hardware)
		{
			parent.context.attributes.hardware = true;
			parent.context.attributes.depth = true;
			parent.context.attributes.stencil = true;
		}
	}

	public override function focus():Void
	{
		if (nativeWindow != null && nativeWindow.visible)
		{
			nativeWindow.activate();
		}
	}

	private function handleNativeWindowEvent(event:Event):Void
	{
		switch (event.type)
		{
			case Event.CLOSING:
				parent.close();

				if (parent.onClose.canceled)
				{
					event.preventDefault();
					event.stopImmediatePropagation();
				}

			case Event.CLOSE:
				closing = true;
				parent.onClose.dispatch();

			// case Event.RESIZE:

			// 	// TODO: Should this be the inner (stageWidth) or outer (nativeWindow width) size?

			// 	parent.__width = parent.stage.stageWidth;
			// 	parent.__height = parent.stage.stageHeight;

			// 	// parent.__width = nativeWindow.width;
			// 	// parent.__height = nativeWindow.height;

			// 	parent.onResize.dispatch (parent.__width, parent.__height);

			case NativeWindowBoundsEvent.MOVE:
				parent.onMove.dispatch(nativeWindow.x, nativeWindow.y);

			default:
		}
	}

	public override function move(x:Int, y:Int):Void
	{
		if (nativeWindow != null)
		{
			nativeWindow.x = x;
			nativeWindow.y = y;
		}
	}

	public override function resize(width:Int, height:Int):Void
	{
		if (nativeWindow != null)
		{
			nativeWindow.width = width;
			nativeWindow.height = height;
		}
	}

	public override function setMaximized(value:Bool):Bool
	{
		if (nativeWindow != null)
		{
			if (value)
			{
				nativeWindow.maximize();
			}
			else
			{
				nativeWindow.restore();
			}
		}

		return value;
	}

	public override function setMinimized(value:Bool):Bool
	{
		if (nativeWindow != null)
		{
			if (value)
			{
				nativeWindow.minimize();
			}
			else
			{
				nativeWindow.restore();
			}
		}

		return value;
	}

	public override function setTitle(value:String):String
	{
		if (nativeWindow != null)
		{
			nativeWindow.title = value;
		}

		return value;
	}
}
