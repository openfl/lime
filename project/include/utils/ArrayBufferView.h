#ifndef LIME_UTILS_ARRAY_BUFFER_VIEW_H
#define LIME_UTILS_ARRAY_BUFFER_VIEW_H


#include <hx/CFFI.h>
#include <utils/Bytes.h>


namespace lime {
	
	
	class ArrayBufferView {
		
		
		public:
			
			ArrayBufferView ();
			ArrayBufferView (int size);
			ArrayBufferView (value arrayBufferView);
			~ArrayBufferView ();
			
			unsigned char *Data ();
			const unsigned char *Data () const;
			int Length () const;
			void Resize (int size);
			void Set (value bytes);
			void Set (const QuickVec<unsigned char> data);
			value Value ();
			
			Bytes *buffer;
			int byteLength;
			int length;
		
		private:
			
			value mValue;
		
		
	};
	
	
}


#endif