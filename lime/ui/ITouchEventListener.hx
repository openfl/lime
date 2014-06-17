package lime.ui;


interface ITouchEventListener {
	
	
	function onTouchEnd (x:Float, y:Float):Void;
	function onTouchMove (x:Float, y:Float):Void;
	function onTouchStart (x:Float, y:Float):Void;
	
	
}