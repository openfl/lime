import utest.Assert;
import utest.Test;

/**
	`<include />`: "Use `<include />` tags to add the tags found in another project file,
	or to find an include.xml file in the target directory", from Lime's XML format
	documentation, along with its "Duplicates" rule.
**/
class IncludeTest extends Test
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

	public function testIncludeAddsTheTagsOfAnotherProjectFile():Void
	{
		fixture.write("extra.xml", '<project>
			<set name="from-extra" value="yes" />
			<haxeflag name="--no-traces" />
		</project>');

		var project = fixture.parse('<project>
			<include path="extra.xml" />
		</project>');

		Assert.equals("yes", project.defines.get("from-extra"));
		Assert.contains("--no-traces", project.haxeflags);
	}

	// <include path="to/shared/library" />
	public function testIncludeOfAFolderUsesItsIncludeXml():Void
	{
		fixture.write("shared/library/include.xml", '<project>
			<set name="from-library" />
		</project>');

		var project = fixture.parse('<project>
			<include path="shared/library" />
		</project>');

		Assert.isTrue(project.defines.exists("from-library"));
	}

	public function testPathsInAnIncludedFileAreRelativeToIt():Void
	{
		fixture.write("lib/data/readme.txt", "readme");
		fixture.write("lib/extra.xml", '<project>
			<source path="src" />
			<icon path="icon.svg" />
			<assets path="data/readme.txt" />
			<include path="more/deeper.xml" />
		</project>');
		fixture.write("lib/more/deeper.xml", '<project>
			<source path="deep" />
		</project>');

		var project = fixture.parse('<project>
			<include path="lib/extra.xml" />
		</project>');

		Assert.contains("lib/src", project.sources);
		Assert.contains("lib/more/deep", project.sources);
		Assert.equals("lib/icon.svg", project.icons[0].path);
		Assert.equals("lib/data/readme.txt", project.assets[0].sourcePath);
	}

	@Ignored("Waiting on #2192")
	public function testAFileIncludedTwiceAddsItsAssetsOnce():Void
	{
		writeSharedFile();

		var project = fixture.parse('<project>
			<include path="shared/shared.xml" />
			<include path="shared/shared.xml" />
		</project>');

		// Its sources and flags are already kept once, as they compare by value
		Assert.equals(1, project.sources.filter(function(source) return source == "shared/src").length, "sources: " + project.sources.join(", "));
		Assert.equals(1, project.haxeflags.filter(function(flag) return flag == "--no-traces").length, "flags: " + project.haxeflags.join(", "));
		Fixture.assertSame(["data/notes.txt", "data/readme.txt"], Fixture.targetPaths(project));
	}

	@Ignored("Waiting on #2192")
	public function testAFileIncludedFromTwoIncludedFilesAddsItsAssetsOnce():Void
	{
		writeSharedFile();
		fixture.write("first.xml", '<project>
			<include path="shared/shared.xml" />
		</project>');
		fixture.write("second.xml", '<project>
			<include path="shared/shared.xml" />
		</project>');

		var project = fixture.parse('<project>
			<include path="first.xml" />
			<include path="second.xml" />
		</project>');

		Fixture.assertSame(["data/notes.txt", "data/readme.txt"], Fixture.targetPaths(project));
	}

	public function testIncludeIsSkippedWhenItsConditionFails():Void
	{
		fixture.write("extra.xml", '<project>
			<set name="from-extra" />
		</project>');

		var project = fixture.parse('<project>
			<include path="extra.xml" if="never-set" />
		</project>');

		Assert.isFalse(project.defines.exists("from-extra"));
	}

	public function testIncludePathCanUseSubstitution():Void
	{
		fixture.write("lib/extra.xml", '<project>
			<set name="from-extra" />
		</project>');

		var project = fixture.parse('<project>
			<set name="folder" value="lib" />
			<include path="$${folder}/extra.xml" />
		</project>');

		Assert.isTrue(project.defines.exists("from-extra"));
	}

	public function testAnIncludedFileSeesValuesSetBeforeIt():Void
	{
		fixture.write("extra.xml", '<project>
			<set name="saw-red" if="red" />
			<set name="copy" value="$${color}" />
		</project>');

		var project = fixture.parse('<project>
			<set name="red" />
			<set name="color" value="blue" />
			<include path="extra.xml" />
		</project>');

		Assert.isTrue(project.defines.exists("saw-red"));
		Assert.equals("blue", project.defines.get("copy"));
	}

	public function testValuesSetInAnIncludedFileApplyAfterIt():Void
	{
		fixture.write("extra.xml", '<project>
			<set name="green" />
			<define name="flag" value="on" />
		</project>');

		var project = fixture.parse('<project>
			<include path="extra.xml" />
			<set name="saw-green" if="green" />
		</project>');

		Assert.isTrue(project.defines.exists("saw-green"));
		Assert.equals("on", project.haxedefs.get("flag"));
	}

	// "If you define the same value more than once, the last definition will be used."
	@Ignored("Waiting on #2163")
	public function testAnIncludedDefineReplacesAnEarlierOne():Void
	{
		fixture.write("blue.xml", '<project>
			<define name="color" value="blue" />
		</project>');

		var project = fixture.parse('<project>
			<define name="color" value="red" />
			<include path="blue.xml" />
			<set name="copy" value="$${color}" />
		</project>');

		Assert.equals("blue", project.defines.get("copy"));
		Assert.equals("blue", project.haxedefs.get("color"));
	}

	@Ignored("Waiting on #2163")
	public function testAnIncludedSetReplacesAnEarlierOne():Void
	{
		fixture.write("dark.xml", '<project>
			<set name="shade" value="dark" />
		</project>');

		var project = fixture.parse('<project>
			<set name="shade" value="light" />
			<include path="dark.xml" />
			<set name="copy" value="$${shade}" />
		</project>');

		Assert.equals("dark", project.defines.get("copy"));
	}

	// "Unsets a previously defined flag." / a removed value "is treated as false"
	@Ignored("Waiting on #2163")
	public function testAnIncludedUndefineRemovesAnEarlierDefine():Void
	{
		fixture.write("off.xml", '<project>
			<undefine name="flag" />
			<unset name="red" />
		</project>');

		var project = fixture.parse('<project>
			<define name="flag" />
			<set name="red" />
			<include path="off.xml" />
			<set name="saw-flag" if="flag" />
			<set name="saw-red" if="red" />
		</project>');

		Assert.isFalse(project.defines.exists("saw-flag"));
		Assert.isFalse(project.haxedefs.exists("flag"));
		Assert.isFalse(project.defines.exists("saw-red"));
	}

	public function testAnIncludedFileOverridesEarlierMetaAndWindowValues():Void
	{
		fixture.write("extra.xml", '<project>
			<meta title="After" />
			<window width="800" />
			<app main="other.Main" />
		</project>');

		var project = fixture.parse('<project>
			<meta title="Before" company="My Company" />
			<window width="640" height="480" />
			<app main="Main" file="MyApplication" />
			<include path="extra.xml" />
		</project>');

		Assert.equals("After", project.meta.title);
		Assert.equals("My Company", project.meta.company);
		Assert.equals(800, project.window.width);
		Assert.equals(480, project.window.height);
		Assert.equals("other.Main", project.app.main);
		Assert.equals("MyApplication", project.app.file);
	}

	public function testLaterValuesOverrideAnIncludedFile():Void
	{
		fixture.write("extra.xml", '<project>
			<define name="color" value="red" />
			<meta title="Included" />
		</project>');

		var project = fixture.parse('<project>
			<include path="extra.xml" />
			<define name="color" value="blue" />
			<meta title="Mine" />
		</project>');

		Assert.equals("blue", project.haxedefs.get("color"));
		Assert.equals("Mine", project.meta.title);
	}

	/** A project file with two assets, a source path and a flag, as a library might share them **/
	private function writeSharedFile():Void
	{
		fixture.write("shared/data/readme.txt", "readme");
		fixture.write("shared/data/notes.txt", "notes");
		fixture.write("shared/shared.xml", '<project>
			<source path="src" />
			<haxeflag name="--no-traces" />
			<assets path="data/readme.txt" />
			<assets path="data/notes.txt" />
		</project>');
	}
}
