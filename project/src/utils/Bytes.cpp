#include <system/System.h>
#include <utils/Bytes.h>


namespace lime {
	
	
	static int id_b;
	static int id_length;
	static bool init = false;
	static bool isHL = false;
	static bool useBuffer = false;
	
	
	inline void _initializeBytes () {
		
		if (!init) {
			
			id_b = val_id ("b");
			id_length = val_id ("length");
			
			buffer b = alloc_buffer_len (1);
			
			if (buffer_data (b)) {
				
				useBuffer = true;
				
			}
			
			init = true;
			
		}
		
	}
	
	
	Bytes::Bytes () {
		
		_initializeBytes ();
		
		_data = 0;
		_length = 0;
		_value = 0;
		_bytes = 0;
		
	}
	
	
	Bytes::Bytes (int size) {
		
		_initializeBytes ();
		
		_data = 0;
		_length = 0;
		_value = 0;
		_bytes = 0;
		
		Resize (size);
		
	}
	
	
	Bytes::Bytes (value bytes) {
		
		_initializeBytes ();
		
		_data = 0;
		_length = 0;
		_value = 0;
		_bytes = 0;
		
		Set (bytes);
		
	}
	
	
	Bytes::Bytes (HL_Bytes* bytes) {
		
		if (!init) {
			
			init = true;
			isHL = true;
			
		}
		
		// _initializeBytes ();
		
		_data = 0;
		_length = 0;
		_value = 0;
		_bytes = 0;
		
		Set (bytes);
		
	}
	
	
	Bytes::Bytes (const char* path) {
		
		_initializeBytes ();
		
		_data = 0;
		_length = 0;
		_value = 0;
		_bytes = 0;
		
		ReadFile (path);
		
	}
	
	
	Bytes::Bytes (const QuickVec<unsigned char> data) {
		
		_initializeBytes ();
		
		_data = 0;
		_length = 0;
		_value = 0;
		_bytes = 0;
		
		Set (data);
		
	}
	
	
	Bytes::~Bytes () {
		
		
		
	}
	
	
	unsigned char* Bytes::Data () {
		
		return (unsigned char*)_data;
		
	}
	
	
	const unsigned char* Bytes::Data () const {
		
		return (const unsigned char*)_data;
		
	}
	
	
	int Bytes::Length () const {
		
		return _length;
		
	}
	
	
	void Bytes::ReadFile (const char* path) {
		
		FILE_HANDLE *file = lime::fopen (path, "rb");
		
		if (!file) {
			
			return;
			
		}
		
		lime::fseek (file, 0, SEEK_END);
		int size = lime::ftell (file);
		lime::fseek (file, 0, SEEK_SET);
		
		if (size > 0) {
			
			Resize (size);
			int status = lime::fread (_data, 1, size, file);
			
		}
		
		lime::fclose (file);
		
	}
	
	
	void Bytes::Resize (int size) {
		
		if (size != _length) {
			
			if (isHL) {
				
				if (size <= 0) {
					
					if (_bytes && _bytes->b) {
						
						free (_bytes->b);
						_bytes->b = 0;
						_bytes->length = 0;
						_data = 0;
						
					}
					
				} else {
					
					unsigned char* data = (unsigned char*)malloc (sizeof (char) * size);
					
					if (_bytes->b && _bytes->length) {
						
						memcpy (data, _bytes->b, _bytes->length < size ? _bytes->length : size);
						free (_bytes->b);
						
					} else if (_bytes->b) {
						
						free (_bytes->b);
						
					}
					
					_bytes->b = data;
					_bytes->length = size;
					_data = data;
					
				}
				
			} else {
				
				if (!_value) {
					
					_value = alloc_empty_object ();
					
				}
				
				if (val_is_null (val_field (_value, id_b))) {
					
					value dataValue;
					
					if (useBuffer) {
						
						buffer b = alloc_buffer_len (size);
						dataValue = buffer_val (b);
						_data = (unsigned char*)buffer_data (b);
						
					} else {
						
						dataValue = alloc_raw_string (size);
						_data = (unsigned char*)val_string (dataValue);
						
					}
					
					alloc_field (_value, id_b, dataValue);
					
				} else {
					
					if (useBuffer) {
						
						buffer b = val_to_buffer (val_field (_value, id_b));
						buffer_set_size (b, size);
						_data = (unsigned char*)buffer_data (b);
						
					} else {
						
						value s = alloc_raw_string (size);
						memcpy ((char *)val_string (s), val_string (val_field (_value, id_b)), _length);
						alloc_field (_value, id_b, s);
						_data = (unsigned char*)val_string (s);
						
					}
					
				}
				
				alloc_field (_value, id_length, alloc_int (size));
				
			}
			
		}
		
		_length = size;
		
	}
	
	
	void Bytes::Set (value bytes) {
		
		if (val_is_null (bytes)) {
			
			_length = 0;
			_data = 0;
			_value = 0;
			
		} else {
			
			_value = bytes;
			_length = val_int (val_field (bytes, val_id ("length")));
			
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
	
	
	void Bytes::Set (HL_Bytes* bytes) {
		
		if (!bytes) {
			
			_bytes = 0;
			_length = 0;
			_data = 0;
			_value = 0;
			
		} else {
			
			_bytes = bytes;
			_value = 0;
			_length = bytes->length;
			
			if (_length > 0) {
				
				_data = bytes->b;
				
			} else {
				
				_data = 0;
				
			}
			
		}
		
	}
	
	
	void Bytes::Set (const QuickVec<unsigned char> data) {
		
		int size = data.size ();
		
		if (size > 0) {
			
			Resize (size);
			memcpy (_data, &data[0], _length);
			
		} else {
			
			_data = 0;
			_length = 0;
			
		}
		
	}
	
	
	void* Bytes::Value () {
		
		if (isHL) {
			
			return _bytes;
			
		} else if (_value) {
			
			return _value;
			
		} else {
			
			return alloc_null ();
			
		}
		
	}
	
	
}