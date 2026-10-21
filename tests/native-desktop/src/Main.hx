import lime.app.Application;
import lime.ui.Menu;
import lime.ui.MenuItem;
import lime.ui.WindowAppearance;

#if (cpp && windows)
@:cppFileCode('
#include <windows.h>
static HWND IntegrationWindow () {
 HWND result = NULL;
 EnumThreadWindows (GetCurrentThreadId (), [](HWND window, LPARAM data) -> BOOL {
  wchar_t title[80]; GetWindowTextW (window, title, 80);
  if (wcscmp (title, L"LimeDesktopIntegration") == 0) { *(HWND*)data = window; return FALSE; }
  return TRUE;
 }, (LPARAM)&result);
 return result;
}
static bool IntegrationMenuAppearance (bool dark) {
 HWND window = IntegrationWindow ();
 HMENU menu = window ? GetMenu (window) : NULL;
 MENUITEMINFOW item = {}; item.cbSize = sizeof(item); item.fMask = MIIM_FTYPE;
 if (!menu || !GetMenuItemInfoW (menu, 0, TRUE, &item)) return false;
 HIGHCONTRASTW contrast = {}; contrast.cbSize = sizeof(contrast);
 bool highContrast = SystemParametersInfoW (SPI_GETHIGHCONTRAST, sizeof(contrast), &contrast, 0) && (contrast.dwFlags & HCF_HIGHCONTRASTON);
 return ((item.fType & MFT_OWNERDRAW) != 0) == (dark && !highContrast);
}
static int IntegrationContentSize (bool horizontal) {
 RECT bounds;
 if (!GetClientRect (IntegrationWindow (), &bounds)) return -1;
 return horizontal ? bounds.right - bounds.left : bounds.bottom - bounds.top;
}
')
#end
class Main extends Application
{
	var selected = 0;
	var frames = 0;
	var phase = 0;
	var command = 0;
	var contentWidth = 0;
	var contentHeight = 0;

	public function new()
	{
		super();
		onCreateWindow.add(window -> {
			captureContentSize();
			var menu = new Menu();
			var item = menu.addItem(new MenuItem("Select"));
			item.onSelect.add(() -> ++selected);
			window.menu = menu;
			checkContentSize();
			#if (cpp && windows)
			// Native rendering is tested by native-desktop. Check Lime's forwarding here.
			window.appearance = WindowAppearance.Dark;
			if (!untyped __cpp__('IntegrationMenuAppearance(true)')) fail("Lime did not forward the dark menu preference");
			window.appearance = WindowAppearance.Light;
			if (!untyped __cpp__('IntegrationMenuAppearance(false)')) fail("Lime did not forward the light menu preference");
			#end
		});
		onUpdate.add(_ -> {
			#if (cpp && windows)
			if (phase == 0)
			{
				phase = 1;
				command = untyped __cpp__('([]() { HWND window = IntegrationWindow(); HMENU menu = window ? GetMenu(window) : NULL; return menu ? (int)GetMenuItemID(menu, 0) : 0; })()');
				if (command <= 0) fail("Native menu was not installed");
				sendSelection();
			}
			else
			{
				frames++;
				if (selected > 1) fail("Native selection was delivered more than once");
				if (phase == 1 && frames >= 3 && selected == 1)
				{
					captureContentSize();
					window.menu = null;
					checkContentSize();
					if (untyped __cpp__('GetMenu(IntegrationWindow()) != NULL')) fail("Lime did not detach its native menu");
					phase = 2;
					frames = 0;
					sendSelection();
				}
				else if (phase == 2 && frames >= 3)
				{
					checkContentSize();
					Sys.println("ok: SDL menu routing, appearance forwarding, content size and detachment");
					Sys.exit(0);
				}
				if (frames >= 30) fail("Native selection did not reach Lime");
			}
			#else
			Sys.println("Native command integration fixture requires Windows C++");
			Sys.exit(0);
			#end
		});
	}

	function captureContentSize():Void
	{
		#if (cpp && windows)
		contentWidth = untyped __cpp__('IntegrationContentSize(true)');
		contentHeight = untyped __cpp__('IntegrationContentSize(false)');
		#end
	}

	function checkContentSize():Void
	{
		#if (cpp && windows)
		var width:Int = untyped __cpp__('IntegrationContentSize(true)');
		var height:Int = untyped __cpp__('IntegrationContentSize(false)');
		if (width != contentWidth || height != contentHeight)
			fail("Changing the menu resized Lime's client area from " + contentWidth + "x" + contentHeight + " to " + width + "x" + height);
		#end
	}

	function sendSelection():Void
	{
		#if (cpp && windows)
		untyped __cpp__('SendMessageW(IntegrationWindow(), WM_COMMAND, MAKEWPARAM({0}, 0), 0)', command);
		#end
	}

	static function fail(message:String):Void
	{
		Sys.println("FAIL: " + message);
		Sys.exit(1);
	}
}
