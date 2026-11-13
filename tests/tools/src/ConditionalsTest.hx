import hxp.Path;
import hxp.System;
import lime.tools.Platform;
import sys.FileSystem;
import utest.Assert;
import utest.Test;

/**
	`if`, `unless`, `<section>`, `<set>`, `<unset>`, `<define>`, `<undefine>` and `${...}`, as
	described under "Conditionals", "Build info" and "Duplicates" in Lime's XML format
	documentation: https://lime.openfl.org/docs/project-files/xml-format/
**/
class ConditionalsTest extends Test
{
	private static var defaultValues = [
		"mobile", "desktop", "web", "ios", "android", "windows", "mac", "linux", "html5", "cpp", "neko", "flash", "js"
	];

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

	// "spaces imply an “and” and vertical bars imply an “or”"
	public function testIfWithSpacesNeedsEveryValue():Void
	{
		var project = fixture.parse('<project>
			<set name="red" />
			<set name="red-and-green" if="red green" />
			<set name="green" />
			<set name="red-and-green-later" if="red green" />
		</project>');

		Assert.isFalse(project.defines.exists("red-and-green"));
		Assert.isTrue(project.defines.exists("red-and-green-later"));
	}

	public function testIfWithBarsNeedsAnyValue():Void
	{
		var project = fixture.parse('<project>
			<set name="green" />
			<set name="red-or-green" if="red || green" />
			<set name="red-or-blue" if="red || blue" />
		</project>');

		Assert.isTrue(project.defines.exists("red-or-green"));
		Assert.isFalse(project.defines.exists("red-or-blue"));
	}

	public function testUnlessWithBarsExcludesTheNodeWhenAnyValueIsSet():Void
	{
		var project = fixture.parse('<project>
			<set name="green" />
			<set name="neither-red-nor-green" unless="red || green" />
			<set name="neither-red-nor-blue" unless="red || blue" />
		</project>');

		Assert.isFalse(project.defines.exists("neither-red-nor-green"));
		Assert.isTrue(project.defines.exists("neither-red-nor-blue"));
	}

	public function testUnlessWithSpacesExcludesTheNodeOnlyWhenEveryValueIsSet():Void
	{
		var project = fixture.parse('<project>
			<set name="red" />
			<set name="not-red-and-green" unless="red green" />
			<set name="green" />
			<set name="not-red-and-green-later" unless="red green" />
		</project>');

		Assert.isTrue(project.defines.exists("not-red-and-green"));
		Assert.isFalse(project.defines.exists("not-red-and-green-later"));
	}

	// <window width="640" height="480" if="define define2" unless="define3 || define4" />
	public function testIfAndUnlessCombineOnOneNode():Void
	{
		fixture.defines.set("define", "");
		fixture.defines.set("define2", "");
		fixture.defines.set("define4", "");

		var project = fixture.parse('<project>
			<window width="640" height="480" if="define define2" unless="define3" />
			<window fps="30" if="define define2" unless="define3 || define4" />
		</project>');

		Assert.equals(640, project.window.width);
		Assert.equals(480, project.window.height);
		Assert.isFalse(Reflect.hasField(project.window, "fps"));
	}

	// "Values not found are treated as false"
	public function testValuesThatWereNeverSetAreFalse():Void
	{
		var project = fixture.parse('<project>
			<set name="saw-it" if="never-set" />
			<set name="did-not-see-it" unless="never-set" />
		</project>');

		Assert.isFalse(project.defines.exists("saw-it"));
		Assert.isTrue(project.defines.exists("did-not-see-it"));
	}

	// "lime test flash -Dblue"
	public function testCommandLineDefinesCanBeTested():Void
	{
		fixture.defines.set("blue", "");

		var project = fixture.parse('<project>
			<set name="is-blue" if="blue" />
		</project>');

		Assert.isTrue(project.defines.exists("is-blue"));
	}

	// "value is optional and is read back with ${}"
	public function testSetValueIsReadBackWithSubstitution():Void
	{
		var project = fixture.parse('<project>
			<set name="color" value="blue" />
			<set name="copy" value="$${color}" />
			<set name="saw-color" if="color" />
		</project>');

		Assert.equals("blue", project.defines.get("copy"));
		Assert.isTrue(project.defines.exists("saw-color"));
	}

	public function testSetWithoutAValueIsStillSet():Void
	{
		var project = fixture.parse('<project>
			<set name="red" />
			<set name="saw-red" if="red" />
		</project>');

		Assert.isTrue(project.defines.exists("saw-red"));
	}

	public function testDefineValueIsReadBackWithSubstitution():Void
	{
		var project = fixture.parse('<project>
			<define name="color" value="blue" />
			<set name="copy" value="$${color}" />
			<set name="saw-color" if="color" />
		</project>');

		Assert.equals("blue", project.defines.get("copy"));
		Assert.isTrue(project.defines.exists("saw-color"));
	}

	// "Unsets a previously set value."
	public function testUnsetRemovesASetValue():Void
	{
		var project = fixture.parse('<project>
			<set name="red" />
			<unset name="red" />
			<set name="saw-red" if="red" />
		</project>');

		Assert.isFalse(project.defines.exists("red"));
		Assert.isFalse(project.defines.exists("saw-red"));
	}

	// <define /> values "will be available in Haxe and in templates"
	public function testDefineIsAvailableToHaxe():Void
	{
		var project = fixture.parse('<project>
			<define name="color" value="blue" />
			<define name="flag" />
		</project>');

		Assert.equals("blue", project.haxedefs.get("color"));
		Assert.isTrue(project.haxedefs.exists("flag"));
	}

	// <set /> values are for conditions and templates; only <define /> also reaches Haxe
	public function testSetIsNotPassedToHaxe():Void
	{
		var project = fixture.parse('<project>
			<set name="color" value="blue" />
		</project>');

		Assert.isFalse(project.haxedefs.exists("color"));
	}

	// "Unsets a previously defined flag."
	public function testUndefineRemovesADefinedFlag():Void
	{
		var project = fixture.parse('<project>
			<define name="flag" />
			<undefine name="flag" />
			<set name="saw-flag" if="flag" />
		</project>');

		Assert.isFalse(project.defines.exists("saw-flag"));
		Assert.isFalse(project.haxedefs.exists("flag"));
	}

	// "If you define the same value more than once, the last definition will be used."
	public function testTheLastDefinitionIsUsed():Void
	{
		var project = fixture.parse('<project>
			<define name="color" value="red" />
			<define name="color" value="blue" />
			<set name="shade" value="light" />
			<set name="shade" value="dark" />
			<set name="copy" value="$${color} $${shade}" />
		</project>');

		Assert.equals("blue dark", project.defines.get("copy"));
		Assert.equals("blue", project.haxedefs.get("color"));
	}

	// "These values will be available in templates using the syntax ::SET_CUSTOM_VALUE::. (Hyphens are converted to underscores.)"
	public function testSetValuesReachTemplatesAsSetNames():Void
	{
		var project = fixture.parse('<project>
			<set name="custom-value" value="hello" />
			<set name="custom-flag" />
		</project>');

		var context = project.templateContext;

		Assert.equals("hello", Reflect.field(context, "SET_CUSTOM_VALUE"));
		Assert.equals(true, Reflect.field(context, "SET_CUSTOM_FLAG"));
	}

	// "For templates, use the syntax ::DEFINE_CUSTOM_VALUE::. Hyphens are converted to underscores in both cases."
	public function testDefineValuesReachTemplatesAsDefineNames():Void
	{
		var project = fixture.parse('<project>
			<define name="custom-value" value="hello" />
		</project>');

		var context = project.templateContext;

		Assert.equals("hello", Reflect.field(context, "DEFINE_CUSTOM_VALUE"));
		Assert.contains("-D custom-value=hello", (context.HAXE_FLAGS : String).split("\n"));
	}

	// "Here are some of the default values: mobile, desktop or web / ios, android, windows, mac, linux or html5 / cpp, neko, flash or js"
	public function testDefaultValuesForAndroid():Void
	{
		Fixture.assertSame(["mobile", "android", "cpp"], defaultValuesFor(ANDROID));
	}

	public function testDefaultValuesForIos():Void
	{
		Fixture.assertSame(["mobile", "ios", "cpp"], defaultValuesFor(IOS));
	}

	@Ignored("Waiting on #2169")
	public function testDefaultValuesForHtml5():Void
	{
		Fixture.assertSame(["web", "html5", "js"], defaultValuesFor(HTML5));
	}

	public function testDefaultValuesForFlash():Void
	{
		Fixture.assertSame(["web", "flash"], defaultValuesFor(FLASH));
	}

	public function testDefaultValuesForNativeDesktop():Void
	{
		var host:Platform = System.hostPlatform;
		Fixture.assertSame(["desktop", Std.string(host), "cpp"], defaultValuesFor(host));
	}

	public function testDefaultValuesForNekoDesktop():Void
	{
		var host:Platform = System.hostPlatform;
		Fixture.assertSame(["desktop", Std.string(host), "neko"], defaultValuesFor(host, ["neko" => ""]));
	}

	// "The <section /> tag is used to group other tags together."
	public function testSectionAppliesItsChildrenWhenItsConditionHolds():Void
	{
		fixture.target = HTML5;

		var project = fixture.parse('<project>
			<section if="html5">
				<source path="extra/src/html5" />
			</section>
		</project>');

		Assert.contains("extra/src/html5", project.sources);
	}

	public function testSectionSkipsItsChildrenWhenItsConditionFails():Void
	{
		fixture.target = ANDROID;

		var project = fixture.parse('<project>
			<section if="html5">
				<source path="extra/src/html5" />
			</section>
			<section unless="android">
				<source path="extra/src/other" />
			</section>
		</project>');

		Assert.notContains("extra/src/html5", project.sources);
		Assert.notContains("extra/src/other", project.sources);
	}

	public function testSectionsCanBeNested():Void
	{
		var project = fixture.parse('<project>
			<set name="red" />
			<section if="red">
				<set name="only-red" />
				<section if="green">
					<set name="red-and-green" />
				</section>
				<section unless="green">
					<set name="red-not-green" />
				</section>
			</section>
		</project>');

		Assert.isTrue(project.defines.exists("only-red"));
		Assert.isFalse(project.defines.exists("red-and-green"));
		Assert.isTrue(project.defines.exists("red-not-green"));
	}

	// <set name="buildOrTest" if="${project.command == build} || ${project.command == test}" />
	public function testBuildInfoComparisonsWorkInConditions():Void
	{
		var xml = '<project>
			<set name="buildOrTest" if="$${project.command == build} || $${project.command == test}" />
		</project>';

		fixture.command = "test";
		Assert.isTrue(fixture.parse(xml).defines.exists("buildOrTest"));

		fixture.command = "update";
		Assert.isFalse(fixture.parse(xml).defines.exists("buildOrTest"));
	}

	// "${project.command}, ${project.target}, ${project.host}"
	public function testBuildInfoNamesTheCommandTargetAndHost():Void
	{
		fixture.target = ANDROID;
		fixture.command = "build";

		var project = fixture.parse('<project>
			<set name="info" value="$${project.command} $${project.target} $${project.host}" />
		</project>');

		var host:Platform = System.hostPlatform;
		Assert.equals("build android " + Std.string(host), project.defines.get("info"));
	}

	// "${project.workingDirectory}"
	public function testWorkingDirectoryIsTheProjectFolder():Void
	{
		var project = fixture.parse('<project>
			<set name="folder" value="$${project.workingDirectory}" />
		</project>');

		var folder = project.defines.get("folder");
		Assert.isTrue(FileSystem.exists(Path.combine(folder, "project.xml")), "\"" + folder + "\" does not hold the project file");
	}

	/**
		Which of the documented default values hold for a target.
	**/
	private function defaultValuesFor(target:Platform, targetFlags:Map<String, String> = null):Array<String>
	{
		fixture.target = target;
		if (targetFlags != null) fixture.targetFlags = targetFlags;

		var xml = "<project>\n";

		for (value in defaultValues)
		{
			xml += '<set name="is-$value" if="$value" />\n';
		}

		var project = fixture.parse(xml + "</project>");
		return [for (value in defaultValues) if (project.defines.exists("is-" + value)) value];
	}
}
