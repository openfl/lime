package ui;

import utest.Assert;
import utest.Test;

#if (cpp && windows)
@:cppFileCode("#include <windows.h>")
#end
class HighDPITest extends Test
{
	public function new()
	{
		super();
	}

	#if (cpp && windows)
	public function testWindowsDrawsAtEachDisplaysOwnResolution():Void
	{
		// The tests' window allows high DPI, so the process is aware of each
		// display's scale rather than drawn at 96 DPI and stretched
		var awareness:Int = untyped __cpp__("(int)GetAwarenessFromDpiAwarenessContext (GetThreadDpiAwarenessContext ())");
		Assert.equals(2, awareness, "the process is not aware of each display's DPI (DPI_AWARENESS_PER_MONITOR_AWARE is 2)");
	}
	#end
}
