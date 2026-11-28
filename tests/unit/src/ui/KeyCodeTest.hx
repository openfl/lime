package ui;

import lime.ui.KeyCode;
import lime.ui.ScanCode;
import utest.Assert;
import utest.Test;

/**
	Lime's key codes and scan codes are SDL's. A key that types a character has
	that character's code, in lowercase, and any other key has its scan code
	with SDLK_SCANCODE_MASK, bit 30, set. Scan codes are the USB keyboard usage
	numbers listed in SDL_scancode.h.
**/
class KeyCodeTest extends Test
{
	private static inline var SCANCODE_MASK = 1 << 30;

	public function new()
	{
		super();
	}

	public function testLetterKeysHaveTheirLowercaseCharacter():Void
	{
		var letters:Array<KeyCode> = [A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z];

		Assert.equals("abcdefghijklmnopqrstuvwxyz", characters(letters));
	}

	public function testDigitKeysHaveTheirCharacter():Void
	{
		var digits:Array<KeyCode> = [
			NUMBER_0, NUMBER_1, NUMBER_2, NUMBER_3, NUMBER_4, NUMBER_5, NUMBER_6, NUMBER_7, NUMBER_8, NUMBER_9
		];

		Assert.equals("0123456789", characters(digits));
	}

	public function testPunctuationKeysHaveTheirCharacter():Void
	{
		var punctuation:Array<KeyCode> = [
			SPACE, EXCLAMATION, QUOTE, HASH, DOLLAR, PERCENT, AMPERSAND, SINGLE_QUOTE, LEFT_PARENTHESIS, RIGHT_PARENTHESIS,
			ASTERISK, PLUS, COMMA, MINUS, PERIOD, SLASH, COLON, SEMICOLON, LESS_THAN, EQUALS, GREATER_THAN, QUESTION, AT,
			LEFT_BRACKET, BACKSLASH, RIGHT_BRACKET, CARET, UNDERSCORE, GRAVE
		];

		Assert.equals(" !\"#$%&'()*+,-./:;<=>?@[\\]^_`", characters(punctuation));
	}

	public function testEditingKeysHaveTheirControlCharacter():Void
	{
		var keys:Array<KeyCode> = [UNKNOWN, BACKSPACE, TAB, RETURN, ESCAPE, DELETE];

		Assert.equals("0,8,9,13,27,127", values(keys));
	}

	public function testKeysWithoutACharacterHaveTheirScanCodeWithTheMask():Void
	{
		var keyCodes = keysWithoutACharacter();
		var scanCodes = scanCodesWithoutACharacter();
		var wrong = [];

		for (i in 0...keyCodes.length)
		{
			var keyCode:Int = keyCodes[i];
			var scanCode:Int = scanCodes[i];

			if (keyCode != (scanCode | SCANCODE_MASK)) wrong.push(scanCode);
		}

		Assert.equals(keyCodes.length, scanCodes.length);
		Assert.equals("", wrong.join(","), "scan codes whose key code is not theirs with the mask: " + wrong.join(","));
	}

	public function testLetterScanCodesFollowTheAlphabet():Void
	{
		var letters:Array<ScanCode> = [A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z];

		Assert.equals([for (usage in 4...30) usage].join(","), scanValues(letters));
	}

	public function testDigitScanCodesStartAtOneAndEndWithZero():Void
	{
		var digits:Array<ScanCode> = [
			NUMBER_1, NUMBER_2, NUMBER_3, NUMBER_4, NUMBER_5, NUMBER_6, NUMBER_7, NUMBER_8, NUMBER_9, NUMBER_0
		];

		Assert.equals("30,31,32,33,34,35,36,37,38,39", scanValues(digits));
	}

