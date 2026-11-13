package utils;

import lime.utils.ArrayBuffer;
import lime.utils.Float32Array;
import lime.utils.Float64Array;
import lime.utils.Int32Array;
import lime.utils.Int8Array;
import lime.utils.UInt32Array;
import lime.utils.UInt8Array;
import utest.Assert;
import utest.Test;

class Float64ArrayTest extends Test
{
	public function new()
	{
		super();
	}

	private function assertElements(expected:Array<Float>, array:Float64Array, ?pos:haxe.PosInfos):Void
	{
		Assert.equals(expected.length, array.length, "length", pos);
		for (i in 0...expected.length)
		{
			var value = array[i];
			if (Math.isNaN(expected[i]))
			{
				Assert.isTrue(Math.isNaN(value), 'Float64: expected NaN but got $value at index $i', pos);
			}
			else
			{
				Assert.equals(expected[i], value, 'Float64: expected ${expected[i]} but got $value at index $i', pos);
			}
		}
	}

	private function bytesOf(buffer:ArrayBuffer):Array<Int>
	{
		var bytes = new UInt8Array(buffer);
		return [for (i in 0...bytes.length) bytes[i]];
	}

	public function testByteLength():Void
	{
		var buffer = new ArrayBuffer(32);
		var array = new Float64Array(buffer);
		Assert.equals(8, Float64Array.BYTES_PER_ELEMENT);
		Assert.equals(4, array.length);
		Assert.equals(32, array.byteLength);
		Assert.equals(0, array.byteOffset);
	}

	public function testConstructWithLength():Void
	{
		var array = new Float64Array(3);
		assertElements([0, 0, 0], array);
		Assert.equals(24, array.byteLength);
	}

	public function testValuesAreExact():Void
	{
		var values:Array<Float> = [0.1, 1 / 3, -1.5, 16777217, 9007199254740993.0, 5e-324, 1.7976931348623157e308, 2.2250738585072014e-308];
		var array = new Float64Array(values.length);
		for (i in 0...values.length)
		{
			array[i] = values[i];
		}
		assertElements(values, array);
	}

	public function testNaNAndInfinity():Void
	{
		var array = new Float64Array([Math.NaN, Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY, -1 / Math.POSITIVE_INFINITY]);
		assertElements([Math.NaN, Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY, 0], array);
		Assert.equals(Math.NEGATIVE_INFINITY, 1 / array[3]);
	}

	@Ignored("Waiting on #2150")
	public function testConstructFromTypedArrayConvertsValues():Void
	{
		assertElements([0.10000000149011612, -2.5], new Float64Array(new Float32Array([0.1, -2.5])));
		assertElements([-1, 127], new Float64Array(new Int8Array([-1, 127])));
		assertElements([-2147483648, 2147483647], new Float64Array(new Int32Array([0x80000000, 0x7fffffff])));
		// Unsigned elements keep their unsigned value
		var unsigned = new Float64Array(new UInt32Array([0xffffffff, 0x80000000]));
		assertElements([4294967295.0, 2147483648.0], unsigned);
		Assert.equals(16, unsigned.byteLength);
	}

	public function testConstructFromBufferWithOffsetAndLength():Void
	{
		var buffer = new ArrayBuffer(32);
		var array = new Float64Array(buffer, 8, 2);
		Assert.equals(2, array.length);
		Assert.equals(16, array.byteLength);
		Assert.equals(8, array.byteOffset);
		array[1] = 1.0;
		var expected = [for (i in 0...32) 0];
		expected[22] = 0xf0;
		expected[23] = 0x3f;
		Assert.same(expected, bytesOf(buffer));

		var rest = new Float64Array(buffer, 16);
		Assert.equals(2, rest.length);
		Assert.equals(1.0, rest[0]);
	}

