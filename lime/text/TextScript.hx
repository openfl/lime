package lime.text;


@:enum abstract TextScript(String) to (String) {
	
	var COMMON = "Zyyy";
	var INHERITED = "Zinh";
	var UNKNOWN = "Zzzz";
	
	var ARABIC = "Arab";
	var ARMENIAN = "Armn";
	var BENGALI = "Beng";
	var CYRILLIC = "Cyrl";
	var DEVANAGARI = "Deva";
	var GEORGIAN = "Geor";
	var GREEK = "Grek";
	var GUJARATI = "Gujr";
	var GURMUKHI = "Guru";
	var HANGUL = "Hang";
	var HAN = "Hani";
	var HEBREW = "Hebr";
	var HIRAGANA = "Hira";
	var KANNADA = "Knda";
	var KATAKANA = "Kana";
	var LAO = "Laoo";
	var LATIN = "Latn";
	var MALAYALAM = "Mlym";
	var ORIYA = "Orya";
	var TAMIL = "Taml";
	var TELUGA = "Telu";
	var THAI = "Thai";
	
	var TIBETAN = "Tibt";
	
	var BOPOMOFO = "Bopo";
	var BRAILLE = "Brai";
	var CANADIAN_SYLLABICS = "Cans";
	var CHEROKEE = "Cher";
	var ETHIOPIC = "Ethi";
	var KHMER = "Khmr";
	var MONGOLIAN = "Mong";
	var MYANMAR = "Mymr";
	var OGHAM = "Ogam";
	var RUNIC = "Runr";
	var SINHALA = "Sinh";
	var SYRIAC = "Syrc";
	var THAANA = "Thaa";
	var YI = "Yiii";
	
	var DESERET = "Dsrt";
	var GOTHIC = "Goth";
	var OLD_ITALIC = "Ital";
	
	var BUHID = "Buhd";
	var HANUNOO = "Hano";
	var TAGALOG = "Tglg";
	var TAGBANWA = "Tagb";
	
	var CYPRIOT = "Cprt";
	var LIMBU = "Limb";
	var LINEAR_B = "Linb";
	var OSMANYA = "Osma";
	var SHAVIAN = "Shaw";
	var TAI_LE = "Tale";
	var UGARITIC = "Ugar";
	
	var BUGINESE = "Bugi";
	var COPTIC = "Copt";
	var GLAGOLITIC = "Glag";
	var KHAROSHTHI = "Khar";
	var NEW_TAI_LUE = "Talu";
	var OLD_PERSIAN = "Xpeo";
	var SYLOTI_NAGRI = "Sylo";
	var TIFINAGH = "Tfng";
	
	var BALINESE = "Bali";
	var CUNEIFORM = "Xsux";
	var NKO = "Nkoo";
	var PHAGS_PA = "Phag";
	var PHOENICIAN = "Phnx";
	
	var CARIAN = "Cari";
	var CHAM = "Cham";
	var KAYAH_LI = "Kali";
	var LEPCHA = "Lepc";
	var LYCIAN = "Lyci";
	var LYDIAN = "Lydi";
	var OL_CHIKI = "Olck";
	var REJANG = "Rjng";
	var SAURASHTRA = "Saur";
	var SUNDANESE = "Sund";
	var VAI = "Vaii";
	
	var AVESTAN = "Avst";
	var BAMUM = "Bamu";
	var EGYPTIAN_HIEROGLYPHS = "Egyp";
	var IMPERIAL_ARAMAIC = "Armi";
	var INSCRIPTIONAL_PAHLAVI = "Phli";
	var INSCRIPTIONAL_PARTHIAN = "Prti";
	var JAVANESE = "Java";
	var KAITHI = "Kthi";
	var LISU = "Lisu";
	var MEETEI_MAYEK = "Mtei";
	var OLD_SOUTH_ARABIAN = "Sarb";
	var OLD_TURKIC = "Orkh";
	var SAMARITAN = "Samr";
	var TAI_THAM = "Lana";
	var TAI_VIET = "Tavt";
	
	var BATAK = "Batk";
	var BRAHMI = "Brah";
	var MANDAIC = "Mand";
	
	var CHAKMA = "Cakm";
	var MEROITIC_CURSIVE = "Merc";
	var MEROITIC_HIEROGLYPHS = "Mero";
	var MIAO = "Plrd";
	var SHARADA = "Shrd";
	var SORA_SOMPENG = "Sora";
	var TAKRI = "Takr";
	
	var BASSA_VAH = "Bass";
	var CAUCASIAN_ALBANIAN = "Aghb";
	var DUPLOYAN = "Dupl";
	var ELBASAN = "Elba";
	var GRANTHA = "Gran";
	var KHOJKI = "Khoj";
	var KHUDAWADI = "Sind";
	var LINEAR_A = "Lina";
	var MAHAJANI = "Mahj";
	var MANICHAEAN = "Mani";
	var MENDE_KIKAKUI = "Mend";
	var MODI = "Modi";
	var MRO = "Mroo";
	var NABATAEAN = "Nbat";
	var OLD_NORTH_ARABIAN = "Narb";
	var OLD_PERMIC = "Perm";
	var PAHAWH_HMONG = "Hmng";
	var PALMYRENE = "Palm";
	var PAU_CIN_HAU = "Pauc";
	var PSALTER_PAHLAVI = "Phlp";
	var SIDDHAM = "Sidd";
	var TIRHUTA = "Tirh";
	var WARANG_CITI = "Wara";
	
	
	public var rightToLeft (get, never):Bool;
	
	
	private inline function get_rightToLeft ():Bool {
		
		return switch (this) {
			
			case HEBREW, ARABIC, SYRIAC, THAANA, NKO, SAMARITAN, MANDAIC, IMPERIAL_ARAMAIC, PHOENICIAN, LYDIAN, CYPRIOT, KHAROSHTHI, OLD_SOUTH_ARABIAN, AVESTAN, INSCRIPTIONAL_PAHLAVI, PSALTER_PAHLAVI, OLD_TURKIC: true;
			//case KURDISH: true;
			default: false;
			
		}
		
	}
	
}