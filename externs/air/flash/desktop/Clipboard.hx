package flash.desktop;

@:require(flash10) extern class Clipboard
{
	var formats(default, never):Array<ClipboardFormats>;
	#if air
	var supportsFilePromise(default, never):Bool;
	#end
	function clear():Void;
	function clearData(format:ClipboardFormats):Void;
	function getData(format:ClipboardFormats, ?transferMode:ClipboardTransferMode):flash.utils.Object;
	function hasFormat(format:ClipboardFormats):Bool;
	function setData(format:ClipboardFormats, data:flash.utils.Object, serializable:Bool = true):Bool;
	function setDataHandler(format:ClipboardFormats, handler:flash.utils.Function, serializable:Bool = true):Bool;
	static var generalClipboard(default, never):Clipboard;
}
