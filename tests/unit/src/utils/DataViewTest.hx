package utils;

import haxe.Int64;
import lime.utils.DataView;
import lime.utils.ArrayBuffer;
import utest.Assert;
import utest.Test;

class DataViewTest extends Test {
	public function new() {
		super();
	}

	public function testInt8():Void {
		var values:Array<Int> = [0, 1, 2, 127,  128, 255, -1, -2, -128, -129];
		var result:Array<Int> = [0, 1, 2, 127, -128,  -1, -1, -2, -128,  127];
		Assert.equals(values.length, result.length);
		var count = values.length;
		var buffer = new ArrayBuffer(count);
		var dataView = new DataView(buffer);
		for (i in 0...count) {
			var value = values[i];
			dataView.setInt8(i, value);
		}
		for (i in 0...count) {
			var value = dataView.getInt8(i);
			var expected = result[i];
			Assert.equals(expected, value, 'Int8: expected $expected but got $value at index $i');
		}
	}

	public function testUint8():Void {
		var values:Array<Int> = [0, 1, 2, 255, 256,  -1,  -2, -255];
		var result:Array<Int> = [0, 1, 2, 255,   0, 255, 254,    1];
		Assert.equals(values.length, result.length);
		var count = values.length;
		var buffer = new ArrayBuffer(count);
		var dataView = new DataView(buffer);
		for (i in 0...count) {
			var value = values[i];
			dataView.setUint8(i, value);
		}
		for (i in 0...count) {
			var value = dataView.getUint8(i);
			var expected = result[i];
			Assert.equals(expected, value, 'Uint8: expected $expected but got $value at index $i');
		}
	}

	public function testInt16():Void {
		var values:Array<Int> = [0, 1, 2, 32767,  32768, 65535, -1, -2, -32768, -32769];
		var result:Array<Int> = [0, 1, 2, 32767, -32768,    -1, -1, -2, -32768,  32767];
		var resultBytesLE:Array<Array<Int>> = [
			[0x00, 0x00],
			[0x01, 0x00],
			[0x02, 0x00],
			[0xff, 0x7f],
			[0x00, 0x80],
			[0xff, 0xff],
			[0xff, 0xff],
			[0xfe, 0xff],
			[0x00, 0x80],
			[0xff, 0x7f]
		];
		Assert.equals(values.length, result.length);
		Assert.equals(values.length, resultBytesLE.length);
		var count = values.length;
		var buffer = new ArrayBuffer(count * 2);
		var dataView = new DataView(buffer);

		// little endian
		for (i in 0...count) {
			var byteIndex = i * 2;
			var value = values[i];
			dataView.setInt16(byteIndex, value);
		}
		for (i in 0...count) {
			var byteIndex = i * 2;
			var value = dataView.getInt16(byteIndex);
			var expected = result[i];
			Assert.equals(expected, value, 'Int16 little endian: expected $expected but got $value at index $i');
			var valueBytes = [
				dataView.getUint8(byteIndex),
				dataView.getUint8(byteIndex + 1)
			];
			var expectedBytesLE = resultBytesLE[i];
			Assert.equals(2, expectedBytesLE.length);
			Assert.equals(expectedBytesLE[0], valueBytes[0], 'Int16 little endian: expected byte 0 to be ${StringTools.hex(expectedBytesLE[0])} but got ${StringTools.hex(valueBytes[0])} at index $i');
			Assert.equals(expectedBytesLE[1], valueBytes[1], 'Int16 little endian: expected byte 1 to be ${StringTools.hex(expectedBytesLE[1])} but got ${StringTools.hex(valueBytes[1])} at index $i');
		}

		// big endian
		for (i in 0...count) {
			var byteIndex = i * 2;
			var value = values[i];
			dataView.setInt16(byteIndex, value, false);
		}
		for (i in 0...count) {
			var byteIndex = i * 2;
			var value = dataView.getInt16(byteIndex, false);
			var expected = result[i];
			Assert.equals(expected, value, 'Int16 big endian: expected $expected but got $value at index $i');
			var valueBytes = [
				dataView.getUint8(byteIndex),
				dataView.getUint8(byteIndex + 1)
			];
			var expectedBytesBE = resultBytesLE[i].copy();
			expectedBytesBE.reverse(); // big endian is little endian reversed
			Assert.equals(2, expectedBytesBE.length);
			Assert.equals(expectedBytesBE[0], valueBytes[0], 'Int16 big endian: expected byte 0 to be ${StringTools.hex(expectedBytesBE[0])} but got ${StringTools.hex(valueBytes[0])} at index $i');
			Assert.equals(expectedBytesBE[1], valueBytes[1], 'Int16 big endian: expected byte 1 to be ${StringTools.hex(expectedBytesBE[1])} but got ${StringTools.hex(valueBytes[1])} at index $i');
		}
	}

