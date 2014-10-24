package lime.graphics;

import lime.system.System;

@:enum abstract TextDirection(Int) to (Int) {

	var Invalid = 0;
	var LeftToRight = 4;
	var RightToLeft = 5;
	var TopToBottom = 6;
	var BottomToTop = 7;

}

@:enum abstract TextScript(String) to (String) {

	var ScriptCommon = "Zyyy";
	var ScriptInherited = "Zinh";
	var ScriptUnknown = "Zzzz";

	var ScriptArabic = "Arab";
	var ScriptArmenian = "Armn";
	var ScriptBengali = "Beng";
	var ScriptCyrillic = "Cyrl";
	var ScriptDevanagari = "Deva";
	var ScriptGeorgian = "Geor";
	var ScriptGreek = "Grek";
	var ScriptGujarati = "Gujr";
	var ScriptGurmukhi = "Guru";
	var ScriptHangul = "Hang";
	var ScriptHan = "Hani";
	var ScriptHebrew = "Hebr";
	var ScriptHiragana = "Hira";
	var ScriptKannada = "Knda";
	var ScriptKatakana = "Kana";
	var ScriptLao = "Laoo";
	var ScriptLatin = "Latn";
	var ScriptMalayalam = "Mlym";
	var ScriptOriya = "Orya";
	var ScriptTamil = "Taml";
	var ScriptTelugu = "Telu";
	var ScriptThai = "Thai";

	var ScriptTibetan = "Tibt";

	var ScriptBopomofo = "Bopo";
	var ScriptBraille = "Brai";
	var ScriptCanadianSyllabics = "Cans";
	var ScriptCherokee = "Cher";
	var ScriptEthiopic = "Ethi";
	var ScriptKhmer = "Khmr";
	var ScriptMongolian = "Mong";
	var ScriptMyanmar = "Mymr";
	var ScriptOgham = "Ogam";
	var ScriptRunic = "Runr";
	var ScriptSinhala = "Sinh";
	var ScriptSyriac = "Syrc";
	var ScriptThaana = "Thaa";
	var ScriptYi = "Yiii";

	var ScriptDeseret = "Dsrt";
	var ScriptGothic = "Goth";
	var ScriptOldItalic = "Ital";

	var ScriptBuhid = "Buhd";
	var ScriptHanunoo = "Hano";
	var ScriptTagalog = "Tglg";
	var ScriptTagbanwa = "Tagb";

	var ScriptCypriot = "Cprt";
	var ScriptLimbu = "Limb";
	var ScriptLinearB = "Linb";
	var ScriptOsmanya = "Osma";
	var ScriptShavian = "Shaw";
	var ScriptTaiLe = "Tale";
	var ScriptUgaritic = "Ugar";

	var ScriptBuginese = "Bugi";
	var ScriptCoptic = "Copt";
	var ScriptGlagolitic = "Glag";
	var ScriptKharoshthi = "Khar";
	var ScriptNewTaiLue = "Talu";
	var ScriptOldPersian = "Xpeo";
	var ScriptSylotiNagri = "Sylo";
	var ScriptTifinagh = "Tfng";

	var ScriptBalinese = "Bali";
	var ScriptCuneiform = "Xsux";
	var ScriptNko = "Nkoo";
	var ScriptPhagsPa = "Phag";
	var ScriptPhoenician = "Phnx";

	var ScriptCarian = "Cari";
	var ScriptCham = "Cham";
	var ScriptKayahLi = "Kali";
	var ScriptLepcha = "Lepc";
	var ScriptLycian = "Lyci";
	var ScriptLydian = "Lydi";
	var ScriptOlChiki = "Olck";
	var ScriptRejang = "Rjng";
	var ScriptSaurashtra = "Saur";
	var ScriptSundanese = "Sund";
	var ScriptVai = "Vaii";

	var ScriptAvestan = "Avst";
	var ScriptBamum = "Bamu";
	var ScriptEgyptianHieroglyphs = "Egyp";
	var ScriptImperialAramaic = "Armi";
	// var ScriptInvar scriptionalPahlavi = "Phli";
	// var ScriptInvar scriptionalParthian = "Prti";
	var ScriptJavanese = "Java";
	var ScriptKaithi = "Kthi";
	var ScriptLisu = "Lisu";
	var ScriptMeeteiMayek = "Mtei";
	var ScriptOldSouthArabian = "Sarb";
	var ScriptOldTurkic = "Orkh";
	var ScriptSamaritan = "Samr";
	var ScriptTaiTham = "Lana";
	var ScriptTaiViet = "Tavt";

	var ScriptBatak = "Batk";
	var ScriptBrahmi = "Brah";
	var ScriptMandaic = "Mand";

	var ScriptChakma = "Cakm";
	var ScriptMeroiticCursive = "Merc";
	var ScriptMeroiticHieroglyphs = "Mero";
	var ScriptMiao = "Plrd";
	var ScriptSharada = "Shrd";
	var ScriptSoraSompeng = "Sora";
	var ScriptTakri = "Takr";

	var ScriptBassaVah = "Bass";
	var ScriptCaucasianAlbanian = "Aghb";
	var ScriptDuployan = "Dupl";
	var ScriptElbasan = "Elba";
	var ScriptGrantha = "Gran";
	var ScriptKhojki = "Khoj";
	var ScriptKhudawadi = "Sind";
	var ScriptLinearA = "Lina";
	var ScriptMahajani = "Mahj";
	var ScriptManichaean = "Mani";
	var ScriptMendeKikakui = "Mend";
	var ScriptModi = "Modi";
	var ScriptMro = "Mroo";
	var ScriptNabataean = "Nbat";
	var ScriptOldNorthArabian = "Narb";
	var ScriptOldPermic = "Perm";
	var ScriptPahawhHmong = "Hmng";
	var ScriptPalmyrene = "Palm";
	var ScriptPauCinHau = "Pauc";
	var ScriptPsalterPahlavi = "Phlp";
	var ScriptSiddham = "Sidd";
	var ScriptTirhuta = "Tirh";
	var ScriptWarangCiti = "Wara";

}


typedef Point = {
	var x:Float;
	var y:Float;
};


typedef PosInfo = {
	var codepoint:UInt;
	var advance:Point;
	var offset:Point;
};


class TextFormat {

	public var direction(default, null):TextDirection;

	#if (cpp || neko || nodejs)

	public var handle:Dynamic;

	#end

	public function new (direction:TextDirection, script:TextScript, language:String) {

		#if (cpp || neko || nodejs)

		handle = lime_text_create (direction, script, language);

		#end

		this.direction = direction;

	}

	public function fromString (font:Font, size:Int, text:String):Array<PosInfo> {

		#if (cpp || neko || nodejs)

		return lime_text_from_string (handle, font.handle, size, text);

		#end

	}

	#if (cpp || neko || nodejs)
	private static var lime_text_create = System.load ("lime", "lime_text_create", 3);
	private static var lime_text_from_string = System.load ("lime", "lime_text_from_string", 4);
	#end

}
