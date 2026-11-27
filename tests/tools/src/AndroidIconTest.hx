import hxp.Log;
import lime.tools.Icon;
import lime.tools.IconHelper;
import sys.FileSystem;
import sys.io.File;
import utest.Assert;
import utest.Test;

/**
	Android adaptive icons (#1114). A layer is an `<icon path="" adaptive="foreground" />`, or
	`background` or `monochrome`, and `<config:android adaptive-icon-background="#RRGGBB" />` is a
	background color (`#RGB`, `#RRGGBB` or `#AARRGGBB`). With either, `res/drawable-anydpi-v26/icon.xml`
	is an `<adaptive-icon>` (https://developer.android.com/develop/ui/views/launch/icon_design_adaptive)
	under the name of the icon for older Android, `@drawable/icon`, which Android 8 and later take it
	over. Its background is `@drawable/icon_background` with a background layer, and otherwise
	`@color/icon_background` from `res/values/icon_background.xml`, white unless a color is given. Its
	foreground is `@drawable/icon_foreground`, and a monochrome layer is there only when given. A layer
	is never the application's icon. Without any of it, nothing more is written.

	The update step writes the adaptive icon once it has drawn the application's icons, which takes
	Lime's native library, which these tests don't load, so they call it themselves after the update.
**/
class AndroidIconTest extends Test
{
	private static inline var RES = "bin/app/src/main/res";
	private static inline var ADAPTIVE = RES + "/drawable-anydpi-v26/icon.xml";
	private static inline var COLOR = RES + "/values/icon_background.xml";

	private var fixture:Fixture;
	private var output:PlatformFixture;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		fixture = new Fixture();
		fixture.target = ANDROID;
		fixture.write("Main.hx", "class Main {}");

		for (name in ["icon.png", "foreground.png", "background.png", "monochrome.png", "odd.png"])
		{
			fixture.write(name, "");
		}

