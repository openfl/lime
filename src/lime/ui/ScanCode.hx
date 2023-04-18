package lime.ui;

import lime._internal.backend.native.NativeCFFI;

@:access(lime._internal.backend.native.NativeCFFI)
@:access(lime.ui.KeyCode)
@:enum abstract ScanCode(Int) from Int to Int from UInt to UInt
{
	var UNKNOWN = 0;
	var BACKSPACE = 42;
	var TAB = 43;
	var RETURN = 40;
	var ESCAPE = 41;
	var SPACE = 44;
	// var EXCLAMATION = 0x21;
	// var QUOTE = 0x22;
	// var HASH = 0x23;
	// var DOLLAR = 0x24;
	// var PERCENT = 0x25;
	// var AMPERSAND = 0x26;
	var SINGLE_QUOTE = 52;
	// var LEFT_PARENTHESIS = 0x28;
	// var RIGHT_PARENTHESIS = 0x29;
	// var ASTERISK = 0x2A;
	// var PLUS = 0x2B;
	var COMMA = 54;
	var MINUS = 45;
	var PERIOD = 55;
	var SLASH = 56;
	var NUMBER_0 = 39;
	var NUMBER_1 = 30;
	var NUMBER_2 = 31;
	var NUMBER_3 = 32;
	var NUMBER_4 = 33;
	var NUMBER_5 = 34;
	var NUMBER_6 = 35;
	var NUMBER_7 = 36;
	var NUMBER_8 = 37;
	var NUMBER_9 = 38;
	// var COLON = 0x3A;
	var SEMICOLON = 51;
	// var LESS_THAN = 0x3C;
	var EQUALS = 46;
	// var GREATER_THAN = 0x3E;
	// var QUESTION = 0x3F;
	// var AT = 0x40;
	var LEFT_BRACKET = 47;
	var BACKSLASH = 49;
	var RIGHT_BRACKET = 48;
	// var CARET = 0x5E;
	// var UNDERSCORE = 0x5F;
	var GRAVE = 53;
	var A = 4;
	var B = 5;
	var C = 6;
	var D = 7;
	var E = 8;
	var F = 9;
	var G = 10;
	var H = 11;
	var I = 12;
	var J = 13;
	var K = 14;
	var L = 15;
	var M = 16;
	var N = 17;
	var O = 18;
	var P = 19;
	var Q = 20;
	var R = 21;
	var S = 22;
	var T = 23;
	var U = 24;
	var V = 25;
	var W = 26;
	var X = 27;
	var Y = 28;
	var Z = 29;
	var DELETE = 76;
	var CAPS_LOCK = 57;
	var F1 = 58;
	var F2 = 59;
	var F3 = 60;
	var F4 = 61;
	var F5 = 62;
	var F6 = 63;
	var F7 = 64;
	var F8 = 65;
	var F9 = 66;
	var F10 = 67;
	var F11 = 68;
	var F12 = 69;
	var PRINT_SCREEN = 70;
	var SCROLL_LOCK = 71;
	var PAUSE = 72;
	var INSERT = 73;
	var HOME = 74;
	var PAGE_UP = 75;
	var END = 77;
	var PAGE_DOWN = 78;
	var RIGHT = 79;
	var LEFT = 80;
	var DOWN = 81;
	var UP = 82;
	var NUM_LOCK = 83;
	var NUMPAD_DIVIDE = 84;
	var NUMPAD_MULTIPLY = 85;
	var NUMPAD_MINUS = 86;
	var NUMPAD_PLUS = 87;
	var NUMPAD_ENTER = 88;
	var NUMPAD_1 = 89;
	var NUMPAD_2 = 90;
	var NUMPAD_3 = 91;
	var NUMPAD_4 = 92;
	var NUMPAD_5 = 93;
	var NUMPAD_6 = 94;
	var NUMPAD_7 = 95;
	var NUMPAD_8 = 96;
	var NUMPAD_9 = 97;
	var NUMPAD_0 = 98;
	var NUMPAD_PERIOD = 99;
	var APPLICATION = 101;
	var POWER = 102;
	var NUMPAD_EQUALS = 103;
	var F13 = 104;
	var F14 = 105;
	var F15 = 106;
	var F16 = 107;
	var F17 = 108;
	var F18 = 109;
	var F19 = 110;
	var F20 = 111;
	var F21 = 112;
	var F22 = 113;
	var F23 = 114;
	var F24 = 115;
	var EXECUTE = 116;
	var HELP = 117;
	var MENU = 118;
	var SELECT = 119;
	var STOP = 120;
	var AGAIN = 121;
	var UNDO = 122;
	var CUT = 123;
	var COPY = 124;
	var PASTE = 125;
	var FIND = 126;
	var MUTE = 127;
	var VOLUME_UP = 128;
	var VOLUME_DOWN = 129;
	var NUMPAD_COMMA = 133;
	// var NUMPAD_EQUALS_AS400 = 134;
	var ALT_ERASE = 153;
	var SYSTEM_REQUEST = 154;
	var CANCEL = 155;
	var CLEAR = 156;
	var PRIOR = 157;
	var RETURN2 = 158;
	var SEPARATOR = 159;
	var OUT = 160;
	var OPER = 161;
	var CLEAR_AGAIN = 162;
	var CRSEL = 163;
	var EXSEL = 164;
	var NUMPAD_00 = 176;
	var NUMPAD_000 = 177;
	var THOUSAND_SEPARATOR = 178;
	var DECIMAL_SEPARATOR = 179;
	var CURRENCY_UNIT = 180;
	var CURRENCY_SUBUNIT = 181;
	var NUMPAD_LEFT_PARENTHESIS = 182;
	var NUMPAD_RIGHT_PARENTHESIS = 183;
	var NUMPAD_LEFT_BRACE = 184;
	var NUMPAD_RIGHT_BRACE = 185;
	var NUMPAD_TAB = 186;
	var NUMPAD_BACKSPACE = 187;
	var NUMPAD_A = 188;
	var NUMPAD_B = 189;
	var NUMPAD_C = 190;
	var NUMPAD_D = 191;
	var NUMPAD_E = 192;
	var NUMPAD_F = 193;
	var NUMPAD_XOR = 194;
	var NUMPAD_POWER = 195;
	var NUMPAD_PERCENT = 196;
	var NUMPAD_LESS_THAN = 197;
	var NUMPAD_GREATER_THAN = 198;
	var NUMPAD_AMPERSAND = 199;
	var NUMPAD_DOUBLE_AMPERSAND = 200;
	var NUMPAD_VERTICAL_BAR = 201;
	var NUMPAD_DOUBLE_VERTICAL_BAR = 202;
	var NUMPAD_COLON = 203;
	var NUMPAD_HASH = 204;
	var NUMPAD_SPACE = 205;
	var NUMPAD_AT = 206;
	var NUMPAD_EXCLAMATION = 207;
	var NUMPAD_MEM_STORE = 208;
	var NUMPAD_MEM_RECALL = 209;
	var NUMPAD_MEM_CLEAR = 210;
	var NUMPAD_MEM_ADD = 211;
	var NUMPAD_MEM_SUBTRACT = 212;
	var NUMPAD_MEM_MULTIPLY = 213;
	var NUMPAD_MEM_DIVIDE = 214;
	var NUMPAD_PLUS_MINUS = 215;
	var NUMPAD_CLEAR = 216;
	var NUMPAD_CLEAR_ENTRY = 217;
	var NUMPAD_BINARY = 218;
	var NUMPAD_OCTAL = 219;
	var NUMPAD_DECIMAL = 220;
	var NUMPAD_HEXADECIMAL = 221;
	var LEFT_CTRL = 224;
	var LEFT_SHIFT = 225;
	var LEFT_ALT = 226;
	var LEFT_META = 227;
	var RIGHT_CTRL = 228;
	var RIGHT_SHIFT = 229;
	var RIGHT_ALT = 230;
	var RIGHT_META = 231;
	var MODE = 257;
	var AUDIO_NEXT = 258;
	var AUDIO_PREVIOUS = 259;
	var AUDIO_STOP = 260;
	var AUDIO_PLAY = 261;
	var AUDIO_MUTE = 262;
	var MEDIA_SELECT = 263;
	var WWW = 264;
	var MAIL = 265;
	var CALCULATOR = 266;
	var COMPUTER = 267;
	var APP_CONTROL_SEARCH = 268;
	var APP_CONTROL_HOME = 269;
	var APP_CONTROL_BACK = 270;
	var APP_CONTROL_FORWARD = 271;
	var APP_CONTROL_STOP = 272;
	var APP_CONTROL_REFRESH = 273;
	var APP_CONTROL_BOOKMARKS = 274;
	var BRIGHTNESS_DOWN = 275;
	var BRIGHTNESS_UP = 276;
	var DISPLAY_SWITCH = 277;
	var BACKLIGHT_TOGGLE = 278;
	var BACKLIGHT_DOWN = 279;
	var BACKLIGHT_UP = 280;
	var EJECT = 281;
	var SLEEP = 282;

	@:from public static function fromKeyCode(keyCode:KeyCode):ScanCode
	{
		return KeyCode.toScanCode(keyCode);
	}

	private static function toKeyCode(scanCode:ScanCode):KeyCode
	{
		return KeyCode.fromScanCode(scanCode);
	}

	@:op(A > B) private static inline function gt(a:ScanCode, b:ScanCode):Bool
	{
		return (a : Int) > (b : Int);
	}

	@:op(A >= B) private static inline function gte(a:ScanCode, b:ScanCode):Bool
	{
		return (a : Int) >= (b : Int);
	}

	@:op(A < B) private static inline function lt(a:ScanCode, b:ScanCode):Bool
	{
		return (a : Int) < (b : Int);
	}

	@:op(A <= B) private static inline function lte(a:ScanCode, b:ScanCode):Bool
	{
		return (a : Int) <= (b : Int);
	}

	@:op(A + B) private static inline function plus(a:ScanCode, b:Int):ScanCode
	{
		return (a : Int) + b;
	}
}
