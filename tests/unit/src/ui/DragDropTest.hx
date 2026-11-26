package ui;

import lime.app.Application;
import lime.app.Future;
import lime.system.ClipboardFormat;
import lime.ui.DragData;
import lime.ui.DropAction;
import lime.ui.Window;
import utest.Assert;
import utest.Async;
import utest.Test;

/**
	`Window.dropTarget`, `onDragEnter`, `onDragOver`, `onDragLeave`, `onDrop`,
	`dropAction` and `doDragDrop`, with `DragData` and `DropAction`.

	On native targets the drag events are handed to the application as
	native-desktop's handler hands them over, and the action the listeners
	chose is read back as the system would read it. On Windows C++, built
	against a native-desktop with drag and drop, a drag is also sent through
	the window's own OLE drop target, as another application would send it.
	On HTML5 the DOM's drag events are dispatched on the page.
**/
@:access(lime.ui.DragData)
class DragDropTest extends Test
{
	#if (lime_cffi && !macro && !mobile)
	private static inline var DRAG_ENTER = 1;
	private static inline var DRAG_OVER = 2;
	private static inline var DRAG_LEAVE = 3;
	private static inline var DRAG_DROP = 4;
	private static inline var DRAG_COMPLETE = 5;

	// SDL numbers windows from 1 as they are created
	private static inline var NO_WINDOW = 0x3FFFFF;

	private var window:Window;
	private var reported:Bool = false;
	#end

	public function new()
	{
		super();
	}

	public function testDropActionsAreFlags():Void
	{
		Assert.equals(0, (DropAction.NONE : Int));
		Assert.equals(1, (DropAction.COPY : Int));
		Assert.equals(2, (DropAction.MOVE : Int));
		Assert.equals(4, (DropAction.LINK : Int));

		var actions:DropAction = DropAction.COPY | DropAction.LINK;
		Assert.equals(5, (actions : Int));
		Assert.equals(DropAction.LINK, actions & DropAction.LINK);
		Assert.equals(DropAction.NONE, actions & DropAction.MOVE);
	}

	public function testMadeDataHoldsWhatIsSet():Void
	{
		var data = new DragData();
		Assert.equals(DropAction.COPY | DropAction.MOVE | DropAction.LINK, data.allowedActions);
		Assert.isFalse(data.hasFormat(TEXT));
		Assert.isNull(data.getData(TEXT));

		Assert.isTrue(data.setData(TEXT, "caf\u00E9 \u6F22"));
		Assert.isTrue(data.setData(URL, "https://lime.openfl.org/"));
		Assert.isTrue(data.setData(FILE_LIST, ["one.txt", "two.txt"]));
		Assert.isFalse(data.setData(HTML, null));

		Assert.isTrue(data.hasFormat(TEXT));
		Assert.isTrue(data.hasFormat(URL));
		Assert.isTrue(data.hasFormat(FILE_LIST));
		Assert.isFalse(data.hasFormat(HTML));
		Assert.equals("caf\u00E9 \u6F22", data.getData(TEXT));
		Assert.equals("https://lime.openfl.org/", data.getData(URL));
		Assert.equals("one.txt|two.txt", (data.getData(FILE_LIST) : Array<String>).join("|"));
	}

	public function testADragsDataCannotBeChanged():Void
	{
		var data = DragData.__fromSystem(DropAction.COPY);
		Assert.equals(DropAction.COPY, data.allowedActions);
		Assert.isFalse(data.setData(TEXT, "changed"));

		// Read after its event, a drag gives nothing
		data.__active = false;
		Assert.isFalse(data.hasFormat(TEXT));
		Assert.isNull(data.getData(TEXT));
	}

	#if (lime_cffi && !macro && !mobile)
	public function teardown():Void
	{
		// A test that failed leaves nothing for the application's own updates to throw
		@:privateAccess lime._internal.backend.native.NativeApplication.deferredException = null;
		@:privateAccess lime._internal.backend.native.NativeApplication.deferredExceptionPending = false;

		if (window == null) return;

		window.onDragEnter.removeAll();
		window.onDragOver.removeAll();
		window.onDragLeave.removeAll();
		window.onDrop.removeAll();
		window.onDropStart.removeAll();
		window.onDropFile.removeAll();
		window.onDropText.removeAll();
		window.onDropEnd.removeAll();
		window.dropTarget = false;
		window.dropAction = NONE;
	}