	public function testUint16():Void {
		var values:Array<Int> = [0, 1, 2, 65535, 65536,    -1,    -2, -65535];
		var result:Array<Int> = [0, 1, 2, 65535,     0, 65535, 65534,      1];
		var resultBytesLE:Array<Array<Int>> = [
			[0x00, 0x00],
			[0x01, 0x00],
			[0x02, 0x00],
			[0xff, 0xff],
			[0x00, 0x00],
			[0xff, 0xff],
			[0xfe, 0xff],
			[0x01, 0x00]
		];
		Assert.equals(values.length, result.length);
		Assert.equals(values.length, resultBytesLE.length);
		var count = values.length;
		var buffer = new ArrayBuffer(count * 2);
		var dataView = new DataView(buffer);

		// little endian
		for (i in 0...count) {
			var byteIndex = i * 2;
			var value = values[i];
			dataView.setUint16(byteIndex, value);
		}
		for (i in 0...count) {
			var byteIndex = i * 2;
			var value = dataView.getUint16(byteIndex);
			var expected = result[i];
			Assert.equals(expected, value, 'Uint16 little endian: expected $expected but got $value at index $i');
			var valueBytes = [
				dataView.getUint8(byteIndex),
				dataView.getUint8(byteIndex + 1)
			];
			var expectedBytesLE = resultBytesLE[i];
			Assert.equals(2, expectedBytesLE.length);
			Assert.equals(expectedBytesLE[0], valueBytes[0], 'Uint16 little endian: expected byte 0 to be ${StringTools.hex(expectedBytesLE[0])} but got ${StringTools.hex(valueBytes[0])} at index $i');
			Assert.equals(expectedBytesLE[1], valueBytes[1], 'Uint16 little endian: expected byte 1 to be ${StringTools.hex(expectedBytesLE[1])} but got ${StringTools.hex(valueBytes[1])} at index $i');
		}

		// big endian
		for (i in 0...count) {
			var byteIndex = i * 2;
			var value = values[i];
			dataView.setUint16(byteIndex, value, false);
		}
		for (i in 0...count) {
			var byteIndex = i * 2;
			var value = dataView.getUint16(byteIndex, false);
			var expected = result[i];
			Assert.equals(expected, value, 'Uint16 big endian: expected $expected but got $value at index $i');
			var valueBytes = [
				dataView.getUint8(byteIndex),
				dataView.getUint8(byteIndex + 1)
			];
			var expectedBytesBE = resultBytesLE[i].copy();
			expectedBytesBE.reverse(); // big endian is little endian reversed
			Assert.equals(2, expectedBytesBE.length);
			Assert.equals(expectedBytesBE[0], valueBytes[0], 'Uint16 big endian: expected byte 0 to be ${StringTools.hex(expectedBytesBE[0])} but got ${StringTools.hex(valueBytes[0])} at index $i');
			Assert.equals(expectedBytesBE[1], valueBytes[1], 'Uint16 big endian: expected byte 1 to be ${StringTools.hex(expectedBytesBE[1])} but got ${StringTools.hex(valueBytes[1])} at index $i');
		}
	}

