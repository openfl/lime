import lime.tools.HXProject;
import lime.tools.Platform;
import utest.Assert;
import utest.Test;
import utils.BuildEnvironment;

/**
	The warning native builds give about the hxcpp haxelib, from the 8.4.0 changelog:

	`lime build` and `lime test` warn when `-lib hxcpp` is not libhxcpp (its haxelib.json is
	named "libhxcpp") where that is a setup mistake: Lime is a git checkout, which is built
	and tested with libhxcpp, or libhxcpp is installed but `haxelib run libhxcpp setup` has
	not pointed hxcpp at it.
**/
class BuildEnvironmentTest extends Test
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

	public function testLibHxcppIsNotWarnedAbout():Void
	{
		var hxcpp = addHaxelib("libhxcpp", "libhxcpp", "6.0.0");

		Assert.isNull(BuildEnvironment.getHxcppWarning(hxcpp, true, hxcpp));
		Assert.isNull(BuildEnvironment.getHxcppWarning(hxcpp, true, null));
	}

	public function testStockHxcppBesideLibHxcppSaysToRunItsSetup():Void
	{
		var hxcpp = addHaxelib("hxcpp", "hxcpp", "4.3.2");
		var libhxcpp = addHaxelib("libhxcpp", "libhxcpp", "6.0.0");

		var message = BuildEnvironment.getHxcppWarning(hxcpp, false, libhxcpp);
		Assert.notNull(message);
		Assert.stringContains("hxcpp 4.3.2", message);
		Assert.stringContains(fixture.directory + "/haxelib/hxcpp", message);
		Assert.stringContains("haxelib run libhxcpp setup", message);
	}

	public function testStockHxcppWithLimeFromGitSaysToInstallLibHxcpp():Void
	{
		var hxcpp = addHaxelib("hxcpp", "hxcpp", "4.3.2");

		var message = BuildEnvironment.getHxcppWarning(hxcpp, true, "");
		Assert.notNull(message);
		Assert.stringContains("hxcpp 4.3.2", message);
		Assert.stringContains("haxelib git libhxcpp https://github.com/openfl/libhxcpp", message);
		Assert.stringContains("haxelib run libhxcpp setup", message);
	}

	// A Lime release with stock hxcpp, and no libhxcpp, is a setup Lime still builds with
	public function testStockHxcppWithLimeReleaseAndNoLibHxcppIsNotWarnedAbout():Void
	{
		var hxcpp = addHaxelib("hxcpp", "hxcpp", "4.3.2");

		Assert.isNull(BuildEnvironment.getHxcppWarning(hxcpp, false, null));
		Assert.isNull(BuildEnvironment.getHxcppWarning(hxcpp, false, ""));
	}

	// An hxcpp checkout of the developer's own, set with haxelib dev
	public function testHxcppCheckoutIsWarnedAboutWithLimeFromGit():Void
	{
		var hxcpp = addHaxelib("hxcpp", "hxcpp", "4.3.150");

		Assert.notNull(BuildEnvironment.getHxcppWarning(hxcpp, true, null));
	}

	public function testHaxelibNameIsReadFromHaxelibJson():Void
	{
		Assert.equals("libhxcpp", BuildEnvironment.getHaxelibName(addHaxelib("hxcpp", "libhxcpp", "6.0.0")));
		Assert.equals("6.0.0", BuildEnvironment.getHaxelibVersion(fixture.directory + "/haxelib/hxcpp"));
		Assert.isNull(BuildEnvironment.getHaxelibName(fixture.directory + "/missing"));
	}

	public function testCppBuildsUseHxcpp():Void
	{
		Assert.isTrue(BuildEnvironment.usesHxcpp(project(WINDOWS)));
		Assert.isTrue(BuildEnvironment.usesHxcpp(project(MAC, ["cpp" => ""])));
		Assert.isTrue(BuildEnvironment.usesHxcpp(project(LINUX)));
		Assert.isTrue(BuildEnvironment.usesHxcpp(project(ANDROID)));
		Assert.isTrue(BuildEnvironment.usesHxcpp(project(IOS)));
		Assert.isTrue(BuildEnvironment.usesHxcpp(project(TVOS)));
		Assert.isTrue(BuildEnvironment.usesHxcpp(project(WEB_ASSEMBLY)));
	}

	public function testOtherBuildsDoNotUseHxcpp():Void
	{
		Assert.isFalse(BuildEnvironment.usesHxcpp(project(WINDOWS, ["neko" => ""])));
		Assert.isFalse(BuildEnvironment.usesHxcpp(project(WINDOWS, ["hl" => ""])));
		Assert.isFalse(BuildEnvironment.usesHxcpp(project(LINUX, ["hl" => "", "hlc" => ""])));
		Assert.isFalse(BuildEnvironment.usesHxcpp(project(MAC, ["java" => ""])));
		Assert.isFalse(BuildEnvironment.usesHxcpp(project(HTML5)));
		Assert.isFalse(BuildEnvironment.usesHxcpp(project(FLASH)));
		Assert.isFalse(BuildEnvironment.usesHxcpp(project(AIR)));
	}

	// The native libraries for Neko and HashLink are compiled with hxcpp
	public function testRebuildsForNekoAndHashLinkUseHxcpp():Void
	{
		Assert.isTrue(BuildEnvironment.usesHxcpp(project(WINDOWS, ["neko" => ""]), true));
		Assert.isTrue(BuildEnvironment.usesHxcpp(project(LINUX, ["hl" => ""]), true));
		Assert.isFalse(BuildEnvironment.usesHxcpp(project(HTML5), true));
	}

	private function addHaxelib(folder:String, name:String, version:String):String
	{
		fixture.write("haxelib/" + folder + "/haxelib.json", '{"name": "$name", "version": "$version"}');
		return fixture.directory + "/haxelib/" + folder;
	}

	private function project(target:Platform, targetFlags:Map<String, String> = null):HXProject
	{
		fixture.target = target;
		fixture.targetFlags = (targetFlags != null ? targetFlags : new Map());
		fixture.prepare();

		var project = new HXProject();
		project.target = target;
		project.targetFlags = fixture.targetFlags;
		return project;
	}
}