	public function testADragThatEntersIsAcceptedWithTheChosenAction():Void
	{
		var window = open();
		if (window == null) return;

		window.dropAction = LINK;
		var heard = [];

		window.onDragEnter.add(function(data:DragData, x:Float, y:Float)
		{
			// Each drag starts refused
			heard.push("enter " + x + "," + y + " " + (data.allowedActions : Int) + " " + (window.dropAction : Int));
			window.dropAction = MOVE;
		});

		Assert.equals(DropAction.MOVE, drag(DRAG_ENTER, window.id, 10, 20.5, COPY | MOVE));
		Assert.equals("enter 10,20.5 3 0", heard.join("|"));
		Assert.equals(DropAction.MOVE, window.dropAction);
	}

	public function testOnlyAnActionTheSourceAllowsIsTaken():Void
	{
		var window = open();
		if (window == null) return;

		window.onDragEnter.add(function(data:DragData, x:Float, y:Float) window.dropAction = MOVE);

		Assert.equals(DropAction.NONE, drag(DRAG_ENTER, window.id, 0, 0, COPY | LINK));
	}

	public function testListenersOfOverChangeTheAction():Void
	{
		var window = open();
		if (window == null) return;

		var positions = [];
		window.onDragEnter.add(function(data:DragData, x:Float, y:Float) window.dropAction = COPY);
		window.onDragOver.add(function(x:Float, y:Float)
		{
			positions.push(x + "," + y);
			// Only the left half of the window takes the drop
			window.dropAction = x < 32 ? COPY : NONE;
		});

		Assert.equals(DropAction.COPY, drag(DRAG_ENTER, window.id, 5, 5, COPY));
		Assert.equals(DropAction.COPY, drag(DRAG_OVER, window.id, 6, 7, COPY));
		Assert.equals(DropAction.NONE, drag(DRAG_OVER, window.id, 40, 7, COPY));
		Assert.equals("6,7|40,7", positions.join("|"));
	}

	public function testADragThatLeavesIsReported():Void
	{
		var window = open();
		if (window == null) return;

		var heard = [];
		window.onDragEnter.add(function(data:DragData, x:Float, y:Float) heard.push("enter"));
		window.onDragLeave.add(function() heard.push("leave"));
		window.onDrop.add(function(data:DragData, x:Float, y:Float) heard.push("drop"));

		drag(DRAG_ENTER, window.id, 0, 0, COPY);
		Assert.equals(DropAction.NONE, drag(DRAG_LEAVE, window.id, 0, 0, COPY));
		Assert.equals("enter|leave", heard.join("|"));
	}

	public function testADropIsReportedWithItsDataAndPosition():Void
	{
		var window = open();
		if (window == null) return;

		var heard = [];
		var dropped:DragData = null;
		window.onDragEnter.add(function(data:DragData, x:Float, y:Float) window.dropAction = COPY);
		window.onDrop.add(function(data:DragData, x:Float, y:Float)
		{
			dropped = data;
			heard.push("drop " + x + "," + y + " " + (window.dropAction : Int) + " " + data.__active);
		});
		window.onDropStart.add(function() heard.push("start"));

		drag(DRAG_ENTER, window.id, 1, 2, COPY);
		Assert.equals(DropAction.COPY, drag(DRAG_DROP, window.id, 3, 4, COPY));

		// Nothing native is dragged here, so there are no files or text to drop as well
		Assert.equals("drop 3,4 1 true", heard.join("|"));
		Assert.isFalse(dropped.__active);
	}

	public function testADragOverNoKnownWindowIsRefused():Void
	{
		var window = open();
		if (window == null) return;

		var heard = 0;
		window.onDragEnter.add(function(data:DragData, x:Float, y:Float)
		{
			heard++;
			window.dropAction = COPY;
		});

		Assert.equals(DropAction.NONE, drag(DRAG_ENTER, NO_WINDOW, 0, 0, COPY));
		Assert.equals(0, heard);
	}

