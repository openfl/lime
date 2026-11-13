package utils;

import lime.utils.ArrayBuffer;
import lime.utils.Float32Array;
import lime.utils.Float64Array;
import lime.utils.Int16Array;
import lime.utils.Int32Array;
import lime.utils.Int8Array;
import lime.utils.UInt32Array;
import lime.utils.UInt8Array;
import utest.Assert;
import utest.Test;

class Int32ArrayTest extends Test
{
	public function new()
	{
		super();
	}

	private function assertElements(expected:Array<Int>, array:Int32Array, ?pos:haxe.PosInfos):Void
	{
		Assert.equals(expected.length, array.length, "length", pos);
		for (i in 0...expected.length)
		{
			var value = array[i];
			Assert.equals(expected[i], value, 'Int32: expected ${expected[i]} but got $value at index $i', pos);
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
		var array = new Int32Array(buffer);
		Assert.equals(4, Int32Array.BYTES_PER_ELEMENT);
		Assert.equals(4, array.length);
		Assert.equals(16, array.byteLength);
		Assert.equals(0, array.byteOffset);
	}

	public function testConstructWithLength():Void
	{
		var array = new Int32Array(3);
		assertElements([0, 0, 0], array);
		Assert.equals(12, array.byteLength);
		Assert.equals(12, array.buffer.byteLength);
	}

	public function testValues():Void
	{
		var buffer = new ArrayBuffer(24);
		var array = new Int32Array(buffer);
		var values:Array<Int> = [0, 1, 0x7fffffff, 0x80000000, -1, 0xcafebabe];
		for (i in 0...values.length)
		{
			array[i] = values[i];
		}
		assertElements([0, 1, 2147483647, -2147483648, -1, 0xcafebabe], array);
	}

	#if neko
	@Ignored("Waiting on #2152")
	#end
	public function testConstructFromArrayOfFloatsWrapsAround():Void
	{
		// ToInt32: NaN and infinities are 0, other values are truncated toward zero, then taken modulo 2^32
		var array = new Int32Array([
			1.9, -1.9, 2147483648.0, 4294967295.0, 4294967296.0, 4294967297.5, -2147483649.0, 3e9, Math.NaN, Math.POSITIVE_INFINITY,
			Math.NEGATIVE_INFINITY
		]);
		assertElements([1, -1, -2147483648, -1, 0, 1, 2147483647, -1294967296, 0, 0, 0], array);
	}

	@Ignored("Waiting on #2150")
	public function testConstructFromTypedArrayConvertsValues():Void
	{
		assertElements([-2147483648, -1, -1294967296], new Int32Array(new Float64Array([2147483648.0, -1.5, 3e9])));
		assertElements([-1, 0x7fffffff], new Int32Array(new UInt32Array([0xffffffff, 0x7fffffff])));
		// Each element converts by value, not by bytes
		var narrow = new Int32Array(new Int8Array([-1, -128]));
		assertElements([-1, -128], narrow);
		Assert.equals(8, narrow.byteLength);
		assertElements([16777216, -3], new Int32Array(new Float32Array([16777217.0, -3.75])));
	}

	public function testConstructFromSubarrayStartsAtItsOffset():Void
	{
		var source = new Int32Array([1, 2, 3, 4, 5]);
		var copy = new Int32Array(source.subarray(3));
		assertElements([4, 5], copy);
		Assert.equals(0, copy.byteOffset);
		Assert.equals(8, copy.byteLength);
	}

	public function testConstructFromBufferWithOffsetAndLength():Void
	{
		var buffer = new ArrayBuffer(16);
		var array = new Int32Array(buffer, 4, 2);
		Assert.equals(2, array.length);
		Assert.equals(8, array.byteLength);
		Assert.equals(4, array.byteOffset);
		array[1] = -2;
		Assert.same([0, 0, 0, 0, 0, 0, 0, 0, 0xfe, 0xff, 0xff, 0xff, 0, 0, 0, 0], bytesOf(buffer));

		var rest = new Int32Array(buffer, 8);
		Assert.equals(2, rest.length);
		Assert.equals(-2, rest[0]);
	}

	public function testConstructWithMisalignedOffsetThrows():Void
	{
		var buffer = new ArrayBuffer(16);
		// RangeError: byteOffset must be a multiple of the element size
		Assert.raises(function():Void
		{
			new Int32Array(buffer, 2);
		});
		Assert.raises(function():Void
		{
			new Int32Array(buffer, 1, 1);
		});
	}

	public function testConstructWithInvalidRangeThrows():Void
	{
		Assert.raises(function():Void
		{
			new Int32Array(new ArrayBuffer(6));
		});
		Assert.raises(function():Void
		{
			new Int32Array(new ArrayBuffer(8), 4, 2);
		});
	}

	public function testLittleEndian():Void
	{
		var array = new Int32Array([0x01020304, -2]);
		Assert.same([0x04, 0x03, 0x02, 0x01, 0xfe, 0xff, 0xff, 0xff], bytesOf(array.buffer));

		var buffer = new ArrayBuffer(4);
		var bytes = new UInt8Array(buffer);
		bytes[3] = 0x80;
		assertElements([-2147483648], new Int32Array(buffer));
	}

	@Ignored("Waiting on #2151")
	public function testSubarray():Void
	{
		var array = new Int32Array([1, 2, 3, 4, 5, 6]);

		var middle = array.subarray(2, 4);
		assertElements([3, 4], middle);
		Assert.equals(8, middle.byteOffset);
		Assert.equals(8, middle.byteLength);

		Assert.equals(0, array.subarray(4, 2).length);
		assertElements([5, 6], array.subarray(4, 100));
	}

	@Ignored("Waiting on #2151")
	public function testSubarrayNegativeIndices():Void
	{
		var array = new Int32Array([1, 2, 3, 4, 5, 6]);

		var lastTwo = array.subarray(-2);
		assertElements([5, 6], lastTwo);
		Assert.equals(16, lastTwo.byteOffset);

		assertElements([2, 3, 4, 5], array.subarray(1, -1));
		assertElements([1, 2], array.subarray(-100, 2));
		Assert.equals(0, array.subarray(-1, -3).length);
		Assert.equals(0, array.subarray(100).length);
	}

	public function testSubarraySharesBuffer():Void
	{
		var array = new Int32Array([1, 2, 3, 4]);
		var sub = array.subarray(1, 3);
		Assert.isTrue(sub.buffer == array.buffer);
		sub[0] = 0xcafebabe;
		Assert.equals(0xcafebabe, array[1]);
	}

	public function testSetArrayWithOffset():Void
	{
		var array = new Int32Array(4);
		array.set([1, -2], 2);
		assertElements([0, 0, 1, -2], array);

		Assert.raises(function():Void
		{
			array.set([7, 7], 3);
		});
		assertElements([0, 0, 1, -2], array);
	}

	#if !js
	// js.lib typed arrays only take Array<Int> in set
	#if neko
	@Ignored("Waiting on #2152")
	#end
	public function testSetArrayOfFloatsWrapsAround():Void
	{
		var array = new Int32Array(3);
		array.set([4294967297.0, -1.9, Math.NaN]);
		assertElements([1, -1, 0], array);
	}
	#end

	public function testSetTypedArrayConvertsValues():Void
	{
		var array = new Int32Array(4);
		array.set(new Int16Array([-1, 0x7fff]), 1);
		assertElements([0, -1, 0x7fff, 0], array);

		array.set(new UInt32Array([0xfffffffe]), 3);
		assertElements([0, -1, 0x7fff, -2], array);
	}

	@Ignored("Waiting on #2150")
	public function testSetFloat32ArrayConvertsValues():Void
	{
		// Float32 and Int32 elements are both 4 bytes, but set copies values, not bytes
		var array = new Int32Array(2);
		array.set(new Float32Array([1.5, -2.5]));
		assertElements([1, -2], array);
	}

	public function testSetOverlappingViewOfSameBuffer():Void
	{
		var forward = new Int32Array([1, 2, 3, 4, 5, 6]);
		forward.set(forward.subarray(0, 4), 2);
		assertElements([1, 2, 1, 2, 3, 4], forward);
	}

	@Ignored("Waiting on #2150")
	public function testSetOverlappingViewOfAnotherType():Void
	{
		var buffer = new ArrayBuffer(16);
		var narrow = new Int16Array(buffer, 0, 4);
		narrow[0] = 1;
		narrow[1] = 2;
		narrow[2] = 3;
		narrow[3] = 4;
		var wide = new Int32Array(buffer);
		wide.set(narrow);
		assertElements([1, 2, 3, 4], wide);
	}

	@Ignored("Waiting on #2152")
	public function testOutOfBoundsWriteIsIgnored():Void
	{
		var buffer = new ArrayBuffer(16);
		var array = new Int32Array(buffer, 4, 2);
		array[2] = 9;
		array[-1] = 9;
		Assert.same([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], bytesOf(buffer));
	}
}
