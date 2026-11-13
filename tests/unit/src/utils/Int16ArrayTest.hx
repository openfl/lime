package utils;

import lime.utils.ArrayBuffer;
import lime.utils.Float64Array;
import lime.utils.Int16Array;
import lime.utils.Int32Array;
import lime.utils.Int8Array;
import lime.utils.UInt16Array;
import lime.utils.UInt8Array;
import utest.Assert;
import utest.Test;

class Int16ArrayTest extends Test
{
	public function new()
	{
		super();
	}

	private function assertElements(expected:Array<Int>, array:Int16Array, ?pos:haxe.PosInfos):Void
	{
		Assert.equals(expected.length, array.length, "length", pos);
		for (i in 0...expected.length)
		{
			var value = array[i];
			Assert.equals(expected[i], value, 'Int16: expected ${expected[i]} but got $value at index $i', pos);
		}
	}

	private function bytesOf(buffer:ArrayBuffer):Array<Int>
	{
		var bytes = new UInt8Array(buffer);
		return [for (i in 0...bytes.length) bytes[i]];
	}

	public function testByteLength():Void
	{
		var buffer = new ArrayBuffer(8);
		var array = new Int16Array(buffer);
		Assert.equals(2, Int16Array.BYTES_PER_ELEMENT);
		Assert.equals(4, array.length);
		Assert.equals(8, array.byteLength);
		Assert.equals(0, array.byteOffset);
	}

	public function testConstructWithLength():Void
	{
		var array = new Int16Array(3);
		assertElements([0, 0, 0], array);
		Assert.equals(6, array.byteLength);
		Assert.equals(6, array.buffer.byteLength);
	}

	public function testValues():Void
	{
		var buffer = new ArrayBuffer(8);
		var array = new Int16Array(buffer);
		assertElements([0, 0, 0, 0], array);
		array[0] = 0x7fff;
		array[1] = -0x8000;
		array[2] = -1;
		array[3] = 0x1234;
		assertElements([0x7fff, -0x8000, -1, 0x1234], array);
	}

	public function testValuesWrapAround():Void
	{
		// ToInt16: the value modulo 2^16, read as signed
		var values:Array<Int> = [0, 1, 32767, 32768, 65535, 65536, -1, -32768, -32769, 0x12345678, 0x7fffffff];
		var result:Array<Int> = [0, 1, 32767, -32768, -1, 0, -1, -32768, 32767, 0x5678, -1];
		var array = new Int16Array(values.length);
		for (i in 0...values.length)
		{
			array[i] = values[i];
		}
		assertElements(result, array);
	}

	#if neko
	@Ignored("Waiting on #2152")
	#end
	public function testConstructFromArrayOfFloatsTruncates():Void
	{
		// ToInt16: NaN and infinities are 0, other values are truncated toward zero, then wrapped
		var array = new Int16Array([1.9, -1.9, 32768.5, 65537.0, -32769.0, Math.NaN, Math.POSITIVE_INFINITY, 4294967297.0]);
		assertElements([1, -1, -32768, 1, 32767, 0, 0, 1], array);
	}

	@Ignored("Waiting on #2150")
	public function testConstructFromTypedArrayConvertsValues():Void
	{
		assertElements([4464, -4464, -32768], new Int16Array(new Int32Array([70000, -70000, 32768])));
		assertElements([-1, -25536], new Int16Array(new Float64Array([-1.5, 40000.9])));
		assertElements([-1], new Int16Array(new UInt16Array([0xffff])));
		// Each element converts by value, not by bytes
		var narrow = new Int16Array(new Int8Array([-1, -128, 127]));
		assertElements([-1, -128, 127], narrow);
		Assert.equals(6, narrow.byteLength);
	}

	public function testConstructFromSubarrayStartsAtItsOffset():Void
	{
		var source = new Int16Array([1, 2, 3, 4, 5]);
		var copy = new Int16Array(source.subarray(2, 4));
		assertElements([3, 4], copy);
		Assert.equals(0, copy.byteOffset);
		Assert.equals(4, copy.byteLength);
	}

	public function testConstructFromBufferWithOffsetAndLength():Void
	{
		var buffer = new ArrayBuffer(10);
		var array = new Int16Array(buffer, 2, 3);
		Assert.equals(3, array.length);
		Assert.equals(6, array.byteLength);
		Assert.equals(2, array.byteOffset);
		array[0] = 0x0102;
		array[2] = -2;
		Assert.same([0, 0, 0x02, 0x01, 0, 0, 0xfe, 0xff, 0, 0], bytesOf(buffer));

		var rest = new Int16Array(buffer, 4);
		Assert.equals(3, rest.length);
		Assert.equals(4, rest.byteOffset);
		Assert.equals(-2, rest[1]);
	}

	public function testConstructWithMisalignedOffsetThrows():Void
	{
		var buffer = new ArrayBuffer(8);
		// RangeError: byteOffset must be a multiple of the element size
		Assert.raises(function():Void
		{
			new Int16Array(buffer, 1);
		});
		Assert.raises(function():Void
		{
			new Int16Array(buffer, 3, 2);
		});
	}

