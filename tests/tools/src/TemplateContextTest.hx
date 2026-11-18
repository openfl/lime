import hxp.Path;
import lime.tools.HXProject;
import utest.Assert;
import utest.Test;

/**
	`HXProject.templateContext`, the values a template can use as `::NAME::`. The names are
	the ones Lime's own templates use (templates/html5/template/index.html, the Android
	gradle files, the iOS and macOS Info.plist, templates/haxe/ApplicationMain.hx), and the
	values are what Lime's XML format documentation says each project setting means.
**/
class TemplateContextTest extends Test
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

	// <meta title="My Application" package="com.example.myapplication" version="1.0.0" company="My Company" />
	public function testMetaValuesAreAppVariables():Void
	{
		var context = contextOf('<project>
			<meta title="My Application" package="com.example.myapplication" version="1.0.0" company="My Company" />
			<meta description="A test" build-number="42" company-url="https://example.com" company-id="ABC123" copyright-years="2020-2026" />
		</project>');

		Assert.equals("My Application", context.APP_TITLE);
		Assert.equals("com.example.myapplication", context.APP_PACKAGE);
		Assert.equals("1.0.0", context.APP_VERSION);
		Assert.equals("My Company", context.APP_COMPANY);
		Assert.equals("A test", context.APP_DESCRIPTION);
		Assert.equals("42", context.APP_BUILD_NUMBER);
		Assert.equals("https://example.com", context.APP_COMPANY_URL);
		Assert.equals("ABC123", context.APP_COMPANY_ID);
		Assert.equals("2020-2026", context.APP_COPYRIGHT_YEARS);
	}

	// The Android gradle files read the same values as ::META_PACKAGE_NAME::, ::META_VERSION:: and ::META_BUILD_NUMBER::
	public function testMetaValuesAreMetaVariables():Void
	{
		var context = contextOf('<project>
			<meta title="My Application" package="com.example.myapplication" version="1.0.0" build-number="42" />
		</project>');

		Assert.equals("My Application", context.META_TITLE);
		Assert.equals("com.example.myapplication", context.META_PACKAGE);
		Assert.equals("com.example.myapplication", context.META_PACKAGE_NAME);
		Assert.equals("1.0.0", context.META_VERSION);
		Assert.equals("42", context.META_BUILD_NUMBER);
		Assert.equals("My Application", context.meta.title);
	}

	// <app main="com.example.MyApplication" file="MyApplication" path="Export" preloader="CustomPreloader" />
	public function testAppValues():Void
	{
		var context = contextOf('<project>
			<app main="com.example.MyApplication" file="MyApplication" path="Export" preloader="CustomPreloader" />
		</project>');

		Assert.equals("com.example.MyApplication", context.APP_MAIN);
		Assert.equals("MyApplication", context.APP_FILE);
		Assert.equals("Export", context.APP_PATH);
		Assert.equals("Export", context.BUILD_DIR);
		Assert.equals("CustomPreloader", context.APP_PRELOADER);
		Assert.equals("CustomPreloader", context.PRELOADER_NAME);
	}

	public function testMainClassIsSplitIntoPackageAndClass():Void
	{
		var context = contextOf('<project>
			<app main="com.example.MyApplication" />
		</project>');

		Assert.equals("com.example.", context.APP_MAIN_PACKAGE);
		Assert.equals("MyApplication", context.APP_MAIN_CLASS);

		context = contextOf('<project>
			<app main="Game" />
		</project>');

		Assert.equals("", context.APP_MAIN_PACKAGE);
		Assert.equals("Game", context.APP_MAIN_CLASS);
	}

	// <app swf-version="11" />
	public function testSwfVersion():Void
	{
		var context = contextOf('<project>
			<app swf-version="11.8" />
		</project>');

		Assert.equals(11.8, context.APP_SWF_VERSION);
		Assert.equals(11.8, context.SWF_VERSION);
	}

	// <window width="640" height="480" background="#FFFFFF" fps="30" />
	// <window fullscreen="false" resizable="true" borderless="false" vsync="false" />
	public function testWindowValues():Void
	{
		var context = contextOf('<project>
			<window width="640" height="480" background="#336699" fps="30" />
			<window fullscreen="false" resizable="true" borderless="false" vsync="false" />
			<window hardware="true" allow-high-dpi="true" />
		</project>');

		Assert.equals(640, context.WIN_WIDTH);
		Assert.equals(480, context.WIN_HEIGHT);
		Assert.equals(0x336699, context.WIN_BACKGROUND);
		Assert.equals(30, context.WIN_FPS);
		Assert.equals(false, context.WIN_FULLSCREEN);
		Assert.equals(true, context.WIN_RESIZABLE);
		Assert.equals(false, context.WIN_BORDERLESS);
		Assert.equals(false, context.WIN_VSYNC);
		Assert.equals(true, context.WIN_HARDWARE);
		// templates/air/template/application.xml reads this name
		Assert.equals(true, context.WIN_ALLOW_HIGH_DPI);
	}

	public function testWindowValuesAreAlsoWindowVariables():Void
	{
		var context = contextOf('<project>
			<window width="640" height="480" fps="30" resizable="true" />
		</project>');

		Assert.equals(640, context.WINDOW_WIDTH);
		Assert.equals(480, context.WINDOW_HEIGHT);
		Assert.equals(30, context.WINDOW_FPS);
		Assert.equals(true, context.WINDOW_RESIZABLE);
	}

	// <window orientation="portrait" /> "Accepts portrait or landscape. Defaults to auto"
	public function testOrientationIsWrittenInLowerCase():Void
	{
		var context = contextOf('<project><window orientation="portrait" /></project>');
		Assert.equals("portrait", context.WIN_ORIENTATION);
		Assert.equals("portrait", context.WINDOW_ORIENTATION);

		context = contextOf('<project><window orientation="landscape" /></project>');
		Assert.equals("landscape", context.WIN_ORIENTATION);

		context = contextOf('<project><window orientation="auto" /></project>');
		Assert.equals("auto", context.WIN_ORIENTATION);

		context = contextOf('<project><window width="640" /></project>');
		Assert.equals("auto", context.WIN_ORIENTATION);
	}

	public function testEachWindowHasNumberedVariables():Void
	{
		var context = contextOf('<project>
			<window title="Main" width="800" height="600" />
			<window id="1" title="Second" width="320" height="240" orientation="portrait" />
		</project>');

		Assert.equals(2, context.windows.length);
		Assert.equals("Main", context.WINDOW_TITLE_0);
		Assert.equals(800, context.WINDOW_WIDTH_0);
		Assert.equals("Second", context.WINDOW_TITLE_1);
		Assert.equals(320, context.WINDOW_WIDTH_1);
		Assert.equals(240, context.WINDOW_HEIGHT_1);
		Assert.equals("portrait", context.WINDOW_ORIENTATION_1);

		// The unnumbered names are the first window's
		Assert.equals("Main", context.WIN_TITLE);
		Assert.equals(800, context.WIN_WIDTH);
	}

	// "Values are available in templates as ::SET_CUSTOM_VALUE::, with hyphens converted to underscores"
	// <set name="color" value="red" /> <set name="custom-value" />
	public function testSetValuesAreSetVariables():Void
	{
		var context = contextOf('<project>
			<set name="color" value="red" />
			<set name="custom-value" />
		</project>');

		Assert.equals("red", context.SET_COLOR);
		Assert.equals(true, context.SET_CUSTOM_VALUE);
		Assert.isFalse(Reflect.hasField(context, "SET_NEVER_SET"));
	}

	// <haxedef name="define" />
	public function testHaxedefsAreDefineVariablesAndCompilerFlags():Void
	{
		var context = contextOf('<project>
			<haxedef name="define" />
			<haxedef name="level" value="3" />
		</project>');

		Assert.equals(true, context.DEFINE_DEFINE);
		Assert.equals("3", Std.string(context.DEFINE_LEVEL));

		var flags = flagsOf(context);

		Assert.contains("-D define", flags);
		Assert.contains("-D level=3", flags);
	}

	// <haxeflag name="-dce" value="full" /> <source path="src" />
	public function testHaxeFlagsHoldSourcesAndFlags():Void
	{
		fixture.write("src/Main.hx", "class Main {}");

		var context = contextOf('<project>
			<source path="src" />
			<haxeflag name="-dce" value="full" />
			<haxeflag name="--no-traces" />
		</project>');

		var flags = flagsOf(context);

		Assert.contains("-cp src", flags);
		Assert.contains("-dce full", flags);
		Assert.contains("--no-traces", flags);
	}

	public function testHaxeFlagsDefineTheTargetAndItsType():Void
	{
		fixture.target = ANDROID;

		var flags = flagsOf(contextOf('<project />'));

		Assert.contains("-D android", flags);
		Assert.contains("-D mobile", flags);

		fixture.target = HTML5;
		flags = flagsOf(contextOf('<project />'));

		Assert.contains("-D html5", flags);
		Assert.contains("-D web", flags);
	}

	// <haxelib name="actuate" />
	public function testHaxelibsAreLibVariablesAndClassPaths():Void
	{
		var path = fixture.addHaxelib("my-lib", '<project />');

		var context = contextOf('<project>
			<haxelib name="my-lib" />
		</project>');

		Assert.equals(true, context.LIB_MY_LIB);

		var flags = flagsOf(context);

		Assert.contains("-cp " + path, flags);
		// As -lib does, so Haxe code can test for the library and its version
		Assert.contains("-D my-lib=1.0.0", flags);
	}

	public function testHaxelibClassPathFollowsItsClassPathSetting():Void
	{
		var path = fixture.addHaxelib("with-src", '<project />');
		fixture.write("haxelib/with-src/haxelib.json", '{"name": "with-src", "version": "2.1.0", "classPath": "src"}');

		var flags = flagsOf(contextOf('<project>
			<haxelib name="with-src" />
		</project>'));

		Assert.contains("-cp " + Path.combine(path, "src"), flags);
		Assert.contains("-D with-src=2.1.0", flags);
	}

	// "-debug -- Use debug configuration instead of release", "-final -- Use final configuration instead of release"
	public function testBuildTypeFlags():Void
	{
		var context = contextOf('<project />');

		Assert.equals(true, context.RELEASE);
		Assert.equals(false, context.DEBUG);
		Assert.equals(false, context.FINAL);

		fixture.debug = true;
		context = contextOf('<project />');

		Assert.equals(false, context.RELEASE);
		Assert.equals(true, context.DEBUG);
		Assert.equals(false, context.FINAL);

		fixture.debug = false;
		fixture.targetFlags.set("final", "");
		context = contextOf('<project />');

		Assert.equals(false, context.RELEASE);
		Assert.equals(false, context.DEBUG);
		Assert.equals(true, context.FINAL);
	}

	// <certificate path="to/certificate.crt" password="1234" alias="my-alias" alias-password="4321" />
	public function testCertificateValues():Void
	{
		fixture.write("to/certificate.crt", "certificate");

		var context = contextOf('<project>
			<certificate path="to/certificate.crt" password="1234" alias="my-alias" alias-password="4321" />
		</project>');

		// The gradle and AIR tools are run from other folders, so the path is a full one
		Assert.equals(absolute(Path.combine(fixture.directory, "to/certificate.crt")), absolute(context.KEY_STORE));
		Assert.equals("1234", context.KEY_STORE_PASSWORD);
		Assert.equals("my-alias", context.KEY_STORE_ALIAS);
		Assert.equals("4321", context.KEY_STORE_ALIAS_PASSWORD);
	}

	// "the alias will be set to the file name of your certificate by default, without the extension"
	public function testCertificateAliasDefaultsToTheFileName():Void
	{
		var context = contextOf('<project>
			<certificate path="to/certificate.crt" password="1234" />
		</project>');

		Assert.equals("certificate", context.KEY_STORE_ALIAS);
	}

	// alias-password is the password unless it is given
	public function testCertificateAliasPasswordDefaultsToThePassword():Void
	{
		var context = contextOf('<project>
			<certificate path="to/certificate.crt" password="1234" />
		</project>');

		Assert.equals("1234", context.KEY_STORE_ALIAS_PASSWORD);
	}

	// "Omitting password means you are prompted for the certificate password", so no password is given to the templates
	public function testCertificateWithoutAPasswordHasNone():Void
	{
		var context = contextOf('<project>
			<certificate path="to/certificate.crt" />
		</project>');

		Assert.isFalse(Reflect.hasField(context, "KEY_STORE_PASSWORD"));
		Assert.isFalse(Reflect.hasField(context, "KEY_STORE_ALIAS_PASSWORD"));
	}

	public function testProjectWithoutACertificateHasNoKeyStore():Void
	{
		var context = contextOf('<project />');

		Assert.isFalse(Reflect.hasField(context, "KEY_STORE"));
	}

	// "If an asset is specified as template, it will not be copied/embedded as an ordinary asset"
	public function testAssetsLeaveOutTemplates():Void
	{
		fixture.write("assets/a.png", "png");
		fixture.write("assets/readme.txt", "text");

		var context = contextOf('<project>
			<assets path="assets/a.png" />
			<assets path="assets/readme.txt" type="template" />
		</project>');

		var assets:Array<Dynamic> = context.assets;

		Assert.equals(1, assets.length);
		Assert.equals("assets/a.png", assets[0].targetPath);
		Assert.equals("assets/a.png", assets[0].id);
		// Templates compare the type in lower case: ::if (type == "font")::
		Assert.equals("image", assets[0].type);
	}

	public function testAssetTypesAreInLowerCase():Void
	{
		for (file in ["a.png", "b.ttf", "c.wav", "e.txt", "f.bin"])
		{
			fixture.write("assets/" + file, "x");
		}

		var context = contextOf('<project>
			<assets path="assets" />
		</project>');

		var types = new Map<String, String>();

		for (asset in (context.assets : Array<Dynamic>))
		{
			types.set(asset.targetPath, asset.type);
		}

		Assert.equals("image", types.get("assets/a.png"));
		Assert.equals("font", types.get("assets/b.ttf"));
		Assert.equals("sound", types.get("assets/c.wav"));
		Assert.equals("text", types.get("assets/e.txt"));
		Assert.equals("binary", types.get("assets/f.bin"));
	}

	// <library name="myOtherLibrary" preload="true" /> <assets path="assets/other" library="myOtherLibrary" />
	public function testLibrariesListDeclaredAndUsedLibraries():Void
	{
		fixture.write("assets/a.png", "png");
		fixture.write("assets/b.png", "png");

		var context = contextOf('<project>
			<library name="myOtherLibrary" preload="true" />
			<assets path="assets/a.png" library="myOtherLibrary" />
			<assets path="assets/b.png" library="third" />
		</project>');

		var libraries:Array<Dynamic> = context.libraries;
		var names = [for (library in libraries) library.name];

		Fixture.assertSame(["myOtherLibrary", "third"], names);
		Assert.equals(true, libraries[0].preload);
	}

	// <ndll name="std" haxelib="hxcpp" />
	public function testNdllsHaveANameThatIsSafeInCode():Void
	{
		var context = contextOf('<project>
			<ndll name="my-native-lib" />
		</project>');

		var ndlls:Array<Dynamic> = context.ndlls;

		Assert.equals(1, ndlls.length);
		Assert.equals("my-native-lib", ndlls[0].name);
		Assert.equals("my_native_lib", ndlls[0].nameSafe);
	}

	// <language name="en-US" /> "The list is empty by default."
	public function testLanguages():Void
	{
		var context = contextOf('<project />');

		// Templates test this with ::if (languages != null)::
		Assert.isNull(context.languages);

		context = contextOf('<project>
			<language name="en-US" />
			<language name="fr" />
		</project>');

		Fixture.assertSame(["en-US", "fr"], context.languages);
	}

	// <setenv name="GLOBAL_DEFINE" />
	public function testEnvironmentValuesAreEnvVariables():Void
	{
		var previous = Sys.getEnv("LIME_TOOLS_TEST_VALUE");

		var context = contextOf('<project>
			<setenv name="LIME_TOOLS_TEST_VALUE" value="from-project" />
		</project>');

		Sys.putEnv("LIME_TOOLS_TEST_VALUE", previous == null ? "" : previous);

		Assert.equals("from-project", context.ENV_LIME_TOOLS_TEST_VALUE);
	}

	public function testConfigIsAvailableToTemplates():Void
	{
		var context = contextOf('<project>
			<config:ios deployment="15.0" />
		</project>');

		Assert.equals("15.0", (context.config : lime.tools.ConfigData).getString("ios.deployment"));
	}

	private function absolute(path:String):String
	{
		return Path.standardize(sys.FileSystem.fullPath(path));
	}

	/**
		The template context of a project, made in the project's folder as the tools make it.
	**/
	private function contextOf(xml:String):Dynamic
	{
		var project:HXProject = fixture.parse(xml);
		var cwd = Sys.getCwd();
		Sys.setCwd(fixture.directory);

		var context:Dynamic = null;

		try
		{
			context = project.templateContext;
		}
		catch (e:Dynamic)
		{
			Sys.setCwd(cwd);
			throw e;
		}

		Sys.setCwd(cwd);
		return context;
	}

	/**
		The compiler arguments in a context, one per line as in an HXML file.
	**/
	private function flagsOf(context:Dynamic):Array<String>
	{
		var flags:String = context.HAXE_FLAGS;
		return [for (flag in flags.split("\n")) if (flag != "") flag];
	}
}
