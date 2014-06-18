package lime.ui;


interface ITouchEventListener {
	
	
	function onTouchEnd (x:Float, y:Float, id:Int):Void;
	function onTouchMove (x:Float, y:Float, id:Int):Void;
	function onTouchStart (x:Float, y:Float, id:Int):Void;
	
	
}