import haxe.xml.Access;
import lime.tools.ConfigData;
import utest.Assert;
import utest.Test;

/**
	`ConfigData`, which holds what `<config />` sets and is what HXP projects and the
	platform classes read with `project.config`. The expectations follow its method
	signatures and Lime's config documentation
	(https://lime.openfl.org/docs/project-files/xml-format/config/): a value is stored under
	a dotted path, a setting given more than once keeps every value for the settings that
	are lists (such as `permission`), and its last value otherwise.
**/
class ConfigDataTest extends Test
{
	public function new()
	{
		super();
	}

	public function testSetStoresAValueUnderADottedPath():Void
	{
		var config = new ConfigData();
		config.set("android.target-sdk-version", 34);

		Assert.isTrue(config.exists("android.target-sdk-version"));
		Assert.equals(34, config.get("android.target-sdk-version"));
		Assert.notNull(config.get("android"));
	}

	public function testMissingValuesDoNotExist():Void
	{
		var config = new ConfigData();
		config.set("android.target-sdk-version", 34);

		Assert.isFalse(config.exists("android.minimum-sdk-version"));
		Assert.isFalse(config.exists("ios.deployment"));
		Assert.isNull(config.get("ios.deployment"));
		// A path that continues past a value has nothing under it
		Assert.isFalse(config.exists("android.target-sdk-version.more"));
	}

	public function testSetReplacesAValue():Void
	{
		var config = new ConfigData();
		config.set("ios.deployment", "12.0");
		config.set("ios.deployment", "15.0");

		Assert.equals("15.0", config.getString("ios.deployment"));
		Fixture.assertSame(["15.0"], config.getArrayString("ios.deployment"));
	}

	public function testGettersReturnTheirDefaultsForMissingValues():Void
	{
		var config = new ConfigData();

		Assert.equals("", config.getString("ios.deployment"));
		Assert.equals("15.0", config.getString("ios.deployment", "15.0"));
		Assert.equals(0, config.getInt("android.minimum-sdk-version"));
		Assert.equals(21, config.getInt("android.minimum-sdk-version", 21));
		Assert.equals(0.0, config.getFloat("ios.deployment"));
		Assert.equals(13.0, config.getFloat("ios.deployment", 13));
		Assert.isTrue(config.getBool("tools.copy-ndlls"));
		Assert.isFalse(config.getBool("ios.enable-bitcode", false));
		Fixture.assertSame([], config.getArray("android.permission"));
		Fixture.assertSame(["a"], config.getArray("android.permission", ["a"]));
		Fixture.assertSame([], config.getArrayString("android.permission"));
		Fixture.assertSame(["a"], config.getArrayString("android.permission", null, ["a"]));
	}

	// Values read from XML are text, so the typed getters parse them
	public function testTypedGettersParseText():Void
	{
		var config = new ConfigData();
		config.set("android.target-sdk-version", "34");
		config.set("ios.deployment", "9.5");
		config.set("ios.enable-bitcode", "true");
		config.set("ios.non-exempt-encryption", "false");

		Assert.equals(34, config.getInt("android.target-sdk-version"));
		Assert.equals(9.5, config.getFloat("ios.deployment"));
		Assert.equals("9.5", config.getString("ios.deployment"));
		Assert.isTrue(config.getBool("ios.enable-bitcode", false));
		Assert.isFalse(config.getBool("ios.non-exempt-encryption", true));
	}

	// An HXP project sets values in Haxe, where a number is a number
	public function testTypedGettersReadHaxeValues():Void
	{
		var config = new ConfigData();
		config.set("android.target-sdk-version", 34);
		config.set("ios.deployment", 9.5);

		Assert.equals(34, config.getInt("android.target-sdk-version"));
		Assert.equals("34", config.getString("android.target-sdk-version"));
		Assert.equals(9.5, config.getFloat("ios.deployment"));
	}

