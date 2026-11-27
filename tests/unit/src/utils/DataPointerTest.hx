package utils;

import haxe.io.Bytes;
import lime.utils.DataPointer;
#if (cpp && lime_cffi && lime_cairo && !macro)
import lime.graphics.cairo.Cairo;
import lime.graphics.cairo.CairoFormat;
import lime.graphics.cairo.CairoImageSurface;
#end
import utest.Assert;
import utest.Test;

/**
	The native addresses a `DataPointer` holds, and the memory behind them.

	On 64-bit Android, from Android 11 for apps that target SDK 30 or higher, the heap sets a tag
	in the top byte of every address it gives out, and ARM's Top-byte Ignore lets memory be read and
	written through the tagged address. Android's page on this
	(source.android.com/docs/security/test/tagged-pointers) names "a pointer cast to double and then
	back, losing the lower address bits" as a mistake that breaks apps, and a `DataPointer` is a
	`Float` on native targets. So a `DataPointer` has to keep every bit of an address with its top
	byte set, and an offset has to move it by exactly that many bytes. An address below 2^53, which
	every untagged one is, stays the number it always was.

	The tests build tagged addresses on C++, where Haxe code can. Those that only compare addresses
	never read through them, so they run on any 64-bit C++ target. Reading and writing through a
	tagged address needs Top-byte Ignore, which 64-bit ARM Linux and Android give user code, so that
	test runs there only.
**/
#if (cpp && lime_cffi && !macro)
@:cppFileCode('
#if defined(__aarch64__) && defined(__linux__)
#define LIME_TEST_TOP_BYTE_IGNORED true
#else
#define LIME_TEST_TOP_BYTE_IGNORED false
#endif
')
#end
class DataPointerTest extends Test
{
	public function new()
	{
		super();
	}

	#if (cpp && lime_cffi && !macro)
	public function testAddressesAByteApartAreDifferentPointers():Void
	{
		if (!is64Bit())
		{
			Assert.pass("A 32-bit address has no top byte to tag");
			return;
		}

		var a = address(0xB400007A, 0x12345678);
		var b = address(0xB400007A, 0x12345679);

		Assert.isFalse(a == b);
		Assert.isTrue(a != b);
	}

	public function testAnOffsetMovesATaggedAddressByThatManyBytes():Void
	{
		if (!is64Bit())
		{
			Assert.pass("A 32-bit address has no top byte to tag");
			return;
		}

		var a = address(0xB400007A, 0x12345678);

		for (offset in [1, 2, 4, 16, 64, 1000, 65536])
		{
			Assert.isTrue(a + offset == address(0xB400007A, 0x12345678 + offset), "+ " + offset);
			Assert.isFalse(a + offset == a, "+ " + offset);
			Assert.isTrue(a + offset - offset == a, "+ and - " + offset);
		}
	}

	public function testATaggedAddressIsNotNull():Void
	{
		if (!is64Bit())
		{
			Assert.pass("A 32-bit address has no top byte to tag");
			return;
		}

		var a = address(0xB4000000, 0);

		Assert.isFalse(a == 0);
		Assert.isTrue(a != 0);
	}

	public function testAnUntaggedAddressIsTheNumberItAlwaysWas():Void
	{
		var bytes = Bytes.alloc(16);
		var data = cpp.Pointer.arrayElem(bytes.getData(), 0).ptr;
		var tagged:Bool = untyped __cpp__('((unsigned long long)(uintptr_t){0} >> 53) != 0', data);

		if (tagged)
		{
			Assert.pass("This heap tags its addresses");
			return;
		}

		var expected:Float = untyped __cpp__('(double)(uintptr_t){0}', data);
		var pointer:DataPointer = bytes;

		Assert.equals(expected, (pointer : Float));
		Assert.equals(expected + 8, ((pointer + 8) : Float));
	}

	#if lime_cairo
	public function testCairoDrawsIntoTheMemoryATaggedAddressPointsAt():Void
	{
		if (!topByteIgnored())
		{
			Assert.pass("Only where the hardware ignores an address's top byte: 64-bit ARM Linux and Android");
			return;
		}

		var bytes = Bytes.alloc(65536);
		bytes.fill(0, bytes.length, 0);

		// 1040 bytes past a multiple of 2048, in the middle of the buffer, so that an address
		// rounded as a double rounds one with its top bit set (to a multiple of 2048) still
		// lands in this buffer, where the test sees it
		var offset = 32768;
		offset += (1040 - lowBits(bytes, offset)) & 2047;

		var surface = CairoImageSurface.create(taggedAddressOf(bytes, offset), CairoFormat.ARGB32, 4, 1, 16);
		var cairo = new Cairo(surface);
		cairo.setSourceRGBA(1, 1, 1, 1);
		cairo.paint();
		surface.flush();

		for (i in 0...16)
		{
			Assert.equals(0xFF, bytes.get(offset + i), "byte " + i);
		}

		Assert.equals(0, bytes.get(offset - 1));
		Assert.equals(0, bytes.get(offset + 16));
	}
	#end

	// An address made of two 32-bit halves, never read or written through
	private static function address(high:Int, low:Int):DataPointer
	{
		var pointer:cpp.Pointer<cpp.UInt8> = cpp.Pointer.fromRaw(untyped __cpp__('(unsigned char *)(uintptr_t)(((unsigned long long)(unsigned int){0} << 32) | (unsigned long long)(unsigned int){1})',
			high, low));
		return pointer;
	}

	// The address of a byte in `bytes`, with 0xB4 in its top byte
	private static function taggedAddressOf(bytes:Bytes, offset:Int):DataPointer
	{
		var data = cpp.Pointer.arrayElem(bytes.getData(), offset).ptr;
		var pointer:cpp.Pointer<cpp.UInt8> = cpp.Pointer.fromRaw(untyped __cpp__('(unsigned char *)(uintptr_t)((unsigned long long)(uintptr_t){0} | (0xB4ULL << 56))', data));
		return pointer;
	}

	private static function lowBits(bytes:Bytes, offset:Int):Int
	{
		var data = cpp.Pointer.arrayElem(bytes.getData(), offset).ptr;
		return untyped __cpp__('(int)((uintptr_t){0} & 2047)', data);
	}

	private static function is64Bit():Bool
	{
		return untyped __cpp__('(sizeof (void *) == 8)');
	}

	private static function topByteIgnored():Bool
	{
		return untyped __cpp__('LIME_TEST_TOP_BYTE_IGNORED');
	}
	#end
}
