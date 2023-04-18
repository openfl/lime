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


	void LZMA::Compress (Bytes* data, Bytes* result) {

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


	void LZMA::Decompress (Bytes* data, Bytes* result) {

		SizeT inputBufferSize = data->length;
		Byte* inputBufferData = data->b;
		Int64 uncompressedLength = -1;

		ELzmaStatus status = LZMA_STATUS_NOT_SPECIFIED;
		ISzAlloc alloc = { LZMA_alloc, LZMA_free };
		CLzmaProps props = { 0 };

		LzmaProps_Decode (&props, inputBufferData, LZMA_PROPS_SIZE);
		uncompressedLength = READ_LE64 (inputBufferData + LZMA_PROPS_SIZE);

		result->Resize ((int)uncompressedLength);

		SizeT outputBufferSize = result->length;
		Byte* outputBufferData = result->b;

		Byte* _inputBufferData = inputBufferData + LZMA_PROPS_SIZE + sizeof (uncompressedLength);
		SizeT _inputBufferSize = inputBufferSize - LZMA_PROPS_SIZE - sizeof (uncompressedLength);

		LzmaDecode (outputBufferData, &outputBufferSize, _inputBufferData, &_inputBufferSize, inputBufferData, LZMA_PROPS_SIZE, LZMA_FINISH_ANY, &status, &alloc);

	}


}