#include <utils/ArrayBufferView.h>


namespace lime {
	
	
	static int id_buffer;
	static int id_byteLength;
	static int id_length;
	static bool init = false;
	
	
	ArrayBufferView::ArrayBufferView () {
		
		byteLength = 0;
		length = 0;
		mValue = 0;
		
	}
	
	
	ArrayBufferView::ArrayBufferView (int size) {
		
		buffer.Resize (size);
		byteLength = size;
		length = size;
		mValue = 0;
		
	}
	
	
	ArrayBufferView::ArrayBufferView (value arrayBufferView) {
		
		Set (arrayBufferView);
		
	}
	
	
	ArrayBufferView::~ArrayBufferView () {
		
	}
	
	
	void ArrayBufferView::Clear () {
		
		buffer.Clear ();
		byteLength = 0;
		length = 0;
		mValue = 0;
		
	}
	
	
	unsigned char *ArrayBufferView::Data () {
		
		return buffer.Data ();
		
	}
	
	
	const unsigned char *ArrayBufferView::Data () const {
		
		return buffer.Data ();
		
	}
	
	
	int ArrayBufferView::Length () const {
		
		return buffer.Length ();
		
	}
	
	
	void ArrayBufferView::Resize (int size) {
		
		buffer.Resize (size);
		byteLength = size;
		length = size;
		
	}
	
	
	void ArrayBufferView::Set (value arrayBufferView) {
		
		if (!init) {
			
			id_buffer = val_id ("buffer");
			id_byteLength = val_id ("byteLength");
			id_length = val_id ("length");
			init = true;
			
		}
		
		if (!val_is_null (arrayBufferView)) {
			
			buffer.Set (val_field (arrayBufferView, id_buffer));
			byteLength = val_int (val_field (arrayBufferView, id_byteLength));
			length = val_int (val_field (arrayBufferView, id_length));
			
		} else {
			
			buffer.Clear ();
			byteLength = 0;
			length = 0;
			
		}
		
		mValue = arrayBufferView;
		
	}
	
	
	void ArrayBufferView::Set (const QuickVec<unsigned char> data) {
		
		buffer.Set (data);
		byteLength = buffer.Length ();
		length = byteLength;
		
	}
	
	
	value ArrayBufferView::Value () {
		
		if (!init) {
			
			id_buffer = val_id ("buffer");
			id_byteLength = val_id ("byteLength");
			id_length = val_id ("length");
			init = true;
			
		}
		
		if (mValue == 0 || val_is_null (mValue)) {
			
			mValue = alloc_empty_object ();
			
		}
		
		alloc_field (mValue, id_buffer, buffer.Value ());
		alloc_field (mValue, id_byteLength, alloc_int (byteLength));
		alloc_field (mValue, id_length, alloc_int (length));
		return mValue;
		
	}
	
	
}