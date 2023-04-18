package lime;

import lime.app.Application;
import lime.ui.Window;
import massive.munit.Assert;

class WindowTest
{
	private var app:Application;

	@BeforeClass public function beforeClass():Void
	{
		app = new Application();
		app.create(null);
	}

	@Test public function createEmptyWindow():Void
	{
		Assert.isNull(app.window);
		Assert.areEqual(0, app.windows.length);

		var window = new Window();

		Assert.isNull(window.renderer);
		Assert.isNull(window.config);
		Assert.isFalse(window.fullscreen);
		Assert.areEqual(0, window.height);
		Assert.areEqual(0, window.width);
		Assert.areEqual(0, window.x);
		Assert.areEqual(0, window.y);

		app.createWindow(window);

		Assert.isNotNull(window.renderer);
		Assert.isNull(window.config);

		#if !html5
		// TODO: standardize the behavior of a 0 x 0 window

		Assert.isFalse(window.fullscreen);
		// Assert.areEqual (0, window.height);
		// Assert.areEqual (0, window.width);
		// Assert.areEqual (0, window.x);
		// Assert.areEqual (0, window.y);
		#end

		window.close();

		Assert.isNull(app.window);
		Assert.areEqual(0, app.windows.length);
	}

	@Test public function createBasicWindow():Void
	{
		Assert.isNull(app.window);
		Assert.areEqual(0, app.windows.length);

		var window = new Window();

		window.width = 400;
		window.height = 300;

		Assert.isNull(window.renderer);
		Assert.isNull(window.config);
		Assert.isFalse(window.fullscreen);
		Assert.areEqual(300, window.height);
		Assert.areEqual(400, window.width);
		Assert.areEqual(0, window.x);
		Assert.areEqual(0, window.y);

		app.createWindow(window);

		Assert.isNotNull(window.renderer);
		Assert.isNull(window.config);
		Assert.isFalse(window.fullscreen);
		Assert.areEqual(300, window.height);
		Assert.areEqual(400, window.width);
		// Assert.areEqual (0, window.x);
		// Assert.areEqual (0, window.y);

		window.close();

		Assert.isNull(app.window);
		Assert.areEqual(0, app.windows.length);
	}

	@Test public function createEmptyWindowFromConfig():Void
	{
		Assert.isNull(app.window);
		Assert.areEqual(0, app.windows.length);

		var config = {};
		var window = new Window(config);

		Assert.isNull(window.renderer);
		Assert.areEqual(config, window.config);
		Assert.isFalse(window.fullscreen);
		Assert.areEqual(0, window.height);
		Assert.areEqual(0, window.width);
		Assert.areEqual(0, window.x);
		Assert.areEqual(0, window.y);

		app.createWindow(window);

		Assert.isNotNull(window.renderer);
		Assert.areEqual(config, window.config);

		#if !html5
		Assert.isFalse(window.fullscreen);
		// Assert.areEqual (0, window.height);
		// Assert.areEqual (0, window.width);
		// Assert.areEqual (0, window.x);
		// Assert.areEqual (0, window.y);
		#end

		window.close();

		Assert.isNull(app.window);
		Assert.areEqual(0, app.windows.length);
	}

	@Test public function createBasicWindowFromConfig():Void
	{
		Assert.isNull(app.window);
		Assert.areEqual(0, app.windows.length);

		var config = {width: 400, height: 300};
		var window = new Window(config);

		Assert.isNull(window.renderer);
		Assert.areEqual(config, window.config);
		Assert.isFalse(window.fullscreen);
		Assert.areEqual(300, window.height);
		Assert.areEqual(400, window.width);
		Assert.areEqual(0, window.x);
		Assert.areEqual(0, window.y);

		app.createWindow(window);

		Assert.isNotNull(window.renderer);
		Assert.areEqual(config, window.config);
		Assert.isFalse(window.fullscreen);
		Assert.areEqual(300, window.height);
		Assert.areEqual(400, window.width);
		// Assert.areEqual (0, window.x);
		// Assert.areEqual (0, window.y);

		window.close();

		Assert.isNull(app.window);
		Assert.areEqual(0, app.windows.length);
	}

	@AfterClass public function afterClass():Void
	{
		app = null;
	}
}
