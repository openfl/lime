package flash.printing;

@:native("flash.printing.PaperSize")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract PaperSize(String)
{
	var A4;
	var A5;
	var A6;
	var CHOUKEI3GOU;
	var CHOUKEI4GOU;
	var ENV_10;
	var ENV_B5;
	var ENV_C5;
	var ENV_DL;
	var ENV_MONARCH;
	var ENV_PERSONAL;
	var EXECUTIVE;
	var FOLIO;
	var JIS_B5;
	var LEGAL;
	var LETTER;
	var STATEMENT;
}
