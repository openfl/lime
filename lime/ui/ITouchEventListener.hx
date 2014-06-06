package lime.ui;


interface ITouchEventListener {
	
	
	function onTouchEnd (event:TouchEvent):Void;
	function onTouchMove (event:TouchEvent):Void;
	function onTouchStart (event:TouchEvent):Void;
	
	
}