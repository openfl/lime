#include <utils/ArrayBufferView.h>


namespace lime {


	static int id_buffer;
	static int id_byteLength;
	static int id_length;
	static bool init = false;


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

	}


	ArrayBufferView::~ArrayBufferView () {

		if (buffer) {

			delete buffer;

		}

	}


	void ArrayBufferView::Resize (int size) {

		buffer->Resize (size);

		byteLength = size;
		length = size;

	}


	void ArrayBufferView::Set (value bytes) {

		buffer->Set (bytes);
		byteLength = buffer->length;
		length = byteLength;

	}


	void ArrayBufferView::Set (const QuickVec<unsigned char> data) {

		buffer->Set (data);
		byteLength = buffer->length;
		length = byteLength;

	}


	value ArrayBufferView::Value () {

		return Value (alloc_empty_object ());

	}


	value ArrayBufferView::Value (value arrayBufferView) {

		if (!init) {

			id_buffer = val_id ("buffer");
			id_byteLength = val_id ("byteLength");
			id_length = val_id ("length");
			init = true;

		}

		alloc_field (arrayBufferView, id_buffer, buffer ? buffer->Value (val_field (arrayBufferView, id_buffer)) : alloc_null ());
		alloc_field (arrayBufferView, id_byteLength, alloc_int (byteLength));
		alloc_field (arrayBufferView, id_length, alloc_int (length));
		return arrayBufferView;

	}


}