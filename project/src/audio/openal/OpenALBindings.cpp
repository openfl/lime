#if defined(HX_MACOS) || defined(IPHONE)
#include <OpenAL/al.h>
#include <OpenAL/alc.h>
#else
#include "AL/al.h"
#include "AL/alc.h"
#endif

#include <hx/CFFI.h>
#include <utils/ByteArray.h>


namespace lime {
	
	
	value lime_al_buffer_data (value buffer, value format, value data, value size, value freq) {
		
		ByteArray byteArray (data);
		//int arraySize = byteArray.Size ();
		const float *bytes = (float *)byteArray.Bytes ();
		//int elements = arraySize / sizeof (float);
		int count = val_int (size);
		
		alBufferData (val_int (buffer), val_int (format), bytes, count, val_int (freq));
		return alloc_null ();
		
	}
	
	
	value lime_al_buffer3f (value buffer, value param, value value1, value value2, value value3) {
		
		alBuffer3f (val_int (buffer), val_int (param), val_float (value1), val_float (value2), val_float (value3));
		return alloc_null ();
		
	}
	
	
	value lime_al_buffer3i (value buffer, value param, value value1, value value2, value value3) {
		
		alBuffer3i (val_int (buffer), val_int (param), val_int (value1), val_int (value2), val_int (value3));
		return alloc_null ();
		
	}
	
	
	value lime_al_bufferf (value buffer, value param, value value) {
		
		alBufferf (val_int (buffer), val_int (param), val_float (value));
		return alloc_null ();
		
	}
	
	
	value lime_al_bufferfv (value buffer, value param, value values) {
		
		float *data = val_array_float (values);
		
		if (data) {
			
			alBufferfv (val_int (buffer), val_int (param), data);
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_al_bufferi (value buffer, value param, value value) {
		
		alBufferi (val_int (buffer), val_int (param), val_int (value));
		return alloc_null ();
		
	}
	
	
	value lime_al_bufferiv (value buffer, value param, value values) {
		
		int *data = val_array_int (values);
		
		if (data) {
			
			alBufferiv (val_int (buffer), val_int (param), data);
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_al_delete_buffer (value buffer) {
		
		ALuint data = val_int (buffer);
		alDeleteBuffers ((ALuint)1, &data);
		return alloc_null ();
		
	}
	
	
	value lime_al_delete_buffers (value n, value buffers) {
		
		int *data = val_array_int (buffers);
		
		if (data) {
			
			alDeleteBuffers (val_int (n), (ALuint*)data);
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_al_delete_source (value source) {
		
		ALuint data = val_int (source);
		alDeleteSources(1, &data);
		return alloc_null ();
		
	}
	
	
	value lime_al_delete_sources (value n, value sources) {
		
		int *data = val_array_int (sources);
		
		if (data) {
			
			alDeleteSources (val_int (n), (ALuint*)data);
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_al_disable (value capability) {
		
		alDisable (val_int (capability));
		return alloc_null ();
		
	}
	
	
	value lime_al_distance_model (value distanceModel) {
		
		alDistanceModel (val_float (distanceModel));
		return alloc_null ();
		
	}
	
	
	value lime_al_doppler_factor (value factor) {
		
		alDopplerFactor (val_float (factor));
		return alloc_null ();
		
	}
	
	
	value lime_al_doppler_velocity (value velocity) {
		
		alDopplerVelocity (val_float (velocity));
		return alloc_null ();
		
	}
	
	
	value lime_al_enable (value capability) {
		
		alEnable (val_int (capability));
		return alloc_null ();
		
	}
	
	
	value lime_al_gen_buffer () {
		
		ALuint buffer;
		alGenBuffers ((ALuint)1, &buffer);
		return alloc_int (buffer);
		
	}
	
	
	value lime_al_gen_buffers (value n) {
		
		int count = val_int (n);
		ALuint* buffers = new ALuint[count];
		
		alGenBuffers (count, buffers);
		
		value result = alloc_array (count);
		
		for (int i = 0; i < count; ++i) {
			
			val_array_set_i (result, i, alloc_int (buffers[i]));
			
		}
		
		delete [] buffers;
		return result;
		
	}
	
	
	value lime_al_gen_source () {
		
		ALuint source;
		alGenSources ((ALuint)1, &source);
		return alloc_int (source);
		
	}
	
	
	value lime_al_gen_sources (value n) {
		
		int count = val_int (n);
		ALuint* sources = new ALuint[count];
		
		alGenSources (count, sources);
		
		value result = alloc_array(count);
		
		for (int i = 0; i < count; ++i) {
			
			val_array_set_i (result, i, alloc_int(sources[i]));
			
		}
		
		return result;
		
	}
	
	
	value lime_al_get_boolean (value param) {
		
		return alloc_bool (alGetBoolean (val_int (param)));
		
	}
	
	
	value lime_al_get_booleanv (value param, value count) {
		
		int length = val_int (count);
		ALboolean* values = new ALboolean[length];
		
		alGetBooleanv (val_int (param), values);
		
		value result = alloc_array (length);
		
		for (int i = 0; i < length; ++i) {
			
			val_array_set_i (result, i, alloc_bool (values[i]));
			
		}
		
		return result;
		
	}
	
	
	value lime_al_get_buffer3f (value buffer, value param) {
		
		ALfloat val1, val2, val3;
		
		alGetBuffer3f (val_int (buffer), val_int (param), &val1, &val2, &val3);
		
		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_float (val1));
		val_array_set_i (result, 1, alloc_float (val2));
		val_array_set_i (result, 2, alloc_float (val3));
		return result;
		
	}
	
	
	value lime_al_get_buffer3i (value buffer, value param) {
		
		ALint val1, val2, val3;
		
		alGetBuffer3i (val_int (buffer), val_int (param), &val1, &val2, &val3);
		
		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_int(val1));
		val_array_set_i (result, 1, alloc_int(val2));
		val_array_set_i (result, 2, alloc_int(val3));
		return result;
		
	}
	
	
	value lime_al_get_bufferf (value buffer, value param) {
		
		float data;
		alGetBufferf (val_int (buffer), val_int (param), &data);
		return alloc_float (data);
		
	}
	
	
	value lime_al_get_bufferfv (value buffer, value param, value count) {
		
		int length = val_int (count);
		ALfloat* values = new ALfloat[length];
		
		alGetBufferfv (val_int (buffer), val_int (param), values);
		
		value result = alloc_array (length);
		
		for (int i = 0; i < length; ++i) {
			
			val_array_set_i (result, i, alloc_float (values[i]));
			
		}
		
		return result;
		
	}
	
	
	value lime_al_get_bufferi (value buffer, value param) {
		
		int data;
		alGetBufferi (val_int (buffer), val_int (param), &data);
		return alloc_int (data);
		
	}
	
	
	value lime_al_get_bufferiv (value buffer, value param, value count) {
		
		int length = val_int (count);
		ALint* values = new ALint[length];
		
		alGetBufferiv (val_int (buffer), val_int (param), values);
		
		value result = alloc_array (length);
		
		for (int i = 0; i < length; ++i) {
			
			val_array_set_i (result, i, alloc_int (values[i]));
			
		}
		
		return result;
		
	}
	
	
	value lime_al_get_double (value param) {
		
		return alloc_float ((float)alGetDouble (val_int (param)));
		
	}
	
	
	value lime_al_get_doublev (value param, value count) {
		
		int length = val_int (count);
		ALdouble* values = new ALdouble[length];
		
		alGetDoublev (val_int (param), values);
		
		value result = alloc_array (length);
		
		for (int i = 0; i < length; ++i) {
			
			val_array_set_i (result, i, alloc_float ((float)values[i]));
			
		}
		
		return result;
		
	}
	
	
	value lime_al_get_enum_value (value ename) {
		
		return alloc_int (alGetEnumValue (val_string (ename)));
		
	}
	
	
	value lime_al_get_error () {
		
		return alloc_int (alGetError ());
		
	}
	
	
	value lime_al_get_float (value param) {
		
		return alloc_float (alGetFloat (val_int (param)));
		
	}
	
	
	value lime_al_get_floatv (value param, value count) {
		
		int length = val_int (count);
		ALfloat* values = new ALfloat[length];
		
		alGetFloatv (val_int (param), values);
		
		value result = alloc_array (length);
		
		for (int i = 0; i < length; ++i) {
			
			val_array_set_i (result, i, alloc_float (values[i]));
			
		}
		
		return result;
		
	}
	
	
	value lime_al_get_integer (value param) {
		
		return alloc_int (alGetInteger (val_int (param)));
		
	}
	
	
	value lime_al_get_integerv (value param, value count) {
		
		int length = val_int (count);
		ALint* values = new ALint[length];
		
		alGetIntegerv (val_int (param), values);
		
		value result = alloc_array (length);
		
		for (int i = 0; i < length; ++i) {
			
			val_array_set_i (result, i, alloc_int (values[i]));
			
		}
		
		return result;
		
	}
	
	
	value lime_al_get_listener3f (value param) {
		
		ALfloat val1, val2, val3;
		
		alGetListener3f (val_int (param), &val1, &val2, &val3);
		
		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_float (val1));
		val_array_set_i (result, 1, alloc_float (val2));
		val_array_set_i (result, 2, alloc_float (val3));
		return result;
		
	}
	
	
	value lime_al_get_listener3i (value param) {
		
		ALint val1, val2, val3;
		
		alGetListener3i (val_int (param), &val1, &val2, &val3);
		
		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_int (val1));
		val_array_set_i (result, 1, alloc_int (val2));
		val_array_set_i (result, 2, alloc_int (val3));
		return result;
		
	}
	
	
	value lime_al_get_listenerf (value param) {
		
		float data;
		alGetListenerf (val_int (param), &data);
		return alloc_float (data);
		
	}
	
	
	value lime_al_get_listenerfv (value param, value count) {
		
		int length = val_int (count);
		ALfloat* values = new ALfloat[length];
		
		alGetListenerfv (val_int (param), values);
		
		value result = alloc_array (length);
		
		for (int i = 0; i < length; ++i) {
			
			val_array_set_i (result, i, alloc_float (values[i]));
			
		}
		
		return result;
		
	}
	
	
	value lime_al_get_listeneri (value param) {
		
		int data;
		alGetListeneri (val_int (param), &data);
		return alloc_int (data);
		
	}
	
	
	value lime_al_get_listeneriv (value param, value count) {
		
		int length = val_int (count);
		ALint* values = new ALint[length];
		
		alGetListeneriv (val_int (param), values);
		
		value result = alloc_array (length);
		
		for (int i = 0; i < length; ++i) {
			
			val_array_set_i (result, i, alloc_int (values[i]));
			
		}
		
		return result;
		
	}
	
	
	value lime_al_get_proc_address (value fname) {
		
		return alloc_null ();
		
	}
	
	
	value lime_al_get_source3f (value source, value param) {
		
		ALfloat val1, val2, val3;
		
		alGetBuffer3f (val_int (source), val_int (param), &val1, &val2, &val3);
		
		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_float (val1));
		val_array_set_i (result, 1, alloc_float (val2));
		val_array_set_i (result, 2, alloc_float (val3));
		return result;
		
	}
	
	
	value lime_al_get_source3i (value source, value param) {
		
		ALint val1, val2, val3;
		
		alGetSource3i (val_int (source), val_int (param), &val1, &val2, &val3);
		
		value result = alloc_array (3);
		val_array_set_i (result, 1, alloc_int (val1));
		val_array_set_i (result, 2, alloc_int (val2));
		val_array_set_i (result, 3, alloc_int (val3));
		return result;
		
	}
	
	
	value lime_al_get_sourcef (value source, value param) {
		
		float data;
		alGetSourcef (val_int (source), val_int (param), &data);
		return alloc_float (data);
		
	}
	
	
	value lime_al_get_sourcefv (value source, value param, value count) {
		
		int length = val_int (count);
		ALfloat* values = new ALfloat[length];
		
		alGetSourcefv (val_int (source), val_int (param), values);
		
		value result = alloc_array (length);
		
		for (int i = 0; i < length; ++i) {
			
			val_array_set_i (result, i, alloc_float (values[i]));
			
		}
		
		return result;
		
	}
	
	
	value lime_al_get_sourcei (value source, value param) {
		
		int data;
		alGetSourcei (val_int (source), val_int (param), &data);
		return alloc_int (data);
		
	}
	
	
	value lime_al_get_sourceiv (value source, value param, value count) {
		
		int length = val_int (count);
		ALint* values = new ALint[length];
		
		alGetSourceiv (val_int (source), val_int (param), values);
		
		value result = alloc_array (length);
		
		for (int i = 0; i < length; ++i) {
			
			val_array_set_i (result, i, alloc_int (values[i]));
			
		}
		
		return result;
		
	}
	
	
	value lime_al_get_string (value param) {
		
		return alloc_string (alGetString (val_int (param)));
		
	}
	
	
	value lime_al_is_buffer (value buffer) {
		
		return alloc_bool (alIsBuffer (val_int (buffer)));
		
	}
	
	
	value lime_al_is_enabled (value capability) {
		
		return alloc_bool (alIsEnabled (val_int (capability)));
		
	}
	
	
	value lime_al_is_source (value source) {
		
		return alloc_bool (alIsSource (val_int (source)));
		
	}
	
	
	value lime_al_is_extension_present (value extname) {
		
		return alloc_bool (alIsExtensionPresent (val_string (extname)));
		
	}
	
	
	value lime_al_listener3f (value param, value value1, value value2, value value3) {
		
		alListener3f (val_int (param), val_float (value1), val_float (value2), val_float (value3));
		return alloc_null ();
		
	}
	
	
	value lime_al_listener3i (value param, value value1, value value2, value value3) {
		
		alListener3i (val_int (param), val_int (value1), val_int (value2), val_int (value3));
		return alloc_null ();
		
	}
	
	
	value lime_al_listenerf (value param, value value1) {
		
		alListenerf (val_int (param), val_float (value1));
		return alloc_null ();
		
	}
	
	
	value lime_al_listenerfv (value param, value values) {
		
		float* data = val_array_float (values);
		
		if (data) {
			
			alListenerfv (val_int (param), data);
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_al_listeneri (value param, value value1) {
		
		alListeneri (val_int (param), val_int (value1));
		return alloc_null ();
		
	}
	
	
	value lime_al_listeneriv (value param, value values) {
		
		int *data = val_array_int (values);
		
		if (data) {
			
			alListeneriv (val_int (param), data);
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_al_source_pause (value source) {
		
		alSourcePause (val_int (source));
		return alloc_null ();
		
	}
	
	
	value lime_al_source_pausev (value n, value sources) {
		
		int *data = val_array_int (sources);
		
		if (data) {
			
			alSourcePausev (val_int (n), (ALuint*)data);
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_al_source_play (value source) {
		
		alSourcePlay (val_int (source));
		return alloc_null ();
		
	}
	
	
	value lime_al_source_playv (value n, value sources) {
		
		int *data = val_array_int (sources);
		
		if (data) {
			
			alSourcePlayv (val_int (n), (ALuint*)data);
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_al_source_queue_buffers (value source, value nb, value buffers) {
		
		int* data = val_array_int (buffers);
		
		if (data) {
			
			alSourceQueueBuffers (val_int (source), val_int (nb), (ALuint*)data);
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_al_source_rewind (value source) {
		
		alSourceRewind (val_int (source));
		return alloc_null ();
		
	}
	
	
	value lime_al_source_rewindv (value n, value sources) {
		
		int *data = val_array_int (sources);
		
		if (data) {
			
			alSourceRewindv (val_int (n), (ALuint*)data);
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_al_source_stop (value source) {
		
		alSourceStop (val_int (source));
		return alloc_null ();
		
	}
	
	
	value lime_al_source_stopv (value n, value sources) {
		
		int *data = val_array_int (sources);
		
		if (data) {
			
			alSourceStopv (val_int (n), (ALuint*)data);
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_al_source_unqueue_buffers (value source, value nb) {
		
		int count = val_int (nb);
		ALuint* buffers = new ALuint[count];
		
		alSourceUnqueueBuffers (val_int (source), val_int (nb), buffers);
		
		value result = alloc_array (count);
		
		for (int i = 0; i < count; ++i) {
			
			val_array_set_i (result, i, alloc_int (buffers[i]));
			
		}
		
		delete [] buffers;
		return result;
		
	}
	
	
	value lime_al_source3f (value source, value param, value value1, value value2, value value3) {
		
		alSource3f (val_int (source), val_int (param), val_float (value1), val_float (value2), val_float (value3));
		return alloc_null ();
		
	}
	
	
	value lime_al_source3i (value source, value param, value value1, value value2, value value3) {
		
		alSource3i (val_int (source), val_int (param), val_int (value1), val_int (value2), val_int (value3));
		return alloc_null ();
		
	}
	
	
	value lime_al_sourcef (value source, value param, value value) {
		
		alSourcef (val_int (source), val_int (param), val_float (value));
		return alloc_null ();
		
	}
	
	
	value lime_al_sourcefv (value source, value param, value values) {
		
		float *data = val_array_float (values);
		
		if (data) {
			
			alSourcefv (val_int (source), val_int (param), data);
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_al_sourcei (value source, value param, value value) {
		
		alSourcei (val_int (source), val_int (param), val_int (value));
		return alloc_null ();
		
	}
	
	
	value lime_al_sourceiv (value source, value param, value values) {
		
		int *data = val_array_int (values);
		
		if (data) {
			
			alSourceiv (val_int (source), val_int (param), data);
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_al_speed_of_sound (value speed) {
		
		alSpeedOfSound (val_float (speed));
		return alloc_null ();
		
	}
	
	
	value lime_alc_close_device (value device) {
		
		ALCdevice* alcDevice = (ALCdevice*)(intptr_t)val_float (device);
		alcCloseDevice (alcDevice);
		return alloc_null ();
		
	}
	
	
	value lime_alc_create_context (value device, value attrlist) {
		
		ALCdevice* alcDevice = (ALCdevice*)(intptr_t)val_float (device);
		int* list = val_array_int (attrlist);
		
		ALCcontext *alcContext = alcCreateContext (alcDevice, list);
		return alloc_float ((intptr_t)alcContext);
		
	}
	
	
	value lime_alc_destroy_context (value context) {
		
		ALCcontext* alcContext = (ALCcontext*)(intptr_t)val_float (context);
		alcDestroyContext (alcContext);
		return alloc_null ();
		
	}
	
	
	value lime_alc_get_contexts_device (value context) {
		
		ALCcontext* alcContext = (ALCcontext*)(intptr_t)val_float (context);
		ALCdevice* alcDevice = alcGetContextsDevice (alcContext);
		return alloc_float ((intptr_t)alcDevice);
		
	}
	
	
	value lime_alc_get_current_context () {
		
		ALCcontext* alcContext = alcGetCurrentContext ();
		return alloc_float ((intptr_t)alcContext);
		
	}
	
	
	value lime_alc_get_error (value device) {
		
		ALCdevice* alcDevice = (ALCdevice*)(intptr_t)val_float (device);
		return alloc_int (alcGetError (alcDevice));
		
	}
	
	
	value lime_alc_get_integerv (value device, value param, value size) {
		
		ALCdevice* alcDevice = (ALCdevice*)(intptr_t)val_float (device);
		
		int count = val_int (size);
		ALint* values = new ALint[count];
		
		alcGetIntegerv (alcDevice, val_int (param), count, values);
		
		value result = alloc_array (count);
		
		for (int i = 0; i < count; ++i) {
			
			val_array_set_i (result, i, alloc_int (values[i]));
			
		}
		
		return result;
		
	}
	
	
	value lime_alc_get_string (value device, value param) {
		
		ALCdevice* alcDevice = (ALCdevice*)(intptr_t)val_float (device);
		return alloc_string (alcGetString (alcDevice, val_int (param)));
		
	}
	
	
	value lime_alc_make_context_current (value context) {
		
		if (val_is_null (context)) {
			
			alcMakeContextCurrent (NULL);
			
		} else {
			
			ALCcontext* alcContext = (ALCcontext*)(intptr_t)val_float (context);
			alcMakeContextCurrent (alcContext);
			
		}
		
		return alloc_null ();
		
	}
	
	
	value lime_alc_open_device (value devicename) {
		
		ALCdevice* alcDevice = alcOpenDevice (devicename == val_null ? 0 : val_string (devicename));
		return alloc_float ((intptr_t)alcDevice);
		
	}
	
	
	value lime_alc_process_context (value context) {
		
		ALCcontext* alcContext = (ALCcontext*)(intptr_t)val_float (context);
		alcProcessContext (alcContext);
		return alloc_null ();
		
	}
	
	
	value lime_alc_suspend_context (value context) {
		
		ALCcontext* alcContext = (ALCcontext*)(intptr_t)val_float (context);
		alcSuspendContext (alcContext);
		return alloc_null ();
		
	}
	
	
	DEFINE_PRIM (lime_al_buffer_data, 5);
	DEFINE_PRIM (lime_al_buffer3f, 5);
	DEFINE_PRIM (lime_al_buffer3i, 5);
	DEFINE_PRIM (lime_al_bufferf, 3);
	DEFINE_PRIM (lime_al_bufferfv, 3);
	DEFINE_PRIM (lime_al_bufferi, 3);
	DEFINE_PRIM (lime_al_bufferiv, 3);
	DEFINE_PRIM (lime_al_delete_buffer, 1);
	DEFINE_PRIM (lime_al_delete_buffers, 2);
	DEFINE_PRIM (lime_al_delete_source, 1);
	DEFINE_PRIM (lime_al_delete_sources, 2);
	DEFINE_PRIM (lime_al_disable, 1);
	DEFINE_PRIM (lime_al_distance_model, 1);
	DEFINE_PRIM (lime_al_doppler_factor, 1);
	DEFINE_PRIM (lime_al_doppler_velocity, 1);
	DEFINE_PRIM (lime_al_enable, 1);
	DEFINE_PRIM (lime_al_gen_buffer, 0);
	DEFINE_PRIM (lime_al_gen_buffers, 1);
	DEFINE_PRIM (lime_al_gen_source, 0);
	DEFINE_PRIM (lime_al_gen_sources, 1);
	DEFINE_PRIM (lime_al_get_boolean, 1);
	DEFINE_PRIM (lime_al_get_booleanv, 2);
	DEFINE_PRIM (lime_al_get_buffer3f, 2);
	DEFINE_PRIM (lime_al_get_buffer3i, 2);
	DEFINE_PRIM (lime_al_get_bufferf, 2);
	DEFINE_PRIM (lime_al_get_bufferfv, 3);
	DEFINE_PRIM (lime_al_get_bufferi, 2);
	DEFINE_PRIM (lime_al_get_bufferiv, 3);
	DEFINE_PRIM (lime_al_get_double, 1);
	DEFINE_PRIM (lime_al_get_doublev, 2);
	DEFINE_PRIM (lime_al_get_enum_value, 1);
	DEFINE_PRIM (lime_al_get_error, 0);
	DEFINE_PRIM (lime_al_get_float, 1);
	DEFINE_PRIM (lime_al_get_floatv, 2);
	DEFINE_PRIM (lime_al_get_integer, 1);
	DEFINE_PRIM (lime_al_get_integerv, 2);
	DEFINE_PRIM (lime_al_get_listener3f, 1);
	DEFINE_PRIM (lime_al_get_listener3i, 1);
	DEFINE_PRIM (lime_al_get_listenerf, 1);
	DEFINE_PRIM (lime_al_get_listenerfv, 2);
	DEFINE_PRIM (lime_al_get_listeneri, 1);
	DEFINE_PRIM (lime_al_get_listeneriv, 2);
	DEFINE_PRIM (lime_al_get_proc_address, 1);
	DEFINE_PRIM (lime_al_get_source3f, 2);
	DEFINE_PRIM (lime_al_get_source3i, 2);
	DEFINE_PRIM (lime_al_get_sourcef, 2);
	DEFINE_PRIM (lime_al_get_sourcefv, 2);
	DEFINE_PRIM (lime_al_get_sourcei, 2);
	DEFINE_PRIM (lime_al_get_sourceiv, 3);
	DEFINE_PRIM (lime_al_get_string, 1);
	DEFINE_PRIM (lime_al_is_buffer, 1);
	DEFINE_PRIM (lime_al_is_enabled, 1);
	DEFINE_PRIM (lime_al_is_extension_present, 1);
	DEFINE_PRIM (lime_al_is_source, 1);
	DEFINE_PRIM (lime_al_listener3f, 4);
	DEFINE_PRIM (lime_al_listener3i, 4);
	DEFINE_PRIM (lime_al_listenerf, 2);
	DEFINE_PRIM (lime_al_listenerfv, 2);
	DEFINE_PRIM (lime_al_listeneri, 2);
	DEFINE_PRIM (lime_al_listeneriv, 2);
	DEFINE_PRIM (lime_al_source_pause, 1);
	DEFINE_PRIM (lime_al_source_pausev, 2);
	DEFINE_PRIM (lime_al_source_play, 1);
	DEFINE_PRIM (lime_al_source_playv, 2);
	DEFINE_PRIM (lime_al_source_queue_buffers, 3);
	DEFINE_PRIM (lime_al_source_rewind, 1);
	DEFINE_PRIM (lime_al_source_rewindv, 2);
	DEFINE_PRIM (lime_al_source_stop, 1);
	DEFINE_PRIM (lime_al_source_stopv, 2);
	DEFINE_PRIM (lime_al_source_unqueue_buffers, 2);
	DEFINE_PRIM (lime_al_source3f, 5);
	DEFINE_PRIM (lime_al_source3i, 5);
	DEFINE_PRIM (lime_al_sourcef, 3);
	DEFINE_PRIM (lime_al_sourcefv, 3);
	DEFINE_PRIM (lime_al_sourcei, 3);
	DEFINE_PRIM (lime_al_sourceiv, 3);
	DEFINE_PRIM (lime_al_speed_of_sound, 1);
	DEFINE_PRIM (lime_alc_create_context, 2);
	DEFINE_PRIM (lime_alc_close_device, 1);
	DEFINE_PRIM (lime_alc_destroy_context, 1);
	DEFINE_PRIM (lime_alc_get_contexts_device, 1);
	DEFINE_PRIM (lime_alc_get_current_context, 0);
	DEFINE_PRIM (lime_alc_get_error, 1);
	DEFINE_PRIM (lime_alc_get_integerv, 3);
	DEFINE_PRIM (lime_alc_get_string, 2);
	DEFINE_PRIM (lime_alc_make_context_current, 1);
	DEFINE_PRIM (lime_alc_open_device, 1);
	DEFINE_PRIM (lime_alc_process_context, 1);
	DEFINE_PRIM (lime_alc_suspend_context, 1);
	
	
}


extern "C" int lime_openal_register_prims () {
	
	return 0;
	
}