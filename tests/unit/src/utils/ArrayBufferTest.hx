package utils;

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
}