package lime._backend.native;


import lime.system.System;
import lime.ui.KeyEventManager;


class NativeKeyEventManager {
	
	
	private static var eventInfo:KeyEventInfo;
	
	
	public static function create ():Void {
		
		eventInfo = new KeyEventInfo ();
		
		lime_key_event_manager_register (handleEvent, eventInfo);
		
	}
	
	
	private static function handleEvent ():Void {
		
		switch (eventInfo.type) {
			
			case KEY_DOWN:
				
				KeyEventManager.onKeyDown.dispatch (eventInfo.keyCode, eventInfo.modifier);
			
			case KEY_UP:
				
				KeyEventManager.onKeyUp.dispatch (eventInfo.keyCode, eventInfo.modifier);
			
		}
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	private static var lime_key_event_manager_register = System.load ("lime", "lime_key_event_manager_register", 2);
	
	
}


private class KeyEventInfo {
	
	
	public var keyCode:Int;
	public var modifier:Int;
	public var type:KeyEventType;
	
	
	public function new (type:KeyEventType = null, keyCode:Int = 0, modifier:Int = 0) {
		
		this.type = type;
		this.keyCode = keyCode;
		this.modifier = modifier;
		
	}
	
	
	public function clone ():KeyEventInfo {
		
		return new KeyEventInfo (type, keyCode, modifier);
		
	}
	
	
}


@:enum private abstract KeyEventType(Int) {
	
	var KEY_DOWN = 0;
	var KEY_UP = 1;
	
}