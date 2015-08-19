package lime.ui;


import lime.app.Event;


class Keyboard {
	
	
	public static var onKeyDown = new Event<KeyCode->KeyModifier->Void> ();
	public static var onKeyUp = new Event<KeyCode->KeyModifier->Void> ();
	
	
}