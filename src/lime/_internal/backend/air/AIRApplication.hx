package lime._internal.backend.air;

import flash.desktop.NativeApplication;
import flash.desktop.SystemIdleMode;
import flash.events.Event;
import lime._internal.backend.flash.FlashApplication;
import lime.app.Application;
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

		if (Application.current.onExit.canceled)
		{
			event.preventDefault();
			event.stopImmediatePropagation();
		}
	}

	public override function exit():Void
	{
		// TODO: Remove event handlers?
	}
}
