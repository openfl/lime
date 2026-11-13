import haxe.xml.Access;
import utest.Assert;
import utest.Test;

/**
	`<config />` and `<config:android />`, from the "config" entry of Lime's XML format
	documentation and its Android options (https://lime.openfl.org/docs/project-files/xml-format/config/),
	and the 8.4.0 changelog: "Added project.xml support for Android manifest tags and Gradle
	plugin entries". The Android tools read Gradle plugins as `android.gradle-apply-plugin`,
	and copy the tags inside `<manifest>`, `<application>` and `<activity>` into AndroidManifest.xml.
**/
class ConfigTest extends Test
{
	private var fixture:Fixture;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		fixture = new Fixture();
		fixture.target = ANDROID;
	}

	public function teardown():Void
	{
		fixture.dispose();
	}

	// <config:android install-location="preferExternal" /> <config:android target-sdk-version="16" /> <config:ios deployment="5.1" />
	public function testConfigSetsPlatformValues():Void
	{
		var project = fixture.parse('<project>
			<config:android install-location="preferExternal" />
			<config:android target-sdk-version="16" />
			<config:ios deployment="5.1" />
		</project>');

		Assert.equals("preferExternal", project.config.getString("android.install-location"));
		Assert.equals(16, project.config.getInt("android.target-sdk-version"));
		Assert.equals("5.1", project.config.getString("ios.deployment"));
	}

	// <config:android permission="android.permission.INTERNET" /> <config:android permission="android.permission.ACCESS_NETWORK_STATE" />
	public function testEveryPermissionIsKept():Void
	{
		var project = fixture.parse('<project>
			<config:android permission="android.permission.INTERNET" />
			<config:android permission="android.permission.ACCESS_NETWORK_STATE" />
		</project>');

		Fixture.assertSame(["android.permission.INTERNET", "android.permission.ACCESS_NETWORK_STATE"], project.config.getArrayString("android.permission"));
	}

	// "If you define the same value more than once, the last definition will be used."
	public function testTheLastValueIsUsed():Void
	{
		var project = fixture.parse('<project>
			<config:android target-sdk-version="30" />
			<config:android target-sdk-version="34" />
		</project>');

		Assert.equals(34, project.config.getInt("android.target-sdk-version"));
	}

	// <echo value="Android config info: ${config.android.target-sdk-version} ${config.android.minimum-sdk-version}" />
	public function testConfigValuesCanBeSubstituted():Void
	{
		var project = fixture.parse('<project>
			<config:android target-sdk-version="34" minimum-sdk-version="21" />
			<set name="info" value="Android config info: $${config.android.target-sdk-version} $${config.android.minimum-sdk-version}" />
		</project>');

		Assert.equals("Android config info: 34 21", project.defines.get("info"));
	}

	public function testConfigValuesCanUseSubstitution():Void
	{
		var project = fixture.parse('<project>
			<set name="sdk" value="34" />
			<config:android target-sdk-version="$${sdk}" />
		</project>');

		Assert.equals(34, project.config.getInt("android.target-sdk-version"));
	}

	// <config:android gradle-version="7.4.2" /> <config:android gradle-plugin="7.3.1" />
	public function testGradleVersions():Void
	{
		var project = fixture.parse('<project>
			<config:android gradle-version="7.4.2" />
			<config:android gradle-plugin="7.3.1" />
		</project>');

		Assert.equals("7.4.2", project.config.getString("android.gradle-version"));
		Assert.equals("7.3.1", project.config.getString("android.gradle-plugin"));
	}

	// <config:android><application android:appCategory="game" android:supportsRtl="true" />
	// <activity android:immersive="false" /><activity android:persistableMode="persistAcrossReboots" /></config:android>
	public function testApplicationAndActivityAttributes():Void
	{
		var project = fixture.parse('<project>
			<config:android>
				<application android:appCategory="game" android:supportsRtl="true" />
				<activity android:immersive="false" />
				<activity android:persistableMode="persistAcrossReboots" />
			</config:android>
		</project>');

		var application = project.config.getKeyValueArray("android.application");
		var activity = project.config.getKeyValueArray("android.activity");

		Assert.equals("game", Fixture.valueOf(application, "android:appCategory"));
		Assert.equals("true", Fixture.valueOf(application, "android:supportsRtl"));
		Assert.equals("false", Fixture.valueOf(activity, "android:immersive"));
		Assert.equals("persistAcrossReboots", Fixture.valueOf(activity, "android:persistableMode"));
	}

	// "Repeating an attribute overwrites the previous value. ...Even if the previous value was set by Lime.
	// Passing an empty string removes that attribute."
	public function testAttributesCanBeOverwrittenAndRemoved():Void
	{
		var project = fixture.parse('<project>
			<config:android>
				<application android:appCategory="game" />
				<activity android:persistableMode="persistAcrossReboots" />
			</config:android>
			<config:android>
				<activity android:persistableMode="persistNever" />
				<application android:theme="@android:style/Theme.Fullscreen" />
				<application android:appCategory="" />
			</config:android>
		</project>');

		// Lime's own values are the defaults given to getKeyValueArray
		var application = project.config.getKeyValueArray("android.application", {"android:theme": "@android:style/Theme.NoTitleBar"});
		var activity = project.config.getKeyValueArray("android.activity");

		Assert.equals("persistNever", Fixture.valueOf(activity, "android:persistableMode"));
		Assert.equals("@android:style/Theme.Fullscreen", Fixture.valueOf(application, "android:theme"));
		var category = Fixture.valueOf(application, "android:appCategory");
		Assert.isTrue(category == null || category == "", "appCategory is still \"" + category + "\"");
	}

	// <gradle-properties org.gradle.jvmargs='-Xmx512m "-XX:MaxMetaspaceSize=384m"' />
	public function testGradlePropertiesAsAttributes():Void
	{
		var project = fixture.parse('<project>
			<config:android>
				<gradle-properties org.gradle.jvmargs=\'-Xmx512m "-XX:MaxMetaspaceSize=384m"\' />
			</config:android>
		</project>');

		var properties = project.config.getKeyValueArray("android.gradle-properties");

		Assert.equals(1, properties.length);
		Assert.equals('-Xmx512m "-XX:MaxMetaspaceSize=384m"', Fixture.valueOf(properties, "org.gradle.jvmargs"));
	}

	// <gradle-properties><org.gradle.project.myProperty>'hello' "world"</org.gradle.project.myProperty></gradle-properties>
	public function testGradlePropertiesAsElements():Void
	{
		var project = fixture.parse('<project>
			<config:android>
				<gradle-properties>
					<org.gradle.project.myProperty>\'hello\' "world"</org.gradle.project.myProperty>
				</gradle-properties>
			</config:android>
		</project>');

		var properties = project.config.getKeyValueArray("android.gradle-properties");

		Assert.equals(1, properties.length);
		Assert.equals('\'hello\' "world"', Fixture.valueOf(properties, "org.gradle.project.myProperty"));
	}

	public function testGradlePluginEntriesAreAllKept():Void
	{
		var project = fixture.parse('<project>
			<config:android gradle-apply-plugin="com.google.gms.google-services" />
			<config:android gradle-apply-plugin="com.google.firebase.crashlytics" />
		</project>');

		Fixture.assertSame(["com.google.gms.google-services", "com.google.firebase.crashlytics"],
			project.config.getArrayString("android.gradle-apply-plugin"));
	}

	public function testManifestTagsAreCopiedIntoTheManifest():Void
	{
		var project = fixture.parse('<project>
			<config:android>
				<manifest>
					<uses-permission android:name="android.permission.CAMERA" android:maxSdkVersion="28" />
				</manifest>
			</config:android>
		</project>');

		var tags = tagsIn(project, "android.manifest");

		Assert.equals(1, tags.length);
		if (tags.length > 0)
		{
			Assert.equals("uses-permission", tags[0].name);
			Assert.equals("android.permission.CAMERA", tags[0].x.get("android:name"));
			Assert.equals("28", tags[0].x.get("android:maxSdkVersion"));
		}
	}

	public function testApplicationAndActivityTagsAreCopied():Void
	{
		var project = fixture.parse('<project>
			<config:android>
				<application>
					<meta-data android:name="com.example.key" android:value="abc" />
				</application>
				<activity>
					<intent-filter>
						<action android:name="android.intent.action.VIEW" />
					</intent-filter>
				</activity>
			</config:android>
		</project>');

		var application = tagsIn(project, "android.application");
		var activity = tagsIn(project, "android.activity");

		Assert.equals(1, application.length);
		Assert.equals(1, activity.length);

		if (application.length > 0)
		{
			Assert.equals("meta-data", application[0].name);
			Assert.equals("abc", application[0].x.get("android:value"));
		}

		if (activity.length > 0)
		{
			Assert.equals("intent-filter", activity[0].name);
			Assert.equals("android.intent.action.VIEW", activity[0].node.action.x.get("android:name"));
		}
	}

	public function testManifestTagsFromAnIncludedFileAreKept():Void
	{
		fixture.write("android.xml", '<project>
			<config:android>
				<manifest>
					<uses-feature android:name="android.hardware.camera" />
				</manifest>
				<application android:appCategory="game" />
			</config:android>
		</project>');

		var project = fixture.parse('<project>
			<config:android>
				<manifest>
					<uses-permission android:name="android.permission.CAMERA" />
				</manifest>
			</config:android>
			<include path="android.xml" />
		</project>');

		Fixture.assertSame(["uses-permission", "uses-feature"], [for (tag in tagsIn(project, "android.manifest")) tag.name]);
		Assert.equals("game", Fixture.valueOf(project.config.getKeyValueArray("android.application"), "android:appCategory"));
	}

	// "every node in the project file format supports if and unless attributes"
	@Ignored("Waiting on #2160")
	public function testApplicationAttributesHonourIf():Void
	{
		var project = fixture.parse('<project>
			<config:android>
				<application android:debuggable="true" if="never-set" />
				<application android:appCategory="game" unless="never-set" />
			</config:android>
		</project>');

		var application = project.config.getKeyValueArray("android.application");

		Assert.isFalse(Fixture.hasKey(application, "android:debuggable"));
		Assert.equals("game", Fixture.valueOf(application, "android:appCategory"));
		Assert.isFalse(Fixture.hasKey(application, "if"));
		Assert.isFalse(Fixture.hasKey(application, "unless"));
	}

	@Ignored("Waiting on #2160")
	public function testGradlePropertiesHonourIf():Void
	{
		var project = fixture.parse('<project>
			<config:android>
				<gradle-properties org.gradle.caching="true" if="android" />
			</config:android>
		</project>');

		var properties = project.config.getKeyValueArray("android.gradle-properties");

		Assert.equals("true", Fixture.valueOf(properties, "org.gradle.caching"));
		Assert.isFalse(Fixture.hasKey(properties, "if"));
	}

	@Ignored("Waiting on #2160")
	public function testManifestTagsHonourIf():Void
	{
		var project = fixture.parse('<project>
			<config:android>
				<manifest>
					<uses-permission android:name="android.permission.CAMERA" if="never-set" />
					<uses-permission android:name="android.permission.INTERNET" />
				</manifest>
			</config:android>
		</project>');

		var tags = tagsIn(project, "android.manifest");

		Fixture.assertSame(["android.permission.INTERNET"], [for (tag in tags) tag.x.get("android:name")]);
	}

	/**
		The tags the Android template copies into one of AndroidManifest.xml's elements.
	**/
	private function tagsIn(project:lime.tools.HXProject, id:String):Array<Access>
	{
		var children:Array<String> = project.config.get(id).xmlChildren;
		return [for (child in children) new Access(Xml.parse(child).firstElement())];
	}
}
