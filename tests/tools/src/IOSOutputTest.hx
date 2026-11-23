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
