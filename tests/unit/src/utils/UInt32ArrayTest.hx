package utils;

import lime.utils.UInt16Array;
import lime.utils.UInt32Array;
import lime.utils.UInt8Array;
import lime.utils.ArrayBuffer;
import utest.Assert;
import utest.Test;

class UInt32ArrayTest extends Test {
	public function new() {
		super();
	}

	public function testByteLength():Void {
		var buffer = new ArrayBuffer(16);
		var array = new UInt32Array(buffer);
		Assert.equals(4, array.length);
		Assert.equals(16, array.byteLength);
	}

	public function testValues():Void {
		var buffer = new ArrayBuffer(16);
		var array = new UInt32Array(buffer);
		Assert.equals(0x0, array[0]);
		Assert.equals(0x0, array[1]);
		Assert.equals(0x0, array[2]);
		Assert.equals(0x0, array[3]);

		array[0] = 0xcafebabe;
		array[1] = 0xdecafbad;
		array[2] = 0xffffffff;
		array[3] = 0xdeadbeef;
		#if js
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xcafebabe'), array[0]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xdecafbad'), array[1]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xffffffff'), array[2]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xdeadbeef'), array[3]);
		#else
		Assert.equals(0xcafebabe, array[0]);
		Assert.equals(0xdecafbad, array[1]);
		Assert.equals(0xffffffff, array[2]);
		Assert.equals(0xdeadbeef, array[3]);
		#end
	}

	public function testSubarray():Void {
		var buffer = new ArrayBuffer(16);
		var array = new UInt32Array(buffer);
		array[0] = 0xcafebabe;
		array[1] = 0xdecafbad;
		array[2] = 0xffffffff;
		array[3] = 0xdeadbeef;

		var four = array.subarray(0, 4);
		Assert.equals(4, four.length);
		Assert.equals(16, four.byteLength);
		#if js
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xcafebabe'), array[0]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xdecafbad'), array[1]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xffffffff'), array[2]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xdeadbeef'), array[3]);
		#else
		Assert.equals(0xcafebabe, four[0]);
		Assert.equals(0xdecafbad, four[1]);
		Assert.equals(0xffffffff, four[2]);
		Assert.equals(0xdeadbeef, four[3]);
		#end

		var twoStart = array.subarray(0, 2);
		Assert.equals(2, twoStart.length);
		Assert.equals(8, twoStart.byteLength);
		#if js
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xcafebabe'), twoStart[0]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xdecafbad'), twoStart[1]);
		#else
		Assert.equals(0xcafebabe, twoStart[0]);
		Assert.equals(0xdecafbad, twoStart[1]);
		#end

		var twoEnd = array.subarray(2, 4);
		Assert.equals(2, twoEnd.length);
		Assert.equals(8, twoEnd.byteLength);
		#if js
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xffffffff'), twoEnd[0]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xdeadbeef'), twoEnd[1]);
		#else
		Assert.equals(0xffffffff, twoEnd[0]);
		Assert.equals(0xdeadbeef, twoEnd[1]);
		#end

		var endBeforeStart = array.subarray(2, 1);
		Assert.equals(0, endBeforeStart.length);
		Assert.equals(0, endBeforeStart.byteLength);

		var endEqualsStart = array.subarray(2, 2);
		Assert.equals(0, endEqualsStart.length);
		Assert.equals(0, endEqualsStart.byteLength);

		var beyondLength = array.subarray(0, 400);
		Assert.equals(4, beyondLength.length);
		Assert.equals(16, beyondLength.byteLength);
		#if js
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xcafebabe'), array[0]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xdecafbad'), array[1]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xffffffff'), array[2]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xdeadbeef'), array[3]);
		#else
		Assert.equals(0xcafebabe, beyondLength[0]);
		Assert.equals(0xdecafbad, beyondLength[1]);
		Assert.equals(0xffffffff, beyondLength[2]);
		Assert.equals(0xdeadbeef, beyondLength[3]);
		#end
	}

	public function testSetArrayOfInts():Void {
		var array1:Array<Int> = [0xcafebabe, 0xdecafbad, 0xffffffff, 0xdeadbeef];

		var buffer2 = new ArrayBuffer(32);
		var array2 = new UInt32Array(buffer2);
		
		array2.set(array1);
		#if js
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xcafebabe'), array2[0]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xdecafbad'), array2[1]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xffffffff'), array2[2]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xdeadbeef'), array2[3]);
		#else
		Assert.equals(0xcafebabe, array2[0]);
		Assert.equals(0xdecafbad, array2[1]);
		Assert.equals(0xffffffff, array2[2]);
		Assert.equals(0xdeadbeef, array2[3]);
		#end
		Assert.equals(0x0, array2[4]);
		Assert.equals(0x0, array2[5]);
		Assert.equals(0x0, array2[6]);
		Assert.equals(0x0, array2[7]);

		for (i in 0...array2.length) {
			array2[i] = 0x0;
		}

		array2.set(array1, 1);
		Assert.equals(0x0, array2[0]);
		#if js
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xcafebabe'), array2[1]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xdecafbad'), array2[2]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xffffffff'), array2[3]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xdeadbeef'), array2[4]);
		#else
		Assert.equals(0xcafebabe, array2[1]);
		Assert.equals(0xdecafbad, array2[2]);
		Assert.equals(0xffffffff, array2[3]);
		Assert.equals(0xdeadbeef, array2[4]);
		#end
		Assert.equals(0x0, array2[5]);
		Assert.equals(0x0, array2[6]);
		Assert.equals(0x0, array2[7]);
	}

	private function testSetArrayOfIntsRangeError():Void
	{
		var array1:Array<Int> = [0xcafebabe, 0xdecafbad, 0xffffffff, 0xdeadbeef];

		var buffer2 = new ArrayBuffer(32);
		var array2 = new UInt32Array(buffer2);

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

		var buffer2 = new ArrayBuffer(32);
		var array2 = new UInt32Array(buffer2);

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
	}

	public function testSetUInt8ArrayRangeError():Void {
		var buffer1 = new ArrayBuffer(4);
		var array1 = new UInt8Array(buffer1);
		array1[0] = 0xca;
		array1[1] = 0xfe;
		array1[2] = 0xba;
		array1[3] = 0xbe;

		var buffer2 = new ArrayBuffer(32);
		var array2 = new UInt32Array(buffer2);

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

		var buffer2 = new ArrayBuffer(32);
		var array2 = new UInt32Array(buffer2);

		array2.set(array1);
		Assert.equals(0xcafe, array2[0]);
		Assert.equals(0xbabe, array2[1]);
		Assert.equals(0xdeca, array2[2]);
		Assert.equals(0xfbad, array2[3]);
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
		Assert.equals(0xcafe, array2[1]);
		Assert.equals(0xbabe, array2[2]);
		Assert.equals(0xdeca, array2[3]);
		Assert.equals(0xfbad, array2[4]);
		Assert.equals(0x0, array2[5]);
		Assert.equals(0x0, array2[6]);
		Assert.equals(0x0, array2[7]);
	}

	public function testSetUInt16ArrayRangeError():Void {
		var buffer1 = new ArrayBuffer(8);
		var array1 = new UInt16Array(buffer1);
		array1[0] = 0xcafe;
		array1[1] = 0xbabe;
		array1[2] = 0xdeca;
		array1[3] = 0xfbad;

		var buffer2 = new ArrayBuffer(32);
		var array2 = new UInt32Array(buffer2);

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

		var buffer2 = new ArrayBuffer(32);
		var array2 = new UInt32Array(buffer2);

		array2.set(array1);
		#if js
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xcafebabe'), array2[0]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xdecafbad'), array2[1]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xffffffff'), array2[2]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xdeadbeef'), array2[3]);
		#else
		Assert.equals(0xcafebabe, array2[0]);
		Assert.equals(0xdecafbad, array2[1]);
		Assert.equals(0xffffffff, array2[2]);
		Assert.equals(0xdeadbeef, array2[3]);
		#end
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
		#if js
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xcafebabe'), array2[1]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xdecafbad'), array2[2]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xffffffff'), array2[3]);
		Assert.equals(untyped #if haxe4 js.Syntax.code #else __js__ #end ('0xdeadbeef'), array2[4]);
		#else
		Assert.equals(0xcafebabe, array2[1]);
		Assert.equals(0xdecafbad, array2[2]);
		Assert.equals(0xffffffff, array2[3]);
		Assert.equals(0xdeadbeef, array2[4]);
		#end
		Assert.equals(0x0, array2[5]);
		Assert.equals(0x0, array2[6]);
		Assert.equals(0x0, array2[7]);
	}

	public function testSetUInt32ArrayRangeError():Void {
		var buffer1 = new ArrayBuffer(16);
		var array1 = new UInt32Array(buffer1);
		array1[0] = 0xcafebabe;
		array1[1] = 0xdecafbad;
		array1[2] = 0xffffffff;
		array1[3] = 0xdeadbeef;

		var buffer2 = new ArrayBuffer(32);
		var array2 = new UInt32Array(buffer2);

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