	public function testScanCodesAreUSBUsageNumbers():Void
	{
		var editing:Array<ScanCode> = [UNKNOWN, RETURN, ESCAPE, BACKSPACE, TAB, SPACE, DELETE];
		Assert.equals("0,40,41,42,43,44,76", scanValues(editing));

		var punctuation:Array<ScanCode> = [
			MINUS, EQUALS, LEFT_BRACKET, RIGHT_BRACKET, BACKSLASH, SEMICOLON, SINGLE_QUOTE, GRAVE, COMMA, PERIOD, SLASH
		];
		Assert.equals("45,46,47,48,49,51,52,53,54,55,56", scanValues(punctuation));

		var functions:Array<ScanCode> = [CAPS_LOCK, F1, F12, PRINT_SCREEN, SCROLL_LOCK, PAUSE, F13, F24];
		Assert.equals("57,58,69,70,71,72,104,115", scanValues(functions));

		var navigation:Array<ScanCode> = [INSERT, HOME, PAGE_UP, END, PAGE_DOWN, RIGHT, LEFT, DOWN, UP];
		Assert.equals("73,74,75,77,78,79,80,81,82", scanValues(navigation));

		var keypad:Array<ScanCode> = [
			NUM_LOCK, NUMPAD_DIVIDE, NUMPAD_MULTIPLY, NUMPAD_MINUS, NUMPAD_PLUS, NUMPAD_ENTER, NUMPAD_1, NUMPAD_9, NUMPAD_0,
			NUMPAD_PERIOD
		];
		Assert.equals("83,84,85,86,87,88,89,97,98,99", scanValues(keypad));

		var modifiers:Array<ScanCode> = [
			LEFT_CTRL, LEFT_SHIFT, LEFT_ALT, LEFT_META, RIGHT_CTRL, RIGHT_SHIFT, RIGHT_ALT, RIGHT_META
		];
		Assert.equals("224,225,226,227,228,229,230,231", scanValues(modifiers));
	}

	public function testKeyCodesCompareByTheirValue():Void
	{
		Assert.isTrue(KeyCode.A < KeyCode.B);
		Assert.isTrue(KeyCode.Z > KeyCode.A);
		Assert.isTrue(KeyCode.NUMBER_9 <= KeyCode.NUMBER_9);
		Assert.isTrue(KeyCode.NUMBER_9 >= KeyCode.NUMBER_0);
		Assert.isFalse(KeyCode.NUMBER_0 > KeyCode.NUMBER_0);
		Assert.isTrue(KeyCode.A + 25 == KeyCode.Z);

		// The mask puts every key without a character after those with one
		Assert.isTrue(KeyCode.CAPS_LOCK > KeyCode.DELETE);
		Assert.isTrue(KeyCode.F1 < KeyCode.F2);
		Assert.isTrue(KeyCode.F1 + 11 == KeyCode.F12);
	}

	public function testScanCodesCompareByTheirValue():Void
	{
		Assert.isTrue(ScanCode.A < ScanCode.B);
		Assert.isTrue(ScanCode.SLEEP > ScanCode.A);
		Assert.isTrue(ScanCode.F1 <= ScanCode.F1);
		Assert.isTrue(ScanCode.F2 >= ScanCode.F1);
		Assert.isTrue(ScanCode.F1 + 11 == ScanCode.F12);
	}

	public function testKeyCodesAreIntegers():Void
	{
		var keyCode:KeyCode = 0x61;
		var value:Int = KeyCode.F1;

		Assert.isTrue(keyCode == KeyCode.A);
		Assert.equals(0x4000003A, value);
	}

	#if (lime_cffi && !macro)
	#if linux
	@Ignored("On X11, SDL takes these keys from the X server's keymap, which may lack F19 and F20 and gives the keypad parentheses and plus-minus their characters")
	#end
	public function testKeysWithoutACharacterConvertToTheirScanCodeAndBack():Void
	{
		var keyCodes = keysWithoutACharacter();
		var scanCodes = scanCodesWithoutACharacter();
		var wrong = [];

		for (i in 0...keyCodes.length)
		{
			var expectedKeyCode:Int = keyCodes[i];
			var expectedScanCode:Int = scanCodes[i];
			var keyCode:Int = KeyCode.fromScanCode(scanCodes[i]);
			var scanCode:Int = ScanCode.fromKeyCode(keyCodes[i]);

			if (keyCode != expectedKeyCode || scanCode != expectedScanCode)
			{
				wrong.push(expectedScanCode + " gave key " + keyCode + " and its key gave " + scanCode);
			}
		}

		Assert.equals("", wrong.join("; "));
	}

