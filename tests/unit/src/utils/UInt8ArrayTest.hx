package utils;

import lime.utils.ArrayBuffer;
import lime.utils.UInt16Array;
import lime.utils.UInt32Array;
import lime.utils.UInt8Array;
import utest.Assert;
import utest.Test;

class UInt8ArrayTest extends Test {
	public function new() {
		super();
	}

	public function testByteLength():Void {
		var buffer = new ArrayBuffer(4);
		var array = new UInt8Array(buffer);
		Assert.equals(4, array.length);
		Assert.equals(4, array.byteLength);
	}

	public function testValues():Void {
		var buffer = new ArrayBuffer(4);
		var array = new UInt8Array(buffer);
		Assert.equals(0x0, array[0]);
		Assert.equals(0x0, array[1]);
		Assert.equals(0x0, array[2]);
		Assert.equals(0x0, array[3]);
		array[0] = 0xca;
		array[1] = 0xfe;
		array[2] = 0xba;
		array[3] = 0xbe;
		Assert.equals(0xca, array[0]);
		Assert.equals(0xfe, array[1]);
		Assert.equals(0xba, array[2]);
		Assert.equals(0xbe, array[3]);
	}

	public function testSubarray():Void {
		var buffer = new ArrayBuffer(4);
		var array = new UInt8Array(buffer);
		array[0] = 0xca;
		array[1] = 0xfe;
		array[2] = 0xba;
		array[3] = 0xbe;

		var four = array.subarray(0, 4);
		Assert.equals(4, four.length);
		Assert.equals(4, four.byteLength);
		Assert.equals(0xca, four[0]);
		Assert.equals(0xfe, four[1]);
		Assert.equals(0xba, four[2]);
		Assert.equals(0xbe, four[3]);

		var twoStart = array.subarray(0, 2);
		Assert.equals(2, twoStart.length);
		Assert.equals(2, twoStart.byteLength);
		Assert.equals(0xca, twoStart[0]);
		Assert.equals(0xfe, twoStart[1]);

		var twoEnd = array.subarray(2, 4);
		Assert.equals(2, twoEnd.length);
		Assert.equals(2, twoEnd.byteLength);
		Assert.equals(0xba, twoEnd[0]);
		Assert.equals(0xbe, twoEnd[1]);

		var endBeforeStart = array.subarray(2, 1);
		Assert.equals(0, endBeforeStart.length);
		Assert.equals(0, endBeforeStart.byteLength);

		var endEqualsStart = array.subarray(2, 2);
		Assert.equals(0, endEqualsStart.length);
		Assert.equals(0, endEqualsStart.byteLength);

		var beyondLength = array.subarray(0, 400);
		Assert.equals(4, beyondLength.length);
		Assert.equals(4, beyondLength.byteLength);
		Assert.equals(0xca, beyondLength[0]);
		Assert.equals(0xfe, beyondLength[1]);
		Assert.equals(0xba, beyondLength[2]);
		Assert.equals(0xbe, beyondLength[3]);
	}

	public function testSetArrayOfInts():Void {
		var array1:Array<Int> = [0xca, 0xfe, 0xba, 0xbe];

		var buffer2 = new ArrayBuffer(8);
		var array2 = new UInt8Array(buffer2);
		
		array2.set(array1);
		Assert.equals(0xca, array2[0]);
		Assert.equals(0xfe, array2[1]);
		Assert.equals(0xba, array2[2]);
		Assert.equals(0xbe, array2[3]);
		Assert.equals(0x0, array2[4]);
		Assert.equals(0x0, array2[5]);
		Assert.equals(0x0, array2[6]);
		Assert.equals(0x0, array2[7]);

		for (i in 0...array2.length) {
			array2[i] = 0x0;
		}

		array2.set(array1, 1);
		Assert.equals(0x0, array2[0]);
		Assert.equals(0xca, array2[1]);
		Assert.equals(0xfe, array2[2]);
		Assert.equals(0xba, array2[3]);
		Assert.equals(0xbe, array2[4]);
		Assert.equals(0x0, array2[5]);
		Assert.equals(0x0, array2[6]);
		Assert.equals(0x0, array2[7]);

		for (i in 0...array2.length) {
			array2[i] = 0x0;
		}

		Assert.raises(function():Void {
			array2.set(array1, 6);
		});
		Assert.equals(0x0, array2[0]);
		Assert.equals(0x0, array2[1]);
		Assert.equals(0x0, array2[2]);
		Assert.equals(0x0, array2[3]);
		Assert.equals(0x0, array2[4]);
		Assert.equals(0x0, array2[5]);
		Assert.equals(0x0, array2[6]);
		Assert.equals(0x0, array2[7]);
	}

