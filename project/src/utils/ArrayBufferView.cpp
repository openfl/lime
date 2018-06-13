#include <utils/ArrayBufferView.h>


namespace lime {
	
	
	static int id_buffer;
	static int id_byteLength;
	static int id_length;
	static bool init = false;
	static bool isHL = false;
	
	
	ArrayBufferView::ArrayBufferView () {
		
		buffer = new Bytes ();
		byteLength = 0;
		length = 0;
		_value = 0;
		_bufferView = 0;
		
	}
	
	
	ArrayBufferView::ArrayBufferView (int size) {
		
		buffer = new Bytes (size);
		byteLength = size;
		length = size;
		_value = 0;
		_bufferView = 0;
		
	}
	
	
	ArrayBufferView::ArrayBufferView (value arrayBufferView) {
		
		if (!init) {
			
			id_buffer = val_id ("buffer");
			id_byteLength = val_id ("byteLength");
			id_length = val_id ("length");
			init = true;
			
		}
		
		if (!val_is_null (arrayBufferView)) {
			
			buffer = new Bytes (val_field (arrayBufferView, id_buffer));
			byteLength = val_int (val_field (arrayBufferView, id_byteLength));
			length = val_int (val_field (arrayBufferView, id_length));
			
		} else {
			
			buffer = new Bytes ();
			byteLength = 0;
			length = 0;
			
		}
		
		_value = arrayBufferView;
		_bufferView = 0;
		
	}
	
	
	ArrayBufferView::ArrayBufferView (HL_ArrayBufferView* arrayBufferView) {
		
		if (!init) {
			
			init = true;
			isHL = true;
			
		}
		
		if (arrayBufferView) {
			
			buffer = new Bytes (arrayBufferView->buffer);
			byteLength = arrayBufferView->byteLength;
			length = arrayBufferView->length;
			_bufferView = arrayBufferView;
			
		} else {
			
			buffer = 0;
			byteLength = 0;
			length = 0;
			_bufferView = 0;
			
		}
		
		_value = 0;
		
	}
	
	
	ArrayBufferView::~ArrayBufferView () {
		
		if (buffer) {
			
			delete buffer;
			
		}
		
	}
	
	
	unsigned char* ArrayBufferView::Data () {
		
		return buffer->Data ();
		
	}
	
	
	const unsigned char* ArrayBufferView::Data () const {
		
		return buffer->Data ();
		
	}
	
	
	int ArrayBufferView::Length () const {
		
		return buffer->Length ();
		
	}
	
	
	void ArrayBufferView::Resize (int size) {
		
		buffer->Resize (size);
		
		if (_bufferView) {
			
			_bufferView->byteLength = size;
			_bufferView->length = size; // ?
			
		}
		
		byteLength = size;
		length = size;
		
	}
	
	
	void ArrayBufferView::Set (value bytes) {
		
		buffer->Set (bytes);
		byteLength = buffer->Length ();
		length = byteLength;
		
	}
	
	
	void ArrayBufferView::Set (const QuickVec<unsigned char> data) {
		
		buffer->Set (data);
		byteLength = buffer->Length ();
		length = byteLength;
		
	}
	
	
	value ArrayBufferView::Value () {
		
		if (!init) {
			
			id_buffer = val_id ("buffer");
			id_byteLength = val_id ("byteLength");
			id_length = val_id ("length");
			init = true;
			
		}
		
		if (val_is_null (_value)) {
			
			_value = alloc_empty_object ();
			
		}
		
		alloc_field (_value, id_buffer, buffer ? (value)buffer->Value () : alloc_null ());
		alloc_field (_value, id_byteLength, alloc_int (byteLength));
		alloc_field (_value, id_length, alloc_int (length));
		return _value;
		
	}
	
	
}