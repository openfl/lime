package utils;

import lime.utils.UInt8Array;
import lime.utils.DataView;
import lime.utils.ArrayBuffer;
import utest.Assert;
import utest.Test;

class ArrayBufferTest extends Test {
	public function new() {
		super();
	}

	public function testByteLength():Void {
		var buffer = new ArrayBuffer(4);
		Assert.equals(4, buffer.byteLength);
	}

	public function testSubarray():Void {
		var buffer = new ArrayBuffer(4);
		var array = new UInt8Array(buffer);
		array[0] = 0xca;
		array[1] = 0xfe;
		array[2] = 0xba;
		array[3] = 0xbe;

		var fourBuffer = buffer.slice(0, 4);
		Assert.equals(4, fourBuffer.byteLength);
		var fourArray = new UInt8Array(fourBuffer);
		Assert.equals(4, fourArray.byteLength);
		Assert.equals(0xca, fourArray[0]);
		Assert.equals(0xfe, fourArray[1]);
		Assert.equals(0xba, fourArray[2]);
		Assert.equals(0xbe, fourArray[3]);

		var twoStartBuffer = buffer.slice(0, 2);
		Assert.equals(2, twoStartBuffer.byteLength);
		var twoStartArray = new UInt8Array(twoStartBuffer);
		Assert.equals(2, twoStartArray.byteLength);
		Assert.equals(0xca, twoStartArray[0]);
		Assert.equals(0xfe, twoStartArray[1]);

		var twoEndBuffer = buffer.slice(2, 4);
		Assert.equals(2, twoEndBuffer.byteLength);
		var twoEndArray = new UInt8Array(twoEndBuffer);
		Assert.equals(2, twoEndArray.byteLength);
		Assert.equals(0xba, twoEndArray[0]);
		Assert.equals(0xbe, twoEndArray[1]);

		var endBeforeStartBuffer = buffer.slice(2, 1);
		Assert.equals(0, endBeforeStartBuffer.byteLength);
		var endBeforeStartArray = new UInt8Array(endBeforeStartBuffer);
		Assert.equals(0, endBeforeStartArray.byteLength);

		var endEqualsStartBuffer = buffer.slice(2, 2);
		Assert.equals(0, endEqualsStartBuffer.byteLength);
		var endEqualsStartArray = new UInt8Array(endEqualsStartBuffer);
		Assert.equals(0, endEqualsStartArray.byteLength);

		var beyondLengthBuffer = buffer.slice(0, 400);
		Assert.equals(4, beyondLengthBuffer.byteLength);
		var beyondLengthArray = new UInt8Array(beyondLengthBuffer);
		Assert.equals(4, beyondLengthArray.byteLength);
		Assert.equals(0xca, beyondLengthArray[0]);
		Assert.equals(0xfe, beyondLengthArray[1]);
		Assert.equals(0xba, beyondLengthArray[2]);
		Assert.equals(0xbe, beyondLengthArray[3]);
	}
}