package graphics;

#if ((cpp || hl) && lime_cffi && lime_cairo && !macro)
import graphics.CairoFixture.*;
import lime.graphics.cairo.CairoPattern;
import system.CollectorWait;
#end
import utest.Assert;
import utest.Test;

/**
	Drawing with Cairo away from the main thread, on C++ and HashLink.

	A worker drawing into a large surface shouldn't hold a collection on the main thread up until the
	drawing is done: each drawing call tells the collector it is blocking, as decoding and encoding an
	image do. Each test gives one call enough pixels to take a good deal longer than a collection.
**/
class CairoWorkerTest extends Test
{
	#if ((cpp || hl) && lime_cffi && lime_cairo && !macro)
	private static inline var SIZE = 4096;
	// A call shorter than this can't be told from a collection that waited for it
	private static inline var LONG_ENOUGH = 0.02;
	#end

	public function new()
	{
		super();
	}

	#if ((cpp || hl) && lime_cffi && lime_cairo && !macro)
	public function testTheCollectorRunsWhileAWorkerPaints():Void
	{
		var fixture = new CairoFixture(SIZE, SIZE);
		var gradient = CairoPattern.createRadial(SIZE / 2, SIZE / 2, 0, SIZE / 2, SIZE / 2, SIZE / 2);
		gradient.addColorStopRGB(0, 1, 0, 0);
		gradient.addColorStopRGB(1, 0, 0, 1);
		fixture.cairo.source = gradient;

		var result = CollectorWait.collectDuring(function()
		{
			fixture.cairo.paint();
		});

		assertCollectorRan(result, "Painting a gradient on a worker");
		fixture.assertPixel(RED, SIZE >> 1, SIZE >> 1, 8, "the gradient's centre");
	}

	public function testTheCollectorRunsWhileAWorkerFills():Void
	{
		var fixture = new CairoFixture(SIZE, SIZE);
		var cairo = fixture.cairo;
		cairo.setSourceRGB(0, 1, 0);

		// A star of many thin spikes over the whole surface, antialiased
		var spikes = 2000;
		var centre = SIZE / 2;
		cairo.moveTo(centre + centre, centre);
		for (i in 1...spikes * 2)
		{
			var angle = Math.PI * i / spikes;
			var radius = i % 2 == 0 ? centre : centre / 4;
			cairo.lineTo(centre + radius * Math.cos(angle), centre + radius * Math.sin(angle));
		}
		cairo.closePath();

		var result = CollectorWait.collectDuring(function()
		{
			cairo.fill();
		});

		assertCollectorRan(result, "Filling a path on a worker");
		fixture.assertPixel(GREEN, SIZE >> 1, SIZE >> 1, 0, "inside the star");
	}

	private static function assertCollectorRan(result:CollectorWaitResult, what:String):Void
	{
		Assert.isNull(result.error, what + ": " + result);
		Assert.isTrue(result.workSeconds > LONG_ENOUGH, what + " was too short to tell: " + result);
		Assert.isFalse(result.waited, what + ": " + result);
	}
	#end
}
