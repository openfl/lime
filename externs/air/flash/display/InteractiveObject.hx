package flash.display;

extern class InteractiveObject extends DisplayObject
{
	var accessibilityImplementation:flash.accessibility.AccessibilityImplementation;
	// var contextMenu : #if air flash.display.NativeMenu #else flash.ui.ContextMenu #end;
	var contextMenu:NativeMenu;
	var doubleClickEnabled:Bool;
	var focusRect:Dynamic;
	var mouseEnabled:Bool;
	@:require(flash11) var needsSoftKeyboard:Bool;
	@:require(flash11) var softKeyboardInputAreaOfInterest:flash.geom.Rectangle;
	var tabEnabled:Bool;
	var tabIndex:Int;
	function new():Void;
	@:require(flash11) function requestSoftKeyboard():Bool;
}
