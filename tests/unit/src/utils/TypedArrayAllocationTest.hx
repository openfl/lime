package utils;

#if hl
import lime.graphics.Image;
import lime.utils.UInt16Array;
import lime.utils.UInt32Array;
import lime.utils.UInt8Array;
#end
import utest.Assert;
import utest.Test;

/**
	Counts what reading typed array elements allocates on HashLink, where a `Null<Int>` is an object of its
	own. The values read are pinned by each typed array's own tests; these only count the allocations,
	which every pixel loop in Lime pays for on HashLink. Counts can differ with the HashLink build: the
	runtime CI builds also allocates reading signed and float elements, where an official 1.14 doesn't.
**/
class TypedArrayAllocationTest extends Test
{
	public function new()
	{
		super();
	}

	#if hl
	@Ignored("Waiting on #2129")
	public function testReadingUnsignedIntegerElementsAllocatesNothing():Void
	{
		for (name in ["UInt8Array", "UInt16Array", "UInt32Array"])
		{
			var count = 0.0;
			var sum = 0;

			switch (name)
			{
				case "UInt8Array":
					var array = new UInt8Array(64);
					count = allocations(function() for (i in 0...64) sum += array[i]);
				case "UInt16Array":
					var array = new UInt16Array(64);
					count = allocations(function() for (i in 0...64) sum += array[i]);
				default:
					var array = new UInt32Array(64);
					count = allocations(function() for (i in 0...64) sum += array[i]);
			}

			Assert.equals(0.0, count, name + ": reading 64 elements allocated " + count + " times");
		}
	}

	@Ignored("Waiting on #2129")
	public function testGetPixel32WithoutAFormatAllocatesNothing():Void
	{
		// The pixel's bytes are read through UInt8Array, and RGBA keeps scratch values in static fields
		for (premultiplied in [false, true])
		{
			var image = new Image(null, 0, 0, 16, 16, 0x80336699);
			image.premultiplied = premultiplied;
			var sum = 0;

			var count = allocations(function()
			{
				for (i in 0...64)
				{
					sum += image.getPixel32(i & 15, i >> 2);
				}
			});

			Assert.equals(0.0, count, (premultiplied ? "premultiplied: " : "straight: ") + "64 calls allocated " + count + " times");
		}
	}

	// Helpers

	private static function allocations(f:Void->Void):Float
	{
		var before = allocationCount();
		f();
		return allocationCount() - before;
	}

	// Through the native call, as Gc.stats() makes an object of its own
	private static function allocationCount():Float
	{
		var total = 0.0, count = 0.0, memory = 0.0;
		@:privateAccess hl.Gc._stats(total, count, memory);
		return count;
	}
	#end
}
