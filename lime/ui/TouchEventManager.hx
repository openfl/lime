package lime.ui;


import lime.app.Event;


class TouchEventManager {
	
	
	public static var onTouchEnd = new Event<Float->Float->Int->Void> ();
	public static var onTouchMove = new Event<Float->Float->Int->Void> ();
	public static var onTouchStart = new Event<Float->Float->Int->Void> ();
	
	
}