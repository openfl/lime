package lime._internal.backend.air;

import flash.desktop.NativeApplication;
import flash.desktop.SystemIdleMode;
import flash.events.Event;
import lime._internal.backend.flash.FlashApplication;
import lime.app.Application;
import lime.system.Orientation;
import lime.system.System;

class AIRApplication extends FlashApplication
{
	public function new(parent:Application):Void
	{
		super(parent);

		NativeApplication.nativeApplication.systemIdleMode = SystemIdleMode.KEEP_AWAKE;
		NativeApplication.nativeApplication.addEventListener(Event.EXITING, handleExitEvent);
	}

	private function handleExitEvent(event:Event):Void
	{
		System.exit(0);

		if (Application.current != null && Application.current.onExit.canceled)
		{
			event.preventDefault();
			event.stopImmediatePropagation();
		}
	}

	public override function exit():Void
	{
		// TODO: Remove event handlers?
	}

	override public function getDeviceOrientation():Orientation
	{
		switch (parent.window.stage.deviceOrientation)
		{
			case DEFAULT:
				return PORTRAIT;
			case UPSIDE_DOWN:
				return PORTRAIT_FLIPPED;
			case ROTATED_LEFT:
				return LANDSCAPE;
			case ROTATED_RIGHT:
				return LANDSCAPE_FLIPPED;
			default:
				return UNKNOWN;
		}
	}
}