	public function testEditingKeysConvertToTheirScanCodeAndBack():Void
	{
		// These are the same key on every keyboard layout
		var keyCodes:Array<KeyCode> = [RETURN, ESCAPE, BACKSPACE, TAB, SPACE, DELETE];
		var scanCodes:Array<ScanCode> = [RETURN, ESCAPE, BACKSPACE, TAB, SPACE, DELETE];

		Assert.equals(scanValues(scanCodes), scanValues([for (keyCode in keyCodes) ScanCode.fromKeyCode(keyCode)]));
		Assert.equals(values(keyCodes), values([for (scanCode in scanCodes) KeyCode.fromScanCode(scanCode)]));
	}

	public function testLetterAndDigitKeysConvertBackToTheirScanCode():Void
	{
		// Which character one of these keys types is up to the keyboard layout,
		// but each types a character of its own
		var scanCodes:Array<ScanCode> = [
			A, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z, NUMBER_1, NUMBER_2, NUMBER_3,
			NUMBER_4, NUMBER_5, NUMBER_6, NUMBER_7, NUMBER_8, NUMBER_9, NUMBER_0
		];
		var wrong = [];

		for (scanCode in scanCodes)
		{
			var expected:Int = scanCode;
			var keyCode = KeyCode.fromScanCode(scanCode);
			var value:Int = keyCode;
			var back:Int = ScanCode.fromKeyCode(keyCode);

			if (value == 0 || (value & SCANCODE_MASK) != 0 || back != expected)
			{
				wrong.push(expected + " gave key " + value + ", which gave " + back);
			}
		}

		Assert.equals("", wrong.join("; "));
	}

	public function testCodesWithoutAKeyConvertToUnknown():Void
	{
		var unknownKey:Int = KeyCode.UNKNOWN;
		var unknownScan:Int = ScanCode.UNKNOWN;
		var keyOfUnknown:Int = KeyCode.fromScanCode(ScanCode.UNKNOWN);
		var scanOfUnknown:Int = ScanCode.fromKeyCode(KeyCode.UNKNOWN);

		Assert.equals(unknownKey, keyOfUnknown);
		Assert.equals(unknownScan, scanOfUnknown);

		// SDL has 512 scan codes, and no key for the last of them
		var keyOfLast:Int = KeyCode.fromScanCode(511);
		var keyPastLast:Int = KeyCode.fromScanCode(512);
		var keyBeforeFirst:Int = KeyCode.fromScanCode(-1);
		var scanOfLast:Int = ScanCode.fromKeyCode(511 | SCANCODE_MASK);

		Assert.equals(unknownKey, keyOfLast);
		Assert.equals(unknownKey, keyPastLast);
		Assert.equals(unknownKey, keyBeforeFirst);
		Assert.equals(unknownScan, scanOfLast);
	}

	public function testAScanCodeBecomesItsKeyCodeWhenAssigned():Void
	{
		var keyCode:KeyCode = ScanCode.F5;
		var scanCode:ScanCode = KeyCode.F5;
		var keyValue:Int = keyCode;
		var scanValue:Int = scanCode;

		Assert.equals(0x4000003E, keyValue);
		Assert.equals(62, scanValue);
	}
	#end

	private static function characters(keyCodes:Array<KeyCode>):String
	{
		return [for (keyCode in keyCodes) String.fromCharCode(keyCode)].join("");
	}

	private static function values(keyCodes:Array<KeyCode>):String
	{
		var values:Array<Int> = [for (keyCode in keyCodes) keyCode];
		return values.join(",");
	}

	private static function scanValues(scanCodes:Array<ScanCode>):String
	{
		var values:Array<Int> = [for (scanCode in scanCodes) scanCode];
		return values.join(",");
	}

