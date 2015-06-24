#include <system/System.h>
#include <utils/Bytes.h>


namespace lime {
	
	
	static int id_b;
	static int id_length;
	static bool init = false;
	
	
	Bytes::Bytes () {
		
		_data = 0;
		_length = 0;
		_value = 0;
		
	}
	
	
	Bytes::Bytes (int size) {
		
		_data = (unsigned char*)malloc (size);
		_length = size;
		_value = 0;
		
	}
	
	
	Bytes::Bytes (value bytes) {
		
		Set (bytes);
		
	}
	
	
	Bytes::Bytes (const char* path) {
		
		FILE_HANDLE *file = lime::fopen (path, "rb");
		
		if (!file) {
			
			return;
			
		}
		
		lime::fseek (file, 0, SEEK_END);
		_length = lime::ftell (file);
		lime::fseek (file, 0, SEEK_SET);
		
		_data = (unsigned char*)malloc (_length);
		
		int status = lime::fread (_data, _length, 1, file);
		lime::fclose (file);
		delete file;
		
		_value = 0;
		
	}
	
	
	Bytes::Bytes (const QuickVec<unsigned char> data) {
		
		Set (data);
		
	}
	
	
	Bytes::~Bytes () {
		
		if (!_value && _data) {
			
			free (_data);
			
		}
		
	}
	
	
	unsigned char *Bytes::Data () {
		
		return (unsigned char*)_data;
		
	}
	
	
	const unsigned char *Bytes::Data () const {
		
		return (const unsigned char*)_data;
		
	}
	
	
	int Bytes::Length () const {
		
		return _length;
		
	}
	
	
	void Bytes::Resize (int size) {
		
		if (_value) {
			
			if (size > _length) {
				
				if (val_is_null (val_field (_value, id_b))) {
					
					buffer buf = alloc_buffer_len (size);
					_data = (unsigned char*)buffer_data (buf);
					
					if (_data) {
						
						alloc_field (_value, id_b, buffer_val (buf));
						
					} else {
						
						value newString = alloc_raw_string (size);
						alloc_field (_value, id_b, newString);
						_data = (unsigned char*)val_string (val_field (_value, id_b));
						memset (_data, 0, size);
						
					}
					
				} else {
					
					resizeByteData (_value, size);
					
				}
				
			}
			
			alloc_field (_value, id_length, alloc_int (size));
			
		} else {
			
			if (size > _length) {
				
				if (_data) {
					
					realloc (_data, size);
					
				} else {
					
					_data = (unsigned char*)malloc (size);
					
				}
				
			}
			
		}
		
		_length = size;
		
	}
	
	
	void Bytes::Set (value bytes) {
		
		if (!init) {
			
			id_b = val_id ("b");
			id_length = val_id ("length");
			init = true;
			
		}
		
		if (!_value && _data) {
			
			free (_data);
			
		}
		
		if (val_is_null (bytes)) {
			
			_length = 0;
			_data = 0;
			_value = 0;
			
		} else {
			
			_value = bytes;
			_length = val_int (val_field (bytes, id_length));
			
			if (_length > 0) {
				
				value b = val_field (bytes, id_b);
				
				if (val_is_string (b)) {
					
					_data = (unsigned char*)val_string (b);
					
				} else {
					
					_data = (unsigned char*)buffer_data (val_to_buffer (b));
					
				}
				
			} else {
				
				_data = 0;
				
			}
			
		}
		
	}
	
	
	void Bytes::Set (const QuickVec<unsigned char> data) {
		
		if (!_value && _data) {
			
			free (_data);
			
		}
		
		_length = data.size ();
		
		if (_length > 0) {
			
			_data = (unsigned char*)malloc (_length);
			memcpy (_data, &data[0], _length);
			
		} else {
			
			_data = 0;
			
		}
		
		_value = 0;
		
	}
	
	
	value Bytes::Value () {
		
		if (_value) {
			
			return _value;
			
		} else {
			
			if (!init) {
				
				id_b = val_id ("b");
				id_length = val_id ("length");
				init = true;
				
			}
			
			_value = alloc_empty_object ();
			
			if (_length > 0 && _data) {
				
				value newString = alloc_raw_string (_length);
				memcpy ((char*)val_string (newString), _data, _length);
				alloc_field (_value, id_b, newString);
				alloc_field (_value, id_length, alloc_int (_length));
				
			} else {
				
				alloc_field (_value, id_b, alloc_raw_string (0));
				alloc_field (_value, id_length, alloc_int (_length));
				
			}
			
			return _value;
			
		}
		
	}
	
	
}