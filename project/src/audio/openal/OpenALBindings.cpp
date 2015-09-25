#if defined(HX_MACOS) || defined(IPHONE)
#include <OpenAL/al.h>
#include <OpenAL/alc.h>
#else
#include "AL/al.h"
#include "AL/alc.h"
#endif

#include <hx/CFFIPrimePatch.h>
//#include <hx/CFFIPrime.h>
#include <system/CFFIPointer.h>
#include <utils/Bytes.h>


namespace lime {
	
	
	void lime_al_buffer_data (int buffer, int format, value data, int size, int freq) {
		
		Bytes bytes (data);
		alBufferData (buffer, format, bytes.Data (), size, freq);
		
	}
	
	
	void lime_al_buffer3f (int buffer, int param, float value1, float value2, float value3) {
		
		alBuffer3f (buffer, param, value1, value2, value3);
		
	}
	
	
	void lime_al_buffer3i (int buffer, int param, int value1, int value2, int value3) {
		
		alBuffer3i (buffer, param, value1, value2, value3);
		
	}
	
	
	void lime_al_bufferf (int buffer, int param, float value) {
		
		alBufferf (buffer, param, value);
		
	}
	
	
	void lime_al_bufferfv (int buffer, int param, value values) {
		
		float* data = val_array_float (values);
		
		if (data) {
			
			alBufferfv (buffer, param, data);
			
		}
		
	}
	
	
	void lime_al_bufferi (int buffer, int param, int value) {
		
		alBufferi (buffer, param, value);
		
	}
	
	
	void lime_al_bufferiv (int buffer, int param, value values) {
		
		int* data = val_array_int (values);
		
		if (data) {
			
			alBufferiv (buffer, param, data);
			
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
	
	
	void lime_al_delete_buffer (int buffer) {
		
		ALuint data = buffer;
		alDeleteBuffers ((ALuint)1, &data);
		
	}
	
	
	void lime_al_delete_buffers (int n, value buffers) {
		
		int* data = val_array_int (buffers);
		
		if (data) {
			
			alDeleteBuffers (n, (ALuint*)data);
			
		}
		
	}
	
	
	void lime_al_delete_source (int source) {
		
		ALuint data = source;
		alDeleteSources(1, &data);
		
	}
	
	
	void lime_al_delete_sources (int n, value sources) {
		
		int* data = val_array_int (sources);
		
		if (data) {
			
			alDeleteSources (n, (ALuint*)data);
			
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
	
	
	int lime_al_gen_buffer () {
		
		ALuint buffer;
		alGenBuffers ((ALuint)1, &buffer);
		return buffer;
		
	}
	
	
	value lime_al_gen_buffers (int n) {
		
		ALuint* buffers = new ALuint[n];
		alGenBuffers (n, buffers);
		
		value result = alloc_array (n);
		
		for (int i = 0; i < n; i++) {
			
			val_array_set_i (result, i, alloc_int (buffers[i]));
			
		}
		
		delete [] buffers;
		return result;
		
	}
	
	
	int lime_al_gen_source () {
		
		ALuint source;
		alGenSources ((ALuint)1, &source);
		return source;
		
	}
	
	
	value lime_al_gen_sources (int n) {
		
		ALuint* sources = new ALuint[n];
		alGenSources (n, sources);
		
		value result = alloc_array (n);
		
		for (int i = 0; i < n; i++) {
			
			val_array_set_i (result, i, alloc_int (sources[i]));
			
		}
		
		delete [] sources;
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
		
		delete [] values;
		return result;
		
	}
	
	
	value lime_al_get_buffer3f (int buffer, int param) {
		
		ALfloat val1, val2, val3;
		
		alGetBuffer3f (buffer, param, &val1, &val2, &val3);
		
		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_float (val1));
		val_array_set_i (result, 1, alloc_float (val2));
		val_array_set_i (result, 2, alloc_float (val3));
		return result;
		
	}
	
	
	value lime_al_get_buffer3i (int buffer, int param) {
		
		ALint val1, val2, val3;
		
		alGetBuffer3i (buffer, param, &val1, &val2, &val3);
		
		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_int(val1));
		val_array_set_i (result, 1, alloc_int(val2));
		val_array_set_i (result, 2, alloc_int(val3));
		return result;
		
	}
	
	
	float lime_al_get_bufferf (int buffer, int param) {
		
		ALfloat data;
		alGetBufferf (buffer, param, &data);
		return data;
		
	}
	
	
	value lime_al_get_bufferfv (int buffer, int param, int count) {
		
		ALfloat* values = new ALfloat[count];
		alGetBufferfv (buffer, param, values);
		
		value result = alloc_array (count);
		
		for (int i = 0; i < count; ++i) {
			
			val_array_set_i (result, i, alloc_float (values[i]));
			
		}
		
		delete [] values;
		return result;
		
	}
	
	
	int lime_al_get_bufferi (int buffer, int param) {
		
		ALint data;
		alGetBufferi (buffer, param, &data);
		return data;
		
	}
	
	
	value lime_al_get_bufferiv (int buffer, int param, int count) {
		
		ALint* values = new ALint[count];
		alGetBufferiv (buffer, param, values);
		
		value result = alloc_array (count);
		
		for (int i = 0; i < count; i++) {
			
			val_array_set_i (result, i, alloc_int (values[i]));
			
		}
		
		delete [] values;
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
		
		delete [] values;
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
		
		delete [] values;
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
		
		delete [] values;
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
		
		delete [] values;
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
		
		delete [] values;
		return result;
		
	}
	
	
	double lime_al_get_proc_address (HxString fname) {
		
		return (intptr_t)alGetProcAddress (fname.__s);
		
	}
	
	
	value lime_al_get_source3f (int source, int param) {
		
		ALfloat val1, val2, val3;
		
		alGetBuffer3f (source, param, &val1, &val2, &val3);
		
		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_float (val1));
		val_array_set_i (result, 1, alloc_float (val2));
		val_array_set_i (result, 2, alloc_float (val3));
		return result;
		
	}
	
	
	value lime_al_get_source3i (int source, int param) {
		
		ALint val1, val2, val3;
		
		alGetSource3i (source, param, &val1, &val2, &val3);
		
		value result = alloc_array (3);
		val_array_set_i (result, 1, alloc_int (val1));
		val_array_set_i (result, 2, alloc_int (val2));
		val_array_set_i (result, 3, alloc_int (val3));
		return result;
		
	}
	
	
	float lime_al_get_sourcef (int source, int param) {
		
		ALfloat data;
		alGetSourcef (source, param, &data);
		return data;
		
	}
	
	
	value lime_al_get_sourcefv (int source, int param, int count) {
		
		ALfloat* values = new ALfloat[count];
		alGetSourcefv (source, param, values);
		
		value result = alloc_array (count);
		
		for (int i = 0; i < count; i++) {
			
			val_array_set_i (result, i, alloc_float (values[i]));
			
		}
		
		delete [] values;
		return result;
		
	}
	
	
	int lime_al_get_sourcei (int source, int param) {
		
		ALint data;
		alGetSourcei (source, param, &data);
		return data;
		
	}
	
	
	value lime_al_get_sourceiv (int source, int param, int count) {
		
		ALint* values = new ALint[count];
		alGetSourceiv (source, param, values);
		
		value result = alloc_array (count);
		
		for (int i = 0; i < count; i++) {
			
			val_array_set_i (result, i, alloc_int (values[i]));
			
		}
		
		delete [] values;
		return result;
		
	}
	
	
	value lime_al_get_string (int param) {
		
		const char* result = alGetString (param);
		return result ? alloc_string (result) : alloc_null ();
		
	}
	
	
	bool lime_al_is_buffer (int buffer) {
		
		return alIsBuffer (buffer);
		
	}
	
	
	bool lime_al_is_enabled (int capability) {
		
		return alIsEnabled (capability);
		
	}
	
	
	bool lime_al_is_extension_present (HxString extname) {
		
		return alIsExtensionPresent (extname.__s);
		
	}
	
	
	bool lime_al_is_source (int source) {
		
		return alIsSource (source);
		
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
		
		float* data = val_array_float (values);
		
		if (data) {
			
			alListenerfv (param, data);
			
		}
		
	}
	
	
	void lime_al_listeneri (int param, int value1) {
		
		alListeneri (param, value1);
		
	}
	
	
	void lime_al_listeneriv (int param, value values) {
		
		int* data = val_array_int (values);
		
		if (data) {
			
			alListeneriv (param, data);
			
		}
		
	}
	
	
	void lime_al_source_pause (int source) {
		
		alSourcePause (source);
		
	}
	
	
	void lime_al_source_pausev (int n, value sources) {
		
		int* data = val_array_int (sources);
		
		if (data) {
			
			alSourcePausev (n, (ALuint*)data);
			
		}
		
	}
	
	
	void lime_al_source_play (int source) {
		
		alSourcePlay (source);
		
	}
	
	
	void lime_al_source_playv (int n, value sources) {
		
		int* data = val_array_int (sources);
		
		if (data) {
			
			alSourcePlayv (n, (ALuint*)data);
			
		}
		
	}
	
	
	void lime_al_source_queue_buffers (int source, int nb, value buffers) {
		
		int* data = val_array_int (buffers);
		
		if (data) {
			
			alSourceQueueBuffers (source, nb, (ALuint*)data);
			
		}
		
	}
	
	
	void lime_al_source_rewind (int source) {
		
		alSourceRewind (source);
		
	}
	
	
	void lime_al_source_rewindv (int n, value sources) {
		
		int* data = val_array_int (sources);
		
		if (data) {
			
			alSourceRewindv (n, (ALuint*)data);
			
		}
		
	}
	
	
	void lime_al_source_stop (int source) {
		
		alSourceStop (source);
		
	}
	
	
	void lime_al_source_stopv (int n, value sources) {
		
		int* data = val_array_int (sources);
		
		if (data) {
			
			alSourceStopv (n, (ALuint*)data);
			
		}
		
	}
	
	
	value lime_al_source_unqueue_buffers (int source, int nb) {
		
		ALuint* buffers = new ALuint[nb];
		alSourceUnqueueBuffers (source, nb, buffers);
		
		value result = alloc_array (nb);
		
		for (int i = 0; i < nb; i++) {
			
			val_array_set_i (result, i, alloc_int (buffers[i]));
			
		}
		
		delete [] buffers;
		return result;
		
	}
	
	
	void lime_al_source3f (int source, int param, float value1, float value2, float value3) {
		
		alSource3f (source, param, value1, value2, value3);
		
	}
	
	
	void lime_al_source3i (int source, int param, int value1, int value2, int value3) {
		
		alSource3i (source, param, value1, value2, value3);
		
	}
	
	
	void lime_al_sourcef (int source, int param, float value) {
		
		alSourcef (source, param, value);
		
	}
	
	
	void lime_al_sourcefv (int source, int param, value values) {
		
		float* data = val_array_float (values);
		
		if (data) {
			
			alSourcefv (source, param, data);
			
		}
		
	}
	
	
	void lime_al_sourcei (int source, int param, int value) {
		
		alSourcei (source, param, value);
		
	}
	
	
	void lime_al_sourceiv (int source, int param, value values) {
		
		int* data = val_array_int (values);
		
		if (data) {
			
			alSourceiv (source, param, data);
			
		}
		
	}
	
	
	void lime_al_speed_of_sound (float speed) {
		
		alSpeedOfSound (speed);
		
	}
	
	
	bool lime_alc_close_device (value device) {
		
		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		return alcCloseDevice (alcDevice);
		
	}
	
	
	value lime_alc_create_context (value device, value attrlist) {
		
		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		int* list = val_array_int (attrlist);
		
		ALCcontext* alcContext = alcCreateContext (alcDevice, list);
		return CFFIPointer (alcContext);
		
	}
	
	
	void lime_alc_destroy_context (value context) {
		
		ALCcontext* alcContext = (ALCcontext*)val_data (context);
		alcDestroyContext (alcContext);
		
	}
	
	
	value lime_alc_get_contexts_device (value context) {
		
		ALCcontext* alcContext = (ALCcontext*)val_data (context);
		ALCdevice* alcDevice = alcGetContextsDevice (alcContext);
		return CFFIPointer (alcDevice);
		
	}
	
	
	value lime_alc_get_current_context () {
		
		ALCcontext* alcContext = alcGetCurrentContext ();
		return CFFIPointer (alcContext);
		
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
		
		delete [] values;
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
		return CFFIPointer (alcDevice);
		
	}
	
	
	void lime_alc_process_context (value context) {
		
		ALCcontext* alcContext = (ALCcontext*)val_data (context);
		alcProcessContext (alcContext);
		
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
	DEFINE_PRIME1v (lime_al_delete_source);
	DEFINE_PRIME2v (lime_al_delete_sources);
	DEFINE_PRIME1v (lime_al_disable);
	DEFINE_PRIME1v (lime_al_distance_model);
	DEFINE_PRIME1v (lime_al_doppler_factor);
	DEFINE_PRIME1v (lime_al_doppler_velocity);
	DEFINE_PRIME1v (lime_al_enable);
	DEFINE_PRIME0 (lime_al_gen_buffer);
	DEFINE_PRIME1 (lime_al_gen_buffers);
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
	DEFINE_PRIME1v (lime_alc_process_context);
	DEFINE_PRIME1v (lime_alc_suspend_context);
	
	
}


extern "C" int lime_openal_register_prims () {
	
	return 0;
	
}