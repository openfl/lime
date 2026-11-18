package ui;

import lime.ui.KeyModifier;
import utest.Assert;
import utest.Test;

/**
	Key modifiers are SDL's SDL_Keymod bits, with a left and a right bit for
	each of Shift, Ctrl, Alt and the Meta (Windows or Command) key. The helper
	properties stand for either side, as the `shiftKey`, `ctrlKey` and `altKey`
	of a Flash keyboard event do.
**/
class KeyModifierTest extends Test
{
	public function new()
	{
		super();
	}

	public function testEachModifierHasItsSDLBit():Void
	{
		var modifiers:Array<Int> = [
			KeyModifier.NONE, KeyModifier.LEFT_SHIFT, KeyModifier.RIGHT_SHIFT, KeyModifier.LEFT_CTRL, KeyModifier.RIGHT_CTRL,
			KeyModifier.LEFT_ALT, KeyModifier.RIGHT_ALT, KeyModifier.LEFT_META, KeyModifier.RIGHT_META, KeyModifier.NUM_LOCK,
			KeyModifier.CAPS_LOCK, KeyModifier.MODE
		];

		Assert.equals("0,1,2,64,128,256,512,1024,2048,4096,8192,16384", modifiers.join(","));
	}

	public function testEitherSideModifiersAreBothSides():Void
	{
		var modifiers:Array<Int> = [KeyModifier.SHIFT, KeyModifier.CTRL, KeyModifier.ALT, KeyModifier.META];

		Assert.equals("3,192,768,3072", modifiers.join(","));
	}

	public function testNoModifierReadsAsNothingHeld():Void
	{
		Assert.equals("", held(KeyModifier.NONE));
	}

	public function testEachBitReadsAsItsOwnKeyOnly():Void
	{
		Assert.equals("shift", held(KeyModifier.LEFT_SHIFT));
		Assert.equals("shift", held(KeyModifier.RIGHT_SHIFT));
		Assert.equals("ctrl", held(KeyModifier.LEFT_CTRL));
		Assert.equals("ctrl", held(KeyModifier.RIGHT_CTRL));
		Assert.equals("alt", held(KeyModifier.LEFT_ALT));
		Assert.equals("alt", held(KeyModifier.RIGHT_ALT));
		Assert.equals("meta", held(KeyModifier.LEFT_META));
		Assert.equals("meta", held(KeyModifier.RIGHT_META));
		Assert.equals("numLock", held(KeyModifier.NUM_LOCK));
		Assert.equals("capsLock", held(KeyModifier.CAPS_LOCK));

		// AltGr on some layouts, which is none of the keys with a helper
		Assert.equals("", held(KeyModifier.MODE));
	}

	public function testBitsWithoutAModifierReadAsNothingHeld():Void
	{
		// The bits SDL leaves between the modifiers, and its scroll lock bit
		Assert.equals("", held(0x0004 | 0x0008 | 0x0010 | 0x0020 | 0x8000));
	}

	public function testBothSidesHeldReadAsHeld():Void
	{
		Assert.equals("shift", held(KeyModifier.SHIFT));
		Assert.equals("ctrl", held(KeyModifier.CTRL));
		Assert.equals("alt", held(KeyModifier.ALT));
		Assert.equals("meta", held(KeyModifier.META));
	}

	public function testSeveralModifiersReadTogether():Void
	{
		var modifier:KeyModifier = KeyModifier.RIGHT_CTRL | KeyModifier.LEFT_ALT | KeyModifier.NUM_LOCK;
		Assert.equals("ctrl,alt,numLock", held(modifier));

		var all:KeyModifier = 0xFFFF;
		Assert.equals("shift,ctrl,alt,meta,numLock,capsLock", held(all));
	}

	public function testHoldingAModifierSetsBothSides():Void
	{
		var shift = KeyModifier.NONE, ctrl = KeyModifier.NONE, alt = KeyModifier.NONE, meta = KeyModifier.NONE;
		shift.shiftKey = true;
		ctrl.ctrlKey = true;
		alt.altKey = true;
		meta.metaKey = true;
		var modifiers:Array<Int> = [shift, ctrl, alt, meta];

		Assert.equals("3,192,768,3072", modifiers.join(","));
	}

	public function testTurningALockOnSetsItsBit():Void
	{
		var numLock = KeyModifier.NONE, capsLock = KeyModifier.NONE;
		numLock.numLock = true;
		capsLock.capsLock = true;
		var modifiers:Array<Int> = [numLock, capsLock];

		Assert.equals("4096,8192", modifiers.join(","));
	}

	public function testHoldingAModifierKeepsTheOthers():Void
	{
		var modifier:KeyModifier = KeyModifier.LEFT_SHIFT | KeyModifier.CAPS_LOCK;
		modifier.altKey = true;
		var value:Int = modifier;

		Assert.equals(0x0001 | 0x2000 | 0x0300, value);
	}

	public function testReleasingAModifierClearsBothSidesAndKeepsTheOthers():Void
	{
		var shift:KeyModifier = 0xFFFF, ctrl:KeyModifier = 0xFFFF, alt:KeyModifier = 0xFFFF, meta:KeyModifier = 0xFFFF;
		var numLock:KeyModifier = 0xFFFF, capsLock:KeyModifier = 0xFFFF;
		shift.shiftKey = false;
		ctrl.ctrlKey = false;
		alt.altKey = false;
		meta.metaKey = false;
		numLock.numLock = false;
		capsLock.capsLock = false;
		var modifiers:Array<Int> = [shift, ctrl, alt, meta, numLock, capsLock];

		Assert.equals([0xFFFC, 0xFF3F, 0xFCFF, 0xF3FF, 0xEFFF, 0xDFFF].join(","), modifiers.join(","));
	}

	public function testReleasingOneSideHeldClearsIt():Void
	{
		var modifier:KeyModifier = KeyModifier.RIGHT_ALT | KeyModifier.LEFT_CTRL;
		modifier.altKey = false;

		Assert.equals("ctrl", held(modifier));
	}

	public function testSettingAModifierToWhatItIsChangesNothing():Void
	{
		var ctrl:KeyModifier = KeyModifier.LEFT_CTRL;
		var none = KeyModifier.NONE;
		ctrl.ctrlKey = true;
		none.ctrlKey = false;
		none.capsLock = false;
		var ctrlValue:Int = ctrl;
		var noneValue:Int = none;

		// Holding it again adds the other side, as the helper stands for both
		Assert.equals(0x00C0, ctrlValue);
		Assert.equals(0, noneValue);
	}

	public function testSettingAModifierGivesTheValueSet():Void
	{
		var modifier = KeyModifier.NONE;

		Assert.isTrue(modifier.shiftKey = true);
		Assert.isFalse(modifier.shiftKey = false);
	}

	private static function held(modifier:KeyModifier):String
	{
		var held = [];

		if (modifier.shiftKey) held.push("shift");
		if (modifier.ctrlKey) held.push("ctrl");
		if (modifier.altKey) held.push("alt");
		if (modifier.metaKey) held.push("meta");
		if (modifier.numLock) held.push("numLock");
		if (modifier.capsLock) held.push("capsLock");

		return held.join(",");
	}
}