	// ...and a Bool is a Bool: project.config.set("ios.enable-bitcode", true)
	public function testGetBoolReadsABoolValue():Void
	{
		var config = new ConfigData();
		config.set("ios.enable-bitcode", true);
		config.set("android.vulkan-required", false);

		Assert.isTrue(config.getBool("ios.enable-bitcode", false));
		Assert.isFalse(config.getBool("android.vulkan-required", true));
	}

	public function testPushKeepsEveryValue():Void
	{
		var config = new ConfigData();
		config.push("android.permission", "android.permission.INTERNET");
		config.push("android.permission", "android.permission.VIBRATE");
		config.push("android.permission", "android.permission.CAMERA");

		Fixture.assertSame([
			"android.permission.INTERNET",
			"android.permission.VIBRATE",
			"android.permission.CAMERA"
		], config.getArrayString("android.permission"));

		// A getter for one value returns the last one
		Assert.equals("android.permission.CAMERA", config.getString("android.permission"));
	}

	public function testASingleValueIsAnArrayOfOne():Void
	{
		var config = new ConfigData();
		config.push("ios.linker-flags", "-ObjC");

		Fixture.assertSame(["-ObjC"], config.getArrayString("ios.linker-flags"));

		config.set("android.extension", "org.haxe.extension.Example");

		Fixture.assertSame(["org.haxe.extension.Example"], config.getArray("android.extension"));
	}

	public function testPushUniqueSkipsAValueItHolds():Void
	{
		var config = new ConfigData();
		config.push("ios.linker-flags", "-ObjC", true);
		config.push("ios.linker-flags", "-lz", true);
		config.push("ios.linker-flags", "-ObjC", true);
		config.push("ios.linker-flags", "-lz", true);

		Fixture.assertSame(["-ObjC", "-lz"], config.getArrayString("ios.linker-flags"));
	}

	public function testPushWithoutUniqueKeepsRepeats():Void
	{
		var config = new ConfigData();
		config.push("ios.linker-flags", "-ObjC");
		config.push("ios.linker-flags", "-ObjC");

		Fixture.assertSame(["-ObjC", "-ObjC"], config.getArrayString("ios.linker-flags"));
	}

	public function testGetArrayStringCanReadAFieldOfEachItem():Void
	{
		var config = new ConfigData();
		config.push("air.extension", {name: "com.example.One", path: "one.ane"});
		config.push("air.extension", {name: "com.example.Two", path: "two.ane"});

		Fixture.assertSame(["com.example.One", "com.example.Two"], config.getArrayString("air.extension", "name"));
		Fixture.assertSame(["one.ane", "two.ane"], config.getArrayString("air.extension", "path"));
	}

	// Lime's own values are the defaults, and the project's values replace them
	public function testKeyValueArrayPutsProjectValuesOverDefaults():Void
	{
		var config = new ConfigData();
		config.set("android.application", {"android:theme": "@style/Custom", "android:appCategory": "game"});

		var pairs = config.getKeyValueArray("android.application", {"android:theme": "@android:style/Theme.NoTitleBar", "android:allowBackup": "true"});

		Assert.equals(3, pairs.length);
		Assert.equals("@style/Custom", Fixture.valueOf(pairs, "android:theme"));
		Assert.equals("true", Fixture.valueOf(pairs, "android:allowBackup"));
		Assert.equals("game", Fixture.valueOf(pairs, "android:appCategory"));
	}

	public function testKeyValueArrayOfAMissingValueIsItsDefaults():Void
	{
		var config = new ConfigData();

		Fixture.assertSame([], config.getKeyValueArray("android.gradle-properties"));

		var pairs = config.getKeyValueArray("android.gradle-properties", {"org.gradle.caching": "true"});

		Assert.equals(1, pairs.length);
		Assert.equals("true", Fixture.valueOf(pairs, "org.gradle.caching"));
	}

