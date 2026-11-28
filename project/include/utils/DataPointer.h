#ifndef LIME_UTILS_DATA_POINTER_H
#define LIME_UTILS_DATA_POINTER_H


#include <stdint.h>
#include <string.h>


namespace lime {


	// A DataPointer reaches Haxe as a double, which holds an address below 2^53 exactly
	// as that number. On 64-bit Android from Android 11, the heap sets a tag in the top
	// byte of every address it gives out, and a double can't hold all 64 bits, so the
	// low ones would be rounded off
	// (source.android.com/docs/security/test/tagged-pointers). Such an address moves its
	// top byte down to bits 52 to 59 and is held as the bits of a double from 2^53 up,
	// which no address below 2^53 can be. Every bit is kept, and two addresses with the
	// same top byte keep their order. An address that uses bits 52 to 55 can't be moved
	// so, and is held as a number, as it always was.

	static const uint64_t DATA_POINTER_LIMIT = (uint64_t)1 << 53;
	// The bits of the double 2^53
	static const uint64_t DATA_POINTER_BASE = 0x4340000000000000ULL;
	static const uint64_t DATA_POINTER_LOW_BITS = 0x000FFFFFFFFFFFFFULL;
	static const uint64_t DATA_POINTER_SPARE_BITS = 0x00F0000000000000ULL;


	inline double DataPointerFromAddress (uintptr_t address) {

		uint64_t value = (uint64_t)address;

		if (value < DATA_POINTER_LIMIT || (value & DATA_POINTER_SPARE_BITS) != 0) {

			return (double)value;

		}

		uint64_t bits = DATA_POINTER_BASE + (((value >> 56) << 52) | (value & DATA_POINTER_LOW_BITS));
		double result;
		memcpy (&result, &bits, sizeof (result));
		return result;

	}


	inline uintptr_t DataPointerToAddress (double value) {

		if (!(value >= (double)DATA_POINTER_LIMIT)) {

			return (uintptr_t)value;

		}

		uint64_t bits;
		memcpy (&bits, &value, sizeof (bits));
		uint64_t payload = bits - DATA_POINTER_BASE;
		return (uintptr_t)(((payload >> 52) << 56) | (payload & DATA_POINTER_LOW_BITS));

	}


}


#endif
