package lime.app;

import lime.ui.WindowAttributes;
import massive.munit.Assert;

@:access(lime.app.Application)
class FrameTimingTest
{
	@Test public function defaultsMatchLimeExpectations():Void
	{
		var app = new Application();

		Assert.areEqual(FrameProfile.Balanced, app.frameProfile);
		Assert.areEqual(VSyncMode.Off, app.vsyncMode);
		Assert.areEqual(TimePrecision.Auto, app.frameOptions.timePrecision);
		Assert.areEqual(BusyWaitMode.Auto, app.frameOptions.busyWait);
		Assert.areEqual(UncapMode.Off, app.frameOptions.uncapMode);
		Assert.areEqual(60.0, app.__getFrameRate());
	}

	@Test public function configureFrameTimingStoresProfileOptionsAndVSync():Void
	{
		var app = new Application();

		app.configureFrameTiming(FrameProfile.Precision,
			{
				timePrecision: TimePrecision.HighResolution,
				busyWait: BusyWaitMode.On,
				uncapMode: UncapMode.Soft
			},
			VSyncMode.Auto);

		Assert.areEqual(FrameProfile.Precision, app.frameProfile);
		Assert.areEqual(VSyncMode.Auto, app.vsyncMode);
		Assert.areEqual(TimePrecision.HighResolution, app.frameOptions.timePrecision);
		Assert.areEqual(BusyWaitMode.On, app.frameOptions.busyWait);
		Assert.areEqual(UncapMode.Soft, app.frameOptions.uncapMode);
	}

	@Test public function seedFrameConfigurationUsesFirstWindowAttributes():Void
	{
		var app = new Application();
		var attributes:WindowAttributes =
		{
			frameRate: 144,
			frameProfile: FrameProfile.LowEnergy,
			frameOptions:
			{
				timePrecision: TimePrecision.Millisecond,
				busyWait: BusyWaitMode.Off,
				uncapMode: UncapMode.Hard
			},
			context:
			{
				vsyncMode: VSyncMode.Adaptive
			}
		};

		app.__seedFrameConfiguration(attributes);

		Assert.areEqual(144.0, app.__getFrameRate());
		Assert.areEqual(FrameProfile.LowEnergy, app.frameProfile);
		Assert.areEqual(VSyncMode.Adaptive, app.vsyncMode);
		Assert.areEqual(TimePrecision.Millisecond, app.frameOptions.timePrecision);
		Assert.areEqual(BusyWaitMode.Off, app.frameOptions.busyWait);
		Assert.areEqual(UncapMode.Hard, app.frameOptions.uncapMode);
	}

	@Test public function explicitConfigurationWinsOverLaterWindowSeeding():Void
	{
		var app = new Application();

		app.configureFrameTiming(FrameProfile.Precision,
			{
				timePrecision: TimePrecision.HighResolution,
				busyWait: BusyWaitMode.On,
				uncapMode: UncapMode.Soft
			},
			VSyncMode.Auto);

		app.__seedFrameConfiguration(
			{
				frameRate: 30,
				frameProfile: FrameProfile.LowEnergy,
				frameOptions:
				{
					timePrecision: TimePrecision.Millisecond,
					busyWait: BusyWaitMode.Off,
					uncapMode: UncapMode.Hard
				},
				context:
				{
					vsyncMode: VSyncMode.Off
				}
			});

		Assert.areEqual(60.0, app.__getFrameRate());
		Assert.areEqual(FrameProfile.Precision, app.frameProfile);
		Assert.areEqual(VSyncMode.Auto, app.vsyncMode);
		Assert.areEqual(TimePrecision.HighResolution, app.frameOptions.timePrecision);
		Assert.areEqual(BusyWaitMode.On, app.frameOptions.busyWait);
		Assert.areEqual(UncapMode.Soft, app.frameOptions.uncapMode);
	}

	@Test public function legacyBooleanVSyncStillSeedsOnMode():Void
	{
		var app = new Application();

		app.__seedFrameConfiguration(
			{
				context:
				{
					vsync: true
				}
			});

		Assert.areEqual(VSyncMode.On, app.vsyncMode);
	}

	@Test public function sharedFrameRateCanBeUpdatedThroughWindowForwarder():Void
	{
		var app = new Application();

		Assert.areEqual(240.0, app.__setFrameRateFromWindow(240));
		Assert.areEqual(240.0, app.__getFrameRate());
	}
}
