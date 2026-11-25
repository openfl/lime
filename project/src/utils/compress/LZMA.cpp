#include <utils/compress/LZMA.h>
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


	void LZMA::Compress (Bytes* data, Bytes* result, int level) {

		SizeT inputBufferSize = data->length;
		Byte* inputBufferData = data->b;

		SizeT outputBufferSize = inputBufferSize + inputBufferSize / 5 + (1 << 16);
		Byte* outputBufferData = (Byte *)malloc (outputBufferSize);
		SizeT propsSize = 100;
		Byte* propsData = (Byte *)malloc (propsSize);
		Int64 uncompressedLength = inputBufferSize;

		CLzmaEncProps props = { 0 };
		LzmaEncProps_Init (&props);

		if (level < 0) {

			// No level is preset 5 with a 1 MB dictionary, as before levels could be chosen
			props.dictSize = (1 << 20);

		} else {

			props.level = level > 9 ? 9 : level;

			// The preset's dictionary, up to 64 MB, but no larger than the data, which is all the
			// encoder can use and all a decoder will allocate
			UInt32 presetDictSize = LzmaEncProps_GetDictSize (&props);
			UInt32 dictSize = (1 << 12);
			while (dictSize < presetDictSize && dictSize < inputBufferSize) dictSize <<= 1;
			props.dictSize = dictSize < presetDictSize ? dictSize : presetDictSize;

		}

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


	bool LZMA::Decompress (Bytes* data, Bytes* result) {

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
		// than the data holds can't make it allocate that much
		const SizeT chunkSize = 1 << 16;
		Byte* chunk = (Byte*)malloc (chunkSize);
		int written = 0;
		bool succeeded = false;

		if (chunk) {

			while (true) {

				if (sizeKnown && (UInt64)written == size) {

					succeeded = true;
					break;

				}

				SizeT outputSize = chunkSize;

				if (sizeKnown && size - written < outputSize) {

					outputSize = (SizeT)(size - written);

				}

				SizeT inputSize = inputLeft;
				ELzmaFinishMode finishMode = (sizeKnown && (UInt64)written + outputSize == size) ? LZMA_FINISH_END : LZMA_FINISH_ANY;
				ELzmaStatus status = LZMA_STATUS_NOT_SPECIFIED;

				SRes res = LzmaDec_DecodeToBuf (&state, chunk, &outputSize, input, &inputSize, finishMode, &status);

				input += inputSize;
				inputLeft -= inputSize;

				if (outputSize > 0) {

					if (!result->TryResize (written + (int)outputSize)) break;
					memcpy (result->b + written, chunk, outputSize);
					written += (int)outputSize;

				}

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

			free (chunk);

		}

		LzmaDec_Free (&state, &alloc);

		return succeeded;

	}


}