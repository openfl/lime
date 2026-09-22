#include <system/Mutex.h>
#include <system/System.h>
#include <utils/Bytes.h>
#include <map>


namespace lime {


	static int id_b;
	static int id_length;
	static bool init = false;
	static bool useBuffer = false;
	static std::map<Bytes*, bool> hadValue;
	static std::map<Bytes*, bool> usingValue;
	static Mutex mutex;


	inline void _initializeBytes () {

		if (!init) {

			id_b = val_id ("b");
			id_length = val_id ("length");

			buffer _buffer = alloc_buffer_len (1);

			if (buffer_data (_buffer)) {

				useBuffer = true;

			}

			init = true;

		}

	}


	Bytes::Bytes () {

		#ifndef LIME_HASHLINK
		_initializeBytes ();
		#endif

		b = 0;
		length = 0;

	}


	Bytes::Bytes (value bytes) {

		_initializeBytes ();

		b = 0;
		length = 0;

		Set (bytes);

	}


	Bytes::~Bytes () {

		mutex.Lock ();

		bool usingHaxeValue = (usingValue.find (this) != usingValue.end ());

		if (usingHaxeValue) {

			usingValue.erase (this);

		}

		if (!usingHaxeValue && b) {

			free (b);

		}

		if (hadValue.find (this) != hadValue.end ()) {

			hadValue.erase (this);

		}

		mutex.Unlock ();

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

			if (TryResize (size)) {

				lime::fread (b, 1, size, file);

			}

		}

		lime::fclose (file);

	}


	bool Bytes::TryResize (int size) {

		if (size != length || (length > 0 && !b)) {

			unsigned char* data = 0;
			unsigned char* oldB = b;
			bool freeOldB = false;

			if (size > 0) {

				data = (unsigned char*)malloc (sizeof (char) * size);

				if (!data) {

					return false;

				}

				if (b && length) {

					memcpy (data, b, length < size ? length : size);

				}

			}

			mutex.Lock ();

			if (usingValue.find (this) != usingValue.end ()) {

				usingValue.erase (this);

			} else if (oldB) {

				freeOldB = true;

			}

			b = data;
			length = size > 0 ? size : 0;

			mutex.Unlock ();

			if (freeOldB) {

				free (oldB);

			}

		}

		return (size == length || (size <= 0 && length == 0));

	}


	void Bytes::Resize (int size) {

		TryResize (size);

	}


	void Bytes::Set(value bytes) {

	    int newLength = 0;
	    unsigned char* newB = 0;
	    bool isNull = val_is_null(bytes);

	    if (!isNull) {

	        //here we can extract the values before calling our mutex to avoid potential deadlock or contention
	        value lengthVal = val_field(bytes, id_length);
	        value bVal = val_field(bytes, id_b);

	        newLength = val_int(lengthVal);

	        if (newLength > 0) {

	            if (val_is_string(bVal)) {
	                newB = (unsigned char*)val_string(bVal);
	            } else {
	                newB = (unsigned char*)buffer_data(val_to_buffer(bVal));
	            }
	        }
	    }

	    //and now it should be save to lock
	    mutex.Lock();

	    bool usingHaxeValue = (usingValue.find(this) != usingValue.end());

	    if (b) {

	        if (usingHaxeValue) {

	            usingValue.erase(this);
	            usingHaxeValue = false;

	        } else {

	            free(b);

	        }

	    } else if (usingHaxeValue) {

	        usingValue.erase(this);
	        usingHaxeValue = false;

	    }

	    if (isNull) {
	        length = 0;
	        b = 0;
	    } else {
	        hadValue[this] = true;
	        usingValue[this] = true;
	        length = newLength;
	        b = newB;
	    }

	    mutex.Unlock();
	}


	void Bytes::Set (const QuickVec<unsigned char> data) {

		int size = data.size ();

		if (size > 0) {

			if (TryResize (size)) {

				memcpy (b, &data[0], length);

			}

		} else {

			TryResize (0);

		}

	}


	value Bytes::Value () {

		return alloc_null ();

	}


	value Bytes::Value (value bytes) {

		if (val_is_null (bytes) || !b) {

			return alloc_null ();

		} else {

			alloc_field (bytes, id_length, alloc_int (length));

			if (useBuffer) {

				value _buffer = val_field (bytes, id_b);

				if (val_is_null (_buffer) || (char*)b != buffer_data (val_to_buffer (_buffer))) {

					buffer bufferValue = alloc_buffer_len (length);
					_buffer = buffer_val (bufferValue);
					memcpy ((unsigned char*)buffer_data (bufferValue), b, length);
					alloc_field (bytes, id_b, _buffer);

				}

			} else {

				value _string = val_field (bytes, id_b);

				if (val_is_null (_string) || (const char*)b != val_string (_string)) {

					value data = alloc_raw_string (length);
					memcpy ((void*)val_string (data), b, length);
					alloc_field (bytes, id_b, data);

				}

			}

			mutex.Lock ();
			hadValue[this] = true;
			mutex.Unlock ();

			return bytes;

		}

	}


}
