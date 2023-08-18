package flash.printing;

@:native("flash.printing.PaperSize")
#if (haxe_ver >= 4.0) extern enum #else @:extern @:enum #end abstract PaperSize(String)
{
	var A4 = "a4";
	var A5 = "a5";
	var A6 = "a6";
	var CHOUKEI3GOU = "choukei3gou";
	var CHOUKEI4GOU = "choukei4gou";
	var ENV_10 = "env_10";
	var ENV_B5 = "env_b5";
	var ENV_C5 = "env_c5";
	var ENV_DL = "env_dl";
	var ENV_MONARCH = "env_monarch";
	var ENV_PERSONAL = "env_personal";
	var EXECUTIVE = "executive";
	var FOLIO = "folio";
	var JIS_B5 = "jis_b5";
	var LEGAL = "legal";
	var LETTER = "letter";
	var STATEMENT = "statement";
}