	public function testInt32():Void {
		var values:Array<Int> = [0, 1, 2, 2147483647, -1, -2, -2147483648];
		var result:Array<Int> = [0, 1, 2, 2147483647, -1, -2, -2147483648];
		var resultBytesLE:Array<Array<Int>> = [
			[0x00, 0x00, 0x00, 0x00],
			[0x01, 0x00, 0x00, 0x00],
			[0x02, 0x00, 0x00, 0x00],
			[0xff, 0xff, 0xff, 0x7f],
			[0xff, 0xff, 0xff, 0xff],
			[0xfe, 0xff, 0xff, 0xff],
			[0x00, 0x00, 0x00, 0x80]
		];
		Assert.equals(values.length, result.length);
		Assert.equals(values.length, resultBytesLE.length);
		var count = values.length;
		var buffer = new ArrayBuffer(count * 4);
		var dataView = new DataView(buffer);

		// little endian
		for (i in 0...count) {
			var byteIndex = i * 4;
			var value = values[i];
			dataView.setInt32(byteIndex, value);
		}
		for (i in 0...count) {
			var byteIndex = i * 4;
			var value = dataView.getInt32(byteIndex);
			var expected = result[i];
			Assert.equals(expected, value, 'Int32 little endian: expected $expected but got $value at index $i');

			var valueBytes = [
				dataView.getUint8(byteIndex),
				dataView.getUint8(byteIndex + 1),
				dataView.getUint8(byteIndex + 2),
				dataView.getUint8(byteIndex + 3)
			];
			var expectedBytesLE = resultBytesLE[i];
			Assert.equals(4, expectedBytesLE.length);
			Assert.equals(expectedBytesLE[0], valueBytes[0], 'Int32 little endian: expected byte 0 to be ${StringTools.hex(expectedBytesLE[0])} but got ${StringTools.hex(valueBytes[0])} at index $i');
			Assert.equals(expectedBytesLE[1], valueBytes[1], 'Int32 little endian: expected byte 1 to be ${StringTools.hex(expectedBytesLE[1])} but got ${StringTools.hex(valueBytes[1])} at index $i');
			Assert.equals(expectedBytesLE[2], valueBytes[2], 'Int32 little endian: expected byte 2 to be ${StringTools.hex(expectedBytesLE[2])} but got ${StringTools.hex(valueBytes[2])} at index $i');
			Assert.equals(expectedBytesLE[3], valueBytes[3], 'Int32 little endian: expected byte 3 to be ${StringTools.hex(expectedBytesLE[3])} but got ${StringTools.hex(valueBytes[3])} at index $i');
		}

		// big endian
		for (i in 0...count) {
			var byteIndex = i * 4;
			var value = values[i];
			dataView.setInt32(byteIndex, value, false);
		}
		for (i in 0...count) {
			var byteIndex = i * 4;
			var value = dataView.getInt32(byteIndex, false);
			var expected = result[i];
			Assert.equals(expected, value, 'Int32 big endian: expected $expected but got $value at index $i');

			var valueBytes = [
				dataView.getUint8(byteIndex),
				dataView.getUint8(byteIndex + 1),
				dataView.getUint8(byteIndex + 2),
				dataView.getUint8(byteIndex + 3)
			];
			var expectedBytesBE = resultBytesLE[i].copy();
			expectedBytesBE.reverse(); // big endian is little endian reversed
			Assert.equals(4, expectedBytesBE.length);
			Assert.equals(expectedBytesBE[0], valueBytes[0], 'Int32 big endian: expected byte 0 to be ${StringTools.hex(expectedBytesBE[0])} but got ${StringTools.hex(valueBytes[0])} at index $i');
			Assert.equals(expectedBytesBE[1], valueBytes[1], 'Int32 big endian: expected byte 1 to be ${StringTools.hex(expectedBytesBE[1])} but got ${StringTools.hex(valueBytes[1])} at index $i');
			Assert.equals(expectedBytesBE[2], valueBytes[2], 'Int32 big endian: expected byte 2 to be ${StringTools.hex(expectedBytesBE[2])} but got ${StringTools.hex(valueBytes[2])} at index $i');
			Assert.equals(expectedBytesBE[3], valueBytes[3], 'Int32 big endian: expected byte 3 to be ${StringTools.hex(expectedBytesBE[3])} but got ${StringTools.hex(valueBytes[3])} at index $i');
		}
	}

