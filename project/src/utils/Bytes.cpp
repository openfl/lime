#include <system/System.h>
#include <utils/Bytes.h>


namespace lime {


	static int id_b;
	static int id_length;
	static bool init = false;
	static bool useBuffer = false;

	// Set as the type of a Bytes whose memory is a Haxe value's, borrowed by
	// Set (value), so that it isn't freed or reallocated here. A Bytes made in
	// C++ has no type of its own, and HashLink's own Bytes keep theirs. Each
	// Bytes keeps this itself, so making and destroying one takes no lock.
	static char borrowedMarker;
	#define BORROWED_TYPE ((hl_type*)&borrowedMarker)


	inline void _initializeBytes () {

		if (!init) {

			id_b = val_id ("b");
			id_length = val_id ("length");

			buffer _buffer = alloc_buffer_len (1);

			// Neko's buffers are strings one byte longer than asked for, ending in
			// a zero that Haxe's Bytes would then compare and copy, so Value () only
			// uses buffers that are the length given, and strings otherwise
			if (buffer_data (_buffer) && buffer_size (_buffer) == 1) {

				useBuffer = true;

			}

			init = true;

		}

	}


	Bytes::Bytes () {

		#ifndef LIME_HASHLINK
		_initializeBytes ();
		#endif

		t = 0;
		b = 0;
		length = 0;

	}


	Bytes::Bytes (value bytes) {

		_initializeBytes ();

		t = 0;
		b = 0;
		length = 0;

		Set (bytes);

	}


	Bytes::~Bytes () {

		if (t != BORROWED_TYPE && b) {

			free (b);

		}

	}


	bool Bytes::ReadFile (const char* path) {

		if (!path) return false;

		FILE_HANDLE *file = lime::fopen (path, "rb");

		if (!file) {

			return false;

		}

		lime::fseek (file, 0, SEEK_END);
		int size = lime::ftell (file);
		lime::fseek (file, 0, SEEK_SET);

		bool read = (size >= 0);

		if (size > 0) {

			read = TryResize (size) && lime::fread (b, 1, size, file) == (size_t)size;

		}

		lime::fclose (file);
		return read;

	}


	bool Bytes::TryResize (int size) {

		if (size != length || (length > 0 && !b)) {

			unsigned char* data = 0;
			unsigned char* oldB = b;
			bool freeOldB = false;

			if (size > 0 && b) {

				if (t != BORROWED_TYPE) {

					// Memory of its own is resized where it is when it can be, so
					// trimming it, or growing it in place, copies nothing
					data = (unsigned char*)realloc (b, sizeof (char) * size);

					if (!data) {

						return false;

					}

					b = data;
					length = size;
					return true;

				}

			}

			if (size > 0) {

				data = (unsigned char*)malloc (sizeof (char) * size);

				if (!data) {

					return false;

				}

				if (b && length) {

					memcpy (data, b, length < size ? length : size);

				}

			}

			if (t == BORROWED_TYPE) {

				t = 0;

			} else if (oldB) {

				freeOldB = true;

			}

			b = data;
			length = size > 0 ? size : 0;

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

	    if (b && t != BORROWED_TYPE) {

	        free(b);

	    }

	    if (isNull) {
	        t = 0;
	        length = 0;
	        b = 0;
	    } else {
	        t = BORROWED_TYPE;
	        length = newLength;
	        b = newB;
	    }
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

			return bytes;

		}

	}


}