	public function testADragOutThatEndsLaterCompletesItsFuture():Void
	{
		var promises = @:privateAccess lime._internal.backend.native.NativeWindow.dragPromises;
		var promise = new lime.app.Promise<DropAction>();
		var id = 0x7FFF0000;
		promises.set(id, promise);

		var result:Null<DropAction> = null;
		promise.future.onComplete(function(action) result = action);

		// macOS and X11 end a drag out with a complete event carrying its ID
		drag(DRAG_COMPLETE, id, 0, 0, NONE, MOVE);

		Assert.equals(DropAction.MOVE, result);
		Assert.isFalse(promises.exists(id));
	}

	// Native code drops what is thrown while the system waits on a drag, so what a listener throws is thrown
	// again from the application's next update, where it reaches the application's handler, the first of
	// them only. The drag is refused, as the listener didn't get to choose its action.

	public function testWhatADragListenerThrowsComesOutOfTheNextUpdate():Void
	{
		var window = open();
		if (window == null) return;

		window.dropAction = COPY;
		window.onDragEnter.add(function(data:DragData, x:Float, y:Float)
		{
			window.dropAction = COPY;
			throw "thrown in onDragEnter";
		});

		var action = dragQuietly(DRAG_ENTER, window.id, 10, 10, COPY | MOVE);
		Assert.equals(DropAction.NONE, action, "the action of a drag whose listener threw");
		Assert.equals("thrown in onDragEnter", Std.string(update()), "what the next update threw");
		Assert.isNull(update(), "the update after that threw too");
	}

	public function testADropWhoseListenerThrowsIsRefused():Void
	{
		var window = open();
		if (window == null) return;

		window.dropAction = COPY;
		window.onDrop.add(function(data:DragData, x:Float, y:Float) throw "thrown in onDrop");

		Assert.equals(DropAction.NONE, dragQuietly(DRAG_DROP, window.id, 10, 10, COPY), "the action of a drop whose listener threw");
		Assert.equals("thrown in onDrop", Std.string(update()), "what the next update threw");
	}

	public function testOnlyTheFirstOfSeveralThrowsComesOut():Void
	{
		var window = open();
		if (window == null) return;

		window.onDragEnter.add(function(data:DragData, x:Float, y:Float) throw "first");
		window.onDragOver.add(function(x:Float, y:Float) throw "second");
		window.onDragLeave.add(function() throw "third");

		dragQuietly(DRAG_ENTER, window.id, 10, 10, COPY);
		dragQuietly(DRAG_OVER, window.id, 11, 11, COPY);
		dragQuietly(DRAG_LEAVE, window.id, 0, 0, COPY);

		Assert.equals("first", Std.string(update()), "what the next update threw");
		Assert.isNull(update(), "the update after that threw too");
	}

	public function testWhatADragOutsFutureListenerThrowsComesOutOfTheNextUpdate():Void
	{
		var promises = @:privateAccess lime._internal.backend.native.NativeWindow.dragPromises;
		var promise = new lime.app.Promise<DropAction>();
		var id = 0x7FFF0001;
		promises.set(id, promise);
		promise.future.onComplete(function(action) throw "thrown when the drag out ended");

		dragQuietly(DRAG_COMPLETE, id, 0, 0, NONE, COPY);

		Assert.equals("thrown when the drag out ended", Std.string(update()), "what the next update threw");
	}

	public function testNothingIsThrownWhenNoListenerThrew():Void
	{
		var window = open();
		if (window == null) return;

		window.onDragEnter.add(function(data:DragData, x:Float, y:Float) window.dropAction = COPY);
		window.onDrop.add(function(data:DragData, x:Float, y:Float) {});

		Assert.equals(DropAction.COPY, dragQuietly(DRAG_ENTER, window.id, 10, 10, COPY));
		Assert.equals(DropAction.COPY, dragQuietly(DRAG_DROP, window.id, 10, 10, COPY));
		Assert.isNull(update(), "an update threw");
	}

	public function testDragsOutNeedDataMadeForThem():Void
	{
		var window = open();
		if (window == null) return;

		Assert.equals(DropAction.NONE, value(window.doDragDrop(null)));
		Assert.equals(DropAction.NONE, value(window.doDragDrop(DragData.__fromSystem(COPY))));
	}

	public function testTheWindowBecomesADropTargetWhereSupported():Void
	{
		var window = open();
		if (window == null) return;

		Assert.isFalse(window.dropTarget);
		window.dropTarget = true;
		Assert.equals(DragData.isSupported, window.dropTarget);
		window.dropTarget = false;
		Assert.isFalse(window.dropTarget);
	}

