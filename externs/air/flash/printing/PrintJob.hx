package flash.printing;

extern class PrintJob extends flash.events.EventDispatcher
{
	#if air
	var copies:Int;
	var firstPage(default, never):Int;
	var isColor(default, never):Bool;
	var jobName:String;
	var lastPage(default, never):Int;
	var maxPixelsPerInch(default, never):Float;
	#end
	var orientation(default, never):PrintJobOrientation;
	var pageHeight(default, never):Int;
	var pageWidth(default, never):Int;
	#if air
	var paperArea(default, never):flash.geom.Rectangle;
	#end
	var paperHeight(default, never):Int;
	var paperWidth(default, never):Int;
	#if air
	var printableArea(default, never):flash.geom.Rectangle;
	var printer:String;
	#end
	function new():Void;
	function addPage(sprite:flash.display.Sprite, ?printArea:flash.geom.Rectangle, ?options:PrintJobOptions, frameNum:Int = 0):Void;
	#if air
	function selectPaperSize(paperSize:PaperSize):Void;
	#end
	function send():Void;
	#if air
	function showPageSetupDialog():Bool;
	#end
	function start():Bool;
	#if air
	function start2(?uiOptions:PrintUIOptions, showPrintDialog:Bool = true):Bool;
	function terminate():Void;
	static var active(default, never):Bool;
	#end
	@:require(flash10_1) static var isSupported(default, never):Bool;
	#if air
	static var printers(default, never):flash.Vector<String>;
	static var supportsPageSetupDialog(default, never):Bool;
	#end
}
