import lime.tools.HXProject;
import lime.tools.XCodeHelper;
import utest.Assert;
import utest.Test;

/**
	Which simulator `lime test ios -simulator` runs on, read from what `xcrun simctl list devices`
	prints: one named on the command line, or else one already running (#1938), or else a
	standard iPhone or iPad.
**/
@:access(lime.tools.XCodeHelper)
class XCodeHelperTest extends Test
{
	private static inline var IPHONE_15 = "6A4F2C3E-1B2D-4C5E-8F9A-0B1C2D3E4F50";
	private static inline var IPAD_PRO = "1A2B3C4D-5E6F-4A8B-9C0D-1E2F3A4B5C6D";
	private static inline var IPHONE_16 = "11111111-2222-4333-8444-555555555555";
	private static inline var IPHONE_16_PRO = "AAAAAAAA-BBBB-4CCC-8DDD-EEEEEEEEEEEE";
	private static inline var IPAD_AIR_M2 = "99999999-8888-4777-8666-555555555555";
	private static inline var APPLE_TV = "ABCDEF01-2345-4678-89AB-CDEF01234567";

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

	public function testTheIDAndNameAreReadWhateverParenthesesTheNameHolds():Void
	{
		var lines = [
			"iPhone 16 Pro (" + IPHONE_16_PRO + ") (Shutdown)" => "iPhone 16 Pro",
			"iPad Air 11-inch (M2) (" + IPAD_AIR_M2 + ") (Booted)" => "iPad Air 11-inch (M2)",
			"iPad Pro (12.9-inch) (6th generation) (" + IPAD_PRO + ") (Shutdown)" => "iPad Pro (12.9-inch) (6th generation)"
		];

		for (line => name in lines)
		{
			Assert.equals(name, XCodeHelper.extractSimulatorFullName(line));
			Assert.equals(36, XCodeHelper.extractSimulatorID(line).length, line);
		}

		Assert.equals(IPAD_AIR_M2, XCodeHelper.extractSimulatorID("iPad Air 11-inch (M2) (" + IPAD_AIR_M2 + ") (Booted)"));
		Assert.equals(IPAD_PRO, XCodeHelper.extractSimulatorID("iPad Pro (12.9-inch) (6th generation) (" + IPAD_PRO + ") (Shutdown)"));
	}

	public function testASimulatorNamedOnTheCommandLineIsUsed():Void
	{
		// Even with another running, listed before it
		Assert.equals(IPHONE_16, select(project(["iphone-16"]), IPHONE_15).id);
	}

	public function testARunningSimulatorIsUsedWhenNoneIsNamed():Void
	{
		Assert.equals(IPHONE_16_PRO, select(project([]), IPHONE_16_PRO).id);
		Assert.equals(IPAD_AIR_M2, select(project([]), IPAD_AIR_M2).id);
		Assert.equals("iPad Air 11-inch (M2)", select(project([]), IPAD_AIR_M2).name);
	}

	public function testARunningIPadIsUsedWhenAnIPadIsAskedFor():Void
	{
		Assert.equals(IPAD_AIR_M2, select(project(["ipad"]), IPAD_AIR_M2).id);
	}

	public function testARunningIPhoneIsLeftAloneWhenAnIPadIsAskedFor():Void
	{
		var chosen = select(project(["ipad"]), IPHONE_16_PRO);
		Assert.isTrue(StringTools.startsWith(chosen.name, "iPad"), "chose " + chosen.name);

		var ipadOnly:HXProject = fixture.parse('<project><config:ios device="ipad" /></project>');
		chosen = XCodeHelper.selectSimulator(ipadOnly, devices(IPHONE_16_PRO));
		Assert.isTrue(StringTools.startsWith(chosen.name, "iPad"), "an iPad-only app chose " + chosen.name);
	}

	public function testARunningSimulatorOfAnotherPlatformIsLeftAlone():Void
	{
		var chosen = select(project([]), APPLE_TV);
		Assert.isTrue(StringTools.startsWith(chosen.name, "iPhone"), "chose " + chosen.name);
	}

	public function testAStandardIPhoneIsUsedWhenNoneIsRunning():Void
	{
		var chosen = select(project([]), null);
		Assert.isTrue(StringTools.startsWith(chosen.name, "iPhone"), "chose " + chosen.name);
	}

	private function project(flags:Array<String>):HXProject
	{
		var project:HXProject = fixture.parse("<project />");
		for (flag in flags)
		{
			project.targetFlags.set(flag, "");
		}
		return project;
	}

	private static function select(project:HXProject, booted:String):Dynamic
	{
		return XCodeHelper.selectSimulator(project, devices(booted));
	}

	// The list as `xcrun simctl list devices` prints it, with the device whose ID is booted running
	private static function devices(booted:String):String
	{
		var state = function(id:String) return id == booted ? "(Booted)" : "(Shutdown)";

		return [
			"== Devices ==",
			"-- iOS 17.5 --",
			"    iPhone 15 (" + IPHONE_15 + ") " + state(IPHONE_15),
			"    iPad Pro (12.9-inch) (6th generation) (" + IPAD_PRO + ") " + state(IPAD_PRO),
			"-- iOS 18.0 --",
			"    iPhone 16 (" + IPHONE_16 + ") " + state(IPHONE_16),
			"    iPhone 16 Pro (" + IPHONE_16_PRO + ") " + state(IPHONE_16_PRO),
			"    iPad Air 11-inch (M2) (" + IPAD_AIR_M2 + ") " + state(IPAD_AIR_M2),
			"-- tvOS 18.0 --",
			"    Apple TV (" + APPLE_TV + ") " + state(APPLE_TV),
			"-- Unavailable: com.apple.CoreSimulator.SimRuntime.iOS-16-0 --",
			"    iPhone 14 (00000000-0000-4000-8000-000000000000) (Shutdown) (unavailable, runtime profile not found)"
		].join("\n");
	}
}