	#if (cpp && windows)
	/**
		Drags text, then two files, over the window through its OLE drop target,
		as another application would, then a drag the window refuses.

		The tests start before the application registers for native events, so
		this waits for it to run.
	**/
	@:timeout(10000)
	public function testADragThroughTheWindowsDropTargetReachesTheListeners(async:Async):Void
	{
		haxe.Timer.delay(function()
		{
			dragThroughTheWindowsDropTarget();
			async.done();
		}, 100);
	}

	private function dragThroughTheWindowsDropTarget():Void
	{
		var window = open();
		if (window == null) return;

		if (!DragData.isSupported)
		{
			// As on CI until a native-desktop release has drag and drop
			trace("Lime is built against a native-desktop without drag and drop, so OLE drags were not tested");
			Assert.pass();
			return;
		}

		window.dropTarget = true;
		var hwnd = window.nativeHandle.window;
		Assert.isTrue(WindowsDragSource.isTarget(hwnd));

		var heard = [];
		var accept:DropAction = COPY;
		var enterX = 0.0, enterY = 0.0, kept:DragData = null;

		window.onDragEnter.add(function(data:DragData, x:Float, y:Float)
		{
			heard.push("enter " + (data.allowedActions : Int) + " " + data.hasFormat(TEXT) + " " + data.hasFormat(FILE_LIST));
			enterX = x;
			enterY = y;
			kept = data;
			window.dropAction = accept;
		});
		window.onDragOver.add(function(x:Float, y:Float) heard.push("over"));
		window.onDragLeave.add(function() heard.push("leave"));
		window.onDrop.add(function(data:DragData, x:Float, y:Float)
		{
			var files:Array<String> = data.getData(FILE_LIST);
			heard.push("drop " + data.getData(TEXT) + " " + (files == null ? "" : files.join(",")));
		});
		window.onDropStart.add(function() heard.push("start"));
		window.onDropText.add(function(text:String) heard.push("text " + text));
		window.onDropFile.add(function(file:String) heard.push("file " + file));
		window.onDropEnd.add(function() heard.push("end"));

		var text = "Dragged caf\u00E9 \u6F22";
		Assert.equals(1, WindowsDragSource.drag(hwnd, text, null, 10, 20, 3));
		Assert.equals("enter 3 true false|over|drop " + text + " |start|text " + text + "|end", heard.join("|"));
		// Twice as far down as across, in the window's own units
		Assert.isTrue(enterX > 0 && Math.abs(enterY - enterX * 2) < 1, "the drag was at " + enterX + ", " + enterY);
		Assert.isTrue(kept != null && kept.getData(TEXT) == null, "the drag's data was readable after its event");

		heard = [];
		var files = ["C:\\Dragged\\one.txt", "C:\\Dragged\\caf\u00E9.txt"];
		Assert.equals(1, WindowsDragSource.drag(hwnd, null, files, 10, 20, 1));
		Assert.equals("enter 1 false true|over|drop null " + files.join(",") + "|start|file " + files[0] + "|file " + files[1] + "|end", heard.join("|"));

		heard = [];
		accept = NONE;
		Assert.equals(0, WindowsDragSource.drag(hwnd, text, null, 10, 20, 3));
		Assert.equals("enter 3 true false|over|leave", heard.join("|"));

		window.dropTarget = false;
		Assert.isFalse(WindowsDragSource.isTarget(hwnd));
	}
	#end

	private function open():Window
	{
		if (window == null)
		{
			// The application listens to the first window it is given
			if (Application.current.window == null) create();
			window = create();
		}

		if (window == null)
		{
			// Without a display, as on the Linux runners, no window can be created.
			// utest takes a warning as a failure, so the test passes, saying why
			if (!reported) trace("No window can be created here, so drag events were not tested");
			reported = true;
			Assert.pass();
			return null;
		}

		return window;
	}

	private static function create():Window
	{
		// Left open, hidden, as closing the last window of the application ends it
		return Application.current.createWindow({
			width: 64,
			height: 64,
			hidden: true,
			title: "DragDropTest"
		});
	}

