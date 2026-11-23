import utest.Assert;
import utest.Test;

/**
	What `lime update ios` writes from templates/ios: the application's Info.plist and the
	Xcode project. The plist is read as strict XML, as Xcode reads it.
**/
class IOSOutputTest extends Test
{
	private static inline var INFO_PLIST = "MyApplication/MyApplication-Info.plist";

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

	private function infoPlist():Map<String, Dynamic>
	{
		return Plist.parse(output.read(INFO_PLIST));
	}
}
