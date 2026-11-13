package utils;

import lime.utils.ArrayBuffer;
import lime.utils.Float32Array;
import lime.utils.Int16Array;
import lime.utils.Int8Array;
import lime.utils.UInt8Array;
import lime.utils.UInt8ClampedArray;
import utest.Assert;
import utest.Test;

class Int8ArrayTest extends Test
{
	public function new()
	{
		super();
	}

	private function assertElements(expected:Array<Int>, array:Int8Array, ?pos:haxe.PosInfos):Void
	{
		Assert.equals(expected.length, array.length, "length", pos);
		for (i in 0...expected.length)
		{
			var value = array[i];
			Assert.equals(expected[i], value, 'Int8: expected ${expected[i]} but got $value at index $i', pos);
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
		var array = new Int8Array(buffer);
		Assert.equals(1, Int8Array.BYTES_PER_ELEMENT);
		Assert.equals(4, array.length);
		Assert.equals(4, array.byteLength);
		Assert.equals(0, array.byteOffset);
	}

	public function testConstructWithLength():Void
	{
		var array = new Int8Array(3);
		assertElements([0, 0, 0], array);
		Assert.equals(3, array.byteLength);
		Assert.equals(0, array.byteOffset);
		Assert.equals(3, array.buffer.byteLength);
	}

	public function testValues():Void
	{
		var buffer = new ArrayBuffer(4);
		var array = new Int8Array(buffer);
		assertElements([0, 0, 0, 0], array);
		array[0] = 0x7f;
		array[1] = -0x80;
		array[2] = -1;
		array[3] = 0x12;
		assertElements([0x7f, -0x80, -1, 0x12], array);
	}

	public function testValuesWrapAround():Void
	{
		// ToInt8: the value modulo 2^8, read as signed
		var values:Array<Int> = [0, 1, 127, 128, 255, 256, -1, -128, -129, 0x7fffffff, 0x12345678];
		var result:Array<Int> = [0, 1, 127, -128, -1, 0, -1, -128, 127, -1, 0x78];
		var array = new Int8Array(values.length);
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
		// ToInt8: NaN and infinities are 0, other values are truncated toward zero, then wrapped
		var array = new Int8Array([
			1.9, -1.9, 127.5, 128.5, 255.9, -0.5, 4294967301.0, Math.NaN, Math.POSITIVE_INFINITY, Math.NEGATIVE_INFINITY
		]);
		assertElements([1, -1, 127, -128, -1, 0, 5, 0, 0, 0], array);
	}

	public function testConstructFromArrayOfInts():Void
	{
		var array = new Int8Array([1, -2, 300]);
		assertElements([1, -2, 44], array);
		Assert.equals(3, array.byteLength);
		Assert.equals(0, array.byteOffset);
	}

	@Ignored("Waiting on #2150")
	public function testConstructFromTypedArrayConvertsValues():Void
	{
		var source = new Int16Array([300, -200, 127, -32768]);
		var array = new Int8Array(source);
		assertElements([44, 56, 127, 0], array);
		Assert.equals(4, array.byteLength);

		var floats = new Float32Array([1.5, -1.5, 200.7, Math.NaN]);
		assertElements([1, -1, -56, 0], new Int8Array(floats));

		var clamped = new UInt8ClampedArray([200, 0]);
		assertElements([-56, 0], new Int8Array(clamped));
	}

	public function testConstructFromTypedArrayCopies():Void
	{
		var source = new Int8Array([1, 2, 3]);
		var copy = new Int8Array(source);
		source[0] = 9;
		assertElements([1, 2, 3], copy);
		Assert.isFalse(source.buffer == copy.buffer);
		Assert.equals(0, copy.byteOffset);
	}

	@Ignored("Waiting on #2150")
	public function testConstructFromSubarrayStartsAtItsOffset():Void
	{
		var source = new Int8Array([1, 2, 3, 4, 5]);
		var copy = new Int8Array(source.subarray(2, 4));
		assertElements([3, 4], copy);
		Assert.equals(0, copy.byteOffset);
		// The new buffer holds only the copied elements
		Assert.equals(2, copy.buffer.byteLength);
	}

	public function testConstructFromBufferWithOffsetAndLength():Void
	{
		var buffer = new ArrayBuffer(8);
		var array = new Int8Array(buffer, 2, 4);
		Assert.equals(4, array.length);
		Assert.equals(4, array.byteLength);
		Assert.equals(2, array.byteOffset);
		Assert.isTrue(array.buffer == buffer);

		// The view shares the buffer
		array[0] = -1;
		array[3] = 0x12;
		Assert.same([0, 0, 0xff, 0, 0, 0x12, 0, 0], bytesOf(buffer));

		var rest = new Int8Array(buffer, 3);
		Assert.equals(5, rest.length);
		Assert.equals(3, rest.byteOffset);
		Assert.equals(0x12, rest[2]);
	}

	public function testConstructWithInvalidRangeThrows():Void
	{
		var buffer = new ArrayBuffer(4);
		// RangeError: the offset is past the end of the buffer
		Assert.raises(function():Void
		{
			new Int8Array(buffer, 5);
		});
		// RangeError: offset + length * 1 is past the end of the buffer
		Assert.raises(function():Void
		{
			new Int8Array(buffer, 2, 3);
		});
	}

	@Ignored("Waiting on #2151")
	public function testSubarray():Void
	{
		var array = new Int8Array([1, 2, 3, 4, 5, 6]);

		var middle = array.subarray(2, 4);
		assertElements([3, 4], middle);
		Assert.equals(2, middle.byteOffset);
		Assert.equals(2, middle.byteLength);

		var endBeforeStart = array.subarray(4, 2);
		Assert.equals(0, endBeforeStart.length);
		Assert.equals(0, endBeforeStart.byteLength);

		var beyondLength = array.subarray(4, 100);
		assertElements([5, 6], beyondLength);
	}

	@Ignored("Waiting on #2151")
	public function testSubarrayNegativeIndices():Void
	{
		// Negative indices count back from the end
		var array = new Int8Array([1, 2, 3, 4, 5, 6]);

		var lastTwo = array.subarray(-2);
		assertElements([5, 6], lastTwo);
		Assert.equals(4, lastTwo.byteOffset);

		assertElements([2, 3, 4, 5], array.subarray(1, -1));
		assertElements([1, 2], array.subarray(-100, 2));
		assertElements([4, 5], array.subarray(-3, -1));
		Assert.equals(0, array.subarray(-1, -3).length);
	}

	@Ignored("Waiting on #2151")
	public function testSubarrayBeginBeyondLengthIsEmpty():Void
	{
		var array = new Int8Array([1, 2, 3, 4, 5, 6]);
		Assert.equals(0, array.subarray(6).length);
		Assert.equals(0, array.subarray(100).length);
		Assert.equals(0, array.subarray(100, 200).length);
	}

	@Ignored("Waiting on #2151")
	public function testSubarrayEndBeyondLengthStaysInsideView():Void
	{
		// end is clamped to this view's length, even when the buffer continues past it
		var buffer = new ArrayBuffer(16);
		var array = new Int8Array(buffer, 0, 6);
		var sub = array.subarray(4, 100);
		Assert.equals(2, sub.length);
		Assert.equals(2, sub.byteLength);
		Assert.equals(4, sub.byteOffset);
	}

	public function testSubarraySharesBuffer():Void
	{
		var array = new Int8Array([1, 2, 3, 4, 5, 6]);
		var sub = array.subarray(2, 5);
		Assert.isTrue(sub.buffer == array.buffer);
		sub[0] = -7;
		Assert.equals(-7, array[2]);
		array[4] = 99;
		Assert.equals(99, sub[2]);

		// A subarray of a subarray is offset from the first
		var inner = sub.subarray(1, 3);
		assertElements([4, 99], inner);
		Assert.equals(3, inner.byteOffset);
	}

	@Ignored("Waiting on #2152")
	public function testSetArrayOfIntsWithOffset():Void
	{
		var array = new Int8Array(6);
		array.set([1, -2, 300], 2);
		assertElements([0, 0, 1, -2, 44, 0], array);

		// RangeError if the source does not fit, and nothing is written
		Assert.raises(function():Void
		{
			array.set([7, 7, 7], 4);
		});
		assertElements([0, 0, 1, -2, 44, 0], array);

		Assert.raises(function():Void
		{
			array.set([7], -1);
		});
	}

	@Ignored("Waiting on #2154")
	public function testSetWritesAtTheViewsOwnOffset():Void
	{
		// A view's indices start at its byteOffset, for set() as for []
		var buffer = new ArrayBuffer(8);
		var view = new Int8Array(buffer, 4, 4);

		view.set([1, 2]);
		Assert.same([0, 0, 0, 0, 1, 2, 0, 0], bytesOf(buffer));

		view.set([3], 3);
		Assert.same([0, 0, 0, 0, 1, 2, 0, 3], bytesOf(buffer));
	}

	@Ignored("Waiting on #2154")
	public function testSetTypedArrayWritesAtTheViewsOwnOffset():Void
	{
		var buffer = new ArrayBuffer(8);
		var view = new Int8Array(buffer).subarray(4);

		view.set(new Int8Array([5, 6]), 1);
		Assert.same([0, 0, 0, 0, 0, 5, 6, 0], bytesOf(buffer));

		view.set(new Int16Array([7]), 3);
		Assert.same([0, 0, 0, 0, 0, 5, 6, 7], bytesOf(buffer));
	}

	#if !js
	// js.lib typed arrays only take Array<Int> in set
	public function testSetArrayOfFloatsTruncates():Void
	{
		var array = new Int8Array(3);
		array.set([1.9, -1.9, 128.5]);
		assertElements([1, -1, -128], array);
	}
	#end

	#if neko
	@Ignored("Waiting on #2150")
	#end
	public function testSetTypedArrayConvertsValues():Void
	{
		var array = new Int8Array(4);
		array.set(new Int16Array([300, -1]), 1);
		assertElements([0, 44, -1, 0], array);

		array.set(new Float32Array([-2.5]), 3);
		assertElements([0, 44, -1, -2], array);
	}

	public function testSetOverlappingViewOfSameBuffer():Void
	{
		// The source is read as it was before any element is written
		var forward = new Int8Array([1, 2, 3, 4, 5, 6]);
		forward.set(forward.subarray(0, 4), 2);
		assertElements([1, 2, 1, 2, 3, 4], forward);

		var backward = new Int8Array([1, 2, 3, 4, 5, 6]);
		backward.set(backward.subarray(2), 0);
		assertElements([3, 4, 5, 6, 5, 6], backward);
	}

	@Ignored("Waiting on #2150")
	public function testSetOverlappingViewOfAnotherType():Void
	{
		var buffer = new ArrayBuffer(8);
		var wide = new Int16Array(buffer, 0, 2);
		wide[0] = 0x0102;
		wide[1] = 0x0304;
		var narrow = new Int8Array(buffer);
		// Writing narrow[2] changes wide[1]; the source values must be the ones from before
		narrow.set(wide, 2);
		Assert.same([0x02, 0x01, 0x02, 0x04, 0, 0, 0, 0], bytesOf(buffer));
	}

	@Ignored("Waiting on #2152")
	public function testOutOfBoundsWriteIsIgnored():Void
	{
		var buffer = new ArrayBuffer(6);
		var array = new Int8Array(buffer, 2, 2);
		// Integer-indexed exotic objects ignore writes outside [0, length)
		array[2] = 9;
		array[-1] = 9;
		Assert.same([0, 0, 0, 0, 0, 0], bytesOf(buffer));
		Assert.equals(2, array.length);
	}

	@Ignored("Waiting on #2152")
	public function testOutOfBoundsReadDoesNotSeeNeighbouringBytes():Void
	{
		var buffer = new ArrayBuffer(6);
		var bytes = new UInt8Array(buffer);
		bytes[1] = 0x55;
		bytes[4] = 0x55;
		var array = new Int8Array(buffer, 2, 2);
		// Reads outside [0, length) are undefined in ECMAScript, never the bytes next to the view
		Assert.notEquals(0x55, array[2]);
		Assert.notEquals(0x55, array[-1]);
	}
}
