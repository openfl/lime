#include <Lzma.h>
#include "lzma/LzmaEnc.h"
#include "lzma/LzmaDec.h"

namespace nme
{
	inline void WRITE_LE8 (unsigned char *ptr, char value) { *ptr = value; }
	inline void WRITE_LE16(unsigned char *ptr, short value) { WRITE_LE8 ((ptr) + 0, ((value) >> 0)); WRITE_LE8 ((ptr) + 1, ((value) >>  8)); }
	inline void WRITE_LE32(unsigned char *ptr, int value) { WRITE_LE16((ptr) + 0, ((value) >> 0)); WRITE_LE16((ptr) + 2, ((value) >> 16)); }
	inline void WRITE_LE64(unsigned char *ptr, Int64 value) { WRITE_LE32((ptr) + 0, ((value) >> 0)); WRITE_LE32((ptr) + 4, ((value) >> 32)); }

	inline unsigned char  READ_LE8 (unsigned char *ptr) { return *ptr; }
	inline unsigned short READ_LE16(unsigned char *ptr) { return ((unsigned short)READ_LE8 (ptr + 0) << 0) | ((unsigned short)READ_LE8 (ptr + 1) <<  8); }
	inline unsigned int   READ_LE32(unsigned char *ptr) { return ((unsigned int)READ_LE16(ptr + 0) << 0) | ((unsigned int)READ_LE16(ptr + 2) << 16); }
	inline UInt64         READ_LE64(unsigned char *ptr) { return ((UInt64)READ_LE32(ptr + 0) << 0) | ((UInt64)READ_LE32(ptr + 4) << 32); }

	extern "C" {
		SRes lzma_Progress(void *p, UInt64 inSize, UInt64 outSize) {
			return SZ_OK;
		}

		void *lzma_Alloc(void *p, size_t size) {
			return malloc(size);
		}
		void lzma_Free(void *p, void *address) { /* address can be 0 */
			if (address == NULL) return;
			free(address);
		}
	}

	void Lzma::Encode(buffer input_buffer, buffer output_buffer)
	{
		SizeT  input_buffer_size = buffer_size(input_buffer);
		Byte*  input_buffer_data = (Byte *)buffer_data(input_buffer);
		SizeT  output_buffer_size = input_buffer_size + 1024;
		Byte*  output_buffer_data = (Byte *)malloc(output_buffer_size);
		SizeT  props_size = 100;
		Byte*  props_data = (Byte *)malloc(props_size);
		Int64  uncompressed_length = input_buffer_size;
		CLzmaEncProps props = {0};
		LzmaEncProps_Init(&props);
		//props.level = 9;
		//props.dictSize = (1 << 24);
		//props.dictSize = (1 << 16);
		//props.dictSize = (1 << 10);
		props.dictSize = (1 << 20);
		/*
		props.lc = 8;
		props.lp = 0;
		props.pb = 2;
		props.algo = 1;
		props.fb = 273;
		props.btMode = 1;
		props.numHashBytes = 4;
		props.mc = 32;
		*/
		props.writeEndMark = 0;
		props.numThreads = 1;
		
		ICompressProgress progress = { lzma_Progress };
		ISzAlloc alloc_small = { lzma_Alloc, lzma_Free };
		ISzAlloc alloc_big = { lzma_Alloc, lzma_Free };

		LzmaEncode(
			output_buffer_data, &output_buffer_size,
			input_buffer_data, input_buffer_size,
			&props, props_data, &props_size, props.writeEndMark,
			&progress, &alloc_small, &alloc_big
		);
		
		unsigned char le_size[8];
		WRITE_LE64(&le_size[0], uncompressed_length);
		
		buffer_append_sub(output_buffer, (const char *)props_data, props_size);
		buffer_append_sub(output_buffer, (const char *)le_size, 8);
		buffer_append_sub(output_buffer, (const char *)output_buffer_data, output_buffer_size);
		
		free(props_data);
		free(output_buffer_data);
	}

	void Lzma::Decode(buffer input_buffer, buffer output_buffer)
	{
		SizeT  input_buffer_size = buffer_size(input_buffer);
		Byte*  input_buffer_data = (Byte *)buffer_data(input_buffer);
		Int64  uncompressed_length = -1;

		ELzmaStatus status = LZMA_STATUS_NOT_SPECIFIED;
		ISzAlloc alloc = { lzma_Alloc, lzma_Free };
		CLzmaProps props = {0};
		
		LzmaProps_Decode(&props, input_buffer_data, LZMA_PROPS_SIZE);
		uncompressed_length = READ_LE64(input_buffer_data + LZMA_PROPS_SIZE);
		
		SizeT output_buffer_size = (SizeT)uncompressed_length;
		Byte *output_buffer_data = (Byte *)malloc(output_buffer_size);

		Byte *_input_buffer_data = input_buffer_data + LZMA_PROPS_SIZE + sizeof(uncompressed_length);
		SizeT _input_buffer_size = input_buffer_size - LZMA_PROPS_SIZE - sizeof(uncompressed_length);

		LzmaDecode(
			output_buffer_data, &output_buffer_size,
			_input_buffer_data, &_input_buffer_size,
			input_buffer_data, LZMA_PROPS_SIZE,
			LZMA_FINISH_ANY,
			&status, &alloc
		);
		
		buffer_append_sub(output_buffer, (const char *)output_buffer_data, output_buffer_size);
	}
}
