package lime.ui;


import lime.app.Event;


class MouseEventManager {
	
	
	public static var onMouseDown = new Event<Float->Float->Int->Void> ();
	public static var onMouseMove = new Event<Float->Float->Int->Void> ();
	public static var onMouseUp = new Event<Float->Float->Int->Void> ();
	public static var onMouseWheel = new Event<Float->Float->Void> ();
	
	
}