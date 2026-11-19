package utils;

import lime.utils.ArrayBuffer;
import lime.utils.Float32Array;
import lime.utils.Float64Array;
import lime.utils.Int16Array;
import lime.utils.Int32Array;
import lime.utils.UInt8Array;
import utest.Assert;
import utest.Test;

class Float32ArrayTest extends Test
{
	public function new()
	{
		super();
	}

	private function assertElements(expected:Array<Float>, array:Float32Array, ?pos:haxe.PosInfos):Void
	{
		Assert.equals(expected.length, array.length, "length", pos);
		for (i in 0...expected.length)
		{
			var value = array[i];
			if (Math.isNaN(expected[i]))
			{
				Assert.isTrue(Math.isNaN(value), 'Float32: expected NaN but got $value at index $i', pos);
			}
			else
			{
				Assert.equals(expected[i], value, 'Float32: expected ${expected[i]} but got $value at index $i', pos);
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
		var buffer = new ArrayBuffer(16);
		var array = new Float32Array(buffer);
		Assert.equals(4, Float32Array.BYTES_PER_ELEMENT);
		Assert.equals(4, array.length);
		Assert.equals(16, array.byteLength);
		Assert.equals(0, array.byteOffset);
	}

	public function testConstructWithLength():Void
	{
		var array = new Float32Array(3);
		assertElements([0, 0, 0], array);
		Assert.equals(12, array.byteLength);
	}

	public function testValues():Void
	{
		var array = new Float32Array(4);
		array[0] = 1.5;
		array[1] = -2.25;
		array[2] = 65504;
		array[3] = 0.15625;
		assertElements([1.5, -2.25, 65504, 0.15625], array);
	}

	public function testValuesRoundToNearestFloat32():Void
	{
		// Values are rounded to the nearest float32, ties to even
		var array = new Float32Array(6);
		array[0] = 0.1;
		array[1] = 1 / 3;
		array[2] = 16777217;
		array[3] = 16777219;
		array[4] = -0.1;
		array[5] = 1.401298464324817e-45;
		assertElements([0.10000000149011612, 0.3333333432674408, 16777216, 16777220, -0.10000000149011612, 1.401298464324817e-45], array);
	}

	public function testValuesOutsideFloat32Range():Void
	{
		var array = new Float32Array(4);
		array[0] = 1e40;
		array[1] = -1e40;
		array[2] = 1e-46;
		array[3] = -1e-46;
		assertElements([Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY, 0, 0], array);
		// Underflow keeps the sign
		Assert.equals(Math.NEGATIVE_INFINITY, 1 / array[3]);
	}

	public function testNaNAndInfinity():Void
	{
		var array = new Float32Array([Math.NaN, Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY, -1 / Math.POSITIVE_INFINITY]);
		assertElements([Math.NaN, Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY, 0], array);
		Assert.equals(Math.NEGATIVE_INFINITY, 1 / array[3]);
	}

	@Ignored("Waiting on #2154")
	public function testSetIntoASubarrayWritesAtItsOffset():Void
	{
		// Uploading part of a vertex buffer through a subarray, as GL code often does
		var vertices = new Float32Array(6);
		vertices.subarray(2).set([1.5, 2.5]);
		assertElements([0, 0, 1.5, 2.5, 0, 0], vertices);

		vertices.subarray(4).set(new Float32Array([3.5, 4.5]));
		assertElements([0, 0, 1.5, 2.5, 3.5, 4.5], vertices);
	}

	@Ignored("Waiting on #2150")
	public function testConstructFromTypedArrayConvertsValues():Void
	{
		assertElements([0.10000000149011612, 16777216, Math.POSITIVE_INFINITY], new Float32Array(new Float64Array([0.1, 16777217.0, 1e40])));
		assertElements([16777216, 2147483648.0, -1], new Float32Array(new Int32Array([16777217, 0x7fffffff, -1])));
		var narrow = new Float32Array(new Int16Array([-32768, 7]));
		assertElements([-32768, 7], narrow);
		Assert.equals(8, narrow.byteLength);
	}

	public function testConstructFromBufferWithOffsetAndLength():Void
	{
		var buffer = new ArrayBuffer(16);
		var array = new Float32Array(buffer, 4, 2);
		Assert.equals(2, array.length);
		Assert.equals(8, array.byteLength);
		Assert.equals(4, array.byteOffset);
		array[1] = 1.0;
		Assert.same([0, 0, 0, 0, 0, 0, 0, 0, 0x00, 0x00, 0x80, 0x3f, 0, 0, 0, 0], bytesOf(buffer));
	}

	public function testConstructWithMisalignedOffsetThrows():Void
	{
		var buffer = new ArrayBuffer(16);
		// RangeError: byteOffset must be a multiple of the element size
		Assert.raises(function():Void
		{
			new Float32Array(buffer, 2);
		});
		Assert.raises(function():Void
		{
			new Float32Array(new ArrayBuffer(6));
		});
		Assert.raises(function():Void
		{
			new Float32Array(new ArrayBuffer(8), 4, 2);
		});
	}

	public function testLittleEndian():Void
	{
		var array = new Float32Array([1.0, -2.0]);
		Assert.same([0x00, 0x00, 0x80, 0x3f, 0x00, 0x00, 0x00, 0xc0], bytesOf(array.buffer));

		var buffer = new ArrayBuffer(12);
		var bytes = new UInt8Array(buffer);
		bytes[2] = 0xc0;
		bytes[3] = 0x7f;
		bytes[6] = 0x80;
		bytes[7] = 0x7f;
		bytes[10] = 0x80;
		bytes[11] = 0xff;
		assertElements([Math.NaN, Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY], new Float32Array(buffer));
	}

	@Ignored("Waiting on #2151")
	public function testSubarray():Void
	{
		var array = new Float32Array([1, 2, 3, 4, 5, 6]);

		var middle = array.subarray(2, 4);
		assertElements([3, 4], middle);
		Assert.equals(8, middle.byteOffset);
		Assert.equals(8, middle.byteLength);

		var lastTwo = array.subarray(-2);
		assertElements([5, 6], lastTwo);
		Assert.equals(16, lastTwo.byteOffset);

		assertElements([2, 3, 4, 5], array.subarray(1, -1));
		Assert.equals(0, array.subarray(-1, -3).length);
		assertElements([5, 6], array.subarray(4, 100));

		middle[0] = 0.5;
		Assert.equals(0.5, array[2]);
	}

	public function testSetArrayWithOffset():Void
	{
		var array = new Float32Array(4);
		array.set([0.1, 1e40], 2);
		assertElements([0, 0, 0.10000000149011612, Math.POSITIVE_INFINITY], array);

		Assert.raises(function():Void
		{
			array.set([7.0, 7.0], 3);
		});
		assertElements([0, 0, 0.10000000149011612, Math.POSITIVE_INFINITY], array);
	}

	@Ignored("Waiting on #2150")
	public function testSetTypedArrayConvertsValues():Void
	{
		var array = new Float32Array(3);
		array.set(new Float64Array([1 / 3, -0.1]), 1);
		assertElements([0, 0.3333333432674408, -0.10000000149011612], array);

		array.set(new Int32Array([16777217]));
		assertElements([16777216, 0.3333333432674408, -0.10000000149011612], array);
	}

	public function testSetOverlappingViewOfSameBuffer():Void
	{
		var forward = new Float32Array([1, 2, 3, 4, 5, 6]);
		forward.set(forward.subarray(0, 4), 2);
		assertElements([1, 2, 1, 2, 3, 4], forward);
	}

	@Ignored("Waiting on #2152")
	public function testOutOfBoundsWriteIsIgnored():Void
	{
		var buffer = new ArrayBuffer(16);
		var array = new Float32Array(buffer, 4, 2);
		array[2] = 9;
		array[-1] = 9;
		Assert.same([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], bytesOf(buffer));
	}
}
