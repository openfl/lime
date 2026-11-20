import utest.Assert;
import utest.Test;

/**
	What `lime update mac` and `lime update ios` write into Info.plist for the
	`<config:mac>` and `<config:ios>` usage descriptions, which macOS and iOS
	show when an application first opens the camera or microphone, and without
	which they end the application.
**/
class AppleOutputTest extends Test
{
	private var fixture:Fixture;
	private var output:PlatformFixture;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		fixture = new Fixture();
		fixture.write("Main.hx", "class Main {}");
		output = new PlatformFixture(fixture);
	}

	public function teardown():Void
	{
		fixture.dispose();
	}

	public function testMacUsageDescriptionsReachInfoPlist():Void
	{
		fixture.target = MAC;
		output.update(project("mac"));

		var plist = Plist.parse(output.read("bin/MyApplication.app/Contents/Info.plist"));
		Assert.equals("Shows you in the video call", plist.get("NSCameraUsageDescription"));
		Assert.equals("Hears you in the video call", plist.get("NSMicrophoneUsageDescription"));
	}

	public function testMacInfoPlistHasNoUsageDescriptionsUnlessGiven():Void
	{
		fixture.target = MAC;
		output.update(project(null));

		var plist = Plist.parse(output.read("bin/MyApplication.app/Contents/Info.plist"));
		Assert.isFalse(plist.exists("NSCameraUsageDescription"));
		Assert.isFalse(plist.exists("NSMicrophoneUsageDescription"));
	}

	public function testIOSUsageDescriptionsReachInfoPlist():Void
	{
		fixture.target = IOS;
		output.update(project("ios"));

		var plist = Plist.parse(output.read("MyApplication/MyApplication-Info.plist"));
		Assert.equals("Shows you in the video call", plist.get("NSCameraUsageDescription"));
		Assert.equals("Hears you in the video call", plist.get("NSMicrophoneUsageDescription"));
	}

	public function testIOSInfoPlistHasNoUsageDescriptionsUnlessGiven():Void
	{
		fixture.target = IOS;
		output.update(project(null));

		var plist = Plist.parse(output.read("MyApplication/MyApplication-Info.plist"));
		Assert.isFalse(plist.exists("NSCameraUsageDescription"));
		Assert.isFalse(plist.exists("NSMicrophoneUsageDescription"));
	}

	public function testTheCameraDescriptionIsGivenOnItsOwn():Void
	{
		// An application that only uses the camera does not have to explain the microphone
		fixture.target = MAC;
		output.update('<project>
			<meta title="My Application" package="com.example.app" />
			<app main="Main" file="MyApplication" />
			<config:mac camera-usage-description="Scans the code" />
		</project>');

		var plist = Plist.parse(output.read("bin/MyApplication.app/Contents/Info.plist"));
		Assert.equals("Scans the code", plist.get("NSCameraUsageDescription"));
		Assert.isFalse(plist.exists("NSMicrophoneUsageDescription"));
	}

	private static function project(platform:String):String
	{
		var config = platform == null ? "" : '<config:' + platform + ' camera-usage-description="Shows you in the video call"'
			+ ' microphone-usage-description="Hears you in the video call" />';

		return '<project>
			<meta title="My Application" package="com.example.app" />
			<app main="Main" file="MyApplication" />
			' + config + '
		</project>';
	}
}
