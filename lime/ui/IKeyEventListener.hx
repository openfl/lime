package lime.ui;


interface IKeyEventListener {
	
	
	function onKeyDown (keyCode:Int, modifier:Int):Void;
	function onKeyUp (keyCode:Int, modifier:Int):Void;
	
	
}