	// Hands a drag event to the application as native-desktop's handler does, and returns the action read back
	private static function drag(type:Int, windowID:Int, x:Float, y:Float, allowedActions:DropAction, action:DropAction = NONE):DropAction
	{
		var backend = @:privateAccess Application.current.__backend;
		var info = @:privateAccess backend.dragEventInfo;
		info.type = cast type;
		info.windowID = windowID;
		info.x = x;
		info.y = y;
		info.allowedActions = allowedActions;
		info.action = action;

		@:privateAccess backend.handleDragEvent();
		return info.action;
	}

	/** As drag(), failing where the event throws back into native code, which would drop it **/
	private static function dragQuietly(type:Int, windowID:Int, x:Float, y:Float, allowedActions:DropAction, action:DropAction = NONE):DropAction
	{
		try
		{
			return drag(type, windowID, x, y, allowedActions, action);
		}
		catch (e:Dynamic)
		{
			Assert.fail("the drag event threw " + e + " back to native code");
			return @:privateAccess Application.current.__backend.dragEventInfo.action;
		}
	}

	/** Runs one update of the application, as its loop does, and gives what it threw, or null **/
	private static function update():Dynamic
	{
		var backend = @:privateAccess Application.current.__backend;
		var info = @:privateAccess backend.applicationEventInfo;
		info.type = cast 0;
		info.deltaTime = 0;

		try
		{
			@:privateAccess backend.handleApplicationEvent();
		}
		catch (e:Dynamic)
		{
			return e;
		}

		return null;
	}

	private static function value(future:Future<DropAction>):Null<DropAction>
	{
		var result:Null<DropAction> = null;
		future.onComplete(function(action) result = action);
		return result;
	}
	#end

	#if (js && html5)
	@:timeout(10000)
	public function testDOMDragsReachTheListeners(async:Async):Void
	{
		// The tests start before the application has opened its window
		var timer = new haxe.Timer(10);
		var started = false;
		timer.run = function()
		{
			var window = Application.current.window;
			// A run already queued can come after stop()
			if (started || window == null) return;
			started = true;
			timer.stop();

			var backend = @:privateAccess window.__backend;
			var element:js.html.Element = backend.canvas != null ? cast backend.canvas : cast backend.div;
			var rect = element.getBoundingClientRect();

			var heard = [];
			var accept:DropAction = COPY;
			window.onDragEnter.add(function(data:DragData, x:Float, y:Float)
			{
				heard.push("enter " + (data.allowedActions : Int) + " " + data.getData(URL));
				window.dropAction = accept;
			});
			window.onDragOver.add(function(x:Float, y:Float) heard.push("over"));
			window.onDragLeave.add(function() heard.push("leave"));
			window.onDrop.add(function(data:DragData, x:Float, y:Float) heard.push("drop " + data.getData(TEXT)));
			window.onDropText.add(function(text:String) heard.push("text " + text));

			// Turned off, drags are left to the page as before
			var dispatch = function(type:String, transfer:js.html.DataTransfer):Bool
			{
				return element.dispatchEvent(new js.html.DragEvent(type, {
					dataTransfer: transfer,
					bubbles: true,
					cancelable: true,
					clientX: Std.int(rect.left) + 4,
					clientY: Std.int(rect.top) + 4
				}));
			};

			var transfer = new js.html.DataTransfer();
			transfer.setData("text/plain", "Dragged text");
			transfer.setData("text/uri-list", "# a comment\nhttps://lime.openfl.org/");
			// A page's own DataTransfer allows nothing outside a real drag
			js.lib.Object.defineProperty(transfer, "effectAllowed", {value: "copyLink"});

			dispatch("dragenter", transfer);
			Assert.equals("", heard.join("|"), "drags reached a window that is not a target");

			window.dropTarget = true;
			Assert.isFalse(dispatch("dragenter", transfer), "an accepted drag was not let through");
			// Entering a child of the element is not a second drag
			dispatch("dragenter", transfer);
			dispatch("dragleave", transfer);
			Assert.isFalse(dispatch("dragover", transfer));
			Assert.isFalse(dispatch("drop", transfer));

			heard.push("|");
			accept = NONE;
			Assert.isTrue(dispatch("dragenter", transfer), "a refused drag was let through");
			dispatch("dragleave", transfer);

			window.dropTarget = false;
			window.onDragEnter.removeAll();
			window.onDragOver.removeAll();
			window.onDragLeave.removeAll();
			window.onDrop.removeAll();
			window.onDropText.removeAll();

			Assert.equals("enter 5 https://lime.openfl.org/|over|drop Dragged text|text Dragged text|||enter 5 https://lime.openfl.org/|leave", heard.join("|"));
			async.done();
		};
	}
	#end
}

