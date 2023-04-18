package flash.desktop;

extern class NativeDragManager
{
	static var dragInitiator(default, never):flash.display.InteractiveObject;
	static var dropAction:NativeDragActions;
	static var isDragging(default, never):Bool;
	static var isSupported(default, never):Bool;
	static function acceptDragDrop(target:flash.display.InteractiveObject):Void;
	static function doDrag(dragInitiator:flash.display.InteractiveObject, clipboard:Clipboard, ?dragImage:flash.display.BitmapData, ?offset:flash.geom.Point,
		?allowedActions:NativeDragOptions):Void;
}
