#if defined (IPHONE) || defined (TVOS) || (defined (HX_MACOS) && !defined (LIME_OPENALSOFT))
#include <OpenAL/al.h>
#include <OpenAL/alc.h>
#else
#include "AL/al.h"
#include "AL/alc.h"
#ifdef LIME_OPENALSOFT
#include "AL/alext.h"
#endif
#endif

#include <hx/CFFIPrime.h>
#include <system/CFFIPointer.h>
#include <utils/ArrayBufferView.h>
#include <map>


namespace lime {
	
	
	std::map<ALuint, value> alObjects;
	std::map<void*, value> alcObjects;
	
	
	void lime_al_delete_buffer (value buffer);
	void lime_al_delete_source (value source);
	void lime_al_delete_filter (value filter);
	
	void gc_al_buffer (value buffer) {
		
		lime_al_delete_buffer (buffer);
		
	}
	
	
	void gc_al_source (value source) {
		
		lime_al_delete_source (source);
		
	}

	void gc_al_filter(value filter) {
		lime_al_delete_filter(filter);
	}
	
	
	void gc_alc_object (value object) {
		
		alcObjects.erase (val_data (object));
		
	}
	
	
	void lime_al_buffer_data (value buffer, int format, value data, int size, int freq) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		ArrayBufferView bufferView (data);
		alBufferData (id, format, bufferView.Data (), size, freq);
		
	}
	
	
	void lime_al_buffer3f (value buffer, int param, float value1, float value2, float value3) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		alBuffer3f (id, param, value1, value2, value3);
		
	}
	
	
	void lime_al_buffer3i (value buffer, int param, int value1, int value2, int value3) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		alBuffer3i (id, param, value1, value2, value3);
		
	}
	
	
	void lime_al_bufferf (value buffer, int param, float value) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		alBufferf (id, param, value);
		
	}
	
	
	void lime_al_bufferfv (value buffer, int param, value values) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		
		if (val_is_null (values) == false) {
			
			int size = val_array_size (values);
			ALfloat *data = new ALfloat[size];
			
			for (int i = 0; i < size; ++i) {
				
				data[i] = (ALfloat)val_float (val_array_i (values, i));
				
			}
			
			alBufferfv (id, param, data);
			delete[] data;
			
		}
		
	}
	
	
	void lime_al_bufferi (value buffer, int param, int value) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		alBufferi (id, param, value);
		
	}
	
	
	void lime_al_bufferiv (value buffer, int param, value values) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		
		if (val_is_null (values) == false) {
			
			int size = val_array_size (values);
			ALint* data = new ALint[size];
			
			for (int i = 0; i < size; ++i) {
				
				data[i] = (ALint)val_int (val_array_i (values, i));
				
			}
			
			alBufferiv (id, param, data);
			delete[] data;
			
		}
		
	}
	
	
	void lime_al_cleanup () {
		
		ALCcontext* alcContext = alcGetCurrentContext ();
		
		if (alcContext) {
			
			ALCdevice* alcDevice = alcGetContextsDevice (alcContext);
			
			alcMakeContextCurrent (0);
			alcDestroyContext (alcContext);
			
			if (alcDevice) {
				
				alcCloseDevice (alcDevice);
				
			}
			
		}
		
	}
	
	
	void lime_al_delete_buffer (value buffer) {
		
		if (!val_is_null (buffer)) {
			
			ALuint data = (ALuint)(uintptr_t)val_data (buffer);
			val_gc (buffer, 0);
			alDeleteBuffers ((ALuint)1, &data);
			alObjects.erase (data);
			
		}
		
	}
	
	
	void lime_al_delete_buffers (int n, value buffers) {
		
		if (val_is_null (buffers) == false) {
			
			int size = val_array_size (buffers);
			ALuint* data = new ALuint[size];
			value buffer;
			
			for (int i = 0; i < size; ++i) {
				
				buffer = val_array_i (buffers, i);
				data[i] = (ALuint)(uintptr_t)val_data (buffer);
				val_gc (buffer, 0);
				alObjects.erase (data[i]);
				
			}
			
			alDeleteBuffers (n, data);
			delete[] data;
			
		}
		
	}


	void lime_al_delete_filter(value filter) {

		if (!val_is_null(filter)) {

			ALuint data = (ALuint)(uintptr_t)val_data(filter);
			alDeleteFilters(1, &data);
			val_gc(filter, 0);

		}

	}
	
	
	void lime_al_delete_source (value source) {
		
		if (!val_is_null (source)) {
			
			ALuint data = (ALuint)(uintptr_t)val_data (source);
			alDeleteSources (1, &data);
			val_gc (source, 0);
			
		}
		
	}
	
	
	void lime_al_delete_sources (int n, value sources) {
		
		if (val_is_null (sources) == false) {
			
			int size = val_array_size (sources);
			ALuint* data = new ALuint[size];
			value source;
			
			for (int i = 0; i < size; ++i) {
				
				source = val_array_i (sources, i);
				data[i] = (ALuint)(uintptr_t)val_data (source);
				val_gc (source, 0);
				
			}
			
			alDeleteSources (n, data);
			delete[] data;
			
		}
		
	}

	
	
	
	void lime_al_disable (int capability) {
		
		alDisable (capability);
		
	}
	
	
	void lime_al_distance_model (int distanceModel) {
		
		alDistanceModel (distanceModel);
		
	}
	
	
	void lime_al_doppler_factor (float factor) {
		
		alDopplerFactor (factor);
		
	}
	
	
	void lime_al_doppler_velocity (float velocity) {
		
		alDopplerVelocity (velocity);
		
	}
	
	
	void lime_al_enable (int capability) {
		
		alEnable (capability);
		
	}


	void lime_al_filteri(value filter, int param, value val) {

		ALuint id = (ALuint)(uintptr_t)val_data(filter);
		ALuint data;

		data = val_int(val);

		alFilteri(id, param, data);

	}


	void lime_al_filterf(value filter, int param, float value) {

		ALuint id = (ALuint)(uintptr_t)val_data(filter);
		alFilterf(id, param, value);

	}
	
	
	value lime_al_gen_buffer () {
		
		ALuint buffer;
		alGenBuffers ((ALuint)1, &buffer);
		value ptr = CFFIPointer ((void*)(uintptr_t)buffer, gc_al_buffer);
		alObjects[buffer] = ptr;
		return ptr;
		
	}
	
	
	value lime_al_gen_buffers (int n) {
		
		ALuint* buffers = new ALuint[n];
		alGenBuffers (n, buffers);
		
		value result = alloc_array (n);
		
		ALuint buffer;
		value ptr;
		
		for (int i = 0; i < n; i++) {
			
			buffer = buffers[i];
			ptr = CFFIPointer ((void*)(uintptr_t)buffer, gc_al_buffer);
			alObjects[buffer] = ptr;
			
			val_array_set_i (result, i, ptr);
			
		}
		
		delete[] buffers;
		return result;
		
	}


	value lime_al_gen_filter() {

		ALuint filter;
		alGenFilters((ALuint)1, &filter);
		return CFFIPointer((void*)(uintptr_t)filter, gc_al_filter);

	}
	
	
	value lime_al_gen_source () {
		
		ALuint source;
		alGenSources ((ALuint)1, &source);
		return CFFIPointer ((void*)(uintptr_t)source, gc_al_source);
		
	}
	
	
	value lime_al_gen_sources (int n) {
		
		ALuint* sources = new ALuint[n];
		alGenSources (n, sources);
		
		value result = alloc_array (n);
		
		for (int i = 0; i < n; i++) {
			
			val_array_set_i (result, i, CFFIPointer ((void*)(uintptr_t)sources[i], gc_al_source));
			
		}
		
		delete[] sources;
		return result;
		
	}
	
	
	bool lime_al_get_boolean (int param) {
		
		return alGetBoolean (param);
		
	}
	
	
	value lime_al_get_booleanv (int param, int count) {
		
		ALboolean* values = new ALboolean[count];
		alGetBooleanv (param, values);
		
		value result = alloc_array (count);
		
		for (int i = 0; i < count; i++) {
			
			val_array_set_i (result, i, alloc_bool (values[i]));
			
		}
		
		delete[] values;
		return result;
		
	}
	
	
	value lime_al_get_buffer3f (value buffer, int param) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		ALfloat val1, val2, val3;
		
		alGetBuffer3f (id, param, &val1, &val2, &val3);
		
		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_float (val1));
		val_array_set_i (result, 1, alloc_float (val2));
		val_array_set_i (result, 2, alloc_float (val3));
		return result;
		
	}
	
	
	value lime_al_get_buffer3i (value buffer, int param) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		ALint val1, val2, val3;
		
		alGetBuffer3i (id, param, &val1, &val2, &val3);
		
		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_int(val1));
		val_array_set_i (result, 1, alloc_int(val2));
		val_array_set_i (result, 2, alloc_int(val3));
		return result;
		
	}
	
	
	float lime_al_get_bufferf (value buffer, int param) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		ALfloat data;
		alGetBufferf (id, param, &data);
		return data;
		
	}
	
	
	value lime_al_get_bufferfv (value buffer, int param, int count) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		ALfloat* values = new ALfloat[count];
		alGetBufferfv (id, param, values);
		
		value result = alloc_array (count);
		
		for (int i = 0; i < count; ++i) {
			
			val_array_set_i (result, i, alloc_float (values[i]));
			
		}
		
		delete[] values;
		return result;
		
	}
	
	
	int lime_al_get_bufferi (value buffer, int param) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		ALint data;
		alGetBufferi (id, param, &data);
		return data;
		
	}
	
	
	value lime_al_get_bufferiv (value buffer, int param, int count) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		ALint* values = new ALint[count];
		alGetBufferiv (id, param, values);
		
		value result = alloc_array (count);
		
		for (int i = 0; i < count; i++) {
			
			val_array_set_i (result, i, alloc_int (values[i]));
			
		}
		
		delete[] values;
		return result;
		
	}
	
	
	double lime_al_get_double (int param) {
		
		return alGetDouble (param);
		
	}
	
	
	value lime_al_get_doublev (int param, int count) {
		
		ALdouble* values = new ALdouble[count];
		alGetDoublev (param, values);
		
		value result = alloc_array (count);
		
		for (int i = 0; i < count; i++) {
			
			val_array_set_i (result, i, alloc_float (values[i]));
			
		}
		
		delete[] values;
		return result;
		
	}
	
	
	int lime_al_get_enum_value (HxString ename) {
		
		return alGetEnumValue (ename.__s);
		
	}
	
	
	int lime_al_get_error () {
		
		return alGetError ();
		
	}
	
	
	float lime_al_get_float (int param) {
		
		return alGetFloat (param);
		
	}
	
	
	value lime_al_get_floatv (int param, int count) {
		
		ALfloat* values = new ALfloat[count];
		alGetFloatv (param, values);
		
		value result = alloc_array (count);
		
		for (int i = 0; i < count; i++) {
			
			val_array_set_i (result, i, alloc_float (values[i]));
			
		}
		
		delete[] values;
		return result;
		
	}
	
	
	int lime_al_get_integer (int param) {
		
		return alGetInteger (param);
		
	}
	
	
	value lime_al_get_integerv (int param, int count) {
		
		ALint* values = new ALint[count];
		alGetIntegerv (param, values);
		
		value result = alloc_array (count);
		
		for (int i = 0; i < count; i++) {
			
			val_array_set_i (result, i, alloc_int (values[i]));
			
		}
		
		delete[] values;
		return result;
		
	}
	
	
	value lime_al_get_listener3f (int param) {
		
		ALfloat val1, val2, val3;
		
		alGetListener3f (param, &val1, &val2, &val3);
		
		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_float (val1));
		val_array_set_i (result, 1, alloc_float (val2));
		val_array_set_i (result, 2, alloc_float (val3));
		return result;
		
	}
	
	
	value lime_al_get_listener3i (int param) {
		
		ALint val1, val2, val3;
		
		alGetListener3i (param, &val1, &val2, &val3);
		
		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_int (val1));
		val_array_set_i (result, 1, alloc_int (val2));
		val_array_set_i (result, 2, alloc_int (val3));
		return result;
		
	}
	
	
	float lime_al_get_listenerf (int param) {
		
		ALfloat data;
		alGetListenerf (param, &data);
		return data;
		
	}
	
	
	value lime_al_get_listenerfv (int param, int count) {
		
		ALfloat* values = new ALfloat[count];
		alGetListenerfv (param, values);
		
		value result = alloc_array (count);
		
		for (int i = 0; i < count; i++) {
			
			val_array_set_i (result, i, alloc_float (values[i]));
			
		}
		
		delete[] values;
		return result;
		
	}
	
	
	int lime_al_get_listeneri (int param) {
		
		ALint data;
		alGetListeneri (param, &data);
		return data;
		
	}
	
	
	value lime_al_get_listeneriv (int param, int count) {
		
		ALint* values = new ALint[count];
		alGetListeneriv (param, values);
		
		value result = alloc_array (count);
		
		for (int i = 0; i < count; i++) {
			
			val_array_set_i (result, i, alloc_int (values[i]));
			
		}
		
		delete[] values;
		return result;
		
	}
	
	
	double lime_al_get_proc_address (HxString fname) {
		
		return (uintptr_t)alGetProcAddress (fname.__s);
		
	}
	
	
	value lime_al_get_source3f (value source, int param) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		ALfloat val1, val2, val3;
		
		alGetSource3f (id, param, &val1, &val2, &val3);
		
		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_float (val1));
		val_array_set_i (result, 1, alloc_float (val2));
		val_array_set_i (result, 2, alloc_float (val3));
		return result;
		
	}
	
	
	value lime_al_get_source3i (value source, int param) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		ALint val1, val2, val3;
		
		alGetSource3i (id, param, &val1, &val2, &val3);
		
		value result = alloc_array (3);
		val_array_set_i (result, 1, alloc_int (val1));
		val_array_set_i (result, 2, alloc_int (val2));
		val_array_set_i (result, 3, alloc_int (val3));
		return result;
		
	}
	
	
	float lime_al_get_sourcef (value source, int param) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		ALfloat data;
		alGetSourcef (id, param, &data);
		return data;
		
	}
	
	
	value lime_al_get_sourcefv (value source, int param, int count) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		ALfloat* values = new ALfloat[count];
		alGetSourcefv (id, param, values);
		
		value result = alloc_array (count);
		
		for (int i = 0; i < count; i++) {
			
			val_array_set_i (result, i, alloc_float (values[i]));
			
		}
		
		delete[] values;
		return result;
		
	}
	
	
	value lime_al_get_sourcei (value source, int param) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		ALint data;
		alGetSourcei (id, param, &data);
		
		if (param == AL_BUFFER) {
			
			if (alObjects.count (data) > 0) {
				
				return alObjects[data];
				
			} else {
				
				value ptr = CFFIPointer ((void*)(uintptr_t)data, gc_al_buffer);
				alObjects[data] = ptr;
				return ptr;
				
			}
			
		} else {
			
			return alloc_int (data);
			
		}
		
	}
	
	
	value lime_al_get_sourceiv (value source, int param, int count) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		ALint* values = new ALint[count];
		alGetSourceiv (id, param, values);
		
		value result = alloc_array (count);
		
		for (int i = 0; i < count; i++) {
			
			val_array_set_i (result, i, alloc_int (values[i]));
			
		}
		
		delete[] values;
		return result;
		
	}
	
	
	value lime_al_get_string (int param) {
		
		const char* result = alGetString (param);
		return result ? alloc_string (result) : alloc_null ();
		
	}
	
	
	bool lime_al_is_buffer (value buffer) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		return alIsBuffer (id);
		
	}
	
	
	bool lime_al_is_enabled (int capability) {
		
		return alIsEnabled (capability);
		
	}
	
	
	bool lime_al_is_extension_present (HxString extname) {
		
		return alIsExtensionPresent (extname.__s);
		
	}
	
	
	bool lime_al_is_source (value source) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		return alIsSource (id);
		
	}
	
	
	void lime_al_listener3f (int param, float value1, float value2, float value3) {
		
		alListener3f (param, value1, value2, value3);
		
	}
	
	
	void lime_al_listener3i (int param, int value1, int value2, int value3) {
		
		alListener3i (param, value1, value2, value3);
		
	}
	
	
	void lime_al_listenerf (int param, float value1) {
		
		alListenerf (param, value1);
		
	}
	
	
	void lime_al_listenerfv (int param, value values) {
		
		if (val_is_null (values) == false) {
			
			int size = val_array_size (values);
			ALfloat *data = new ALfloat[size];
			
			for (int i = 0; i < size; ++i) {
				
				data[i] = (ALfloat)val_float (val_array_i (values, i));
				
			}
			
			alListenerfv (param, data);
			delete[] data;
			
		}
		
	}
	
	
	void lime_al_listeneri (int param, int value1) {
		
		alListeneri (param, value1);
		
	}
	
	
	void lime_al_listeneriv (int param, value values) {
		
		if (val_is_null (values) == false) {
			
			int size = val_array_size (values);
			ALint* data = new ALint[size];
			
			for (int i = 0; i < size; ++i) {
				
				data[i] = (ALint)val_int (val_array_i (values, i));
				
			}
			
			alListeneriv (param, data);
			delete[] data;
			
		}
		
	}
	
	
	void lime_al_source_pause (value source) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		alSourcePause (id);
		
	}
	
	
	void lime_al_source_pausev (int n, value sources) {
		
		if (val_is_null (sources) == false) {
			
			int size = val_array_size (sources);
			ALuint* data = new ALuint[size];
			
			for (int i = 0; i < size; ++i) {
				
				data[i] = (ALuint)(uintptr_t)val_data (val_array_i (sources, i));
				
			}
			
			alSourcePausev (n, data);
			delete[] data;
			
		}
	}
	
	
	void lime_al_source_play (value source) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		alSourcePlay (id);
		
	}
	
	
	void lime_al_source_playv (int n, value sources) {
		
		if (val_is_null (sources) == false) {
			
			int size = val_array_size (sources);
			ALuint* data = new ALuint[size];
			
			for (int i = 0; i < size; ++i) {
				
				data[i] = (ALuint)(uintptr_t)val_data (val_array_i (sources, i));
				
			}
			
			alSourcePlayv (n, data);
			delete[] data;
			
		}
		
	}
	
	
	void lime_al_source_queue_buffers (value source, int nb, value buffers) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		
		if (val_is_null (buffers) == false) {
			
			int size = val_array_size (buffers);
			ALuint* data = new ALuint[size];
			
			for (int i = 0; i < size; ++i) {
				
				data[i] = (ALuint)(uintptr_t)val_data (val_array_i (buffers, i));
				
			}
			
			alSourceQueueBuffers (id, nb, data);
			delete[] data;
			
		}
		
	}
	
	
	void lime_al_source_rewind (value source) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		alSourceRewind (id);
		
	}
	
	
	void lime_al_source_rewindv (int n, value sources) {
		
		if (val_is_null (sources) == false) {
			
			int size = val_array_size (sources);
			ALuint* data = new ALuint[size];
			
			for (int i = 0; i < size; ++i) {
				
				data[i] = (ALuint)(uintptr_t)val_data (val_array_i (sources, i));
				
			}
			
			alSourceRewindv (n, data);
			delete[] data;
			
		}
		
	}
	
	
	void lime_al_source_stop (value source) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		alSourceStop (id);
		
	}
	
	
	void lime_al_source_stopv (int n, value sources) {
		
		if (val_is_null (sources) == false) {
			
			int size = val_array_size (sources);
			ALuint* data = new ALuint[size];
			
			for (int i = 0; i < size; ++i) {
				
				data[i] = (ALuint)(uintptr_t)val_data (val_array_i (sources, i));
				
			}
			
			alSourceStopv (n, data);
			delete[] data;
			
		}
		
	}
	
	
	value lime_al_source_unqueue_buffers (value source, int nb) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		ALuint* buffers = new ALuint[nb];
		alSourceUnqueueBuffers (id, nb, buffers);
		
		value result = alloc_array (nb);
		ALuint buffer;
		value ptr;
		
		for (int i = 0; i < nb; i++) {
			
			buffer = buffers[i];
			
			if (alObjects.count (buffer) > 0) {
				
				ptr = alObjects[buffer];
				
			} else {
				
				ptr = CFFIPointer ((void*)(uintptr_t)buffer, gc_al_buffer);
				alObjects[buffer] = ptr;
				
			}
			
			val_array_set_i (result, i, ptr);
			
		}
		
		delete[] buffers;
		return result;
		
	}
	
	
	void lime_al_source3f (value source, int param, float value1, float value2, float value3) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		alSource3f (id, param, value1, value2, value3);
		
	}
	
	
	void lime_al_source3i (value source, int param, int value1, int value2, int value3) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		alSource3i (id, param, value1, value2, value3);
		
	}
	
	
	void lime_al_sourcef (value source, int param, float value) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		alSourcef (id, param, value);
		
	}
	
	
	void lime_al_sourcefv (value source, int param, value values) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		
		if (val_is_null (values) == false) {
			
			int size = val_array_size (values);
			ALfloat *data = new ALfloat[size];
			
			for (int i = 0; i < size; ++i) {
				
				data[i] = (ALfloat)val_float (val_array_i (values, i));
				
			}
			
			alSourcefv (id, param, data);
			delete[] data;
			
		}
		
	}
	
	
	void lime_al_sourcei (value source, int param, value val) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		ALuint data;
		
		if (param == AL_BUFFER || param == AL_DIRECT_FILTER) {
			
			data = (ALuint)(uintptr_t)val_data (val);
			
		} else {
			
			data = val_int (val);
			
		}
		
		alSourcei (id, param, data);
		
	}

	
	void lime_al_sourceiv (value source, int param, value values) {
		
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		
		if (val_is_null (values) == false) {
			
			int size = val_array_size (values);
			ALint* data = new ALint[size];
			
			for (int i = 0; i < size; ++i) {
				
				data[i] = (ALint)val_int (val_array_i (values, i));
				
			}
			
			alSourceiv (id, param, data);
			delete[] data;
			
		}
		
	}
	
	
	void lime_al_speed_of_sound (float speed) {
		
		alSpeedOfSound (speed);
		
	}
	
	
	bool lime_alc_close_device (value device) {
		
		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		alcObjects.erase (alcDevice);
		return alcCloseDevice (alcDevice);
		
	}
	
	
	value lime_alc_create_context (value device, value attrlist) {
		
		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		
		ALCint* list = NULL;
		
		if (val_is_null (attrlist) == false) {
			
			int size = val_array_size (attrlist);
			list = new ALCint[size];
			
			for (int i = 0; i < size; ++i) {
				
				list[i] = (ALCint)val_int (val_array_i (attrlist, i));
				
			}
			
		}
		
		ALCcontext* alcContext = alcCreateContext (alcDevice, list);
		
		if (list != NULL) {
			
			delete[] list;
			
		}
		
		value object = CFFIPointer (alcContext, gc_alc_object);
		alcObjects[alcContext] = object;
		return object;
		
	}
	
	
	void lime_alc_destroy_context (value context) {
		
		ALCcontext* alcContext = (ALCcontext*)val_data (context);
		alcObjects.erase (alcContext);
		alcDestroyContext (alcContext);
		
	}
	
	
	value lime_alc_get_contexts_device (value context) {
		
		ALCcontext* alcContext = (ALCcontext*)val_data (context);
		ALCdevice* alcDevice = alcGetContextsDevice (alcContext);
		
		if (alcObjects.find (alcDevice) != alcObjects.end ()) {
			
			return alcObjects[alcDevice];
			
		} else {
			
			value object = CFFIPointer (alcDevice, gc_alc_object);
			alcObjects[alcDevice] = object;
			return object;
			
		}
		
	}
	
	
	value lime_alc_get_current_context () {
		
		ALCcontext* alcContext = alcGetCurrentContext ();
		
		if (alcObjects.find (alcContext) != alcObjects.end ()) {
			
			return alcObjects[alcContext];
			
		} else {
			
			value object = CFFIPointer (alcContext, gc_alc_object);
			alcObjects[alcContext] = object;
			return object;
			
		}
		
	}
	
	
	int lime_alc_get_error (value device) {
		
		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		return alcGetError (alcDevice);
		
	}
	
	
	value lime_alc_get_integerv (value device, int param, int size) {
		
		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		
		ALCint* values = new ALCint[size];
		alcGetIntegerv (alcDevice, param, size, values);
		
		value result = alloc_array (size);
		
		for (int i = 0; i < size; i++) {
			
			val_array_set_i (result, i, alloc_int (values[i]));
			
		}
		
		delete[] values;
		return result;
		
	}
	
	
	value lime_alc_get_string (value device, int param) {
		
		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		const char* result = alcGetString (alcDevice, param);
		return result ? alloc_string (result) : alloc_null ();
		
	}
	
	
	bool lime_alc_make_context_current (value context) {
		
		ALCcontext* alcContext = (ALCcontext*)val_data (context);
		return alcMakeContextCurrent (alcContext);
		
	}
	
	
	value lime_alc_open_device (HxString devicename) {
		
		ALCdevice* alcDevice = alcOpenDevice (devicename.__s);
		atexit (lime_al_cleanup);
		
		value ptr = CFFIPointer (alcDevice, gc_alc_object);
		alcObjects[alcDevice] = ptr;
		return ptr;
		
	}
	
	
	void lime_alc_pause_device (value device) {
		
		#ifdef LIME_OPENALSOFT
		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		alcDevicePauseSOFT (alcDevice);
		#endif
		
	}
	
	
	void lime_alc_process_context (value context) {
		
		ALCcontext* alcContext = (ALCcontext*)val_data (context);
		alcProcessContext (alcContext);
		
	}
	
	
	void lime_alc_resume_device (value device) {
		
		#ifdef LIME_OPENALSOFT
		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		alcDeviceResumeSOFT (alcDevice);
		#endif
		
	}
	
	
	void lime_alc_suspend_context (value context) {
		
		ALCcontext* alcContext = (ALCcontext*)val_data (context);
		alcSuspendContext (alcContext);
		
	}


	
	
	DEFINE_PRIME5v (lime_al_buffer_data);
	DEFINE_PRIME5v (lime_al_buffer3f);
	DEFINE_PRIME5v (lime_al_buffer3i);
	DEFINE_PRIME3v (lime_al_bufferf);
	DEFINE_PRIME3v (lime_al_bufferfv);
	DEFINE_PRIME3v (lime_al_bufferi);
	DEFINE_PRIME3v (lime_al_bufferiv);
	DEFINE_PRIME1v (lime_al_delete_buffer);
	DEFINE_PRIME2v (lime_al_delete_buffers);
	DEFINE_PRIME1v(lime_al_delete_filter);
	DEFINE_PRIME1v (lime_al_delete_source);
	DEFINE_PRIME2v (lime_al_delete_sources);
	DEFINE_PRIME1v (lime_al_disable);
	DEFINE_PRIME1v (lime_al_distance_model);
	DEFINE_PRIME1v (lime_al_doppler_factor);
	DEFINE_PRIME1v (lime_al_doppler_velocity);
	DEFINE_PRIME1v (lime_al_enable);	
	DEFINE_PRIME3v (lime_al_filteri);
	DEFINE_PRIME3v (lime_al_filterf);
	DEFINE_PRIME0 (lime_al_gen_buffer);
	DEFINE_PRIME1 (lime_al_gen_buffers);
	DEFINE_PRIME0 (lime_al_gen_filter);
	DEFINE_PRIME0 (lime_al_gen_source);
	DEFINE_PRIME1 (lime_al_gen_sources);
	DEFINE_PRIME1 (lime_al_get_boolean);
	DEFINE_PRIME2 (lime_al_get_booleanv);
	DEFINE_PRIME2 (lime_al_get_buffer3f);
	DEFINE_PRIME2 (lime_al_get_buffer3i);
	DEFINE_PRIME2 (lime_al_get_bufferf);
	DEFINE_PRIME3 (lime_al_get_bufferfv);
	DEFINE_PRIME2 (lime_al_get_bufferi);
	DEFINE_PRIME3 (lime_al_get_bufferiv);
	DEFINE_PRIME1 (lime_al_get_double);
	DEFINE_PRIME2 (lime_al_get_doublev);
	DEFINE_PRIME1 (lime_al_get_enum_value);
	DEFINE_PRIME0 (lime_al_get_error);
	DEFINE_PRIME1 (lime_al_get_float);
	DEFINE_PRIME2 (lime_al_get_floatv);
	DEFINE_PRIME1 (lime_al_get_integer);
	DEFINE_PRIME2 (lime_al_get_integerv);
	DEFINE_PRIME1 (lime_al_get_listener3f);
	DEFINE_PRIME1 (lime_al_get_listener3i);
	DEFINE_PRIME1 (lime_al_get_listenerf);
	DEFINE_PRIME2 (lime_al_get_listenerfv);
	DEFINE_PRIME1 (lime_al_get_listeneri);
	DEFINE_PRIME2 (lime_al_get_listeneriv);
	DEFINE_PRIME1 (lime_al_get_proc_address);
	DEFINE_PRIME2 (lime_al_get_source3f);
	DEFINE_PRIME2 (lime_al_get_source3i);
	DEFINE_PRIME2 (lime_al_get_sourcef);
	DEFINE_PRIME3 (lime_al_get_sourcefv);
	DEFINE_PRIME2 (lime_al_get_sourcei);
	DEFINE_PRIME3 (lime_al_get_sourceiv);
	DEFINE_PRIME1 (lime_al_get_string);
	DEFINE_PRIME1 (lime_al_is_buffer);
	DEFINE_PRIME1 (lime_al_is_enabled);
	DEFINE_PRIME1 (lime_al_is_extension_present);
	DEFINE_PRIME1 (lime_al_is_source);
	DEFINE_PRIME4v (lime_al_listener3f);
	DEFINE_PRIME4v (lime_al_listener3i);
	DEFINE_PRIME2v (lime_al_listenerf);
	DEFINE_PRIME2v (lime_al_listenerfv);
	DEFINE_PRIME2v (lime_al_listeneri);
	DEFINE_PRIME2v (lime_al_listeneriv);
	DEFINE_PRIME1v (lime_al_source_pause);
	DEFINE_PRIME2v (lime_al_source_pausev);
	DEFINE_PRIME1v (lime_al_source_play);
	DEFINE_PRIME2v (lime_al_source_playv);
	DEFINE_PRIME3v (lime_al_source_queue_buffers);
	DEFINE_PRIME1v (lime_al_source_rewind);
	DEFINE_PRIME2v (lime_al_source_rewindv);
	DEFINE_PRIME1v (lime_al_source_stop);
	DEFINE_PRIME2v (lime_al_source_stopv);
	DEFINE_PRIME2 (lime_al_source_unqueue_buffers);
	DEFINE_PRIME5v (lime_al_source3f);
	DEFINE_PRIME5v (lime_al_source3i);
	DEFINE_PRIME3v (lime_al_sourcef);
	DEFINE_PRIME3v (lime_al_sourcefv);
	DEFINE_PRIME3v (lime_al_sourcei);
	DEFINE_PRIME3v (lime_al_sourceiv);
	DEFINE_PRIME1v (lime_al_speed_of_sound);
	DEFINE_PRIME2 (lime_alc_create_context);
	DEFINE_PRIME1 (lime_alc_close_device);
	DEFINE_PRIME1v (lime_alc_destroy_context);
	DEFINE_PRIME1 (lime_alc_get_contexts_device);
	DEFINE_PRIME0 (lime_alc_get_current_context);
	DEFINE_PRIME1 (lime_alc_get_error);
	DEFINE_PRIME3 (lime_alc_get_integerv);
	DEFINE_PRIME2 (lime_alc_get_string);
	DEFINE_PRIME1 (lime_alc_make_context_current);
	DEFINE_PRIME1 (lime_alc_open_device);
	DEFINE_PRIME1v (lime_alc_pause_device);
	DEFINE_PRIME1v (lime_alc_process_context);
	DEFINE_PRIME1v (lime_alc_resume_device);
	DEFINE_PRIME1v (lime_alc_suspend_context);
	
}


extern "C" int lime_openal_register_prims () {
	
	return 0;
	
}
