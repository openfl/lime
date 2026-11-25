import utest.Assert;
import utest.Test;

/**
	What `lime update ios` writes from templates/ios: the application's Info.plist and the
	Xcode project. The plist is read as strict XML, as Xcode reads it.
**/
class IOSOutputTest extends Test
{
	private static inline var INFO_PLIST = "MyApplication/MyApplication-Info.plist";
	private static inline var PRIVACY_MANIFEST = "MyApplication/PrivacyInfo.xcprivacy";

	private var fixture:Fixture;
	private var output:PlatformFixture;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		fixture = new Fixture();
		fixture.target = IOS;
		fixture.write("Main.hx", "class Main {}");

		output = new PlatformFixture(fixture);
	}

	public function teardown():Void
	{
		fixture.dispose();
	}

	// Core Animation only runs above 60 Hz on a ProMotion iPhone with this key, which iPads don't
	// need. Without a window asking for more than 60 frames a second, the display link is left
	// at 60, so an application at 60 isn't woken for frames it skips.
	public function testAWindowAbove60FramesASecondCanUseProMotionOnIPhone():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
		</project>');

		Assert.isFalse(infoPlist().exists("CADisableMinimumFrameDurationOnPhone"));

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<window fps="120" />
		</project>');

		Assert.equals(true, infoPlist().get("CADisableMinimumFrameDurationOnPhone"));
	}

	// <config:ios high-frame-rate="..." /> decides for an application that changes its frame rate as it runs
	public function testHighFrameRateCanBeAskedForOrLeftOut():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:ios high-frame-rate="true" />
		</project>');

		Assert.equals(true, infoPlist().get("CADisableMinimumFrameDurationOnPhone"));

		output.update('<project>
			<app main="Main" file="MyApplication" />
			<window fps="120" />
			<config:ios high-frame-rate="false" />
		</project>');

		Assert.isFalse(infoPlist().exists("CADisableMinimumFrameDurationOnPhone"));
	}

	// App Store Connect refuses apps whose privacy manifest doesn't give a reason for each
	// required reason API they call. Lime's frame clock reads the system boot time, and
	// hxcpp's sys.FileSystem reads file timestamps.
	// The arm64 simulator is a platform of its own, so its libraries are kept apart from those of
	// arm64 devices, and the Xcode project finds them for simulator builds alone
	public function testArm64SimulatorLibrariesAreKeptApartFromArm64Devices():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
		</project>');

		var project = output.read("MyApplication.xcodeproj/project.pbxproj");
		Assert.isTrue(project.indexOf('"LIBRARY_SEARCH_PATHS[sdk=iphonesimulator*][arch=arm64]"') > -1);
		// Devices name their SDK too, or the simulator's setting would inherit their folder first
		Assert.isTrue(project.indexOf('"LIBRARY_SEARCH_PATHS[sdk=iphoneos*][arch=arm64]"') > -1);
		Assert.equals(-1, project.indexOf('"LIBRARY_SEARCH_PATHS[arch=arm64]"'));
		Assert.isTrue(project.indexOf('/MyApplication/lib/arm64-simulator') > -1);
		Assert.isTrue(project.indexOf('/MyApplication/lib/arm64-simulator-debug') > -1);

		var makefile = output.read("MyApplication/haxe/makefile");
		Assert.isTrue(makefile.indexOf("HXCPP_FLAGS_arm64 = -D simulator -D HXCPP_ARM64") > -1);
		Assert.isTrue(makefile.indexOf("LIBDIR_arm64 = arm64-simulator") > -1);
		Assert.isTrue(makefile.indexOf("../lib/$(LIBDIR_$*)$(LIB_DEST)") > -1);
	}

	// libhxcpp builds for the arm64 simulator, which hxcpp up to 4.3 does not
	public function testArm64SimulatorBuildsNeedAnHxcppThatMakesThem():Void
	{
		fixture.addHaxelib("toolstest-newhxcpp", "<project />", [
			"toolchain/finish-setup.xml" => '<xml><set name="LIBEXTRA" value=".iphonesim-arm64" if="HXCPP_ARM64"/></xml>'
		]);
		fixture.addHaxelib("toolstest-oldhxcpp", "<project />", [
			"toolchain/finish-setup.xml" => '<xml><set name="LIBEXTRA" value=".iphonesim-64" if="iphonesim"/></xml>'
		]);

		Assert.isTrue(lime.tools.IOSHelper.buildsArm64Simulator("toolstest-newhxcpp"));
		Assert.isFalse(lime.tools.IOSHelper.buildsArm64Simulator("toolstest-oldhxcpp"));
	}

	public function testX86_64CanBeAskedForInsteadOfTheArm64Simulator():Void
	{
		var project = fixture.parse('<project>
			<app main="Main" file="MyApplication" />
		</project>');
		project.targetFlags.set("simulator", "");
		project.targetFlags.set("x86_64", "");

		Assert.isFalse(lime.tools.IOSHelper.useArm64Simulator(project));
	}

	public function testThePrivacyManifestDeclaresTheAPIsLimeUses():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
		</project>');

		var types = accessedAPITypes();
		Fixture.assertSame(["35F9.1"], types.get("NSPrivacyAccessedAPICategorySystemBootTime"));
		Fixture.assertSame(["C617.1"], types.get("NSPrivacyAccessedAPICategoryFileTimestamp"));

		var manifest = Plist.parse(output.read(PRIVACY_MANIFEST));
		Assert.equals(false, manifest.get("NSPrivacyTracking"));

		// It is copied into the application, as the Xcode project's resources
		var project = output.read("MyApplication.xcodeproj/project.pbxproj");
		var phase = project.substring(project.indexOf("/* Begin PBXResourcesBuildPhase section */"), project.indexOf("/* End PBXResourcesBuildPhase section */"));
		Assert.isTrue(phase.indexOf("PrivacyInfo.xcprivacy in Resources") > -1, "the privacy manifest is not among the application's resources");
		Assert.isTrue(project.indexOf('path = "MyApplication/PrivacyInfo.xcprivacy"') > -1);
	}

	// <config:ios privacy-accessed-api="NSPrivacyAccessedAPICategoryUserDefaults CA92.1" />
	public function testAnApplicationCanDeclareAPIsOfItsOwn():Void
	{
		output.update('<project>
			<app main="Main" file="MyApplication" />
			<config:ios privacy-accessed-api="NSPrivacyAccessedAPICategoryUserDefaults CA92.1" />
			<config:ios privacy-accessed-api="NSPrivacyAccessedAPICategoryFileTimestamp 3B52.1" />
		</project>');

		var types = accessedAPITypes();
		Fixture.assertSame(["CA92.1"], types.get("NSPrivacyAccessedAPICategoryUserDefaults"));
		Fixture.assertSame(["C617.1", "3B52.1"], types.get("NSPrivacyAccessedAPICategoryFileTimestamp"));
		Fixture.assertSame(["35F9.1"], types.get("NSPrivacyAccessedAPICategorySystemBootTime"));
	}

	private function accessedAPITypes():Map<String, Array<String>>
	{
		var types = new Map<String, Array<String>>();
		var manifest = Plist.parse(output.read(PRIVACY_MANIFEST));
		var entries:Array<Dynamic> = manifest.get("NSPrivacyAccessedAPITypes");

		for (entry in entries)
		{
			var dict:Map<String, Dynamic> = entry;
			var reasons:Array<Dynamic> = dict.get("NSPrivacyAccessedAPITypeReasons");
			Assert.isFalse(types.exists(dict.get("NSPrivacyAccessedAPIType")), dict.get("NSPrivacyAccessedAPIType") + " is listed twice");
			types.set(dict.get("NSPrivacyAccessedAPIType"), [for (reason in reasons) (reason : String)]);
		}

		return types;
	}

	private function infoPlist():Map<String, Dynamic>
	{
		return Plist.parse(output.read(INFO_PLIST));
	}
}