	// The list of every value a key was given is kept beside its last value, which is not a key of its own
	public function testKeyValueArrayHasOneEntryForARepeatedKey():Void
	{
		var config = new ConfigData();
		config.push("android.gradle-properties.org.gradle.jvmargs", "-Xmx512m");
		config.push("android.gradle-properties.org.gradle.jvmargs", "-Xmx2048m");

		// The dots of the property's name are path separators here, so read it as a path too
		var pairs = config.getKeyValueArray("android.gradle-properties.org.gradle");

		Assert.equals(1, pairs.length);
		Assert.equals("-Xmx2048m", Fixture.valueOf(pairs, "jvmargs"));
	}

	public function testMergeAddsValuesTheConfigLacks():Void
	{
		var config = new ConfigData();
		config.set("android.target-sdk-version", 34);

		var other = new ConfigData();
		other.set("android.minimum-sdk-version", 21);
		other.set("ios.deployment", "15.0");

		config.merge(other);

		Assert.equals(34, config.getInt("android.target-sdk-version"));
		Assert.equals(21, config.getInt("android.minimum-sdk-version"));
		Assert.equals("15.0", config.getString("ios.deployment"));
	}

	public function testMergeOfNothingChangesNothing():Void
	{
		var config = new ConfigData();
		config.set("ios.deployment", "15.0");
		config.merge(null);

		Assert.equals("15.0", config.getString("ios.deployment"));
	}

	// "If you define the same value more than once, the last definition will be used."
	public function testMergedValueIsTheLastDefinition():Void
	{
		var config = new ConfigData();
		config.set("android.target-sdk-version", 30);

		var other = new ConfigData();
		other.set("android.target-sdk-version", 34);

		config.merge(other);

		Assert.equals(34, config.getInt("android.target-sdk-version"));
	}

	// <config:android permission="..." /> in a project and in a file it includes
	public function testMergeKeepsTheValuesOfBothLists():Void
	{
		var config = new ConfigData();
		config.push("android.permission", "android.permission.INTERNET");
		config.push("android.permission", "android.permission.VIBRATE");

		var other = new ConfigData();
		other.push("android.permission", "android.permission.CAMERA");
		other.push("android.permission", "android.permission.RECORD_AUDIO");

		config.merge(other);

		Fixture.assertSame([
			"android.permission.INTERNET",
			"android.permission.VIBRATE",
			"android.permission.CAMERA",
			"android.permission.RECORD_AUDIO"
		], config.getArrayString("android.permission"));
	}

	public function testMergeAddsASingleValueToAList():Void
	{
		var config = new ConfigData();
		config.push("android.permission", "android.permission.INTERNET");
		config.push("android.permission", "android.permission.VIBRATE");

		var other = new ConfigData();
		other.set("android.permission", "android.permission.CAMERA");

		config.merge(other);

		Fixture.assertSame([
			"android.permission.INTERNET",
			"android.permission.VIBRATE",
			"android.permission.CAMERA"
		], config.getArrayString("android.permission"));
	}

	// Two lists that happen to end with the same value are still two lists
	public function testMergeKeepsEarlierValuesWhenBothListsEndAlike():Void
	{
		var config = new ConfigData();
		config.push("android.permission", "android.permission.INTERNET");
		config.push("android.permission", "android.permission.VIBRATE");

		var other = new ConfigData();
		other.push("android.permission", "android.permission.CAMERA");
		other.push("android.permission", "android.permission.VIBRATE");

		config.merge(other);

		var permissions = config.getArrayString("android.permission");

		Assert.contains("android.permission.INTERNET", permissions);
		Assert.contains("android.permission.CAMERA", permissions);
		Assert.contains("android.permission.VIBRATE", permissions);
	}

	public function testMergeDoesNotChangeTheOtherConfig():Void
	{
		var config = new ConfigData();
		config.push("android.permission", "android.permission.INTERNET");

		var other = new ConfigData();
		other.push("android.permission", "android.permission.CAMERA");
		other.set("ios.deployment", "15.0");

		config.merge(other);

		Fixture.assertSame(["android.permission.CAMERA"], other.getArrayString("android.permission"));
		Assert.equals("15.0", other.getString("ios.deployment"));
	}

