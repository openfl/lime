#include <system/System.h>
#include <utils/Bytes.h>


namespace lime {
	
	
	static int id_b;
	static int id_length;
	static bool init = false;

	static void initId () {

		if (!init) {

			id_b = val_id ("b");
			id_length = val_id ("length");
			init = true;

		}

	}
	
	static unsigned char *getPointerFromBytes (value _value) {
		
		if (val_is_null (_value))
			return NULL;
		
		initId ();
		value b = val_field (_value, id_b);
		if (val_is_buffer (b))
			return (unsigned char *)buffer_data (val_to_buffer (b));
		else
			return (unsigned char *)val_string (b);
		
	}
	
	Bytes::Bytes () {
		
		_value = 0;
		
	}
	
	
	Bytes::Bytes (int size) {

		_value = 0;
		Resize (size);
		
	}
	
	
	Bytes::Bytes (value bytes) {
		
		_value = bytes;
		
	}
	
	
	Bytes::Bytes (const char* path) {
		
		_value = 0;
		FILE_HANDLE *file = lime::fopen (path, "rb");
		
		if (!file) {
			
			return;
			
		}
		
		lime::fseek (file, 0, SEEK_END);
		long int length = lime::ftell (file);
		lime::fseek (file, 0, SEEK_SET);
		
		Resize (length);
		void *data = Data ();
		
		int status = lime::fread (data, length, 1, file);
		lime::fclose (file);
		delete file;
		
	}
	
	
	Bytes::Bytes (const QuickVec<unsigned char> data) {
		
		_value = 0;
		int length = data.size ();
		
		if (length > 0) {
			
			Resize (length);
			unsigned char *_data = Data ();
			memcpy (_data, &data[0], length);
			
		}
		
	}
	
	
	Bytes::~Bytes () {}


	unsigned char *Bytes::Data () {
		
		return getPointerFromBytes (_value);
		
	}
	
	
	const unsigned char *Bytes::Data () const {
		
		return getPointerFromBytes (_value);
		
	}
	
	
	int Bytes::Length () const {
		
		initId ();
		return !val_is_null(_value) ? val_int (val_field (_value, id_length)) : NULL;
		
	}
	
	
	void Bytes::Resize (int size) {
		
		initId ();
		
		void *src;
		if (_value == 0)
		{
			
			_value = alloc_empty_object ();
			src = NULL;
			
		} else {
			
			src = Data ();
			
		}
		
		buffer buf = alloc_buffer_len (size);
		value bufVal = buffer_val (buf);
		if (val_is_null (bufVal)) {
			
			bufVal = buffer_to_string (buf);
			memset ((void*)val_string (bufVal), 0, size);
			
		}
		alloc_field (_value, id_b, bufVal);
		alloc_field (_value, id_length, alloc_int (size));
		
		if (src != NULL)
		{
			
			memcpy (Data (), src, size);
			
		}
		
	}


	value Bytes::Value () {
		
		return _value;
		
	}
	
	
}