	public function testConstructWithInvalidRangeThrows():Void
	{
		// RangeError: without a length, the bytes after the offset must be whole elements
		Assert.raises(function():Void
		{
			new Int16Array(new ArrayBuffer(5));
		});
		// RangeError: offset + length * 2 is past the end of the buffer
		Assert.raises(function():Void
		{
			new Int16Array(new ArrayBuffer(4), 0, 3);
		});
		Assert.raises(function():Void
		{
			new Int16Array(new ArrayBuffer(4), 6);
		});
	}

	public function testLittleEndian():Void
	{
		var array = new Int16Array([0x0102, -2]);
		Assert.same([0x02, 0x01, 0xfe, 0xff], bytesOf(array.buffer));

		var buffer = new ArrayBuffer(4);
		var bytes = new UInt8Array(buffer);
		bytes[0] = 0xff;
		bytes[1] = 0x7f;
		bytes[2] = 0x00;
		bytes[3] = 0x80;
		assertElements([32767, -32768], new Int16Array(buffer));
	}

	@Ignored("Waiting on #2151")
	public function testSubarray():Void
	{
		var array = new Int16Array([1, 2, 3, 4, 5, 6]);

		var middle = array.subarray(2, 4);
		assertElements([3, 4], middle);
		Assert.equals(4, middle.byteOffset);
		Assert.equals(4, middle.byteLength);

		Assert.equals(0, array.subarray(4, 2).length);
		Assert.equals(0, array.subarray(4, 2).byteLength);
		assertElements([5, 6], array.subarray(4, 100));
	}

	@Ignored("Waiting on #2151")
	public function testSubarrayNegativeIndices():Void
	{
		var array = new Int16Array([1, 2, 3, 4, 5, 6]);

		var lastTwo = array.subarray(-2);
		assertElements([5, 6], lastTwo);
		Assert.equals(8, lastTwo.byteOffset);
		Assert.equals(4, lastTwo.byteLength);

		assertElements([2, 3, 4, 5], array.subarray(1, -1));
		assertElements([1, 2], array.subarray(-100, 2));
		Assert.equals(0, array.subarray(-1, -3).length);
		Assert.equals(0, array.subarray(100).length);
	}

	public function testSubarraySharesBuffer():Void
	{
		var buffer = new ArrayBuffer(16);
		var array = new Int16Array(buffer, 4, 6);
		var sub = array.subarray(1, 3);
		Assert.isTrue(sub.buffer == buffer);
		Assert.equals(6, sub.byteOffset);
		Assert.equals(4, sub.byteLength);
		sub[1] = -3;
		Assert.equals(-3, array[2]);
		Assert.same([0, 0, 0, 0, 0, 0, 0, 0, 0xfd, 0xff, 0, 0, 0, 0, 0, 0], bytesOf(buffer));
	}

	public function testSetArrayWithOffset():Void
	{
		var array = new Int16Array(6);
		array.set([1, -2, 70000], 2);
		assertElements([0, 0, 1, -2, 4464, 0], array);

		Assert.raises(function():Void
		{
			array.set([7, 7, 7], 4);
		});
		assertElements([0, 0, 1, -2, 4464, 0], array);
	}

	#if !js
	// js.lib typed arrays only take Array<Int> in set
	public function testSetArrayOfFloatsTruncates():Void
	{
		var array = new Int16Array(3);
		array.set([1.9, -1.9, 32768.5]);
		assertElements([1, -1, -32768], array);
	}
	#end

	public function testSetTypedArrayConvertsValues():Void
	{
		var array = new Int16Array(4);
		array.set(new Int32Array([70000, -1]), 1);
		assertElements([0, 4464, -1, 0], array);

		array.set(new Int8Array([-128]), 3);
		assertElements([0, 4464, -1, -128], array);
	}

	public function testSetOverlappingViewOfSameBuffer():Void
	{
		var forward = new Int16Array([1, 2, 3, 4, 5, 6]);
		forward.set(forward.subarray(0, 4), 2);
		assertElements([1, 2, 1, 2, 3, 4], forward);

		var backward = new Int16Array([1, 2, 3, 4, 5, 6]);
		backward.set(backward.subarray(2), 0);
		assertElements([3, 4, 5, 6, 5, 6], backward);
	}

	@Ignored("Waiting on #2150")
	public function testSetOverlappingViewOfAnotherType():Void
	{
		// Int8 [1, 2, 3, 4] spread into Int16 elements 0 to 3 overwrite the bytes still to be read
		var buffer = new ArrayBuffer(8);
		var narrow = new Int8Array(buffer, 0, 4);
		narrow[0] = 1;
		narrow[1] = 2;
		narrow[2] = 3;
		narrow[3] = 4;
		var wide = new Int16Array(buffer);
		wide.set(narrow);
		assertElements([1, 2, 3, 4], wide);
	}

	@Ignored("Waiting on #2152")
	public function testOutOfBoundsWriteIsIgnored():Void
	{
		var buffer = new ArrayBuffer(8);
		var array = new Int16Array(buffer, 2, 2);
		array[2] = 9;
		array[-1] = 9;
		Assert.same([0, 0, 0, 0, 0, 0, 0, 0], bytesOf(buffer));
	}
}
