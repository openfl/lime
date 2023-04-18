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

		_initializeBytes ();

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

		if (hadValue.find (this) != hadValue.end ()) {

			hadValue.erase (this);

			if (usingValue.find (this) == usingValue.end () && b) {

				free (b);

			}

		}

		if (usingValue.find (this) != usingValue.end ()) {

			usingValue.erase (this);

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

			Resize (size);
			int status = lime::fread (b, 1, size, file);

		}

		lime::fclose (file);

	}


	void Bytes::Resize (int size) {

		if (size != length || (length > 0 && !b)) {

			mutex.Lock ();

			if (size <= 0) {

				if (b) {

					if (usingValue.find (this) != usingValue.end ()) {

						usingValue.erase (this);

					} else {

						free (b);

					}

					b = 0;
					length = 0;

				}

			} else {

				unsigned char* data = (unsigned char*)malloc (sizeof (char) * size);

				if (b) {

					if (length) {

						memcpy (data, b, length < size ? length : size);

					}

					if (usingValue.find (this) != usingValue.end ()) {

						usingValue.erase (this);

					} else {

						free (b);

					}

				} else if (usingValue.find (this) != usingValue.end ()) {

					usingValue.erase (this);

				}

				b = data;
				length = size;

			}

			mutex.Unlock ();

		}

	}


	void Bytes::Set (value bytes) {

		mutex.Lock ();

		if (val_is_null (bytes)) {

			if (usingValue.find (this) != usingValue.end ()) {

				usingValue.erase (this);

			}

			length = 0;
			b = 0;

		} else {

			hadValue[this] = true;
			usingValue[this] = true;

			length = val_int (val_field (bytes, id_length));

			if (length > 0) {

				value _b = val_field (bytes, id_b);

				if (val_is_string (_b)) {

					b = (unsigned char*)val_string (_b);

				} else {

					b = (unsigned char*)buffer_data (val_to_buffer (_b));

				}

			} else {

				b = 0;

			}

		}

		mutex.Unlock ();

	}


	void Bytes::Set (const QuickVec<unsigned char> data) {

		int size = data.size ();

		if (size > 0) {

			Resize (size);
			memcpy (b, &data[0], length);

		} else {

			mutex.Lock ();

			if (usingValue.find (this) != usingValue.end ()) {

				usingValue.erase (this);

			}

			mutex.Unlock ();

			b = 0;
			length = 0;

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