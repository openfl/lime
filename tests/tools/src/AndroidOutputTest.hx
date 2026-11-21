import haxe.xml.Access;
import hxp.Path;
import utest.Assert;
import utest.Test;

/**
	What `lime update android` writes from templates/android: AndroidManifest.xml and the
	Gradle files. The settings come from Lime's Android config documentation
	(https://lime.openfl.org/docs/project-files/xml-format/config/) and the 8.4.0 changelog:
	"Added `<config:android vulkan-required="false" />` to let Vulkan applications install on
	devices without Vulkan, and `<config:android vulkan-version="..." />`", "Added project.xml
	support for Android manifest tags and Gradle plugin entries" and "Fixed
	`::ANDROID_INSTALL_LOCATION::` in Android manifest templates copied from Lime 8.3 and
	earlier". The manifest is read as strict XML, as the Android build tools read it.
**/
class AndroidOutputTest extends Test
{
	private static inline var MANIFEST = "bin/app/src/main/AndroidManifest.xml";

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

		output = new PlatformFixture(fixture);
	}

	public function teardown():Void
	{
		fixture.dispose();
	}

	// <meta title="My Application" package="com.example.myapplication" version="1.0.0" />
	public function testTheManifestNamesTheVersion():Void
	{
		output.update('<project>
			<meta title="My Application" package="com.example.myapplication" version="1.2.3" build-number="42" />
			<app main="Main" file="MyApplication" />
		</project>');

		var manifest = manifest();

		Assert.equals("manifest", manifest.name);
		Assert.equals("http://schemas.android.com/apk/res/android", manifest.x.get("xmlns:android"));
		Assert.equals("1.2.3", manifest.x.get("android:versionName"));
		Assert.equals("42", manifest.x.get("android:versionCode"));
	}

	// <config:android install-location="preferExternal" />
	public function testInstallLocation():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
		</project>');

		Assert.equals("auto", manifest().x.get("android:installLocation"));

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:android install-location="preferExternal" />
		</project>');

		Assert.equals("preferExternal", manifest().x.get("android:installLocation"));
	}

	// CHANGELOG 8.4.0: "Fixed ::ANDROID_INSTALL_LOCATION:: in Android manifest templates copied from Lime 8.3 and earlier"
	public function testAManifestTemplateFromLime83GetsTheInstallLocation():Void
	{
		fixture.write("templates/android/template/app/src/main/AndroidManifest.xml", '<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android" android:installLocation="::ANDROID_INSTALL_LOCATION::" />');

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<template path="templates" />
		</project>');

		Assert.equals("auto", manifest().x.get("android:installLocation"));

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<template path="templates" />
			<config:android install-location="preferExternal" />
		</project>');

		Assert.equals("preferExternal", manifest().x.get("android:installLocation"));
	}

	// <config:android permission="android.permission.INTERNET" />
	public function testPermissionsAreUsesPermissionTags():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:android permission="android.permission.INTERNET" />
			<config:android permission="android.permission.CAMERA" />
		</project>');

		Fixture.assertSame(["android.permission.INTERNET", "android.permission.CAMERA"], permissions(manifest()));
	}

	public function testTheApplicationAndActivityAreLabelledWithTheTitle():Void
	{
		output.update('<project>
			<meta title="My Application" />
			<app main="Main" file="MyApplication" />
		</project>');

		var manifest = manifest();

		Assert.equals("My Application", manifest.node.application.x.get("android:label"));
		Assert.equals("My Application", manifest.node.application.node.activity.x.get("android:label"));
		Assert.equals("MainActivity", manifest.node.application.node.activity.x.get("android:name"));
	}

	// An attribute value in XML: "&", "<" and the quote that ends it have to be escaped
	public function testATitleWithSpecialCharactersKeepsTheManifestValid():Void
	{
		output.update('<project>
			<meta title="Tom &amp; Jerry&apos;s &quot;Big&quot; &lt;Adventure&gt;" />
			<app main="Main" file="MyApplication" />
		</project>');

		var manifest = manifest();

		Assert.equals("Tom & Jerry's \"Big\" <Adventure>", manifest.node.application.x.get("android:label"));
	}

	// <window orientation="portrait" />
	public function testOrientationLocksTheActivity():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<window orientation="portrait" />
		</project>');

		Assert.equals("sensorPortrait", activity().x.get("android:screenOrientation"));

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<window orientation="landscape" />
		</project>');

		Assert.equals("sensorLandscape", activity().x.get("android:screenOrientation"));
	}

	// "the default is auto which allows the operating system to decide which orientation to use"
	public function testAutoOrientationLeavesTheActivityUnlocked():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
		</project>');

		Assert.isFalse(activity().x.exists("android:screenOrientation"));
	}

	// <config:android><application android:appCategory="game" /><activity android:immersive="false" /></config:android>
	public function testApplicationAndActivityAttributesReachTheManifest():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:android>
				<application android:appCategory="game" android:supportsRtl="true" />
				<activity android:immersive="false" />
			</config:android>
		</project>');

		var manifest = manifest();

		Assert.equals("game", manifest.node.application.x.get("android:appCategory"));
		Assert.equals("true", manifest.node.application.x.get("android:supportsRtl"));
		Assert.equals("false", activity().x.get("android:immersive"));
	}

	// "Repeating an attribute overwrites the previous value. ...Even if the previous value was set by Lime.
	// Passing an empty string removes that attribute."
	public function testAttributesSetByLimeCanBeReplacedAndRemoved():Void
	{
		output.update('<project>
			<meta title="My Application" />
			<app main="Main" file="MyApplication" />
		</project>');

		Assert.equals("true", manifest().node.application.x.get("android:allowBackup"));
		Assert.equals("singleTask", activity().x.get("android:launchMode"));

		output.update('<project>
			<meta title="My Application" />
			<app main="Main" file="MyApplication" />
			<config:android>
				<application android:label="Renamed" android:allowBackup="" />
				<activity android:launchMode="standard" />
			</config:android>
		</project>');

		var manifest = manifest();

		Assert.equals("Renamed", manifest.node.application.x.get("android:label"));
		Assert.isFalse(manifest.node.application.x.exists("android:allowBackup"));
		Assert.equals("standard", activity().x.get("android:launchMode"));
	}

	// CHANGELOG 8.4.0: "Added project.xml support for Android manifest tags"
	public function testManifestTagsAreWrittenWhereTheyBelong():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:android>
				<manifest>
					<uses-feature android:name="android.hardware.camera" android:required="false" />
				</manifest>
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

		var manifest = manifest();
		var features = [for (feature in manifest.nodes.resolve("uses-feature")) feature.x.get("android:name")];

		Assert.contains("android.hardware.camera", features);

		var metaData = [for (data in manifest.node.application.nodes.resolve("meta-data")) data.x.get("android:name")];

		Assert.contains("com.example.key", metaData);

		var actions = [];

		for (filter in activity().nodes.resolve("intent-filter"))
		{
			for (action in filter.nodes.action)
			{
				actions.push(action.x.get("android:name"));
			}
		}

		// The launcher filter is Lime's own
		Assert.contains("android.intent.action.MAIN", actions);
		Assert.contains("android.intent.action.VIEW", actions);
	}

	// Without Vulkan the application needs OpenGL ES 2
	public function testOpenGLIsRequiredWithoutVulkan():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
		</project>');

		var manifest = manifest();

		Assert.isNull(vulkanFeature(manifest));

		var versions = [for (feature in manifest.nodes.resolve("uses-feature")) if (feature.x.exists("android:glEsVersion")) feature.x.get("android:glEsVersion")];

		Fixture.assertSame(["0x00020000"], versions);
	}

	// CHANGELOG 8.4.0: "Added the vulkan define, which makes Vulkan the default"
	public function testVulkanIsRequiredByDefaultInAVulkanBuild():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<define name="vulkan" />
			<define name="lime-vulkan" />
		</project>');

		var feature = vulkanFeature(manifest());

		Assert.notNull(feature);
		if (feature == null) return;

		Assert.equals("true", feature.x.get("android:required"));
		// android.hardware.vulkan.version takes a Vulkan version number, such as 0x400003 for 1.0.3
		Assert.isTrue(~/^0x[0-9A-Fa-f]+$/.match(feature.x.get("android:version")));
	}

	// "Added <config:android vulkan-required="false" /> to let Vulkan applications install on devices without Vulkan"
	public function testVulkanRequiredFalseLetsTheApplicationInstallWithoutVulkan():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<define name="vulkan" />
			<define name="lime-vulkan" />
			<config:android vulkan-required="false" />
		</project>');

		var feature = vulkanFeature(manifest());

		Assert.notNull(feature);
		if (feature != null) Assert.equals("false", feature.x.get("android:required"));
	}

	// "...and <config:android vulkan-version="..." />"
	public function testVulkanVersionIsConfigurable():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<define name="vulkan" />
			<define name="lime-vulkan" />
			<config:android vulkan-version="0x401000" />
		</project>');

		var feature = vulkanFeature(manifest());

		Assert.notNull(feature);
		if (feature != null) Assert.equals("0x401000", feature.x.get("android:version"));
	}

	// The Vulkan settings change nothing in a build without Vulkan
	public function testVulkanSettingsAreUnusedWithoutVulkan():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:android vulkan-required="false" vulkan-version="0x401000" />
		</project>');

		Assert.isNull(vulkanFeature(manifest()));
	}

	// CHANGELOG 8.4.0: "Added project.xml support for ... Gradle plugin entries"
	public function testGradlePluginEntriesAreApplied():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:android gradle-apply-plugin="com.google.gms.google-services" />
			<config:android gradle-apply-plugin="com.google.firebase.crashlytics" />
		</project>');

		var lines = lines(output.read("bin/app/build.gradle"));

		Assert.contains("apply plugin: 'com.android.application'", lines);
		Assert.contains("apply plugin: 'com.google.gms.google-services'", lines);
		Assert.contains("apply plugin: 'com.google.firebase.crashlytics'", lines);
		// A plugin for Android applications is applied after the Android plugin
		Assert.isTrue(lines.indexOf("apply plugin: 'com.android.application'") < lines.indexOf("apply plugin: 'com.google.gms.google-services'"));
	}

	public function testNoPluginIsAppliedUnlessAsked():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
		</project>');

		var applied = [for (line in lines(output.read("bin/app/build.gradle"))) if (StringTools.startsWith(line, "apply plugin:")) line];

		Fixture.assertSame(["apply plugin: 'com.android.application'"], applied);
	}

	// <config:android gradle-version="7.4.2" /> <config:android gradle-plugin="7.3.1" />
	public function testGradleVersions():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:android gradle-version="7.4.2" />
			<config:android gradle-plugin="7.3.1" />
		</project>');

		var build = output.read("bin/build.gradle");

		Assert.isTrue(build.indexOf("classpath 'com.android.tools.build:gradle:7.3.1'") > -1);
		Assert.isTrue(build.indexOf("gradleVersion = '7.4.2'") > -1);
		Assert.equals("https\\://services.gradle.org/distributions/gradle-7.4.2-bin.zip",
			properties(output.read("bin/gradle/wrapper/gradle-wrapper.properties")).get("distributionUrl"));
	}

	// Google Play requires API 36 for new apps and updates. Android lists plugin 8.9.1 as the
	// first for API 36, and plugin 8.9 needs Gradle 8.11.1
	public function testTheDefaultsTargetTheLevelGooglePlayRequires():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
		</project>');

		var properties = properties(output.read("bin/gradle.properties"));
		Assert.equals("36", properties.get("ANDROID_BUILD_TARGET_SDK_VERSION"));
		Assert.equals("36", properties.get("ANDROID_BUILD_SDK_VERSION"));

		var build = output.read("bin/build.gradle");
		Assert.isTrue(build.indexOf("classpath 'com.android.tools.build:gradle:8.9.1'") > -1);
		Assert.isTrue(build.indexOf("gradleVersion = '8.11.1'") > -1);
	}

	// From API 36, on screens 600dp wide both ways, Android ignores the orientation lock of an
	// app that isn't a game
	public function testTheApplicationIsAGameUnlessTheProjectSaysOtherwise():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<window orientation="landscape" />
		</project>');

		Assert.equals("game", manifest().node.application.x.get("android:appCategory"));

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:android>
				<application android:appCategory="productivity" />
			</config:android>
		</project>');

		Assert.equals("productivity", manifest().node.application.x.get("android:appCategory"));
	}

	// From API 36, Android 16 gives back presses only to an OnBackInvokedCallback. The class is
	// only in API 33 and later, so a project that compiles against an older one doesn't name it
	public function testBackReachesTheApplicationThroughAnOnBackInvokedCallback():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
		</project>');

		var activity = output.read("bin/app/src/main/java/org/haxe/lime/GameActivity.java");
		Assert.isTrue(activity.indexOf("registerOnBackInvokedCallback") > -1);
		Assert.isFalse(manifest().node.application.x.exists("android:enableOnBackInvokedCallback"));

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:android target-sdk-version="32" />
		</project>');

		activity = output.read("bin/app/src/main/java/org/haxe/lime/GameActivity.java");
		Assert.equals(-1, activity.indexOf("OnBackInvoked"));
	}

	// From API 35, Android 15 draws an application edge to edge, under the status and navigation
	// bars, and Android 16 doesn't let it opt out. A window that isn't fullscreen is kept clear of
	// them, as it was. The insets API is only in API 30 and later.
	public function testAWindowIsKeptClearOfTheSystemBarsFromAPI35():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
		</project>');

		var activity = output.read("bin/app/src/main/java/org/haxe/lime/GameActivity.java");
		Assert.isTrue(activity.indexOf("keepClearOfSystemBars ();") > -1, "the activity doesn't keep its window clear of the system bars");
		Assert.isTrue(activity.indexOf("WindowInsets.Type.systemBars ()") > -1);

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:android target-sdk-version="34" />
		</project>');

		activity = output.read("bin/app/src/main/java/org/haxe/lime/GameActivity.java");
		Assert.equals(-1, activity.indexOf("keepClearOfSystemBars"));
	}

	// The template asks whether the plugin is 4.0 or later, and 7.1 or later; version 10 is both
	public function testGradlePluginVersionsCompareAsVersions():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:android gradle-plugin="10.0.0" />
		</project>');

		var build = output.read("bin/app/build.gradle");

		Assert.isTrue(~/^\s*ndkPath '/m.match(build), "ndkPath, which plugins from 4.0 need, is not set");
		Assert.isTrue(build.indexOf("androidResources {") > -1, "aaptOptions is used, which plugins from 7.1 replace with androidResources");
		Assert.isFalse(properties(output.read("bin/local.properties")).exists("ndk.dir"));
	}

	// <config:android target-sdk-version="16" /> <config:android minimum-sdk-version="..." />
	public function testGradlePropertiesHoldTheVersionsAndSdkLevels():Void
	{
		output.update('<project>
			<meta version="1.2.3" build-number="42" />
			<app main="Main" file="MyApplication" />
			<config:android target-sdk-version="34" minimum-sdk-version="23" build-tools-version="34.0.0" />
		</project>');

		var properties = properties(output.read("bin/gradle.properties"));

		Assert.equals("1.2.3", properties.get("VERSION_NAME"));
		Assert.equals("42", properties.get("VERSION_CODE"));
		Assert.equals("34", properties.get("ANDROID_BUILD_TARGET_SDK_VERSION"));
		Assert.equals("34", properties.get("ANDROID_BUILD_SDK_VERSION"));
		Assert.equals("23", properties.get("ANDROID_BUILD_MIN_SDK_VERSION"));
		Assert.equals("34.0.0", properties.get("ANDROID_BUILD_TOOLS_VERSION"));
	}

	// Without build-tools-version, the newest build tools the SDK has are used
	public function testBuildToolsVersionIsTheNewestInstalled():Void
	{
		for (version in ["9.0.1", "33.0.2", "35.0.0", "34.0.0", "36.0.0-rc1"])
		{
			sys.FileSystem.createDirectory(Path.combine(fixture.directory, "android-sdk/build-tools/" + version));
		}

		output.update('<project>
			<app main="Main" file="MyApplication" />
		</project>');

		Assert.equals("35.0.0", properties(output.read("bin/gradle.properties")).get("ANDROID_BUILD_TOOLS_VERSION"));
	}

	// <gradle-properties org.gradle.jvmargs='-Xmx512m "-XX:MaxMetaspaceSize=384m"' />
	public function testGradlePropertiesFromTheProjectAreWritten():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:android>
				<gradle-properties org.gradle.jvmargs=\'-Xmx512m "-XX:MaxMetaspaceSize=384m"\' org.gradle.caching="true" />
			</config:android>
		</project>');

		var properties = properties(output.read("bin/gradle.properties"));

		Assert.equals('-Xmx512m "-XX:MaxMetaspaceSize=384m"', properties.get("org.gradle.jvmargs"));
		Assert.equals("true", properties.get("org.gradle.caching"));
	}

	// <config:android useAndroidX="..." enableJetifier="..." />
	public function testAndroidXSettings():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:android useAndroidX="false" enableJetifier="true" />
		</project>');

		var properties = properties(output.read("bin/gradle.properties"));

		Assert.equals("false", properties.get("android.useAndroidX"));
		Assert.equals("true", properties.get("android.enableJetifier"));
	}

	// <config:android gradle-build-directory="..." />, "a workaround for Windows' file path length limit"
	public function testGradleBuildDirectory():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:android gradle-build-directory="D:/b" />
		</project>');

		Assert.isTrue(output.read("bin/build.gradle").indexOf('buildDir = "D:/b/MyApplication/$' + '{project.name}"') > -1);
	}

	public function testTheAppIsBuiltUnderItsPackageName():Void
	{
		output.update('<project>
			<meta package="com.example.myapplication" />
			<app main="Main" file="MyApplication" />
		</project>');

		var build = output.read("bin/app/build.gradle");

		Assert.isTrue(build.indexOf('namespace "com.example.myapplication"') > -1);
		Assert.isTrue(build.indexOf('applicationId "com.example.myapplication"') > -1);
		// The APK is named after the app file
		Assert.isTrue(build.indexOf('outputFileName =  "MyApplication-" + variant.buildType.name + ".apk"') > -1);

		var activity = output.read("bin/app/src/main/java/com/example/myapplication/MainActivity.java");

		Assert.isTrue(~/^package com\.example\.myapplication;/m.match(activity));
	}

	// <certificate path="to/certificate.crt" password="1234" alias="my-alias" alias-password="4321" />
	public function testTheCertificateSignsTheRelease():Void
	{
		fixture.write("to/release.keystore", "keystore");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<certificate path="to/release.keystore" password="12\\34" alias="my-alias" alias-password="4321" />
		</project>');

		var properties = properties(output.read("bin/gradle.properties"));

		// A backslash starts an escape in a properties file, so each one is doubled
		Assert.equals(Path.standardize(sys.FileSystem.fullPath(Path.combine(fixture.directory, "to/release.keystore"))),
			Path.standardize(sys.FileSystem.fullPath(StringTools.replace(properties.get("KEY_STORE"), "\\\\", "\\"))));
		Assert.equals("12\\\\34", properties.get("KEY_STORE_PASSWORD"));
		Assert.equals("my-alias", properties.get("KEY_STORE_ALIAS"));
		Assert.equals("4321", properties.get("KEY_STORE_ALIAS_PASSWORD"));
		Assert.isTrue(output.read("bin/app/build.gradle").indexOf("storeFile file(project.KEY_STORE)") > -1);
	}

	public function testAProjectWithoutACertificateHasNoKeyStore():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
		</project>');

		Assert.isFalse(properties(output.read("bin/gradle.properties")).exists("KEY_STORE"));
	}

	// <dependency name="example-sdk" path="dependencies/android/example-sdk" if="android" />
	public function testALibraryProjectDependencyIsIncluded():Void
	{
		fixture.write("dependencies/android/example-sdk/build.gradle", "apply plugin: 'com.android.library'");
		fixture.write("dependencies/android/example-sdk/src/Example.java", "class Example {}");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<dependency name="example-sdk" path="dependencies/android/example-sdk" if="android" />
		</project>');

		Assert.contains("include ':deps:example-sdk'", lines(output.read("bin/settings.gradle")));
		Assert.contains("implementation project(':deps:example-sdk')", lines(output.read("bin/app/build.gradle")));
		Assert.isTrue(output.exists("bin/deps/example-sdk/build.gradle"));
		Assert.isTrue(output.exists("bin/deps/example-sdk/src/Example.java"));
	}

	// <java path="to/classes" />
	public function testJavaPathsAreCopiedIntoTheSources():Void
	{
		fixture.write("to/classes/com/example/Helper.java", "package com.example; class Helper {}");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<java path="to/classes" />
		</project>');

		Assert.equals("package com.example; class Helper {}", output.read("bin/app/src/main/java/com/example/Helper.java"));
	}

	public function testAssetsAreCopiedIntoTheApplicationsAssets():Void
	{
		fixture.write("assets/data/level.txt", "level one");

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<assets path="assets/data" rename="data" />
		</project>');

		Assert.equals("level one", output.read("bin/app/src/main/assets/data/level.txt"));
	}

	private function activity():Access
	{
		return manifest().node.application.node.activity;
	}

	private function lines(text:String):Array<String>
	{
		return [for (line in text.split("\n")) StringTools.trim(line)];
	}

	private function manifest():Access
	{
		return new Access(PlatformFixture.xml(output.read(MANIFEST)).firstElement());
	}

	private function permissions(manifest:Access):Array<String>
	{
		return [for (permission in manifest.nodes.resolve("uses-permission")) permission.x.get("android:name")];
	}

	/**
		The keys and values of a Java properties file, with the values as they are written.
	**/
	private function properties(text:String):Map<String, String>
	{
		var properties = new Map<String, String>();

		for (line in text.split("\n"))
		{
			line = StringTools.trim(line);
			if (line == "" || StringTools.startsWith(line, "#")) continue;

			var equals = line.indexOf("=");
			if (equals > 0) properties.set(line.substr(0, equals), line.substr(equals + 1));
		}

		return properties;
	}

	private function vulkanFeature(manifest:Access):Access
	{
		for (feature in manifest.nodes.resolve("uses-feature"))
		{
			if (feature.x.get("android:name") == "android.hardware.vulkan.version") return feature;
		}

		return null;
	}
}
