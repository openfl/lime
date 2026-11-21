import lime.app.Application;
import lime.system.Clipboard;
import lime.ui.DragData;
import lime.ui.DropAction;
import lime.ui.Menu;
import lime.ui.MenuItem;
import lime.ui.WindowAppearance;

#if (cpp && windows)
@:cppFileCode('
#include <windows.h>
#include <ole2.h>
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
// Drags the clipboard over the window through its OLE drop target, as another application would, and drops it
// when the window accepts. Returns the effect taken, or a negative value when the target is missing.
static int IntegrationDrag (int x, int y, DWORD allowed) {
 HWND window = IntegrationWindow ();
 IDropTarget* target = window ? (IDropTarget*)GetPropW (window, L"OleDropTargetInterface") : NULL;
 IDataObject* data = NULL;
 if (!target) return -1;
 if (FAILED (OleGetClipboard (&data))) return -2;
 POINT client = { x, y }; ClientToScreen (window, &client);
 POINTL point = { client.x, client.y };
 DWORD effect = allowed;
 target->DragEnter (data, MK_LBUTTON, point, &effect);
 effect = allowed;
 target->DragOver (MK_LBUTTON, point, &effect);
 if (effect != DROPEFFECT_NONE) { effect = allowed; target->Drop (data, 0, point, &effect); }
 else target->DragLeave ();
 data->Release ();
 return (int)effect;
}
static bool IntegrationDropTarget () { HWND window = IntegrationWindow (); return window && GetPropW (window, L"OleDropTargetInterface") != NULL; }
static int IntegrationContentSize (bool horizontal) {
 RECT bounds;
 if (!GetClientRect (IntegrationWindow (), &bounds)) return -1;
 return horizontal ? bounds.right - bounds.left : bounds.bottom - bounds.top;
}
')
#end
#if (cpp && windows)
@:buildXml('<target id="haxe"><lib name="ole32.lib" /></target>')
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
			var item = menu.add(new MenuItem("Select"));
			item.onSelect.add(() -> ++selected);
			window.menu = menu;
			checkContentSize();
			#if (cpp && windows)
			// Native rendering is tested by native-desktop. Check Lime's forwarding here.
			window.appearance = WindowAppearance.DARK;
			if (!untyped __cpp__('IntegrationMenuAppearance(true)')) fail("Lime did not forward the dark menu preference");
			window.appearance = WindowAppearance.LIGHT;
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
					checkDragAndDrop();
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

	function checkDragAndDrop():Void
	{
		#if (cpp && windows)
		// Lime built against a native-desktop release without drag and drop
		if (!DragData.isSupported)
		{
			Sys.println("skipped: drag and drop, which this native-desktop does not have");
			return;
		}

		window.dragTarget = true;
		if (!window.dragTarget || !untyped __cpp__('IntegrationDropTarget()')) fail("The window did not become a drop target");

		var accept:DropAction = COPY;
		var allowed:DropAction = COPY | MOVE;
		var log = [];
		var enterText:String = null, dropText:String = null, kept:DragData = null;
		var enterX = 0.0, enterY = 0.0, overX = 0.0;

		window.onDragEnter.add((data, x, y) -> {
			log.push("enter");
			enterText = data.getData(TEXT);
			if (data.allowedActions != allowed) fail("Allowed actions were " + data.allowedActions);
			enterX = x;
			enterY = y;
			kept = data;
			window.dropAction = accept;
		});
		window.onDragOver.add((x, y) -> {
			log.push("over");
			overX = x;
		});
		window.onDragLeave.add(() -> log.push("leave"));
		window.onDrop.add((data, x, y) -> {
			log.push("drop");
			dropText = data.getData(TEXT);
			if (window.dropAction != DropAction.COPY) fail("The drop's action was " + window.dropAction);
		});
		window.onDropStart.add(() -> log.push("dropStart"));
		window.onDropText.add(text -> log.push("dropText " + text));
		window.onDropEnd.add(() -> log.push("dropEnd"));

		Clipboard.text = "lime drag";

		var effect:Int = untyped __cpp__('IntegrationDrag(10, 20, DROPEFFECT_COPY | DROPEFFECT_MOVE)');
		if (effect != 1) fail("An accepted drop took effect " + effect + ", " + log);
		if (log.join(",") != "enter,over,drop,dropStart,dropText lime drag,dropEnd") fail("Accepted drop events were " + log);
		if (enterText != "lime drag" || dropText != "lime drag") fail("The drag's text read " + enterText + " and " + dropText);
		if (kept.getData(TEXT) != null) fail("A drag's data could be read after its event");
		// Twice as far down as across, in the window's own units
		if (enterX <= 0 || Math.abs(enterY - enterX * 2) > 1 || overX != enterX) fail("The drag was at " + enterX + ", " + enterY);

		// Files dropped together reach onDropFile one by one, between onDropStart and onDropEnd
		var files = [Sys.programPath(), haxe.io.Path.directory(Sys.programPath())];
		window.onDropFile.add(file -> log.push("dropFile " + file));
		var dropFiles:Array<String> = null;
		window.onDrop.add((data, x, y) -> dropFiles = data.getData(FILE_LIST));
		Clipboard.setData(FILE_LIST, files);

		log = [];
		allowed = COPY;
		effect = untyped __cpp__('IntegrationDrag(10, 20, DROPEFFECT_COPY)');
		if (effect != 1 || log.join(",") != "enter,over,drop,dropStart,dropFile " + files[0] + ",dropFile " + files[1] + ",dropEnd")
			fail("A file drop took effect " + effect + ", " + log);
		if (dropFiles == null || dropFiles.join("|") != files.join("|")) fail("The dropped files read " + dropFiles);

		Clipboard.text = "lime drag";
		log = [];
		allowed = COPY | MOVE;
		accept = NONE;
		effect = untyped __cpp__('IntegrationDrag(10, 20, DROPEFFECT_COPY | DROPEFFECT_MOVE)');
		if (effect != 0 || log.join(",") != "enter,over,leave") fail("A refused drag took effect " + effect + ", " + log);

		// A drag out needs the left button down
		if (!untyped __cpp__('(GetAsyncKeyState (VK_LBUTTON) & 0x8000) != 0'))
		{
			var data = new DragData();
			data.setData(TEXT, "out");
			var result:Null<DropAction> = null;
			window.startDrag(data, null, 0, 0, COPY).onComplete(action -> result = action);
			if (result != DropAction.NONE) fail("A drag out without a held button gave " + result);
		}

		window.dragTarget = false;
		if (window.dragTarget || untyped __cpp__('IntegrationDropTarget()')) fail("The window stayed a drop target");

		Sys.println("ok: drag and drop forwarding, drop actions, file and text drops, and drop target registration");
		#end
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
