package flash.display;

@:native("flash.display.StageAspectRatio")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract StageAspectRatio(String)
{
	var ANY = "any";
	var LANDSCAPE = "landscape";
	var PORTRAIT = "portrait";
}
