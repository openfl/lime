import haxe.Serializer;
import haxe.Unserializer;
import hxp.Path;
import lime.tools.HXProject;
import utest.Assert;
import utest.Test;

/**
	`<haxelib />` and a haxelib's include.xml, from Lime's XML format documentation:
	"Haxelib authors can place an include.xml in the top-level directory ... The build tools
	will automatically add the contents of the file to the user’s project."

	Every haxelib here is a folder in the fixture, given to `Haxelib.pathOverrides`, so
	nothing runs the `haxelib` command.
**/
class HaxelibTest extends Test
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

	public function testHaxelibAddsTheLibrary():Void
	{
		fixture.addHaxelib("toolstest-plain", "<project />");

		var project = fixture.parse('<project>
			<haxelib name="toolstest-plain" />
		</project>');

		Assert.equals(1, project.haxelibs.length);
		Assert.equals("toolstest-plain", project.haxelibs[0].name);
		Assert.equals("", project.haxelibs[0].version);
	}

	// <haxelib name="actuate" version="1.0.0" />
	public function testHaxelibVersionIsKept():Void
	{
		fixture.addHaxelib("toolstest-plain", "<project />");

		var project = fixture.parse('<project>
			<haxelib name="toolstest-plain" version="1.0.0" />
		</project>');

		Assert.equals("1.0.0", project.haxelibs[0].version);
	}

	public function testHaxelibIncludeXmlIsAddedToTheProject():Void
	{
		var path = fixture.addHaxelib("toolstest-included", '<project>
			<haxedef name="toolstest-feature" />
			<source path="src" />
		</project>');

		var project = fixture.parse('<project>
			<haxelib name="toolstest-included" />
		</project>');

		Assert.isTrue(project.haxedefs.exists("toolstest-feature"));
		Assert.contains(Path.combine(path, "src"), project.sources);
	}

	public function testHaxelibIsSkippedWhenItsConditionFails():Void
	{
		fixture.addHaxelib("toolstest-included", '<project>
			<haxedef name="toolstest-feature" />
		</project>');

		var project = fixture.parse('<project>
			<haxelib name="toolstest-included" if="never-set" />
		</project>');

		Assert.equals(0, project.haxelibs.length);
		Assert.isFalse(project.haxedefs.exists("toolstest-feature"));
	}

	// <haxelib name="actuate" path="../alt-haxelibs/actuate" />
	public function testHaxelibPathUsesALocalFolder():Void
	{
		fixture.write("libs/local/haxelib.json", '{"name": "toolstest-local", "version": "1.0.0"}');
		fixture.write("libs/local/include.xml", '<project>
			<set name="toolstest-local-included" />
		</project>');

		var project = fixture.parse('<project>
			<haxelib name="toolstest-local" path="libs/local" />
		</project>');

		Assert.isTrue(project.defines.exists("toolstest-local-included"));
	}

	// Paths in a file are relative to that file, as <source /> and <assets /> are in an included file
	public function testHaxelibPathInAnIncludedFileIsRelativeToThatFile():Void
	{
		fixture.write("sub/nested/haxelib.json", '{"name": "toolstest-nested", "version": "1.0.0"}');
		fixture.write("sub/nested/include.xml", '<project>
			<set name="toolstest-nested-included" />
		</project>');
		fixture.write("sub/extra.xml", '<project>
			<haxelib name="toolstest-nested" path="nested" />
		</project>');

		var project = fixture.parse('<project>
			<include path="sub/extra.xml" />
		</project>');

		Assert.isTrue(project.defines.exists("toolstest-nested-included"));
	}

	// <sample path="${haxelib:flixel-demos}/Arcade" />
	public function testHaxelibSubstitutionGivesItsFolder():Void
	{
		var path = fixture.addHaxelib("toolstest-plain", "<project />");

		var project = fixture.parse('<project>
			<set name="folder" value="$${haxelib:toolstest-plain}/Arcade" />
		</project>');

		Assert.equals(Path.standardize(path) + "/Arcade", project.defines.get("folder"));
	}

	// "Usually an <ndll /> tag will be included as a part of an extension"
	public function testNdllsInAHaxelibIncludeBelongToThatHaxelib():Void
	{
		fixture.addHaxelib("toolstest-extension", '<project>
			<ndll name="toolstest-native" />
		</project>');

		var project = fixture.parse('<project>
			<haxelib name="toolstest-extension" />
		</project>');

		Assert.equals(1, project.ndlls.length);
		Assert.equals("toolstest-native", project.ndlls[0].name);
		Assert.equals("toolstest-extension", project.ndlls[0].haxelib.name);
	}

	// CHANGELOG 8.4.0: "Fixed HXP projects processing Haxelib include files twice"
	public function testHxpProjectAddsAHaxelibIncludeOnce():Void
	{
		fixture.addHaxelib("toolstest-assets", '<project>
			<assets path="logo.txt" embed="true" />
		</project>', ["logo.txt" => "logo"]);

		var xml = fixture.parse('<project>
			<haxelib name="toolstest-assets" />
		</project>');

		// A project.hxp that wraps project.xml merges it, then the tools take its result and process its haxelibs
		fixture.prepare();
		var wrapper = new HXProject();
		wrapper.merge(xml);

		var serializer = new Serializer();
		serializer.useCache = true;
		serializer.serialize(wrapper);
		var project:HXProject = Unserializer.run(serializer.toString());

		@:privateAccess HXProject.processHaxelibs(project, project.defines);

		Assert.equals(1, Fixture.countAssets(project, "logo.txt"));
	}

	// The include.xml of a haxelib that another haxelib also asks for is added once, as an HXP project's is
	public function testHaxelibIncludeAskedForTwiceIsAddedOnce():Void
	{
		fixture.addHaxelib("toolstest-base", '<project>
			<assets path="base.txt" embed="true" />
		</project>', ["base.txt" => "base"]);
		fixture.addHaxelib("toolstest-addon", '<project>
			<haxelib name="toolstest-base" />
		</project>');

		var project = fixture.parse('<project>
			<haxelib name="toolstest-base" />
			<haxelib name="toolstest-addon" />
		</project>');

		Assert.equals(1, Fixture.countAssets(project, "base.txt"));
	}

	// A haxelib at a path of its own gives the Haxe arguments `haxelib path` would: its
	// extraParams.hxml, its class path and its version as a define
	public function testAHaxelibAtAPathOfItsOwnGivesItsHaxeArguments():Void
	{
		var path = fixture.addHaxelib("toolstest-params", "<project />", [
			"haxelib.json" => '{"name": "toolstest-params", "version": "2.3.4", "classPath": "src"}',
			"extraParams.hxml" => "# a comment\n--macro toolstest.Setup.run()\r\n-D toolstest-extra\n\n"
		]);

		var project = fixture.parse('<project>
			<haxelib name="toolstest-params" />
		</project>');

		var flags = (project.templateContext.HAXE_FLAGS : String).split("\n");
		Assert.contains("--macro toolstest.Setup.run()", flags);
		Assert.contains("-D toolstest-extra", flags);
		Assert.contains("-cp " + Path.standardize(Path.combine(path, "src")), flags);
		Assert.contains("-D toolstest-params=2.3.4", flags);
		Assert.equals(-1, flags.indexOf("-cp # a comment"), "the comment became a class path");

		for (flag in flags)
		{
			Assert.isFalse(StringTools.startsWith(flag, "#"), "a comment was passed on: " + flag);
		}
	}

	public function testAHaxelibAtAPathOfItsOwnWithoutExtraParamsGivesItsClassPathAndVersion():Void
	{
		var path = fixture.addHaxelib("toolstest-plain", "<project />");

		var project = fixture.parse('<project>
			<haxelib name="toolstest-plain" />
		</project>');

		var flags = (project.templateContext.HAXE_FLAGS : String).split("\n");
		Assert.contains("-D toolstest-plain=1.0.0", flags);
		Assert.isTrue([for (flag in flags) if (StringTools.startsWith(flag, "-cp ") && Path.standardize(flag.substr(4)).indexOf("haxelib/toolstest-plain") > -1) flag].length == 1,
			"the class path is not given once: " + flags.join(", "));
	}
}
