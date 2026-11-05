package ui;

import lime.app.Application;
import lime.ui.WebView;
import lime.ui.Window;
import utest.Assert;
import utest.Test;

/**
	These drive the system's real engine, so they need it installed. Views made
	without a window are never shown, and windows are hidden.
**/
class WebViewTest extends Test
{
	private var view:WebView;

	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro)
	public function setup():Void
	{
		view = WebView.isSupported ? new WebView() : null;
	}

	public function teardown():Void
	{
		if (view != null)
		{
			view.close();
			view = null;
		}
	}

	public function testALoadedPageHasItsTitle():Void
	{
		if (!canRun()) return;

		var loaded = false;
		view.onLoad.add(function() loaded = true);
		view.loadHTML("<!doctype html><html><head><title>Lime test</title></head><body>hello</body></html>");

		Assert.isTrue(pumpUntil(function() return loaded), "onLoad was not dispatched");
		Assert.isTrue(pumpUntil(function() return view.title == "Lime test"), 'title is "${view.title}"');
	}

	public function testThePageAndTheApplicationTalkBothWays():Void
	{
		if (!canRun()) return;

		var messages:Array<String> = [];
		view.onMessage.add(function(message)
		{
			messages.push(message);
			if (message == "ready") view.postMessage("ping é \"quoted\"");
		});

		view.loadHTML("<!doctype html><html><body><script>
			window.chrome.webview.addEventListener('message', function (event) {
				window.chrome.webview.postMessage('echo:' + event.data);
			});
			window.chrome.webview.postMessage('ready');
		</script></body></html>");

		Assert.isTrue(pumpUntil(function() return messages.length >= 2), 'expected two messages, got $messages');
		Assert.equals("ready", messages[0]);
		Assert.equals("echo:ping é \"quoted\"", messages[1]);
	}

	public function testScriptsRunInThePage():Void
	{
		if (!canRun()) return;

		var messages:Array<String> = [];
		view.onMessage.add(messages.push);
		view.addInitScript("window.fromInit = 'init';");

		var loaded = false;
		view.onLoad.add(function() loaded = true);
		view.loadHTML("<!doctype html><html><body></body></html>");

		Assert.isTrue(pumpUntil(function() return loaded), "onLoad was not dispatched");
		view.evaluateJavaScript("window.chrome.webview.postMessage(window.fromInit + ':ran');");
		Assert.isTrue(pumpUntil(function() return messages.length > 0), "the script did not report");
		Assert.equals("init:ran", messages[0]);
	}

	public function testCancelingANavigationStopsIt():Void
	{
		if (!canRun()) return;

		var loaded = false;
		view.onLoad.add(function() loaded = true);
		view.loadHTML("<!doctype html><html><head><title>Stays</title></head><body></body></html>");
		Assert.isTrue(pumpUntil(function() return loaded), "the first page did not load");

		var asked:Array<String> = [];
		var changed:Array<String> = [];
		var errors:Array<String> = [];
		view.onError.add(errors.push);
		view.onURLChange.add(changed.push);
		view.onNavigate.add(function(url)
		{
			asked.push(url);
			view.onNavigate.cancel();
		});

		view.load("https://example.invalid/never");

		Assert.isTrue(pumpUntil(function() return asked.length > 0), "onNavigate was not dispatched");
		Assert.equals("https://example.invalid/never", asked[0]);
		pumpFor(0.5);
		Assert.equals(0, changed.length);
		Assert.equals(0, errors.length, Std.string(errors));
		Assert.equals("Stays", view.title);
	}

	public function testAViewCanCloseFromItsOwnListener():Void
	{
		if (!canRun()) return;

		var closing = view;
		var asked = 0;
		closing.onNavigate.add(function(_)
		{
			asked++;
			closing.close();
		});

		closing.loadHTML("<!doctype html><html><body></body></html>");
		Assert.isTrue(pumpUntil(function() return asked > 0), "onNavigate was not dispatched");
		pumpFor(0.2);

		// What is asked of a closed view does nothing
		closing.load("about:blank");
		Assert.equals(null, closing.url);
	}

	public function testAPageCanBeSavedAsAPDF():Void
	{
		if (!canRun()) return;

		var path = haxe.io.Path.join([Sys.getCwd(), "web-view-test.pdf"]);
		if (sys.FileSystem.exists(path)) sys.FileSystem.deleteFile(path);

		var loaded = false;
		view.onLoad.add(function() loaded = true);
		view.loadHTML("<!doctype html><html><body><h1>Report</h1></body></html>");
		Assert.isTrue(pumpUntil(function() return loaded), "onLoad was not dispatched");

		var saved:String = null;
		var failed:String = null;
		view.printToPDF(path).onComplete(function(value) saved = value).onError(function(error) failed = Std.string(error));

		Assert.isTrue(pumpUntil(function() return saved != null || failed != null), "printToPDF did not report back");
		Assert.equals(null, failed);
		Assert.equals(path, saved);

		if (sys.FileSystem.exists(path))
		{
			Assert.equals("%PDF", sys.io.File.getBytes(path).getString(0, 4));
			sys.FileSystem.deleteFile(path);
		}
	}

	public function testAPDFInAFolderThatIsNotThereFails():Void
	{
		if (!canRun()) return;

		var loaded = false;
		view.onLoad.add(function() loaded = true);
		view.loadHTML("<!doctype html><html><body></body></html>");
		Assert.isTrue(pumpUntil(function() return loaded), "onLoad was not dispatched");

		var saved = false;
		var failed = false;
		view.printToPDF(haxe.io.Path.join([Sys.getCwd(), "no-such-folder", "report.pdf"])).onComplete(function(_) saved = true).onError(function(_) failed = true);

		Assert.isTrue(pumpUntil(function() return saved || failed), "printToPDF did not report back");
		Assert.isTrue(failed);
	}

	public function testAViewSitsInItsWindowAndClosesWithIt():Void
	{
		if (!canRun()) return;

		var window = create();
		var other = create();
		if (window == null || other == null)
		{
			trace("No window can be created here, so a view in one was not tested");
			Assert.pass();
			return;
		}

		var inWindow = new WebView(window, {x: 2, y: 3, width: 40, height: 30});
		Assert.equals(window, inWindow.window);
		Assert.equals(2, inWindow.x);
		Assert.equals(3, inWindow.y);
		Assert.equals(40, inWindow.width);
		Assert.equals(30, inWindow.height);

		var loaded = false;
		inWindow.onLoad.add(function() loaded = true);
		inWindow.loadHTML("<!doctype html><html><head><title>In a window</title></head><body></body></html>");
		Assert.isTrue(pumpUntil(function() return loaded), "onLoad was not dispatched");

		inWindow.x = 5;
		inWindow.width = 50;
		Assert.equals(5, inWindow.x);
		Assert.equals(50, inWindow.width);
		inWindow.visible = false;
		Assert.isFalse(inWindow.visible);
		inWindow.visible = true;

		window.close();
		pumpFor(0.1);
		Assert.equals(null, inWindow.title);
	}

	private static function canRun():Bool
	{
		if (WebView.isSupported) return true;

		// utest takes a warning as a failure, so the test passes, saying why
		trace("No web engine here, so views were not tested");
		Assert.pass();
		return false;
	}

	private static function create():Window
	{
		// As in WindowTest: closing the last window of the application ends it
		return Application.current.createWindow({
			width: 64,
			height: 64,
			hidden: true,
			title: "WebViewTest"
		});
	}

	private static function pump():Void
	{
		// The application's loop does not run yet, so this does what it would
		@:privateAccess lime._internal.backend.native.NativeCFFI.lime_web_view_process_events();
		var update = @:privateAccess lime._internal.backend.native.NativeApplication.__updateWebViews;
		if (update != null) update();
		Sys.sleep(0.005);
	}

	private static function pumpFor(seconds:Float):Void
	{
		var end = Sys.time() + seconds;
		while (Sys.time() < end) pump();
	}

	private static function pumpUntil(condition:Void->Bool, seconds:Float = 20):Bool
	{
		var end = Sys.time() + seconds;

		while (Sys.time() < end)
		{
			pump();
			if (condition()) return true;
		}

		return condition();
	}
	#end
}
