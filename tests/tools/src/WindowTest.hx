import lime.tools.Orientation;
import utest.Assert;
import utest.Test;

/**
	`<window />`, from Lime's XML format documentation and the 8.4.0 changelog
	("Added `Window.alwaysOnTop` and transparent window support"). Attributes the page
	doesn't list are held to the types `WindowData.expectedFields` gives them, which the
	tools also use to read `--window-...` options from the command line.
**/
class WindowTest extends Test
{
	private var fixture:Fixture;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		fixture = new Fixture();
	}

	public function teardown():Void
	{
		fixture.dispose();
	}

	// <window width="640" height="480" background="#FFFFFF" fps="30" />
	public function testWindowSetsSizeBackgroundAndFrameRate():Void
	{
		var project = fixture.parse('<project>
			<window width="640" height="480" background="#FFFFFF" fps="30" />
		</project>');

		Assert.equals(640, project.window.width);
		Assert.equals(480, project.window.height);
		Assert.equals(0xFFFFFF, project.window.background);
		Assert.equals(30, project.window.fps);
	}

	public function testBackgroundAcceptsHexadecimalNotation():Void
	{
		var project = fixture.parse('<project>
			<window background="0x336699" />
			<window id="1" background="#00FF00" />
		</project>');

		Assert.equals(0x336699, project.windows[0].background);
		Assert.equals(0x00FF00, project.windows[1].background);
	}

	// <window hardware="true" allow-shaders="true" require-shaders="true" depth-buffer="false" stencil-buffer="false" />
	// <window fullscreen="false" resizable="true" borderless="false" vsync="false" />
	public function testWindowFlagsAreBooleans():Void
	{
		var project = fixture.parse('<project>
			<window hardware="true" allow-shaders="true" require-shaders="true" depth-buffer="false" stencil-buffer="false" />
			<window fullscreen="false" resizable="true" borderless="false" vsync="false" />
		</project>');

		var window = project.window;

		Assert.equals(true, window.hardware);
		Assert.equals(true, window.allowShaders);
		Assert.equals(true, window.requireShaders);
		Assert.equals(false, window.depthBuffer);
		Assert.equals(false, window.stencilBuffer);
		Assert.equals(false, window.fullscreen);
		Assert.equals(true, window.resizable);
		Assert.equals(false, window.borderless);
		Assert.equals(false, window.vsync);
	}

	// "The orientation value expects either “portrait” or “landscape” ... the default is “auto”"
	public function testOrientationAcceptsPortraitLandscapeAndAuto():Void
	{
		var project = fixture.parse('<project>
			<window orientation="portrait" />
			<window id="1" orientation="landscape" />
			<window id="2" orientation="auto" />
		</project>');

		Assert.equals(Orientation.PORTRAIT, project.windows[0].orientation);
		Assert.equals(Orientation.LANDSCAPE, project.windows[1].orientation);
		Assert.equals(Orientation.AUTO, project.windows[2].orientation);
	}

	// "By default, mobile platforms use a window width and height of 0 ... the resolution of the current display."
	public function testPlatformVariantsApplyOnlyToTheirPlatform():Void
	{
		var xml = '<project>
			<window width="1024" height="768" />
			<window width="0" height="0" if="mobile" />
		</project>';

		fixture.target = ANDROID;
		var mobile = fixture.parse(xml);
		Assert.equals(0, mobile.window.width);
		Assert.equals(0, mobile.window.height);

		fixture.target = WINDOWS;
		var desktop = fixture.parse(xml);
		Assert.equals(1024, desktop.window.width);
		Assert.equals(768, desktop.window.height);
	}

	// "There is a special fps="0" value for HTML5"
	public function testHtml5FrameRateVariant():Void
	{
		var xml = '<project>
			<window fps="60" />
			<window fps="0" if="html5" />
		</project>';

		fixture.target = HTML5;
		Assert.equals(0, fixture.parse(xml).window.fps);

		fixture.target = ANDROID;
		Assert.equals(60, fixture.parse(xml).window.fps);
	}

	public function testAlwaysOnTopIsParsed():Void
	{
		var project = fixture.parse('<project>
			<window always-on-top="true" />
			<window id="1" alwaysOnTop="true" />
			<window id="2" always-on-top="false" />
		</project>');

		Assert.equals(true, project.windows[0].alwaysOnTop);
		Assert.equals(true, project.windows[1].alwaysOnTop);
		Assert.equals(false, project.windows[2].alwaysOnTop);
	}

	public function testTransparentIsParsed():Void
	{
		var project = fixture.parse('<project>
			<window transparent="true" />
			<window id="1" transparent="false" />
		</project>');

		Assert.equals(true, project.windows[0].transparent);
		Assert.equals(false, project.windows[1].transparent);
	}

	public function testMoreFlagsAndNumbers():Void
	{
		var project = fixture.parse('<project>
			<window allow-high-dpi="true" color-depth="16" antialiasing="4" hidden="true" maximized="true" minimized="false" />
		</project>');

		var window = project.window;

		Assert.equals(true, window.allowHighDPI);
		Assert.equals(16, window.colorDepth);
		Assert.equals(4, window.antialiasing);
		Assert.equals(true, window.hidden);
		Assert.equals(true, window.maximized);
		Assert.equals(false, window.minimized);
	}

	public function testVsyncAcceptsModes():Void
	{
		var project = fixture.parse('<project>
			<window vsync="true" />
			<window id="1" vsync="adaptive" />
		</project>');

		Assert.equals(true, project.windows[0].vsync);
		Assert.isNull(project.windows[0].vsyncMode);
		Assert.equals(true, project.windows[1].vsync);
		Assert.equals("adaptive", project.windows[1].vsyncMode);
	}

	public function testInvalidNumbersAreIgnored():Void
	{
		var project = fixture.parse('<project>
			<window width="wide" height="480" />
		</project>');

		Assert.isFalse(Reflect.hasField(project.window, "width"));
		Assert.equals(480, project.window.height);
	}

	// WindowData.expectedFields gives x and y as numbers (x: 0.0, y: 0.0)
	@Ignored("Waiting on #2161")
	public function testWindowPositionIsNumeric():Void
	{
		var project = fixture.parse('<project>
			<window x="100" y="50" />
		</project>');

		Assert.equals("100", Std.string(project.window.x));
		Assert.equals("50", Std.string(project.window.y));
	}

	// WindowData.expectedFields gives display as a number (display: 0)
	@Ignored("Waiting on #2161")
	public function testWindowDisplayIsNumeric():Void
	{
		var project = fixture.parse('<project>
			<window display="1" />
		</project>');

		Assert.equals("1", Std.string(project.window.display));
	}

	public function testWindowIdAddsAnotherWindow():Void
	{
		var project = fixture.parse('<project>
			<window title="Main" />
			<window id="1" title="Second" width="320" height="240" />
		</project>');

		Assert.equals(2, project.windows.length);
		Assert.equals("Main", project.windows[0].title);
		Assert.equals("Second", project.windows[1].title);
		Assert.equals(320, project.windows[1].width);
		Assert.isFalse(Reflect.hasField(project.windows[0], "width"));
	}

	// <echo value="Window info: ${window.fps} ${window.allowShaders}" />
	public function testWindowValuesCanBeSubstituted():Void
	{
		var project = fixture.parse('<project>
			<window fps="30" allow-shaders="true" />
			<set name="info" value="Window info: $${window.fps} $${window.allowShaders}" />
		</project>');

		Assert.equals("Window info: 30 true", project.defines.get("info"));
	}

	// "If you define the same value more than once, the last definition will be used."
	public function testLaterWindowAttributesOverrideEarlierOnes():Void
	{
		var project = fixture.parse('<project>
			<window width="640" height="480" />
			<window width="800" />
		</project>');

		Assert.equals(800, project.window.width);
		Assert.equals(480, project.window.height);
	}

	public function testWindowAttributesCanUseSubstitution():Void
	{
		var project = fixture.parse('<project>
			<set name="size" value="512" />
			<window width="$${size}" height="$${size}" />
		</project>');

		Assert.equals(512, project.window.width);
		Assert.equals(512, project.window.height);
	}
}
