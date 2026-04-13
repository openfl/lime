#ifndef LIME_UTILS_ARRAY_BUFFER_VIEW_H
#define LIME_UTILS_ARRAY_BUFFER_VIEW_H


#include <system/CFFI.h>
#include <utils/Bytes.h>


namespace lime {


	struct ArrayBufferView {

		hl_type* t;
		/*TypedArrayType*/ int type;
		Bytes* buffer;
		int byteOffset;
		int byteLength;
		int length;
		int bytesPerElement;

		ArrayBufferView (value arrayBufferView);
		~ArrayBufferView ();

		void Resize (int size);
		void Set (value bytes);
		void Set (const QuickVec<unsigned char> data);
		value Value ();
		value Value (value arrayBufferView);

	};


}


#endif