#include <utils/compress/LZMA.h>
#include <system/System.h>
#include "LzmaEnc.h"
#include "LzmaDec.h"


namespace lime {


	inline void WRITE_LE8 (unsigned char *ptr, char value) { *ptr = value; }
	inline void WRITE_LE16 (unsigned char *ptr, short value) { WRITE_LE8 ((ptr) + 0, ((value) >> 0)); WRITE_LE8 ((ptr) + 1, ((value) >>  8)); }
	inline void WRITE_LE32 (unsigned char *ptr, int value) { WRITE_LE16 ((ptr) + 0, ((value) >> 0)); WRITE_LE16 ((ptr) + 2, ((value) >> 16)); }
	inline void WRITE_LE64 (unsigned char *ptr, Int64 value) { WRITE_LE32 ((ptr) + 0, ((value) >> 0)); WRITE_LE32 ((ptr) + 4, ((value) >> 32)); }

	inline unsigned char READ_LE8 (unsigned char *ptr) { return *ptr; }
	inline unsigned short READ_LE16 (unsigned char *ptr) { return ((unsigned short)READ_LE8 (ptr + 0) << 0) | ((unsigned short)READ_LE8 (ptr + 1) <<  8); }
	inline unsigned int READ_LE32 (unsigned char *ptr) { return ((unsigned int)READ_LE16 (ptr + 0) << 0) | ((unsigned int)READ_LE16 (ptr + 2) << 16); }
	inline UInt64 READ_LE64 (unsigned char *ptr) { return ((UInt64)READ_LE32 (ptr + 0) << 0) | ((UInt64)READ_LE32 (ptr + 4) << 32); }


	extern "C" {

		SRes LZMA_progress (void *p, UInt64 inSize, UInt64 outSize) { return SZ_OK; }
		void *LZMA_alloc (void *p, size_t size) { return malloc (size); }

		void LZMA_free (void *p, void *address) {

			if (address == NULL) return;
			free (address);

		}

	}


	static void Encode (Bytes* data, Bytes* result);
	static bool Decode (Bytes* data, Bytes* result);


	// The LZMA coder only reads the input and writes the result's own memory,
	// so the collector needn't wait for this thread: compressing on a worker
	// thread otherwise holds up every collection until it finishes
	void LZMA::Compress (Bytes* data, Bytes* result) {

		System::GCEnterBlocking ();
		Encode (data, result);
		System::GCExitBlocking ();

	}


	bool LZMA::Decompress (Bytes* data, Bytes* result) {

		System::GCEnterBlocking ();
		bool decompressed = Decode (data, result);
		System::GCExitBlocking ();

		return decompressed;

	}


	static void Encode (Bytes* data, Bytes* result) {

		SizeT inputBufferSize = data->length;
		Byte* inputBufferData = data->b;

		SizeT outputBufferSize = inputBufferSize + inputBufferSize / 5 + (1 << 16);
		Byte* outputBufferData = (Byte *)malloc (outputBufferSize);
		SizeT propsSize = 100;
		Byte* propsData = (Byte *)malloc (propsSize);
		Int64 uncompressedLength = inputBufferSize;

		CLzmaEncProps props = { 0 };
		LzmaEncProps_Init (&props);
		props.dictSize = (1 << 20);
		props.writeEndMark = 0;
		props.numThreads = 1;

		ICompressProgress progress = { LZMA_progress };
		ISzAlloc allocSmall = { LZMA_alloc, LZMA_free };
		ISzAlloc allocBig = { LZMA_alloc, LZMA_free };

		LzmaEncode (outputBufferData, &outputBufferSize, inputBufferData, inputBufferSize, &props, propsData, &propsSize, props.writeEndMark, &progress, &allocSmall, &allocBig);

		result->Resize (outputBufferSize + propsSize + 8);
		Byte* resultData = result->b;

		memcpy (resultData, propsData, propsSize);
		WRITE_LE64 (resultData + propsSize, uncompressedLength);
		memcpy (resultData + propsSize + 8, outputBufferData, outputBufferSize);

		free (outputBufferData);
		free (propsData);

	}


	static bool Decode (Bytes* data, Bytes* result) {

		// The .lzma header: the properties, then the uncompressed size, all
		// ones when it isn't known and the data ends with an end marker
		const SizeT headerSize = LZMA_PROPS_SIZE + 8;

		if (!data->b || data->length < 0 || (SizeT)data->length < headerSize) return false;

		Byte* input = data->b + headerSize;
		SizeT inputLeft = (SizeT)data->length - headerSize;

		UInt64 size = READ_LE64 (data->b + LZMA_PROPS_SIZE);
		bool sizeKnown = (size != (UInt64)(Int64)-1);

		if (sizeKnown && size > 0x7FFFFFFF) return false;

		ISzAlloc alloc = { LZMA_alloc, LZMA_free };
		CLzmaDec state;
		LzmaDec_Construct (&state);

		if (LzmaDec_Allocate (&state, data->b, LZMA_PROPS_SIZE, &alloc) != SZ_OK) return false;

		LzmaDec_Init (&state);

		// The output grows as it is decoded, so a size field that claims more
		// than the data holds can't make it allocate that much. It is decoded
		// straight into the result, which grows by doubling and is trimmed at the
		// end: growing it to fit each chunk in turn copied everything so far.
		const int chunkSize = 1 << 16;
		int capacity = 0;
		int written = 0;
		bool succeeded = false;

		while (true) {

			if (sizeKnown && (UInt64)written == size) {

				succeeded = true;
				break;

			}

			if (capacity - written < chunkSize && !(sizeKnown && (UInt64)capacity >= size)) {

				if (capacity == 0x7FFFFFFF) break;

				SizeT grown = capacity < chunkSize ? chunkSize : (capacity > 0x3FFFFFFF ? 0x7FFFFFFF : (SizeT)capacity * 2);
				if (sizeKnown && grown > size) grown = (SizeT)size;
				if (!result->TryResize ((int)grown)) break;
				capacity = (int)grown;

			}

			SizeT outputSize = (SizeT)(capacity - written);

			if (sizeKnown && size - written < outputSize) {

				outputSize = (SizeT)(size - written);

			}

			SizeT inputSize = inputLeft;
			ELzmaFinishMode finishMode = (sizeKnown && (UInt64)written + outputSize == size) ? LZMA_FINISH_END : LZMA_FINISH_ANY;
			ELzmaStatus status = LZMA_STATUS_NOT_SPECIFIED;

			SRes res = LzmaDec_DecodeToBuf (&state, result->b + written, &outputSize, input, &inputSize, finishMode, &status);

			input += inputSize;
			inputLeft -= inputSize;
			written += (int)outputSize;

			if (res != SZ_OK) break;

			if (status == LZMA_STATUS_FINISHED_WITH_MARK) {

				// A marker before the stated size is a stream that ends early
				succeeded = !sizeKnown || (UInt64)written == size;
				break;

			}

			if (inputSize == 0 && outputSize == 0) {

				// The input ended before the stream did
				if (sizeKnown && (UInt64)written == size) succeeded = true;
				break;

			}

		}

		LzmaDec_Free (&state, &alloc);

		if (result->length != written) {

			result->TryResize (written);

		}

		return succeeded;

	}


}