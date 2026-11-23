package ui;

import haxe.Timer;
import lime.app.Application;
import lime.ui.MouseButton;
import lime.ui.TrayIcon;
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	A tray icon's clicks and mouse events carry the pointer's position on the
	screen, and the mouse events their button.

	Native tray icons report these through native-desktop, from 1.2.0. With an
	older native-desktop, clicks carry no position and the mouse events are not
	dispatched, and the test that clicks a real icon says so and passes.
**/
class TrayIconTest extends Test
{
	private var trayIcon:TrayIcon;

	public function new()
	{
		super();
	}

	public function teardown():Void
	{
		if (trayIcon != null)
		{
			trayIcon.close();
			trayIcon = null;
		}
	}

	#if (lime_cffi && !macro)
	private static inline var TRAY_ICON_CLICK = 0;
	private static inline var TRAY_ICON_RIGHT_CLICK = 2;
	private static inline var TRAY_ICON_MOUSE_DOWN = 3;
	private static inline var TRAY_ICON_MOUSE_UP = 4;
	private static inline var TRAY_ICON_DOUBLE_CLICK = 5;

	public function testTheEventsCarryThePositionAndButton():Void
	{
		if (!open()) return;

		var heard = [];
		listen(heard);

		event(TRAY_ICON_MOUSE_DOWN, 10, 20, MouseButton.LEFT);
		event(TRAY_ICON_MOUSE_UP, 11, 21, MouseButton.LEFT);
		event(TRAY_ICON_CLICK, 12, 22, 0);
		event(TRAY_ICON_DOUBLE_CLICK, 13, 23, MouseButton.MIDDLE);
		// Left of and above the primary display
		event(TRAY_ICON_MOUSE_DOWN, -40, -5, MouseButton.RIGHT);
		event(TRAY_ICON_RIGHT_CLICK, -40, -5, 0);

		Assert.same([
			"down 10,20 0",
			"up 11,21 0",
			"click 12,22",
			"double click 13,23 1",
			"down -40,-5 2",
			"right click -40,-5"
		], heard);
	}

	#if windows
	/**
		Posts the messages Windows sends a tray icon's window for clicks of the
		left and right buttons and a double-click, through PowerShell, as no
		real pointer is moved.
	**/
	@:timeout(20000)
	public function testRealClicksCarryTheirPositions(async:Async):Void
	{
		if (!open())
		{
			async.done();
			return;
		}

		var heard = [];
		listen(heard);

		// Posted from the application's loop, where the icon's window gets its messages
		Timer.delay(function()
		{
			var posted = postClicks(@:privateAccess trayIcon.__backend.id);

			Timer.delay(function()
			{
				Assert.isTrue(posted, "the tray icon's window was not found");

				var expected = [
					"down 1500,1050 0",
					"up 1500,1050 0",
					"click 1500,1050",
					"double click 1501,1051 0",
					"up 1501,1051 0",
					"down -40,20 2",
					"up -40,20 2",
					"right click -40,20"
				];

				#if (native_desktop >= "1.2.0")
				Assert.same(expected, heard);
				#else
				if (heard.length > 0 && StringTools.startsWith(heard[0], "down"))
				{
					Assert.same(expected, heard);
				}
				else
				{
					// utest takes a warning as a failure, so the test passes, saying why
					trace("native-desktop " + haxe.macro.Compiler.getDefine("native-desktop")
						+ " has no tray icon positions or mouse events, so only the clicks were tested: " + heard.join(", "));
					Assert.isTrue(heard.indexOf("click 0,0") > -1 && heard.indexOf("right click 0,0") > -1, "heard " + heard.join(", "));
				}
				#end

				async.done();
			}, 500);
		}, 10);
	}

