package flash.printing;

@:native("flash.printing.PrintMethod")
#if (haxe_ver >= 4.0) extern #else @:extern #end enum abstract PrintMethod(String)
{
	var AUTO;
	var BITMAP;
	var VECTOR;
}
