package lime.ui;


interface IMouseEventListener {
	
	
	function onMouseDown (x:Float, y:Float, button:Int):Void;
	function onMouseMove (x:Float, y:Float, button:Int):Void;
	function onMouseUp (x:Float, y:Float, button:Int):Void;
	
	
}