	public function testConstructWithMisalignedOffsetThrows():Void
	{
		var buffer = new ArrayBuffer(32);
		// RangeError: byteOffset must be a multiple of the element size
		Assert.raises(function():Void
		{
			new Float64Array(buffer, 4);
		});
		Assert.raises(function():Void
		{
			new Float64Array(buffer, 12, 1);
		});
		Assert.raises(function():Void
		{
			new Float64Array(new ArrayBuffer(12));
		});
		Assert.raises(function():Void
		{
			new Float64Array(new ArrayBuffer(16), 8, 2);
		});
	}

	public function testLittleEndian():Void
	{
		var array = new Float64Array([1.0, -2.5]);
		Assert.same([0, 0, 0, 0, 0, 0, 0xf0, 0x3f, 0, 0, 0, 0, 0, 0, 0x04, 0xc0], bytesOf(array.buffer));

		var buffer = new ArrayBuffer(16);
		var bytes = new UInt8Array(buffer);
		bytes[6] = 0xf0;
		bytes[7] = 0x7f;
		bytes[14] = 0xf8;
		bytes[15] = 0x7f;
		assertElements([Math.POSITIVE_INFINITY, Math.NaN], new Float64Array(buffer));
	}

	@Ignored("Waiting on #2151")
	public function testSubarray():Void
	{
		var array = new Float64Array([1, 2, 3, 4, 5, 6]);

		var middle = array.subarray(2, 4);
		assertElements([3, 4], middle);
		Assert.equals(16, middle.byteOffset);
		Assert.equals(16, middle.byteLength);

		var lastTwo = array.subarray(-2);
		assertElements([5, 6], lastTwo);
		Assert.equals(32, lastTwo.byteOffset);

		assertElements([2, 3, 4, 5], array.subarray(1, -1));
		assertElements([1, 2], array.subarray(-100, 2));
		Assert.equals(0, array.subarray(-1, -3).length);
		assertElements([5, 6], array.subarray(4, 100));

		middle[1] = 0.25;
		Assert.equals(0.25, array[3]);
	}

	public function testSetArrayWithOffset():Void
	{
		var array = new Float64Array(4);
		array.set([0.1, 1e300], 2);
		assertElements([0, 0, 0.1, 1e300], array);

		Assert.raises(function():Void
		{
			array.set([7.0, 7.0], 3);
		});
		assertElements([0, 0, 0.1, 1e300], array);
	}

	@Ignored("Waiting on #2150")
	public function testSetTypedArrayConvertsValues():Void
	{
		var array = new Float64Array(3);
		array.set(new Float32Array([0.1]), 1);
		assertElements([0, 0.10000000149011612, 0], array);

		array.set(new UInt32Array([0xffffffff]), 2);
		assertElements([0, 0.10000000149011612, 4294967295.0], array);
	}

	public function testSetOverlappingViewOfSameBuffer():Void
	{
		var forward = new Float64Array([1, 2, 3, 4, 5, 6]);
		forward.set(forward.subarray(0, 4), 2);
		assertElements([1, 2, 1, 2, 3, 4], forward);
	}

	@Ignored("Waiting on #2150")
	public function testSetOverlappingViewOfAnotherType():Void
	{
		// Float32 elements spread into Float64 elements overwrite the bytes still to be read
		var buffer = new ArrayBuffer(32);
		var narrow = new Float32Array(buffer, 0, 4);
		narrow[0] = 1.5;
		narrow[1] = 2.5;
		narrow[2] = 3.5;
		narrow[3] = 4.5;
		var wide = new Float64Array(buffer);
		wide.set(narrow);
		assertElements([1.5, 2.5, 3.5, 4.5], wide);
	}

	@Ignored("Waiting on #2152")
	public function testOutOfBoundsWriteIsIgnored():Void
	{
		var buffer = new ArrayBuffer(32);
		var array = new Float64Array(buffer, 8, 2);
		array[2] = 9;
		array[-1] = 9;
		Assert.same([for (i in 0...32) 0], bytesOf(buffer));
	}
}