#if (cpp && windows && lime_cffi && !macro)
@:cppFileCode('#include <windows.h>
#include <ole2.h>
#include <shlobj.h>
#include <string>')
@:buildXml('<target id="haxe"><lib name="ole32.lib" /><lib name="shell32.lib" /></target>')
private class WindowsDragSource
{
	public static function isTarget(hwnd:haxe.Int64):Bool
	{
		var low = haxe.Int64.getLow(hwnd);
		var high = haxe.Int64.getHigh(hwnd);
		return untyped __cpp__('::GetPropW((HWND)(((unsigned long long)(unsigned int){1} << 32) | (unsigned int){0}), L"OleDropTargetInterface") != NULL', low, high);
	}

	/**
		Drags `text` or `files` over the window's OLE drop target at `x`, `y` in
		its client area, drops them if the window accepts, and returns the effect.
	**/
	public static function drag(hwnd:haxe.Int64, text:String, files:Array<String>, x:Int, y:Int, allowed:Int):Int
	{
		var low = haxe.Int64.getLow(hwnd);
		var high = haxe.Int64.getHigh(hwnd);
		var hasText = text != null;
		var hasFiles = files != null;
		if (text == null) text = "";
		if (files == null) files = [];

		return untyped __cpp__('[&]() -> int {
			HWND window = (HWND)(((unsigned long long)(unsigned int){1} << 32) | (unsigned int){0});
			IDropTarget* target = (IDropTarget*)::GetPropW(window, L"OleDropTargetInterface");
			if (!target) return -1;
			IDataObject* data = NULL;
			if (FAILED(SHCreateDataObject(NULL, 0, NULL, NULL, IID_IDataObject, (void**)&data))) return -2;
			auto wide = [](const char* utf8) {
				int count = MultiByteToWideChar(CP_UTF8, 0, utf8, -1, NULL, 0);
				std::wstring result(count, 0);
				MultiByteToWideChar(CP_UTF8, 0, utf8, -1, &result[0], count);
				return result;
			};
			auto put = [&](CLIPFORMAT format, const void* bytes, size_t size, size_t header) {
				HGLOBAL memory = GlobalAlloc(GHND, header + size);
				char* target = (char*)GlobalLock(memory);
				if (header) { DROPFILES* drop = (DROPFILES*)target; drop->pFiles = (DWORD)header; drop->fWide = TRUE; }
				memcpy(target + header, bytes, size);
				GlobalUnlock(memory);
				FORMATETC etc = { format, NULL, DVASPECT_CONTENT, -1, TYMED_HGLOBAL };
				STGMEDIUM medium = {}; medium.tymed = TYMED_HGLOBAL; medium.hGlobal = memory;
				data->SetData(&etc, &medium, TRUE);
			};
			if ({4}) {
				std::wstring value = wide({2}.utf8_str());
				put(CF_UNICODETEXT, value.c_str(), value.size() * sizeof(wchar_t), 0);
			}
			if ({5}) {
				// The paths, each ending in a null character, and a null character after the last
				std::wstring list;
				for (int i = 0; i < {3}->length; i++) { std::wstring file = wide({3}->__get(i).utf8_str()); list.append(file.c_str(), file.size()); }
				list.push_back(0);
				put(CF_HDROP, list.data(), list.size() * sizeof(wchar_t), sizeof(DROPFILES));
			}
			POINT client = { {6}, {7} };
			::ClientToScreen(window, &client);
			POINTL point = { client.x, client.y };
			DWORD effect = (DWORD){8};
			target->DragEnter(data, MK_LBUTTON, point, &effect);
			effect = (DWORD){8};
			target->DragOver(MK_LBUTTON, point, &effect);
			if (effect != DROPEFFECT_NONE) { effect = (DWORD){8}; target->Drop(data, 0, point, &effect); }
			else target->DragLeave();
			data->Release();
			return (int)effect;
		}()', low, high, text, files, hasText, hasFiles, x, y, allowed);
	}
}
#end
