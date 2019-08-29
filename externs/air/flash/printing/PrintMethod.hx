package flash.printing;

@:native("flash.printing.PrintMethod")
@:enum extern abstract PrintMethod(String)
{
	var AUTO;
	var BITMAP;
	var VECTOR;
}
