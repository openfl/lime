package flash.printing;

extern class PrintJobOptions
{
	#if air
	var pixelsPerInch:Float;
	#end
	var printAsBitmap:Bool;
	#if air
	var printMethod:PrintMethod;
	#end
	function new(printAsBitmap:Bool = false):Void;
}
