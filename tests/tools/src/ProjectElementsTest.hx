import lime.tools.Architecture;
import lime.tools.AssetType;
import utest.Assert;
import utest.Test;

/**
	`<icon />`, `<architecture />`, `<dependency />`, `<ndll />`, `<module />` and `<template />`,
	from Lime's XML format documentation and the 8.4.0 changelog ("Fixed Android architecture
	parsing for x86_64 and x86_32"), and `HXProject.clone()` of what they set.
**/
class ProjectElementsTest extends Test
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

	// <icon path="icon.png" size="64" />
	public function testIconWithASizeIsSquare():Void
	{
		var project = fixture.parse('<project>
			<icon path="icon.png" size="64" />
		</project>');

		Assert.equals(1, project.icons.length);
		Assert.equals("icon.png", project.icons[0].path);
		Assert.equals(64, project.icons[0].size);
		Assert.equals(64, project.icons[0].width);
		Assert.equals(64, project.icons[0].height);
	}

	// <icon path="icon.png" width="96" height="96" />
	public function testIconWithAWidthAndHeight():Void
	{
		var project = fixture.parse('<project>
			<icon path="icon.png" width="96" height="96" />
		</project>');

		Assert.equals(96, project.icons[0].width);
		Assert.equals(96, project.icons[0].height);
	}

	// <icon path="icon.svg" />, which is resized to every size
	public function testIconWithoutASizeHasNone():Void
	{
		var project = fixture.parse('<project>
			<icon path="icon.svg" />
		</project>');

		Assert.equals("icon.svg", project.icons[0].path);
		Assert.equals(0, project.icons[0].size);
		Assert.equals(0, project.icons[0].width);
		Assert.equals(0, project.icons[0].height);
	}

	public function testEveryIconIsKept():Void
	{
		var project = fixture.parse('<project>
			<icon path="icon-16.png" size="16" />
			<icon path="icon-32.png" size="32" />
			<icon path="icon.svg" />
			<icon path="icon-ios.png" size="180" if="ios" />
		</project>');

		Fixture.assertSame(["icon-16.png", "icon-32.png", "icon.svg"], [for (icon in project.icons) icon.path]);
	}

	// <architecture name="armv6" exclude="armv7" if="android" />
	public function testArchitectureSetsAndExcludes():Void
	{
		fixture.target = ANDROID;

		var project = fixture.parse('<project>
			<architecture name="armv6" exclude="armv7" if="android" />
		</project>');

		Fixture.assertSame([Architecture.ARMV6], project.architectures);
		Fixture.assertSame([Architecture.ARMV7], project.excludeArchitectures);
	}

	// "such as arm64, armv7, x86, or x64"
	public function testArchitectureNames():Void
	{
		fixture.target = ANDROID;

		var project = fixture.parse('<project>
			<architecture name="armv7" />
			<architecture name="arm64" />
			<architecture name="x86" />
			<architecture name="x64" />
		</project>');

		Fixture.assertSame([Architecture.ARMV7, Architecture.ARM64, Architecture.X86, Architecture.X64], project.architectures);
	}

	// CHANGELOG 8.4.0: "Fixed Android architecture parsing for x86_64 and x86_32"
	public function testX86_64AndX86_32AreAndroidArchitectures():Void
	{
		fixture.target = ANDROID;

		var project = fixture.parse('<project>
			<architecture name="x86_64" />
			<architecture name="x86_32" />
		</project>');

		Fixture.assertSame([Architecture.X64, Architecture.X86], project.architectures);
	}

	public function testX86_64CanBeExcluded():Void
	{
		fixture.target = ANDROID;

		var project = fixture.parse('<project>
			<architecture exclude="x86_64" />
			<architecture exclude="x86_32" />
		</project>');

		Fixture.assertSame([Architecture.X64, Architecture.X86], project.excludeArchitectures);
		Fixture.assertSame([], project.architectures);
	}

	public function testAnArchitectureIsAddedOnce():Void
	{
		fixture.target = ANDROID;

		var project = fixture.parse('<project>
			<architecture name="x64" />
			<architecture name="x86_64" />
			<architecture name="arm64" />
			<architecture name="ARM64" />
		</project>');

		Fixture.assertSame([Architecture.X64, Architecture.ARM64], project.architectures);
	}

	// <dependency name="GameKit.framework" if="ios" />
	public function testDependencyNamesAFramework():Void
	{
		fixture.target = IOS;

		var project = fixture.parse('<project>
			<dependency name="GameKit.framework" if="ios" />
		</project>');

		Assert.equals(1, project.dependencies.length);
		Assert.equals("GameKit.framework", project.dependencies[0].name);
	}

	// <dependency name="example-sdk" path="dependencies/android/example-sdk" if="android" />
	public function testDependencyWithAPath():Void
	{
		fixture.target = ANDROID;

		var project = fixture.parse('<project>
			<dependency name="example-sdk" path="dependencies/android/example-sdk" if="android" />
			<dependency name="GameKit.framework" if="ios" />
		</project>');

		Assert.equals(1, project.dependencies.length);
		Assert.equals("example-sdk", project.dependencies[0].name);
		Assert.equals("dependencies/android/example-sdk", project.dependencies[0].path);
	}

	// "If you define the same value more than once, the last definition will be used."
	public function testRepeatedDependencyUsesTheLastDefinition():Void
	{
		fixture.target = ANDROID;

		var project = fixture.parse('<project>
			<dependency name="example-sdk" path="old/example-sdk" />
			<dependency name="example-sdk" path="new/example-sdk" />
		</project>');

		Assert.equals(1, project.dependencies.length);
		Assert.equals("new/example-sdk", project.dependencies[0].path);
	}

	// <ndll name="std" haxelib="hxcpp" />
	public function testNdllNamesItsHaxelib():Void
	{
		var project = fixture.parse('<project>
			<ndll name="std" haxelib="hxcpp" />
		</project>');

		Assert.equals(1, project.ndlls.length);
		Assert.equals("std", project.ndlls[0].name);
		Assert.equals("hxcpp", project.ndlls[0].haxelib.name);
	}

	// <module /> is undocumented ("More to come."); these follow the fields of ModuleData
	public function testModuleCollectsItsClassesAndFlags():Void
	{
		fixture.write("modsrc/pkg/Foo.hx", "package pkg; class Foo {}");

		var project = fixture.parse('<project>
			<module name="extras" source="modsrc">
				<class name="extra.Manual" />
				<haxedef name="EXTRA" value="1" />
				<haxeflag name="-dce" value="full" />
				<include type="extra.Kept" />
				<exclude type="extra.Dropped" />
				<class name="extra.Skipped" if="never-set" />
			</module>
		</project>');

		var module = project.modules.get("extras");

		Assert.notNull(module);
		if (module != null)
		{
			Fixture.assertSame(["pkg.Foo", "extra.Manual"], module.classNames);
			Fixture.assertSame(["-cp modsrc", "-D EXTRA=1", "-dce full"], module.haxeflags);
			Fixture.assertSame(["extra.Kept"], module.includeTypes);
			Fixture.assertSame(["extra.Dropped"], module.excludeTypes);
		}
	}

	public function testModulesWithTheSameNameAreMerged():Void
	{
		var project = fixture.parse('<project>
			<module name="extras">
				<class name="extra.A" />
			</module>
			<module name="extras">
				<class name="extra.B" />
			</module>
		</project>');

		Fixture.assertSame(["extra.A", "extra.B"], project.modules.get("extras").classNames);
	}

	// <template path="templates" />
	public function testTemplateFolderIsATemplatePath():Void
	{
		fixture.write("templates/haxe/ApplicationMain.hx", "");

		var project = fixture.parse('<project>
			<template path="templates" />
		</project>');

		Assert.contains("templates", project.templatePaths);
	}

	// <template path="Assets/index.html" rename="index.php" />
	public function testTemplateFileCanBeRenamed():Void
	{
		fixture.write("Assets/index.html", "<html></html>");

		var project = fixture.parse('<project>
			<template path="Assets/index.html" rename="index.php" />
		</project>');

		Assert.equals(1, project.assets.length);
		Assert.equals(AssetType.TEMPLATE, project.assets[0].type);
		Assert.equals("Assets/index.html", project.assets[0].sourcePath);
		Assert.equals("index.php", project.assets[0].targetPath);
	}

	@Ignored("Waiting on #2169")
	public function testCloneKeepsIconPriority():Void
	{
		var project = fixture.parse('<project>
			<icon path="icon.png" size="64" priority="2" />
		</project>');

		Assert.equals(2, project.icons[0].priority);
		Assert.equals(2, project.clone().icons[0].priority);
	}

	@Ignored("Waiting on #2169")
	public function testCloneKeepsDependencyOptions():Void
	{
		fixture.target = HTML5;

		var project = fixture.parse('<project>
			<dependency path="lib/worker.js" embed="true" allow-web-workers="true" />
		</project>');

		var clone = project.clone().dependencies[0];

		Assert.equals(true, clone.embed);
		Assert.equals(true, clone.allowWebWorkers);
	}

	@Ignored("Waiting on #2169")
	public function testCloneKeepsTheProjectFile():Void
	{
		var project = fixture.parse('<project />');

		Assert.equals("project.xml", project.projectFilePath);
		Assert.equals("project.xml", project.clone().projectFilePath);
	}
}
