import sys.FileSystem;
import utest.Assert;
import utest.Test;

/**
	What `lime update html5` writes: index.html from templates/html5/template, the HXML
	files, ApplicationMain.hx and ManifestResources.hx, and the copied assets. The settings
	come from Lime's XML format documentation (meta, app, window, assets, library,
	dependency, template and `<config:html5 />`), and each file is held to the format its
	reader needs: the browser for index.html, the Haxe compiler for the generated code, and
	Lime's `AssetManifest.parse()` for the manifest.
**/
class HTML5OutputTest extends Test
{
	private var fixture:Fixture;
	private var output:PlatformFixture;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		fixture = new Fixture();
		fixture.target = HTML5;
		fixture.write("Main.hx", "class Main {}");

		output = new PlatformFixture(fixture);
	}

	public function teardown():Void
	{
		fixture.dispose();
	}

	// <app main="com.example.MyApplication" file="MyApplication" path="Export" />
	public function testOutputGoesToTheHtml5FolderOfTheAppPath():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" path="Export" />
		</project>');

		Assert.equals("Export/html5", output.platform.targetDirectory);
		Assert.isTrue(output.exists("bin/index.html"));
		Assert.isTrue(output.exists("haxe/ApplicationMain.hx"));
		Assert.isTrue(output.exists("haxe/ManifestResources.hx"));
		Assert.isTrue(output.exists("haxe/debug.hxml"));
		Assert.isTrue(output.exists("haxe/release.hxml"));
		Assert.isTrue(output.exists("haxe/final.hxml"));
	}

	// <config:html5 output-directory="..." /> names the folder inside the app path
	public function testOutputDirectoryCanBeConfigured():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" path="Export" />
			<config:html5 output-directory="web" />
		</project>');

		Assert.equals("Export/web", output.platform.targetDirectory);
		Assert.isTrue(output.exists("bin/index.html"));
	}

	public function testThePageTitleIsTheMetaTitle():Void
	{
		output.update('<project>
			<meta title="My Application" />
			<app main="Main" file="MyApplication" />
		</project>');

		Assert.equals("My Application", titleOf(output.read("bin/index.html")));
	}

	// Text in an HTML page: "&" starts a character reference, so "&micro" would be shown as a micro sign
	public function testThePageTitleIsEscaped():Void
	{
		output.update('<project>
			<meta title="Camera&amp;microphone &lt;demo&gt;" />
			<app main="Main" file="MyApplication" />
		</project>');

		var title = titleOf(output.read("bin/index.html"));

		Assert.isFalse(~/&(?!amp;|lt;|gt;|quot;|#)/.match(title), "the title has a bare \"&\": " + title);
		Assert.equals("Camera&microphone <demo>", StringTools.htmlUnescape(title));
	}

	// <window width="640" height="480" />
	public function testThePageEmbedsTheAppAtTheWindowSize():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<window width="640" height="480" />
		</project>');

		var html = output.read("bin/index.html");

		Assert.isTrue(html.indexOf('<script type="text/javascript" src="./MyApplication.js"></script>') > -1);
		Assert.isTrue(~/lime\.embed \("MyApplication", "content", 640, 480\);/.match(html));
		Assert.isTrue(html.indexOf('<div id="content"></div>') > -1);
	}

	// Without a size the application fills the page, which the embed call takes as 0 by 0
	public function testThePageEmbedsTheAppAtNoFixedSizeByDefault():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
		</project>');

		Assert.isTrue(~/lime\.embed \("MyApplication", "content", 0, 0\);/.match(output.read("bin/index.html")));
	}

	// <dependency path="..." /> names a script the page needs, kept in the "lib" folder
	public function testAScriptDependencyIsCopiedAndLinked():Void
	{
		fixture.write("scripts/extra.js", "var extra = 1;");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<dependency path="scripts/extra.js" />
		</project>');

		Assert.isTrue(output.exists("bin/lib/extra.js"));
		Assert.equals("var extra = 1;", output.read("bin/lib/extra.js"));
		Fixture.assertSame(["./lib/extra.js", "./MyApplication.js"], scriptsOf(output.read("bin/index.html")));
	}

	// <config:html5 dependency-path="lib" />
	public function testDependencyPathNamesTheScriptFolder():Void
	{
		fixture.write("scripts/extra.js", "var extra = 1;");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:html5 dependency-path="js/vendor" />
			<dependency path="scripts/extra.js" />
		</project>');

		Assert.isTrue(output.exists("bin/js/vendor/extra.js"));
		Assert.isFalse(output.exists("bin/lib/extra.js"));
		Fixture.assertSame(["./js/vendor/extra.js", "./MyApplication.js"], scriptsOf(output.read("bin/index.html")));
	}

	public function testADependencyNamedAsAScriptIsLinkedByName():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<dependency name="https://cdn.example.com/library.min.js" />
		</project>');

		Fixture.assertSame(["https://cdn.example.com/library.min.js", "./MyApplication.js"], scriptsOf(output.read("bin/index.html")));
	}

	// An embedded script is written into the application's own file, so the page has no tag for it
	public function testAnEmbeddedDependencyIsNotLinked():Void
	{
		fixture.write("scripts/extra.js", "var extra = 1;");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<dependency path="scripts/extra.js" embed="true" />
		</project>');

		Fixture.assertSame(["./MyApplication.js"], scriptsOf(output.read("bin/index.html")));
		Assert.isFalse(output.exists("bin/lib/extra.js"));
	}

	// "The target path will mirror the source path by default"
	public function testAssetsAreCopiedToTheirTargetPaths():Void
	{
		fixture.write("assets/data/level.txt", "level one");
		fixture.write("assets/images/logo.png", "png bytes");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<assets path="assets/data" rename="data" />
			<assets path="assets/images/logo.png" />
		</project>');

		Assert.equals("level one", output.read("bin/data/level.txt"));
		Assert.equals("png bytes", output.read("bin/assets/images/logo.png"));
	}

	public function testTheManifestListsEveryAsset():Void
	{
		fixture.write("assets/data/level.txt", "level one");
		fixture.write("assets/images/logo.png", "png bytes");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<assets path="assets/data" rename="data" />
			<assets path="assets/images/logo.png" id="logo" />
		</project>');

		var manifest = PlatformFixture.embeddedManifest(output.read("haxe/ManifestResources.hx"));

		Assert.notNull(manifest);
		if (manifest == null) return;

		var level = entry(manifest.assets, "data/level.txt");
		var logo = entry(manifest.assets, "logo");

		Assert.equals(2, manifest.assets.length);
		Assert.equals("data/level.txt", level.path);
		Assert.equals("TEXT", level.type);
		Assert.equals(9, level.size);
		Assert.equals("assets/images/logo.png", logo.path);
		Assert.equals("IMAGE", logo.type);
	}

	public function testAssetNamesWithSpecialCharactersSurviveTheManifest():Void
	{
		var name = "it's 100% & more+ (final) #1.txt";
		fixture.write("assets/" + name, "x");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<assets path="assets" />
		</project>');

		Assert.isTrue(output.exists("bin/assets/" + name));

		var manifest = PlatformFixture.embeddedManifest(output.read("haxe/ManifestResources.hx"));

		Assert.notNull(manifest);
		if (manifest == null) return;

		Assert.equals("assets/" + name, entry(manifest.assets, "assets/" + name).path);
	}

	// "All assets go into the default library unless you specify otherwise", and it is preloaded
	public function testTheDefaultLibraryIsPreloaded():Void
	{
		fixture.write("assets/a.txt", "a");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<assets path="assets" />
		</project>');

		Fixture.assertSame(["default"], preloadedLibraries(output.read("haxe/ManifestResources.hx")));
	}

	// "Libraries other than default are not preloaded by default; preload="true" enables it"
	// <library name="myOtherLibrary" preload="true" /> <assets path="assets/other" library="myOtherLibrary" />
	public function testOtherLibrariesPreloadWhenAsked():Void
	{
		fixture.write("assets/a.txt", "a");
		fixture.write("assets/other/b.txt", "b");
		fixture.write("assets/later/c.txt", "c");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<library name="myOtherLibrary" preload="true" />
			<assets path="assets/a.txt" />
			<assets path="assets/other" library="myOtherLibrary" />
			<assets path="assets/later" library="later" />
		</project>');

		var resources = output.read("haxe/ManifestResources.hx");
		var preloaded = preloadedLibraries(resources);
		preloaded.sort(Reflect.compare);

		Fixture.assertSame(["default", "myOtherLibrary"], preloaded);

		// A library that is not preloaded is still known, by the path of its manifest
		Assert.isTrue(resources.indexOf('Assets.libraryPaths["later"] = rootPath + "manifest/later.json";') > -1);
		Assert.isTrue(output.exists("bin/manifest/later.json"));
	}

	// "If an asset is specified as template, it will ... be copied to the root directory of your project", with its values filled in
	public function testTemplateAssetsAreProcessedAndCopied():Void
	{
		fixture.write("extra/about.txt", "::APP_TITLE:: ::APP_VERSION::");

		output.update('<project>
			<meta title="My Application" version="2.5.0" />
			<app main="Main" file="MyApplication" />
			<assets path="extra/about.txt" rename="info/about.txt" type="template" />
		</project>');

		Assert.equals("My Application 2.5.0", output.read("bin/info/about.txt"));
	}

	// <template path="Assets/index.html" rename="index.php" />
	public function testATemplateFileCanBeRenamed():Void
	{
		fixture.write("Assets/index.html", "<html><title>::APP_TITLE::</title></html>");

		output.update('<project>
			<meta title="My Application" />
			<app main="Main" file="MyApplication" />
			<template path="Assets/index.html" rename="index.php" />
		</project>');

		Assert.equals("<html><title>My Application</title></html>", output.read("bin/index.php"));
	}

	// "Use <template /> tags to add paths which can override the templates used by the command-line tools."
	// <template path="templates" />
	public function testATemplateFolderOverridesLimesTemplates():Void
	{
		fixture.write("templates/html5/template/index.html", "<html><body>custom ::APP_FILE::</body></html>");
		fixture.write("templates/html5/template/extra.css", "body { color: red; }");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<template path="templates" />
		</project>');

		Assert.equals("<html><body>custom MyApplication</body></html>", output.read("bin/index.html"));
		Assert.equals("body { color: red; }", output.read("bin/extra.css"));
		// The files it does not replace still come from Lime
		Assert.isTrue(output.exists("haxe/ApplicationMain.hx"));
	}

	// An asset that leaves the project is removed from the output on the next update
	public function testAssetsNoLongerInTheProjectAreRemoved():Void
	{
		fixture.write("assets/keep.txt", "keep");
		fixture.write("assets/drop.txt", "drop");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<assets path="assets" />
		</project>');

		Assert.isTrue(output.exists("bin/assets/keep.txt"));
		Assert.isTrue(output.exists("bin/assets/drop.txt"));

		FileSystem.deleteFile(fixture.directory + "/assets/drop.txt");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<assets path="assets" />
		</project>');

		Assert.isTrue(output.exists("bin/assets/keep.txt"));
		Assert.isFalse(output.exists("bin/assets/drop.txt"));
	}

	public function testHxmlBuildsApplicationMainToTheAppFile():Void
	{
		fixture.write("src/Game.hx", "class Game {}");

		output.update('<project>
			<app main="Game" file="MyApplication" path="Export" />
			<source path="src" />
			<haxedef name="my-define" />
		</project>');

		var release = hxmlLines(output.read("haxe/release.hxml"));

		Assert.contains("-main ApplicationMain", release);
		Assert.contains("-js Export/html5/bin/MyApplication.js", release);
		Assert.contains("-cp Export/html5/haxe", release);
		Assert.contains("-cp src", release);
		Assert.contains("-D my-define", release);
		Assert.contains("-D html5", release);
		Assert.isFalse(release.indexOf("-debug") > -1);

		Assert.contains("-debug", hxmlLines(output.read("haxe/debug.hxml")));
		Assert.contains("-D final", hxmlLines(output.read("haxe/final.hxml")));
	}

	// <app main="com.example.MyApplication" />
	public function testApplicationMainStartsTheMainClass():Void
	{
		fixture.write("src/com/example/MyApplication.hx", "package com.example; class MyApplication {}");

		output.update('<project>
			<app main="com.example.MyApplication" file="MyApplication" />
			<source path="src" />
		</project>');

		var main = output.read("haxe/ApplicationMain.hx");

		Assert.isTrue(main.indexOf("import com.example.MyApplication;") > -1);
		Assert.isTrue(main.indexOf("var app = new com.example.MyApplication();") > -1);
		Assert.isTrue(main.indexOf('lime.system.System.__registerEntryPoint("MyApplication", create);') > -1);
	}

	// <meta title="My Application" package="com.example.myapplication" version="1.0.0" company="My Company" />
	public function testApplicationMainHoldsTheMetaValues():Void
	{
		output.update('<project>
			<meta title="My Application" package="com.example.myapplication" version="1.0.0" company="My Company" build-number="42" />
			<app main="Main" file="MyApplication" />
		</project>');

		var main = output.read("haxe/ApplicationMain.hx");

		Assert.equals("My Application", metaValue(main, "name"));
		Assert.equals("com.example.myapplication", metaValue(main, "packageName"));
		Assert.equals("1.0.0", metaValue(main, "version"));
		Assert.equals("My Company", metaValue(main, "company"));
		Assert.equals("42", metaValue(main, "build"));
		Assert.equals("MyApplication", metaValue(main, "file"));
	}

	// The values are written as Haxe strings, where a quote or a backslash has to be escaped
	public function testMetaValuesWithQuotesAreValidHaxeStrings():Void
	{
		output.update('<project>
			<meta title="The &quot;Best&quot; Game" company="Back\\Slash Ltd" />
			<app main="Main" file="MyApplication" />
		</project>');

		var main = output.read("haxe/ApplicationMain.hx");

		Assert.equals('The "Best" Game', metaValue(main, "name"));
		Assert.equals("Back\\Slash Ltd", metaValue(main, "company"));
	}

	public function testAWindowTitleWithQuotesIsAValidHaxeString():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<window title="The &quot;Best&quot; Game" />
		</project>');

		var main = output.read("haxe/ApplicationMain.hx");

		Assert.equals('The "Best" Game', PlatformFixture.haxeString(main, "title: ", ","));
	}

	// <window width="640" height="480" background="#FFFFFF" fps="30" />
	// <window fullscreen="false" resizable="true" borderless="false" vsync="false" />
	public function testApplicationMainCreatesTheWindowAsConfigured():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<window title="Custom" width="640" height="480" background="#336699" fps="30" />
			<window resizable="false" borderless="true" vsync="true" />
		</project>');

		var main = output.read("haxe/ApplicationMain.hx");
		var windows = PlatformFixture.windowAttributes(main);

		Assert.equals(1, windows.length);
		if (windows.length != 1) return;

		Assert.equals('"Custom"', windows[0].get("title"));
		Assert.equals("640", windows[0].get("width"));
		Assert.equals("480", windows[0].get("height"));
		Assert.equals("30", windows[0].get("frameRate"));
		Assert.equals("false", windows[0].get("resizable"));
		Assert.equals("true", windows[0].get("borderless"));
		Assert.equals(0x336699, Std.parseInt(windows[0].get("background")));
		Assert.equals("true", windows[0].get("vsync"));
	}

	// <window preserve-drawing-buffer="true" /> reaches the main window's render context, and without
	// it the context doesn't keep its image, as a WebGL context's default is (#1275)
	public function testPreserveDrawingBufferReachesTheRenderContext():Void
	{
		for (attribute in ['preserve-drawing-buffer="true"', '', 'preserve-drawing-buffer="false"'])
		{
			output.update('<project>
				<app main="Main" file="MyApplication" />
				<window $attribute />
			</project>');

			var main = output.read("haxe/ApplicationMain.hx");
			var start = main.indexOf("attributes.context =");
			var end = start > -1 ? main.indexOf("};", start) : -1;
			var context = (start > -1 && end > -1) ? main.substring(start, end) : "";
			var entry = ~/#if html5 preserveDrawingBuffer: (\w+), #end/;

			Assert.isTrue(entry.match(context), "no preserveDrawingBuffer in the render context for <window " + attribute + " />");
			if (entry.match(context)) Assert.equals(attribute == 'preserve-drawing-buffer="true"' ? "true" : "false", entry.matched(1), attribute);
		}
	}

	// A window with no title of its own is named after the application
	public function testTheWindowTitleDefaultsToTheMetaTitle():Void
	{
		output.update('<project>
			<meta title="My Application" />
			<app main="Main" file="MyApplication" />
		</project>');

		var windows = PlatformFixture.windowAttributes(output.read("haxe/ApplicationMain.hx"));

		Assert.equals(1, windows.length);
		if (windows.length == 1) Assert.equals('"My Application"', windows[0].get("title"));
	}

	// <window id="1" /> describes a second window, with settings of its own
	public function testEachWindowKeepsItsOwnSettings():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<window title="Main" width="800" height="600" />
			<window id="1" title="Second" width="320" height="240" />
		</project>');

		var windows = PlatformFixture.windowAttributes(output.read("haxe/ApplicationMain.hx"));

		Assert.equals(2, windows.length);
		if (windows.length != 2) return;

		Assert.equals('"Main"', windows[0].get("title"));
		Assert.equals("800", windows[0].get("width"));
		Assert.equals("600", windows[0].get("height"));
		Assert.equals('"Second"', windows[1].get("title"));
		Assert.equals("320", windows[1].get("width"));
		Assert.equals("240", windows[1].get("height"));
	}

	// Each asset's URL gets a version from its content, so a build that changes other
	// assets, or only code, leaves its URL as it was
	public function testEachAssetHasAVersionFromItsContent():Void
	{
		fixture.write("assets/a.txt", "same");
		fixture.write("assets/b.txt", "same");
		fixture.write("assets/c.txt", "other");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<assets path="assets" />
		</project>');

		var manifest = PlatformFixture.embeddedManifest(output.read("haxe/ManifestResources.hx"));
		Assert.notNull(manifest);
		if (manifest == null) return;

		var a:String = entry(manifest.assets, "assets/a.txt").version;
		var b:String = entry(manifest.assets, "assets/b.txt").version;
		var c:String = entry(manifest.assets, "assets/c.txt").version;

		Assert.equals(haxe.crypto.Md5.encode("same").substr(0, 10), a);
		Assert.equals(a, b);
		Assert.notEquals(a, c);

		// A change to one asset changes its version alone
		fixture.write("assets/c.txt", "changed");
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<assets path="assets" />
		</project>');

		manifest = PlatformFixture.embeddedManifest(output.read("haxe/ManifestResources.hx"));
		Assert.equals(a, entry(manifest.assets, "assets/a.txt").version);
		Assert.equals(haxe.crypto.Md5.encode("changed").substr(0, 10), entry(manifest.assets, "assets/c.txt").version);
	}

	// A sound in several formats has a version for each of its files
	public function testEachFileOfASoundHasAVersion():Void
	{
		fixture.write("assets/beep.ogg", "ogg bytes");
		fixture.write("assets/beep.mp3", "mp3 bytes");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<assets path="assets" />
		</project>');

		var manifest = PlatformFixture.embeddedManifest(output.read("haxe/ManifestResources.hx"));
		Assert.notNull(manifest);
		if (manifest == null) return;

		var sound = null;
		for (asset in manifest.assets) if (asset.pathGroup != null) sound = asset;
		Assert.notNull(sound, "no sound with a path group");
		if (sound == null) return;

		var paths:Array<String> = sound.pathGroup;
		var versions:Array<String> = sound.versionGroup;
		Assert.notNull(versions);
		Assert.equals(paths.length, versions.length);

		for (i in 0...paths.length)
		{
			var content = StringTools.endsWith(paths[i], ".ogg") ? "ogg bytes" : "mp3 bytes";
			Assert.equals(haxe.crypto.Md5.encode(content).substr(0, 10), versions[i], paths[i]);
		}
	}

	private function entry(assets:Array<Dynamic>, id:String):Dynamic
	{
		for (asset in assets)
		{
			if (asset.id == id) return asset;
		}

		Assert.fail("The manifest has no \"" + id + "\"");
		return {};
	}

	private function hxmlLines(hxml:String):Array<String>
	{
		return [for (line in hxml.split("\n")) StringTools.trim(line)];
	}

	/**
		A value that generated code gives `app.meta`.
	**/
	private function metaValue(applicationMain:String, name:String):String
	{
		return PlatformFixture.haxeString(applicationMain, 'app.meta.set("' + name + '", ', ");");
	}

	/**
		The names of the libraries that generated code adds to the preloader.
	**/
	private function preloadedLibraries(manifestResources:String):Array<String>
	{
		var names = [];
		var pattern = ~/library = Assets\.getLibrary \("([^"]*)"\);/;
		var rest = manifestResources;

		while (pattern.match(rest))
		{
			names.push(pattern.matched(1));
			rest = pattern.matchedRight();
		}

		return names;
	}

	private function scriptsOf(html:String):Array<String>
	{
		var sources = [];
		var pattern = ~/<script type="text\/javascript" src="([^"]*)"><\/script>/;
		var rest = html;

		while (pattern.match(rest))
		{
			sources.push(pattern.matched(1));
			rest = pattern.matchedRight();
		}

		return sources;
	}

	private function titleOf(html:String):String
	{
		var pattern = ~/<title>(.*)<\/title>/;
		return pattern.match(html) ? pattern.matched(1) : null;
	}

	// The application as the compiler would write it, with a comment and long names a minifier drops
	private static inline var APPLICATION = "(function () {\n\t/* an application comment */\n\tfunction applicationMarker(aRatherLongArgumentName) {\n\t\tvar aRatherLongLocalName = aRatherLongArgumentName + 41;\n\t\treturn aRatherLongLocalName;\n\t}\n\twindow.applicationResult = applicationMarker(1);\n})();\n";

	// A library with a comment and a sum a minifier would change
	private static inline var LIBRARY = "/* a library comment */\nvar libraryAnswer = 41+1;\n";

	// -minify minifies the application before the libraries it embeds are added to it, so they go
	// in as they are written, where minifying the whole file changed them (#1317)
	public function testMinifyLeavesTheEmbeddedLibrariesAsTheyAreWritten():Void
	{
		if (!closureRuns()) return;

		var minified = buildWithALibrary(true);
		Assert.isTrue(minified.indexOf(LIBRARY) > -1, "the library was changed: " + minified);
		Assert.equals(-1, minified.indexOf("an application comment"), "the application kept its comment");
		Assert.equals(-1, minified.indexOf("aRatherLongLocalName"), "the application kept its long names");

		var plain = buildWithALibrary(false);
		Assert.isTrue(plain.indexOf(LIBRARY) > -1, "the library was changed without -minify: " + plain);
		Assert.isTrue(plain.indexOf(APPLICATION) > -1, "the application was changed without -minify: " + plain);
	}

	/**
		Builds a project that embeds lib/library.js, with -minify or without, and gives the
		JavaScript written. The compiler isn't run: the build's HXML is left doing nothing, and the
		application is written where the compiler writes it.
	**/
	private function buildWithALibrary(minify:Bool):String
	{
		var xml = '<project>
			<app main="Main" file="Minified" path="Export" />
			<dependency path="lib/library.js" embed="true" />
		</project>';

		fixture.write("lib/library.js", LIBRARY);
		if (minify) fixture.targetFlags.set("minify", "") else fixture.targetFlags.remove("minify");

		output.update(xml);
		sys.io.File.saveContent(output.path("haxe/release.hxml"), "--version\n");
		sys.io.File.saveContent(output.path("bin/Minified.js"), APPLICATION);
		output.build(xml);

		fixture.targetFlags.remove("minify");
		return output.read("bin/Minified.js");
	}

	// The Closure Compiler, which -minify runs, needs Java, which a test machine may not have, and
	// a minify that fails ends the tools
	private static function closureRuns():Bool
	{
		try
		{
			var process = new sys.io.Process("java", ["-jar", hxp.Path.combine(PlatformFixture.templates(), "bin/compiler.jar"), "--version"]);
			process.stdout.readAll();
			process.stderr.readAll();
			var code = process.exitCode();
			process.close();
			if (code == 0) return true;
		}
		catch (e:Dynamic) {}

		trace("The Closure Compiler can't run here, without Java, so -minify was not tested");
		Assert.pass();
		return false;
	}
}