	public function testUint32():Void {
		var values:Array<UInt> = [0, 1, 2, 0xffffffff, 0xdeadbeef, 0xcafebabe, 0xdecafbad];
		var resultBytesLE:Array<Array<Int>> = [
			[0x00, 0x00, 0x00, 0x00],
			[0x01, 0x00, 0x00, 0x00],
			[0x02, 0x00, 0x00, 0x00],
			[0xff, 0xff, 0xff, 0xff],
			[0xef, 0xbe, 0xad, 0xde],
			[0xbe, 0xba, 0xfe, 0xca],
			[0xad, 0xfb, 0xca, 0xde]
		];
		Assert.equals(values.length, resultBytesLE.length);
		var count = values.length;
		var buffer = new ArrayBuffer(count * 4);
		var dataView = new DataView(buffer);

		// little endian
		for (i in 0...count) {
			var byteIndex = i * 4;
			var value = values[i];
			dataView.setUint32(byteIndex, value);
		}
		for (i in 0...count) {
			var byteIndex = i * 4;
			var valueBytes = [
				dataView.getUint8(byteIndex),
				dataView.getUint8(byteIndex + 1),
				dataView.getUint8(byteIndex + 2),
				dataView.getUint8(byteIndex + 3)
			];
			var expectedBytesLE = resultBytesLE[i];
			Assert.equals(4, expectedBytesLE.length);
			Assert.equals(expectedBytesLE[0], valueBytes[0], 'Uint32 little endian: expected byte 0 to be ${StringTools.hex(expectedBytesLE[0])} but got ${StringTools.hex(valueBytes[0])} at index $i');
			Assert.equals(expectedBytesLE[1], valueBytes[1], 'Uint32 little endian: expected byte 1 to be ${StringTools.hex(expectedBytesLE[1])} but got ${StringTools.hex(valueBytes[1])} at index $i');
			Assert.equals(expectedBytesLE[2], valueBytes[2], 'Uint32 little endian: expected byte 2 to be ${StringTools.hex(expectedBytesLE[2])} but got ${StringTools.hex(valueBytes[2])} at index $i');
			Assert.equals(expectedBytesLE[3], valueBytes[3], 'Uint32 little endian: expected byte 3 to be ${StringTools.hex(expectedBytesLE[3])} but got ${StringTools.hex(valueBytes[3])} at index $i');
		}

		// big endian
		for (i in 0...count) {
			var byteIndex = i * 4;
			var value = values[i];
			dataView.setUint32(byteIndex, value, false);
		}
		for (i in 0...count) {
			var byteIndex = i * 4;
			var valueBytes = [
				dataView.getUint8(byteIndex),
				dataView.getUint8(byteIndex + 1),
				dataView.getUint8(byteIndex + 2),
				dataView.getUint8(byteIndex + 3)
			];
			var expectedBytesBE = resultBytesLE[i].copy();
			expectedBytesBE.reverse(); // big endian is little endian reversed
			Assert.equals(4, expectedBytesBE.length);
			Assert.equals(expectedBytesBE[0], valueBytes[0], 'Uint32 big endian: expected byte 0 to be ${StringTools.hex(expectedBytesBE[0])} but got ${StringTools.hex(valueBytes[0])} at index $i');
			Assert.equals(expectedBytesBE[1], valueBytes[1], 'Uint32 big endian: expected byte 1 to be ${StringTools.hex(expectedBytesBE[1])} but got ${StringTools.hex(valueBytes[1])} at index $i');
			Assert.equals(expectedBytesBE[2], valueBytes[2], 'Uint32 big endian: expected byte 2 to be ${StringTools.hex(expectedBytesBE[2])} but got ${StringTools.hex(valueBytes[2])} at index $i');
			Assert.equals(expectedBytesBE[3], valueBytes[3], 'Uint32 big endian: expected byte 3 to be ${StringTools.hex(expectedBytesBE[3])} but got ${StringTools.hex(valueBytes[3])} at index $i');
		}
	}
}