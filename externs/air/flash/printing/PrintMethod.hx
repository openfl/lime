package flash.printing;

@:native("flash.printing.PrintMethod")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract PrintMethod(String)
{
	var AUTO = "auto";
	var BITMAP = "bitmap";
	var VECTOR = "vector";
}
