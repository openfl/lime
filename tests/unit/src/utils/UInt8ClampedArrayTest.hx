package utils;

import lime.utils.ArrayBuffer;
import lime.utils.Float32Array;
import lime.utils.Float64Array;
import lime.utils.Int16Array;
import lime.utils.Int8Array;
import lime.utils.UInt8Array;
import lime.utils.UInt8ClampedArray;
import utest.Assert;
import utest.Test;

class UInt8ClampedArrayTest extends Test
{
	public function new()
	{
		super();
	}

	private function assertElements(expected:Array<Int>, array:UInt8ClampedArray, ?pos:haxe.PosInfos):Void
	{
		Assert.equals(expected.length, array.length, "length", pos);
		for (i in 0...expected.length)
		{
			var value:Int = array[i];
			Assert.equals(expected[i], value, 'UInt8Clamped: expected ${expected[i]} but got $value at index $i', pos);
		}
	}

	private function bytesOf(buffer:ArrayBuffer):Array<Int>
	{
		var bytes = new UInt8Array(buffer);
		return [for (i in 0...bytes.length) bytes[i]];
	}

	public function testByteLength():Void
	{
		var buffer = new ArrayBuffer(4);
		var array = new UInt8ClampedArray(buffer);
		Assert.equals(1, UInt8ClampedArray.BYTES_PER_ELEMENT);
		Assert.equals(4, array.length);
		Assert.equals(4, array.byteLength);
		Assert.equals(0, array.byteOffset);
	}

	public function testValues():Void
	{
		var array = new UInt8ClampedArray(4);
		assertElements([0, 0, 0, 0], array);
		array[0] = 0xca;
		array[1] = 0xfe;
		array[2] = 0;
		array[3] = 255;
		assertElements([0xca, 0xfe, 0, 255], array);
	}

	#if (cpp || neko || hl)
	@Ignored("Waiting on #2184")
	#end
	public function testValuesClampInsteadOfWrapping():Void
	{
		// ToUint8Clamp: above 255 is 255, below 0 is 0
		var array = new UInt8ClampedArray(4);
		array[0] = 256;
		array[1] = 0x12345;
		array[2] = -1;
		array[3] = -0x12345;
		assertElements([255, 255, 0, 0], array);
	}

	@Ignored("Waiting on #2152")
	public function testClampedValuesRoundHalfToEven():Void
	{
		// ToUint8Clamp rounds to the nearest integer, and halves to the even one
		var array = new UInt8ClampedArray([0.5, 1.5, 2.5, 3.5, 254.5, 0.49, 0.51, 1.4, 1.6, 254.6]);
		assertElements([0, 2, 2, 4, 254, 0, 1, 1, 2, 255], array);
	}

	@Ignored("Waiting on #2152")
	public function testClampedValuesOutOfRange():Void
	{
		var array = new UInt8ClampedArray([Math.NaN, -0.5, -1, -1000.7, 255.5, 300, 1e10, Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY]);
		assertElements([0, 0, 0, 0, 255, 255, 255, 255, 0], array);
	}

	#if (cpp || neko || hl)
	@Ignored("Waiting on #2184")
	#end
	public function testConstructFromArrayOfInts():Void
	{
		var array = new UInt8ClampedArray([-5, 0, 128, 255, 256, 1000]);
		assertElements([0, 0, 128, 255, 255, 255], array);
	}

	@Ignored("Waiting on #2150")
	public function testConstructFromTypedArrayClampsValues():Void
	{
		assertElements([0, 255, 128, 255, 255], new UInt8ClampedArray(new Int16Array([-5, 300, 128, 255, 256])));
		assertElements([0, 2, 2, 0, 255, 0], new UInt8ClampedArray(new Float32Array([0.5, 1.5, 2.5, -3, 300, Math.NaN])));
		assertElements([254, 255, 4], new UInt8ClampedArray(new Float64Array([254.5, 254.6, 3.5])));
		assertElements([0, 127], new UInt8ClampedArray(new Int8Array([-128, 127])));
	}

	public function testConstructFromBufferWithOffsetAndLength():Void
	{
		var buffer = new ArrayBuffer(6);
		var array = new UInt8ClampedArray(buffer, 2, 3);
		Assert.equals(3, array.length);
		Assert.equals(3, array.byteLength);
		Assert.equals(2, array.byteOffset);
		array[0] = 300;
		Assert.same([0, 0, 255, 0, 0, 0], bytesOf(buffer));
	}

	@Ignored("Waiting on #2151")
	public function testSubarray():Void
	{
		var array = new UInt8ClampedArray([1, 2, 3, 4, 5, 6]);

		var middle = array.subarray(2, 4);
		assertElements([3, 4], middle);
		Assert.equals(2, middle.byteOffset);
		Assert.equals(2, middle.byteLength);

		var lastTwo = array.subarray(-2);
		assertElements([5, 6], lastTwo);
		Assert.equals(4, lastTwo.byteOffset);

		assertElements([2, 3, 4, 5], array.subarray(1, -1));
		Assert.equals(0, array.subarray(-1, -3).length);
		assertElements([5, 6], array.subarray(4, 100));

		middle[0] = 400;
		Assert.equals(255, (array[2] : Int));
	}

	#if (cpp || neko || hl)
	@Ignored("Waiting on #2184")
	#end
	public function testSetArrayClampsValues():Void
	{
		var array = new UInt8ClampedArray(6);
		array.set([-7, 700, 128], 1);
		assertElements([0, 0, 255, 128, 0, 0], array);

		Assert.raises(function():Void
		{
			array.set([7, 7, 7], 4);
		});
		assertElements([0, 0, 255, 128, 0, 0], array);
	}

	#if !js
	// js.lib typed arrays only take Array<Int> in set
	@Ignored("Waiting on #2152")
	public function testSetArrayOfFloatsRoundsHalfToEven():Void
	{
		var array = new UInt8ClampedArray(5);
		array.set([0.5, 1.5, 2.5, -1.0, 256.0]);
		assertElements([0, 2, 2, 0, 255], array);
	}
	#end

	#if (cpp || neko || hl)
	@Ignored("Waiting on #2184")
	#end
	public function testSetTypedArrayClampsValues():Void
	{
		var array = new UInt8ClampedArray(4);
		array.set(new Int16Array([-1, 1000]), 1);
		assertElements([0, 0, 255, 0], array);

		array.set(new Float64Array([2.5]), 3);
		assertElements([0, 0, 255, 2], array);
	}

	@Ignored("Waiting on #2150")
	public function testSetInt8ArrayClampsNegativeValues():Void
	{
		// Int8 and UInt8Clamped elements are both 1 byte, but -1 clamps to 0 rather than keeping its bits
		var array = new UInt8ClampedArray(3);
		array.set(new Int8Array([-1, -128, 127]));
		assertElements([0, 0, 127], array);
	}

	public function testSetOverlappingViewOfSameBuffer():Void
	{
		var forward = new UInt8ClampedArray([1, 2, 3, 4, 5, 6]);
		forward.set(forward.subarray(0, 4), 2);
		assertElements([1, 2, 1, 2, 3, 4], forward);
	}

	@Ignored("Waiting on #2152")
	public function testOutOfBoundsWriteIsIgnored():Void
	{
		var buffer = new ArrayBuffer(6);
		var array = new UInt8ClampedArray(buffer, 2, 2);
		array[2] = 9;
		array[-1] = 9;
		Assert.same([0, 0, 0, 0, 0, 0], bytesOf(buffer));
	}
}
