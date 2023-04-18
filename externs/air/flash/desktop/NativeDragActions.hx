package flash.desktop;

@:native("flash.desktop.NativeDragActions")
@:enum extern abstract NativeDragActions(String)
{
	var COPY;
	var LINK;
	var MOVE;
	var NONE;
}