	public function testCloneIsIndependent():Void
	{
		var config = new ConfigData();
		config.set("android.target-sdk-version", 34);
		config.push("android.permission", "android.permission.INTERNET");
		config.push("android.permission", "android.permission.VIBRATE");

		var clone = config.clone();
		clone.set("android.target-sdk-version", 35);
		clone.push("android.permission", "android.permission.CAMERA");

		Assert.equals(34, config.getInt("android.target-sdk-version"));
		Fixture.assertSame(["android.permission.INTERNET", "android.permission.VIBRATE"], config.getArrayString("android.permission"));
		Assert.equals(35, clone.getInt("android.target-sdk-version"));
		Assert.equals(3, clone.getArrayString("android.permission").length);
	}

	// <config:ios deployment="5.1" />
	public function testParseStoresAttributesUnderThePlatform():Void
	{
		var config = new ConfigData();
		config.parse(element('<config:ios deployment="5.1" device="iphone" />'));

		Assert.equals("5.1", config.getString("ios.deployment"));
		Assert.equals("iphone", config.getString("ios.device"));
	}

	public function testParseKeepsEveryValueOfARepeatedAttribute():Void
	{
		var config = new ConfigData();
		config.parse(element('<config:ios linker-flags="-ObjC" />'));
		config.parse(element('<config:ios linker-flags="-lz" />'));

		Fixture.assertSame(["-ObjC", "-lz"], config.getArrayString("ios.linker-flags"));
		Assert.equals("-lz", config.getString("ios.linker-flags"));
	}

	// <config:project><rebuild path="project" file="Build.xml" fullDebug="true" /></config:project>
	public function testParseStoresAChildElementAsAGroup():Void
	{
		var config = new ConfigData();
		config.parse(element('<config:project><rebuild path="project" file="Build.xml" fullDebug="true" /></config:project>'));

		Assert.equals("project", config.getString("project.rebuild.path"));
		Assert.equals("Build.xml", config.getString("project.rebuild.file"));
		Assert.isTrue(config.getBool("project.rebuild.fullDebug", false));
	}

	// <gradle-properties><org.gradle.project.myProperty>value</org.gradle.project.myProperty></gradle-properties>
	public function testParseStoresTheTextOfAChildElement():Void
	{
		var config = new ConfigData();
		config.parse(element('<config:android><gradle-properties><org.gradle.daemon>false</org.gradle.daemon></gradle-properties></config:android>'));

		var properties = config.getKeyValueArray("android.gradle-properties");

		Assert.equals(1, properties.length);
		Assert.equals("false", Fixture.valueOf(properties, "org.gradle.daemon"));
	}

	public function testParseSubstitutesValues():Void
	{
		var config = new ConfigData();

		config.parse(element('<config:ios deployment="$${version}"><identity>$${name}</identity></config:ios>'), function(value:String):String
		{
			return StringTools.replace(StringTools.replace(value, "${version}", "15.0"), "${name}", "iPhone Developer");
		});

		Assert.equals("15.0", config.getString("ios.deployment"));
		Assert.equals("iPhone Developer", config.getString("ios.identity"));
	}

	// A value is not given the place of a group of values: <config:android application="x" /> leaves the application's attributes alone
	public function testAValueDoesNotReplaceAGroup():Void
	{
		var config = new ConfigData();
		config.parse(element('<config:android><application android:appCategory="game" /></config:android>'));
		config.parse(element('<config:android application="oops" />'));

		Assert.equals("game", Fixture.valueOf(config.getKeyValueArray("android.application"), "android:appCategory"));

		var other = new ConfigData();
		other.set("android.application", "oops");
		config.merge(other);

		Assert.equals("game", Fixture.valueOf(config.getKeyValueArray("android.application"), "android:appCategory"));
	}

	private function element(xml:String):Access
	{
		return new Access(Xml.parse(xml).firstElement());
	}
}