	public function testSetUInt8Array():Void {
		var buffer1 = new ArrayBuffer(4);
		var array1 = new UInt8Array(buffer1);
		array1[0] = 0xca;
		array1[1] = 0xfe;
		array1[2] = 0xba;
		array1[3] = 0xbe;

		var buffer2 = new ArrayBuffer(8);
		var array2 = new UInt8Array(buffer2);

		array2.set(array1);
		Assert.equals(0xca, array2[0]);
		Assert.equals(0xfe, array2[1]);
		Assert.equals(0xba, array2[2]);
		Assert.equals(0xbe, array2[3]);
		Assert.equals(0x0, array2[4]);
		Assert.equals(0x0, array2[5]);
		Assert.equals(0x0, array2[6]);
		Assert.equals(0x0, array2[7]);

		// reset the array to all zeros
		for (i in 0...array2.length) {
			array2[i] = 0x0;
		}

		array2.set(array1, 1);
		Assert.equals(0x0, array2[0]);
		Assert.equals(0xca, array2[1]);
		Assert.equals(0xfe, array2[2]);
		Assert.equals(0xba, array2[3]);
		Assert.equals(0xbe, array2[4]);
		Assert.equals(0x0, array2[5]);
		Assert.equals(0x0, array2[6]);
		Assert.equals(0x0, array2[7]);

		for (i in 0...array2.length) {
			array2[i] = 0x0;
		}

		// if the array can't fit, it throws
		Assert.raises(function():Void {
			array2.set(array1, 6);
		});
		// in that case, none of the values should have been updated
		Assert.equals(0x0, array2[0]);
		Assert.equals(0x0, array2[1]);
		Assert.equals(0x0, array2[2]);
		Assert.equals(0x0, array2[3]);
		Assert.equals(0x0, array2[4]);
		Assert.equals(0x0, array2[5]);
		Assert.equals(0x0, array2[6]);
		Assert.equals(0x0, array2[7]);
	}

	public function testSetUInt16Array():Void {
		var buffer1 = new ArrayBuffer(8);
		var array1 = new UInt16Array(buffer1);
		array1[0] = 0xcafe;
		array1[1] = 0xbabe;
		array1[2] = 0xdeca;
		array1[3] = 0xfbad;

		var buffer2 = new ArrayBuffer(8);
		var array2 = new UInt8Array(buffer2);

		array2.set(array1);
		Assert.equals(0xfe, array2[0]);
		Assert.equals(0xbe, array2[1]);
		Assert.equals(0xca, array2[2]);
		Assert.equals(0xad, array2[3]);
		Assert.equals(0x0, array2[4]);
		Assert.equals(0x0, array2[5]);
		Assert.equals(0x0, array2[6]);
		Assert.equals(0x0, array2[7]);

		// reset the array to all zeros
		for (i in 0...array2.length) {
			array2[i] = 0x0;
		}

		array2.set(array1, 1);
		Assert.equals(0x0, array2[0]);
		Assert.equals(0xfe, array2[1]);
		Assert.equals(0xbe, array2[2]);
		Assert.equals(0xca, array2[3]);
		Assert.equals(0xad, array2[4]);
		Assert.equals(0x0, array2[5]);
		Assert.equals(0x0, array2[6]);
		Assert.equals(0x0, array2[7]);

		for (i in 0...array2.length) {
			array2[i] = 0x0;
		}

		// if the array can't fit, it throws
		Assert.raises(function():Void {
			array2.set(array1, 6);
		});
		// in that case, none of the values should have been updated
		Assert.equals(0x0, array2[0]);
		Assert.equals(0x0, array2[1]);
		Assert.equals(0x0, array2[2]);
		Assert.equals(0x0, array2[3]);
		Assert.equals(0x0, array2[4]);
		Assert.equals(0x0, array2[5]);
		Assert.equals(0x0, array2[6]);
		Assert.equals(0x0, array2[7]);
	}

	public function testSetUInt32Array():Void {
		var buffer1 = new ArrayBuffer(16);
		var array1 = new UInt32Array(buffer1);
		array1[0] = 0xcafebabe;
		array1[1] = 0xdecafbad;
		array1[2] = 0xffffffff;
		array1[3] = 0xdeadbeef;

		var buffer2 = new ArrayBuffer(8);
		var array2 = new UInt8Array(buffer2);

		array2.set(array1);
		Assert.equals(0xbe, array2[0]);
		Assert.equals(0xad, array2[1]);
		Assert.equals(0xff, array2[2]);
		Assert.equals(0xef, array2[3]);
		Assert.equals(0x0, array2[4]);
		Assert.equals(0x0, array2[5]);
		Assert.equals(0x0, array2[6]);
		Assert.equals(0x0, array2[7]);

		// reset the array to all zeros
		for (i in 0...array2.length) {
			array2[i] = 0x0;
		}

		array2.set(array1, 1);
		Assert.equals(0x0, array2[0]);
		Assert.equals(0xbe, array2[1]);
		Assert.equals(0xad, array2[2]);
		Assert.equals(0xff, array2[3]);
		Assert.equals(0xef, array2[4]);
		Assert.equals(0x0, array2[5]);
		Assert.equals(0x0, array2[6]);
		Assert.equals(0x0, array2[7]);

		for (i in 0...array2.length) {
			array2[i] = 0x0;
		}

		// if the array can't fit, it throws
		Assert.raises(function():Void {
			array2.set(array1, 6);
		});
		// in that case, none of the values should have been updated
		Assert.equals(0x0, array2[0]);
		Assert.equals(0x0, array2[1]);
		Assert.equals(0x0, array2[2]);
		Assert.equals(0x0, array2[3]);
		Assert.equals(0x0, array2[4]);
		Assert.equals(0x0, array2[5]);
		Assert.equals(0x0, array2[6]);
		Assert.equals(0x0, array2[7]);
	}
}