	private static function keysWithoutACharacter():Array<KeyCode>
	{
		return [
			CAPS_LOCK, F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, PRINT_SCREEN, SCROLL_LOCK, PAUSE,
			INSERT, HOME, PAGE_UP, END, PAGE_DOWN, RIGHT, LEFT, DOWN, UP, NUM_LOCK, NUMPAD_DIVIDE,
			NUMPAD_MULTIPLY, NUMPAD_MINUS, NUMPAD_PLUS, NUMPAD_ENTER, NUMPAD_1, NUMPAD_2, NUMPAD_3, NUMPAD_4,
			NUMPAD_5, NUMPAD_6, NUMPAD_7, NUMPAD_8, NUMPAD_9, NUMPAD_0, NUMPAD_PERIOD, APPLICATION, POWER,
			NUMPAD_EQUALS, F13, F14, F15, F16, F17, F18, F19, F20, F21, F22, F23, F24, EXECUTE, HELP, MENU,
			SELECT, STOP, AGAIN, UNDO, CUT, COPY, PASTE, FIND, MUTE, VOLUME_UP, VOLUME_DOWN, NUMPAD_COMMA,
			ALT_ERASE, SYSTEM_REQUEST, CANCEL, CLEAR, PRIOR, RETURN2, SEPARATOR, OUT, OPER, CLEAR_AGAIN, CRSEL,
			EXSEL, NUMPAD_00, NUMPAD_000, THOUSAND_SEPARATOR, DECIMAL_SEPARATOR, CURRENCY_UNIT,
			CURRENCY_SUBUNIT, NUMPAD_LEFT_PARENTHESIS, NUMPAD_RIGHT_PARENTHESIS, NUMPAD_LEFT_BRACE,
			NUMPAD_RIGHT_BRACE, NUMPAD_TAB, NUMPAD_BACKSPACE, NUMPAD_A, NUMPAD_B, NUMPAD_C, NUMPAD_D, NUMPAD_E,
			NUMPAD_F, NUMPAD_XOR, NUMPAD_POWER, NUMPAD_PERCENT, NUMPAD_LESS_THAN, NUMPAD_GREATER_THAN,
			NUMPAD_AMPERSAND, NUMPAD_DOUBLE_AMPERSAND, NUMPAD_VERTICAL_BAR, NUMPAD_DOUBLE_VERTICAL_BAR,
			NUMPAD_COLON, NUMPAD_HASH, NUMPAD_SPACE, NUMPAD_AT, NUMPAD_EXCLAMATION, NUMPAD_MEM_STORE,
			NUMPAD_MEM_RECALL, NUMPAD_MEM_CLEAR, NUMPAD_MEM_ADD, NUMPAD_MEM_SUBTRACT, NUMPAD_MEM_MULTIPLY,
			NUMPAD_MEM_DIVIDE, NUMPAD_PLUS_MINUS, NUMPAD_CLEAR, NUMPAD_CLEAR_ENTRY, NUMPAD_BINARY,
			NUMPAD_OCTAL, NUMPAD_DECIMAL, NUMPAD_HEXADECIMAL, LEFT_CTRL, LEFT_SHIFT, LEFT_ALT, LEFT_META,
			RIGHT_CTRL, RIGHT_SHIFT, RIGHT_ALT, RIGHT_META, MODE, AUDIO_NEXT, AUDIO_PREVIOUS, AUDIO_STOP,
			AUDIO_PLAY, AUDIO_MUTE, MEDIA_SELECT, WWW, MAIL, CALCULATOR, COMPUTER, APP_CONTROL_SEARCH,
			APP_CONTROL_HOME, APP_CONTROL_BACK, APP_CONTROL_FORWARD, APP_CONTROL_STOP, APP_CONTROL_REFRESH,
			APP_CONTROL_BOOKMARKS, BRIGHTNESS_DOWN, BRIGHTNESS_UP, DISPLAY_SWITCH, BACKLIGHT_TOGGLE,
			BACKLIGHT_DOWN, BACKLIGHT_UP, EJECT, SLEEP
		];
	}