		output = new PlatformFixture(fixture);
	}

	public function teardown():Void
	{
		fixture.dispose();
	}

	// Parsing

	public function testEachLayerIsParsed():Void
	{
		var project = fixture.parse('<project>
			<icon path="icon.png" />
			<icon path="foreground.png" adaptive="foreground" />
			<icon path="background.png" adaptive="background" />
			<icon path="monochrome.png" adaptive="monochrome" />
		</project>');

		Assert.equals("null,foreground,background,monochrome", [for (icon in project.icons) Std.string(icon.adaptive)].join(","));
	}

	public function testAnIconOfAnUnknownLayerIsLeftOut():Void
	{
		// It is warned about, and not taken for the application's icon, which it wasn't meant to be
		var mute = Log.mute;
		Log.mute = true;
		var project = fixture.parse('<project>
			<icon path="icon.png" />
			<icon path="odd.png" adaptive="middle" />
		</project>');
		Log.mute = mute;

		Assert.equals(1, project.icons.length);
		if (project.icons.length > 0) Assert.isTrue(StringTools.endsWith(project.icons[0].path, "icon.png"), project.icons[0].path);
	}

	public function testALayerIsNotTheApplicationsIcon():Void
	{
		var layer = new Icon("foreground.png", 108);
		layer.adaptive = "foreground";
		var icon = new Icon("icon.png", 48);

		Assert.isFalse(IconHelper.hasIcons([layer]), "layers alone are taken for an icon");
		Assert.isTrue(IconHelper.hasIcons([layer, icon]));
		Assert.isNull(IconHelper.findMatch([layer, icon], 108, 108), "a layer of the size asked for was found");
		Assert.equals(icon, IconHelper.findNearestMatch([layer, icon], 108, 108), "the nearest icon to a layer's size");
		Assert.isNull(IconHelper.findNearestMatch([layer], 108, 108), "a layer was found as the nearest icon");
	}

	// Output

	public function testWithoutAdaptiveSettingsNothingMoreIsWritten():Void
	{
		update('<project>
			<meta package="com.example.app" />
			<icon path="icon.png" />
		</project>');

		Assert.isFalse(output.exists(ADAPTIVE), ADAPTIVE + " was written");
		Assert.isFalse(output.exists(COLOR), COLOR + " was written");
	}

	public function testABackgroundColorIsTheBackground():Void
	{
		update('<project>
			<meta package="com.example.app" />
			<icon path="icon.png" />
			<config:android adaptive-icon-background="#3DDC84" />
		</project>');

		Assert.equals("background @color/icon_background|foreground @drawable/icon_foreground", layers());
		Assert.equals("#3DDC84", color());
	}

	public function testColorsMayHaveThreeSixOrEightDigits():Void
	{
		for (value in ["#3D8", "#3ddc84", "#803DDC84"])
		{
			update('<project>
				<meta package="com.example.app" />
				<icon path="icon.png" />
				<config:android adaptive-icon-background="$value" />
			</project>');

			Assert.equals(value, color(), value);
		}
	}

	public function testAColorThatIsNotOneIsNotWritten():Void
	{
		update('<project>
			<meta package="com.example.app" />
			<icon path="icon.png" />
			<config:android adaptive-icon-background="green" />
		</project>');

		var written = output.exists(COLOR) ? color() : null;
		Assert.notEquals("green", written, "the color written");
		if (output.exists(ADAPTIVE)) Assert.equals("#FFFFFF", written, "the background of an adaptive icon without a color");
	}

	public function testAForegroundLayerAloneHasAWhiteBackground():Void
	{
		update('<project>
			<meta package="com.example.app" />
			<icon path="icon.png" />
			<icon path="foreground.png" adaptive="foreground" />
		</project>');

		Assert.equals("background @color/icon_background|foreground @drawable/icon_foreground", layers());
		Assert.equals("#FFFFFF", color());
	}

	public function testABackgroundLayerIsTheBackground():Void
	{
		update('<project>
			<meta package="com.example.app" />
			<icon path="icon.png" />
			<icon path="background.png" adaptive="background" />
			<config:android adaptive-icon-background="#3DDC84" />
		</project>');

		Assert.equals("background @drawable/icon_background|foreground @drawable/icon_foreground", layers());
		Assert.isFalse(output.exists(COLOR), "a color was written for a background drawn as a layer");
	}

	public function testAMonochromeLayerIsWritten():Void
	{
		update('<project>
			<meta package="com.example.app" />
			<icon path="icon.png" />
			<icon path="monochrome.png" adaptive="monochrome" />
		</project>');

		Assert.equals("background @color/icon_background|foreground @drawable/icon_foreground|monochrome @drawable/icon_monochrome", layers());
	}

	/** Updates the project, then writes its adaptive icon as the update step does once it has drawn the icons **/
	private function update(xml:String):Void
	{
		output.update(xml);

		// What an update before wrote, as the same project folder is updated again
		for (file in [ADAPTIVE, COLOR])
		{
			if (output.exists(file)) FileSystem.deleteFile(output.path(file));
		}

		var mute = Log.mute;
		Log.mute = true;
		var platform:AndroidPlatform = cast output.platform;
		@:privateAccess platform.createAdaptiveIcon(output.project.icons, output.path(RES));
		Log.mute = mute;
	}

	/** Each layer of the adaptive icon and its drawable, read as strict XML **/
	private function layers():String
	{
		if (!output.exists(ADAPTIVE)) return "no " + ADAPTIVE;

		var root = PlatformFixture.xml(output.read(ADAPTIVE)).firstElement();
		Assert.equals("adaptive-icon", root.nodeName);
		Assert.equals("http://schemas.android.com/apk/res/android", root.get("xmlns:android"));

		return [for (layer in root.elements()) layer.nodeName + " " + layer.get("android:drawable")].join("|");
	}

	/** The color named icon_background **/
	private function color():String
	{
		if (!output.exists(COLOR)) return null;

		for (color in PlatformFixture.xml(output.read(COLOR)).firstElement().elementsNamed("color"))
		{
			if (color.get("name") == "icon_background") return StringTools.trim(color.firstChild().nodeValue);
		}

		return null;
	}
}