	private static function postClicks(iconID:Int):Bool
	{
		var script = "Add-Type -Namespace LimeTest -Name Tray -MemberDefinition @'\n"
			+ "[DllImport(\"user32.dll\")] public static extern bool PostMessage(IntPtr hWnd, uint msg, IntPtr wParam, IntPtr lParam);\n"
			+ "[DllImport(\"user32.dll\")] public static extern uint GetWindowThreadProcessId(IntPtr hWnd, out uint processId);\n"
			+ "[DllImport(\"user32.dll\", CharSet = CharSet.Unicode)] public static extern IntPtr FindWindowEx(IntPtr parent, IntPtr after, string className, string title);\n"
			+ "public static IntPtr Find(uint process) {\n"
			+ "  IntPtr window = IntPtr.Zero;\n"
			+ "  while ((window = FindWindowEx(IntPtr.Zero, window, \"NativeDesktopTrayIconWindow\", null)) != IntPtr.Zero) {\n"
			+ "    uint owner; GetWindowThreadProcessId(window, out owner); if (owner == process) return window;\n"
			+ "  }\n"
			+ "  return IntPtr.Zero;\n"
			+ "}\n"
			+ "'@\n"
			// This process started the script
			+ "$parent = (Get-CimInstance Win32_Process -Filter \"ProcessId=$PID\").ParentProcessId\n"
			+ "$tray = [LimeTest.Tray]::Find([uint32]$parent)\n"
			+ "if ($tray -eq [IntPtr]::Zero) { exit 1 }\n"
			+ "function Send($message, $x, $y) {\n"
			// NOTIFYICON_VERSION_4: the position in wParam, the message and the icon's ID in lParam
			+ "  $w = [IntPtr](($x -band 0xFFFF) + (($y -band 0xFFFF) -shl 16))\n"
			+ "  [LimeTest.Tray]::PostMessage($tray, 0x8001, $w, [IntPtr]($message + (" + iconID + " -shl 16))) | Out-Null\n"
			+ "}\n"
			// WM_LBUTTONDOWN, WM_LBUTTONUP, NIN_SELECT, then WM_LBUTTONDBLCLK and WM_LBUTTONUP
			+ "Send 0x0201 1500 1050; Send 0x0202 1500 1050; Send 0x0400 1500 1050\n"
			+ "Send 0x0203 1501 1051; Send 0x0202 1501 1051\n"
			// WM_RBUTTONDOWN, WM_RBUTTONUP, WM_CONTEXTMENU
			+ "Send 0x0204 -40 20; Send 0x0205 -40 20; Send 0x007B -40 20\n"
			+ "exit 0\n";

		// An encoded command is UTF-16, and needs no quoting
		var utf16 = haxe.io.Bytes.alloc(script.length * 2);
		for (i in 0...script.length)
		{
			utf16.setUInt16(i * 2, StringTools.fastCodeAt(script, i));
		}

		var process = new sys.io.Process(powerShell(), ["-NoProfile", "-NonInteractive", "-EncodedCommand", haxe.crypto.Base64.encode(utf16)]);
		var exitCode = process.exitCode();
		process.close();
		return exitCode == 0;
	}

	private static function powerShell():String
	{
		// HashLink starts a process by its path, without looking through PATH
		var root = Sys.getEnv("SystemRoot");
		var path = root != null ? root + "\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" : null;
		return path != null && sys.FileSystem.exists(path) ? path : "powershell";
	}

	#end

	private function open():Bool
	{
		if (!TrayIcon.isSupported)
		{
			// utest takes a warning as a failure, so the test passes, saying why
			trace("Tray icons are not supported here, so their events were not tested");
			Assert.pass();
			return false;
		}

		trayIcon = new TrayIcon(null, "TrayIconTest");
		return true;
	}

	private function listen(heard:Array<String>):Void
	{
		trayIcon.onMouseDown.add(function(x, y, button) heard.push('down $x,$y ${(button : Int)}'));
		trayIcon.onMouseUp.add(function(x, y, button) heard.push('up $x,$y ${(button : Int)}'));
		trayIcon.onClick.add(function(x, y) heard.push('click $x,$y'));
		trayIcon.onDoubleClick.add(function(x, y, button) heard.push('double click $x,$y ${(button : Int)}'));
		trayIcon.onRightClick.add(function(x, y) heard.push('right click $x,$y'));
	}

	private function event(type:Int, x:Int, y:Int, button:Int):Void
	{
		// The event as native code fills it in, then the handler it calls
		var backend = @:privateAccess Application.current.__backend;
		var info = @:privateAccess backend.trayIconEventInfo;
		info.type = cast type;
		info.id = @:privateAccess trayIcon.__backend.id;
		info.itemID = button;
		info.x = x;
		info.y = y;
		@:privateAccess backend.handleTrayIconEvent();
	}
	#end
}
