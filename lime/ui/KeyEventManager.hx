package lime.ui;


import lime.app.Event;


class KeyEventManager {
	
	
	public static var onKeyDown = new Event<Int->Int->Void> ();
	public static var onKeyUp = new Event<Int->Int->Void> ();
	
	
}