	// The same keys, in the same order
	private static function scanCodesWithoutACharacter():Array<ScanCode>
	{
		return [
			CAPS_LOCK, F1, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12, PRINT_SCREEN, SCROLL_LOCK, PAUSE,
			INSERT, HOME, PAGE_UP, END, PAGE_DOWN, RIGHT, LEFT, DOWN, UP, NUM_LOCK, NUMPAD_DIVIDE,
			NUMPAD_MULTIPLY, NUMPAD_MINUS, NUMPAD_PLUS, NUMPAD_ENTER, NUMPAD_1, NUMPAD_2, NUMPAD_3, NUMPAD_4,
			NUMPAD_5, NUMPAD_6, NUMPAD_7, NUMPAD_8, NUMPAD_9, NUMPAD_0, NUMPAD_PERIOD, APPLICATION, POWER,
			NUMPAD_EQUALS, F13, F14, F15, F16, F17, F18, F19, F20, F21, F22, F23, F24, EXECUTE, HELP, MENU,
			SELECT, STOP, AGAIN, UNDO, CUT, COPY, PASTE, FIND, MUTE, VOLUME_UP, VOLUME_DOWN, NUMPAD_COMMA,
			ALT_ERASE, SYSTEM_REQUEST, CANCEL, CLEAR, PRIOR, RETURN2, SEPARATOR, OUT, OPER, CLEAR_AGAIN, CRSEL,
			EXSEL, NUMPAD_00, NUMPAD_000, THOUSAND_SEPARATOR, DECIMAL_SEPARATOR, CURRENCY_UNIT,
			CURRENCY_SUBUNIT, NUMPAD_LEFT_PARENTHESIS, NUMPAD_RIGHT_PARENTHESIS, NUMPAD_LEFT_BRACE,
			NUMPAD_RIGHT_BRACE, NUMPAD_TAB, NUMPAD_BACKSPACE, NUMPAD_A, NUMPAD_B, NUMPAD_C, NUMPAD_D, NUMPAD_E,
			NUMPAD_F, NUMPAD_XOR, NUMPAD_POWER, NUMPAD_PERCENT, NUMPAD_LESS_THAN, NUMPAD_GREATER_THAN,
			NUMPAD_AMPERSAND, NUMPAD_DOUBLE_AMPERSAND, NUMPAD_VERTICAL_BAR, NUMPAD_DOUBLE_VERTICAL_BAR,
			NUMPAD_COLON, NUMPAD_HASH, NUMPAD_SPACE, NUMPAD_AT, NUMPAD_EXCLAMATION, NUMPAD_MEM_STORE,
			NUMPAD_MEM_RECALL, NUMPAD_MEM_CLEAR, NUMPAD_MEM_ADD, NUMPAD_MEM_SUBTRACT, NUMPAD_MEM_MULTIPLY,
			NUMPAD_MEM_DIVIDE, NUMPAD_PLUS_MINUS, NUMPAD_CLEAR, NUMPAD_CLEAR_ENTRY, NUMPAD_BINARY,
			NUMPAD_OCTAL, NUMPAD_DECIMAL, NUMPAD_HEXADECIMAL, LEFT_CTRL, LEFT_SHIFT, LEFT_ALT, LEFT_META,
			RIGHT_CTRL, RIGHT_SHIFT, RIGHT_ALT, RIGHT_META, MODE, AUDIO_NEXT, AUDIO_PREVIOUS, AUDIO_STOP,
			AUDIO_PLAY, AUDIO_MUTE, MEDIA_SELECT, WWW, MAIL, CALCULATOR, COMPUTER, APP_CONTROL_SEARCH,
			APP_CONTROL_HOME, APP_CONTROL_BACK, APP_CONTROL_FORWARD, APP_CONTROL_STOP, APP_CONTROL_REFRESH,
			APP_CONTROL_BOOKMARKS, BRIGHTNESS_DOWN, BRIGHTNESS_UP, DISPLAY_SWITCH, BACKLIGHT_TOGGLE,
			BACKLIGHT_DOWN, BACKLIGHT_UP, EJECT, SLEEP
		];
	}
}
