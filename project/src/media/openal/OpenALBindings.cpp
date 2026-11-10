#if defined (IPHONE) || defined (TVOS) || (defined (HX_MACOS) && !defined (LIME_OPENALSOFT))
#include <OpenAL/al.h>
#include <OpenAL/alc.h>
#define LIME_OPENAL_DELETION_DELAY 600
#include <time.h>
#else
#include "AL/al.h"
#include "AL/alc.h"
#ifdef LIME_OPENALSOFT
// TODO: Can we support EFX on macOS?
#include "AL/alext.h"
#endif
#endif

#ifndef ALC_ALL_DEVICES_SPECIFIER
#define ALC_ALL_DEVICES_SPECIFIER 0x1013
#endif

#include <system/CFFI.h>
#include <system/CFFIPointer.h>
#include <system/Mutex.h>
#include <system/System.h>
#include <utils/ArrayBufferView.h>
#include <algorithm>
#include <map>
#include <utility>
#include <vector>


namespace lime {


	enum ALObjectType {

		// In the order they are released, since a source can hold the others
		AL_OBJECT_SOURCE,
		AL_OBJECT_AUXILIARY_EFFECT_SLOT,
		AL_OBJECT_EFFECT,
		AL_OBJECT_FILTER,
		AL_OBJECT_BUFFER

	};


	// Sources and effect slots belong to a context and the others to a device, and
	// each of those numbers its objects from the start, so an ID needs its owner
	struct ALObject {

		ALObjectType type;
		ALuint id;
		ALCdevice* device;
		ALCcontext* context;
		#ifdef LIME_OPENAL_DELETION_DELAY
		time_t deleted;
		#endif

	};


	std::map<void*, ALObject> alObjects;
	std::map<std::pair<ALCdevice*, ALuint>, void*> alBuffers;
	std::map<void*, void*> alcObjects;
	std::vector<ALObject> alUnreleased;
	ALenum alHeldError = AL_NO_ERROR;
	Mutex al_gc_mutex;

	std::vector<void*> alFinalized;
	std::vector<std::pair<void*, void*> > alcFinalized;
	Mutex al_finalized_mutex;


	void lock_al_gc () {

		// The thread that holds the lock may allocate, and so wait for a
		// collection, which can't start until the threads waiting here are
		// known to be blocked
		if (!al_gc_mutex.TryLock ()) {

			System::GCEnterBlocking ();
			al_gc_mutex.Lock ();
			System::GCExitBlocking ();

		}

	}


	ALCdevice* current_al_device () {

		ALCcontext* context = alcGetCurrentContext ();
		return context ? alcGetContextsDevice (context) : 0;

	}


	bool is_al_object_current (const ALObject& object) {

		if (object.context) {

			return object.context == alcGetCurrentContext ();

		}

		return object.device == current_al_device ();

	}


	bool is_al_object_before (const ALObject& a, const ALObject& b) {

		return a.type < b.type;

	}


	// Returns false if the object is still there, as a buffer is while a source holds it
	bool delete_al_object (ALObject& object) {

		#ifdef LIME_OPENAL_DELETION_DELAY
		if (!object.deleted) {

			object.deleted = time (0);

			if (object.type == AL_OBJECT_SOURCE) {

				alSourcei (object.id, AL_BUFFER, 0);

			}

		}

		if (difftime (time (0), object.deleted) * 1000 <= LIME_OPENAL_DELETION_DELAY) {

			return false;

		}
		#endif

		switch (object.type) {

			case AL_OBJECT_SOURCE:

				alDeleteSources (1, &object.id);
				return !alIsSource (object.id);

			case AL_OBJECT_BUFFER:

				alDeleteBuffers (1, &object.id);
				return !alIsBuffer (object.id);

			#ifdef LIME_OPENALSOFT
			case AL_OBJECT_AUXILIARY_EFFECT_SLOT:

				alDeleteAuxiliaryEffectSlots (1, &object.id);
				return !alIsAuxiliaryEffectSlot (object.id);

			case AL_OBJECT_EFFECT:

				alDeleteEffects (1, &object.id);
				return !alIsEffect (object.id);

			case AL_OBJECT_FILTER:

				alDeleteFilters (1, &object.id);
				return !alIsFilter (object.id);
			#endif

			default:

				return true;

		}

	}


	void forget_al_object (std::map<void*, ALObject>::iterator object) {

		if (object->second.type == AL_OBJECT_BUFFER) {

			alBuffers.erase (std::make_pair (object->second.device, object->second.id));

		}

		alObjects.erase (object);

	}


	// What a device or context held has gone with it, and its IDs can be used again
	void forget_al_objects (ALCdevice* device, ALCcontext* context) {

		std::map<void*, ALObject>::iterator object = alObjects.begin ();

		while (object != alObjects.end ()) {

			std::map<void*, ALObject>::iterator next = object;
			++next;

			if (object->second.device == device || (context && object->second.context == context)) {

				forget_al_object (object);

			}

			object = next;

		}

		std::vector<ALObject> unreleased;

		for (size_t i = 0; i < alUnreleased.size (); i++) {

			if (alUnreleased[i].device != device && (!context || alUnreleased[i].context != context)) {

				unreleased.push_back (alUnreleased[i]);

			}

		}

		alUnreleased.swap (unreleased);

	}


	// Forgets the collected handles, leaving their objects to delete_unreleased_al
	void collect_finalized_al () {

		std::vector<void*> finalized;
		std::vector<std::pair<void*, void*> > finalizedALC;

		al_finalized_mutex.Lock ();
		finalized.swap (alFinalized);
		finalizedALC.swap (alcFinalized);
		al_finalized_mutex.Unlock ();

		for (size_t i = 0; i < finalizedALC.size (); i++) {

			std::map<void*, void*>::iterator object = alcObjects.find (finalizedALC[i].first);

			if (object != alcObjects.end () && object->second == finalizedALC[i].second) {

				alcObjects.erase (object);

			}

		}

		for (size_t i = 0; i < finalized.size (); i++) {

			std::map<void*, ALObject>::iterator object = alObjects.find (finalized[i]);

			if (object != alObjects.end ()) {

				alUnreleased.push_back (object->second);
				forget_al_object (object);

			}

		}

	}


	void delete_unreleased_al () {

		if (alUnreleased.empty () || !alcGetCurrentContext ()) {

			return;

		}

		// A buffer in use fails to delete, which isn't the application's error
		// to read, and the error it had already can't be lost to that
		ALenum error = alGetError ();

		if (alHeldError == AL_NO_ERROR) {

			alHeldError = error;

		}

		std::stable_sort (alUnreleased.begin (), alUnreleased.end (), is_al_object_before);
		std::vector<ALObject> unreleased;

		for (size_t i = 0; i < alUnreleased.size (); i++) {

			if (!is_al_object_current (alUnreleased[i]) || !delete_al_object (alUnreleased[i])) {

				unreleased.push_back (alUnreleased[i]);

			}

		}

		alUnreleased.swap (unreleased);
		alGetError ();

	}


	// Takes back the buffers waiting to be deleted that the application is given again
	void claim_unreleased_al_buffers (const ALuint* ids, int count) {

		ALCdevice* device = current_al_device ();
		std::vector<ALObject> unreleased;

		for (size_t i = 0; i < alUnreleased.size (); i++) {

			bool claimed = false;

			if (alUnreleased[i].type == AL_OBJECT_BUFFER && alUnreleased[i].device == device) {

				for (int j = 0; j < count && !claimed; j++) {

					claimed = alUnreleased[i].id == ids[j];

				}

			}

			if (!claimed) {

				unreleased.push_back (alUnreleased[i]);

			}

		}

		alUnreleased.swap (unreleased);

	}


	void release_finalized_al () {

		collect_finalized_al ();
		delete_unreleased_al ();

	}


	void track_al_object (void* handle, ALObjectType type, ALuint id) {

		// The new handle may have the address of one that was collected
		collect_finalized_al ();

		ALCcontext* context = alcGetCurrentContext ();
		ALCdevice* device = current_al_device ();
		bool inContext = type == AL_OBJECT_SOURCE || type == AL_OBJECT_AUXILIARY_EFFECT_SLOT;

		ALObject object = { type, id, device, inContext ? context : 0 };
		alObjects[handle] = object;

		if (type == AL_OBJECT_BUFFER) {

			alBuffers[std::make_pair (device, id)] = handle;

			// It may have been waiting for a source to let go of it
			claim_unreleased_al_buffers (&id, 1);

		}

		delete_unreleased_al ();

	}


	void* find_al_buffer (ALuint id) {

		std::map<std::pair<ALCdevice*, ALuint>, void*>::iterator buffer = alBuffers.find (std::make_pair (current_al_device (), id));
		return buffer != alBuffers.end () ? buffer->second : 0;

	}


	// Finalizers run while the collector has the other threads stopped, and one of
	// them may hold al_gc_mutex, so they only queue the object for the next thread
	// that takes the lock to release
	void gc_al_object (value object) {

		al_finalized_mutex.Lock ();
		alFinalized.push_back ((void*)object);
		al_finalized_mutex.Unlock ();

	}


	void hl_gc_al_object (HL_CFFIPointer* object) {

		al_finalized_mutex.Lock ();
		alFinalized.push_back (object);
		al_finalized_mutex.Unlock ();

	}


	void gc_alc_object (value object) {

		al_finalized_mutex.Lock ();
		alcFinalized.push_back (std::make_pair (val_data (object), (void*)object));
		al_finalized_mutex.Unlock ();

	}


	void hl_gc_alc_object (HL_CFFIPointer* object) {

		al_finalized_mutex.Lock ();
		alcFinalized.push_back (std::make_pair (object->ptr, (void*)object));
		al_finalized_mutex.Unlock ();

	}


	value al_object (ALObjectType type, ALuint id) {

		lock_al_gc ();
		value object = CFFIPointer ((void*)(uintptr_t)id, gc_al_object);
		track_al_object (object, type, id);
		al_gc_mutex.Unlock ();
		return object;

	}


	HL_CFFIPointer* hl_al_object (ALObjectType type, ALuint id) {

		lock_al_gc ();
		HL_CFFIPointer* object = HLCFFIPointer ((void*)(uintptr_t)id, (hl_finalizer)hl_gc_al_object);
		track_al_object (object, type, id);
		al_gc_mutex.Unlock ();
		return object;

	}


	value al_buffer_object (ALuint id) {

		if (!id) {

			return alloc_null ();

		}

		lock_al_gc ();
		release_finalized_al ();
		value object = (value)find_al_buffer (id);

		if (!object) {

			object = CFFIPointer ((void*)(uintptr_t)id, gc_al_object);
			track_al_object (object, AL_OBJECT_BUFFER, id);

		}

		al_gc_mutex.Unlock ();
		return object;

	}


	HL_CFFIPointer* hl_al_buffer_object (ALuint id) {

		if (!id) {

			return 0;

		}

		lock_al_gc ();
		release_finalized_al ();
		HL_CFFIPointer* object = (HL_CFFIPointer*)find_al_buffer (id);

		if (!object) {

			object = HLCFFIPointer ((void*)(uintptr_t)id, (hl_finalizer)hl_gc_al_object);
			track_al_object (object, AL_OBJECT_BUFFER, id);

		}

		al_gc_mutex.Unlock ();
		return object;

	}


	value alc_object (void* ptr) {

		if (!ptr) {

			return alloc_null ();

		}

		lock_al_gc ();
		release_finalized_al ();

		value object;
		std::map<void*, void*>::iterator found = alcObjects.find (ptr);

		if (found != alcObjects.end ()) {

			object = (value)found->second;

		} else {

			object = CFFIPointer (ptr, gc_alc_object);

			// The new handle may have the address of one that was collected
			release_finalized_al ();
			alcObjects[ptr] = object;

		}

		al_gc_mutex.Unlock ();
		return object;

	}


	HL_CFFIPointer* hl_alc_object (void* ptr) {

		if (!ptr) {

			return 0;

		}

		lock_al_gc ();
		release_finalized_al ();

		HL_CFFIPointer* object;
		std::map<void*, void*>::iterator found = alcObjects.find (ptr);

		if (found != alcObjects.end ()) {

			object = (HL_CFFIPointer*)found->second;

		} else {

			object = HLCFFIPointer (ptr, (hl_finalizer)hl_gc_alc_object);

			// The new handle may have the address of one that was collected
			release_finalized_al ();
			alcObjects[ptr] = object;

		}

		al_gc_mutex.Unlock ();
		return object;

	}


	// Returns false if the object is still there, so its handle stays in charge of it
	bool delete_al_handle (void* handle) {

		release_finalized_al ();

		std::map<void*, ALObject>::iterator object = alObjects.find (handle);

		if (object == alObjects.end ()) {

			return true;

		}

		if (!is_al_object_current (object->second)) {

			return false;

		}

		bool deleted = delete_al_object (object->second);

		#ifdef LIME_OPENAL_DELETION_DELAY
		alUnreleased.push_back (object->second);
		deleted = true;
		#endif

		if (deleted) {

			forget_al_object (object);

		}

		return deleted;

	}


	void delete_al_value (value object) {

		if (!val_is_null (object)) {

			lock_al_gc ();

			if (delete_al_handle (object)) {

				val_gc (object, 0);

			}

			al_gc_mutex.Unlock ();

		}

	}


	void hl_delete_al_value (HL_CFFIPointer* object) {

		if (object) {

			lock_al_gc ();

			if (delete_al_handle (object)) {

				object->finalizer = 0;

			}

			al_gc_mutex.Unlock ();

		}

	}


	void forget_alc_device (ALCdevice* device) {

		lock_al_gc ();
		release_finalized_al ();
		forget_al_objects (device, 0);
		alcObjects.erase (device);
		al_gc_mutex.Unlock ();

	}


	void destroy_alc_context (ALCcontext* context) {

		lock_al_gc ();
		release_finalized_al ();
		forget_al_objects (0, context);
		alcObjects.erase (context);
		alHeldError = AL_NO_ERROR;

		if (context == alcGetCurrentContext ()) {

			alcMakeContextCurrent (0);

		}

		alcDestroyContext (context);
		al_gc_mutex.Unlock ();

	}


	ALenum read_al_error () {

		lock_al_gc ();
		ALenum error = alGetError ();

		if (alHeldError != AL_NO_ERROR) {

			error = alHeldError;
			alHeldError = AL_NO_ERROR;

		}

		al_gc_mutex.Unlock ();
		return error;

	}

	/*This has been removed after updating to openal 1.20.0+ since the cleanup functions involved
	* lead to deadlocking. See https://github.com/openfl/lime/issues/1803 for more info.
	* Developers should use lime.system.System.exit() instead of Sys.exit() to clean up any system
	* resources
	*/
	/*
	void lime_al_atexit () {

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
	*/


	void lime_al_auxf (value aux, int param, float value) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)val_data (aux);
		alAuxiliaryEffectSlotf (id, param, value);
		#endif

	}


	HL_PRIM void HL_NAME(hl_al_auxf) (HL_CFFIPointer* aux, int param, float value) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)aux->ptr;
		alAuxiliaryEffectSlotf (id, param, value);
		#endif

	}


	void lime_al_auxfv (value aux, int param, value values) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)val_data (aux);

		if (!val_is_null (values)) {

			int size = val_array_size (values);
			ALfloat *data = new ALfloat[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALfloat)val_float (val_array_i (values, i));

			}

			alAuxiliaryEffectSlotfv (id, param, data);
			delete[] data;

		}
		#endif

	}


	HL_PRIM void HL_NAME(hl_al_auxfv) (HL_CFFIPointer* aux, int param, varray* values) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)aux->ptr;

		if (values) {

			int size = values->size;
			alAuxiliaryEffectSlotfv (id, param, hl_aptr (values, float));

		}
		#endif

	}


	void lime_al_auxi (value aux, int param, value val) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)val_data (aux);
		ALuint data = 0;

		if (param == AL_EFFECTSLOT_EFFECT) {

			data = (ALuint)(uintptr_t)val_data (val);

		} else {

			data = val_int (val);

		}

		alAuxiliaryEffectSloti (id, param, data);
		#endif

	}


	HL_PRIM void HL_NAME(hl_al_auxi) (HL_CFFIPointer* aux, int param, vdynamic* val) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)aux->ptr;
		ALuint data = 0;

		if (param == AL_EFFECTSLOT_EFFECT) {

			data = (ALuint)(uintptr_t)((HL_CFFIPointer*)val)->ptr;

		} else {

			data = val->v.i;

		}

		alAuxiliaryEffectSloti (id, param, data);
		#endif

	}


	void lime_al_auxiv (value aux, int param, value values) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)val_data (aux);

		if (!val_is_null (values)) {

			int size = val_array_size (values);
			ALint* data = new ALint[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALint)val_int (val_array_i (values, i));

			}

			alAuxiliaryEffectSlotiv (id, param, data);
			delete[] data;

		}
		#endif

	}


	HL_PRIM void HL_NAME(hl_al_auxiv) (HL_CFFIPointer* aux, int param, varray* values) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)aux->ptr;

		if (values) {

			alAuxiliaryEffectSlotiv (id, param, hl_aptr (values, int));

		}
		#endif

	}


	void lime_al_buffer_data (value buffer, int format, value data, int size, int freq) {

		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		ArrayBufferView bufferView (data);
		alBufferData (id, format, bufferView.buffer->b, size, freq);

	}


	HL_PRIM void HL_NAME(hl_al_buffer_data) (HL_CFFIPointer* buffer, int format, ArrayBufferView* data, int size, int freq) {

		ALuint id = (ALuint)(uintptr_t)buffer->ptr;
		alBufferData (id, format, data->buffer->b, size, freq);

	}


	void lime_al_buffer3f (value buffer, int param, float value1, float value2, float value3) {

		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		alBuffer3f (id, param, value1, value2, value3);

	}


	HL_PRIM void HL_NAME(hl_al_buffer3f) (HL_CFFIPointer* buffer, int param, float value1, float value2, float value3) {

		ALuint id = (ALuint)(uintptr_t)buffer->ptr;
		alBuffer3f (id, param, value1, value2, value3);

	}


	void lime_al_buffer3i (value buffer, int param, int value1, int value2, int value3) {

		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		alBuffer3i (id, param, value1, value2, value3);

	}


	HL_PRIM void HL_NAME(hl_al_buffer3i) (HL_CFFIPointer* buffer, int param, int value1, int value2, int value3) {

		ALuint id = (ALuint)(uintptr_t)buffer->ptr;
		alBuffer3i (id, param, value1, value2, value3);

	}


	void lime_al_bufferf (value buffer, int param, float value) {

		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		alBufferf (id, param, value);

	}


	HL_PRIM void HL_NAME(hl_al_bufferf) (HL_CFFIPointer* buffer, int param, float value) {

		ALuint id = (ALuint)(uintptr_t)buffer->ptr;
		alBufferf (id, param, value);

	}


	void lime_al_bufferfv (value buffer, int param, value values) {

		ALuint id = (ALuint)(uintptr_t)val_data (buffer);

		if (!val_is_null (values)) {

			int size = val_array_size (values);
			ALfloat *data = new ALfloat[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALfloat)val_float (val_array_i (values, i));

			}

			alBufferfv (id, param, data);
			delete[] data;

		}

	}


	HL_PRIM void HL_NAME(hl_al_bufferfv) (HL_CFFIPointer* buffer, int param, varray* values) {

		ALuint id = (ALuint)(uintptr_t)buffer->ptr;

		if (values) {

			int size = values->size;
			alBufferfv (id, param, hl_aptr (values, float));

		}

	}


	void lime_al_bufferi (value buffer, int param, int value) {

		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		alBufferi (id, param, value);

	}


	HL_PRIM void HL_NAME(hl_al_bufferi) (HL_CFFIPointer* buffer, int param, int value) {

		ALuint id = (ALuint)(uintptr_t)buffer->ptr;
		alBufferi (id, param, value);

	}


	void lime_al_bufferiv (value buffer, int param, value values) {

		ALuint id = (ALuint)(uintptr_t)val_data (buffer);

		if (!val_is_null (values)) {

			int size = val_array_size (values);
			ALint* data = new ALint[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALint)val_int (val_array_i (values, i));

			}

			alBufferiv (id, param, data);
			delete[] data;

		}

	}


	HL_PRIM void HL_NAME(hl_al_bufferiv) (HL_CFFIPointer* buffer, int param, varray* values) {

		ALuint id = (ALuint)(uintptr_t)buffer->ptr;

		if (values) {

			alBufferiv (id, param, hl_aptr (values, int));

		}

	}


	void lime_al_cleanup () {

		lock_al_gc ();
		release_finalized_al ();
		al_gc_mutex.Unlock ();

	}


	HL_PRIM void HL_NAME(hl_al_cleanup) () {

		lime_al_cleanup ();

	}


	void lime_al_delete_auxiliary_effect_slot (value aux) {

		delete_al_value (aux);

	}


	HL_PRIM void HL_NAME(hl_al_delete_auxiliary_effect_slot) (HL_CFFIPointer* aux) {

		hl_delete_al_value (aux);

	}


	void lime_al_delete_buffer (value buffer) {

		delete_al_value (buffer);

	}


	HL_PRIM void HL_NAME(hl_al_delete_buffer) (HL_CFFIPointer* buffer) {

		hl_delete_al_value (buffer);

	}


	void lime_al_delete_buffers (int n, value buffers) {

		if (!val_is_null (buffers)) {

			int size = val_array_size (buffers);

			for (int i = 0; i < size; ++i) {

				delete_al_value (val_array_i (buffers, i));

			}

		}

	}


	HL_PRIM void HL_NAME(hl_al_delete_buffers) (int n, varray* buffers) {

		if (buffers) {

			HL_CFFIPointer** data = hl_aptr (buffers, HL_CFFIPointer*);

			for (int i = 0; i < buffers->size; ++i) {

				hl_delete_al_value (*data++);

			}

		}

	}


	void lime_al_delete_effect (value effect) {

		delete_al_value (effect);

	}


	HL_PRIM void HL_NAME(hl_al_delete_effect) (HL_CFFIPointer* effect) {

		hl_delete_al_value (effect);

	}


	void lime_al_delete_filter (value filter) {

		delete_al_value (filter);

	}


	HL_PRIM void HL_NAME(hl_al_delete_filter) (HL_CFFIPointer* filter) {

		hl_delete_al_value (filter);

	}


	void lime_al_delete_source (value source) {

		delete_al_value (source);

	}


	HL_PRIM void HL_NAME(hl_al_delete_source) (HL_CFFIPointer* source) {

		hl_delete_al_value (source);

	}


	void lime_al_delete_sources (int n, value sources) {

		if (!val_is_null (sources)) {

			int size = val_array_size (sources);

			for (int i = 0; i < size; ++i) {

				delete_al_value (val_array_i (sources, i));

			}

		}

	}


	HL_PRIM void HL_NAME(hl_al_delete_sources) (int n, varray* sources) {

		if (sources) {

			HL_CFFIPointer** data = hl_aptr (sources, HL_CFFIPointer*);

			for (int i = 0; i < sources->size; ++i) {

				hl_delete_al_value (*data++);

			}

		}

	}


	void lime_al_disable (int capability) {

		alDisable (capability);

	}


	HL_PRIM void HL_NAME(hl_al_disable) (int capability) {

		alDisable (capability);

	}


	void lime_al_distance_model (int distanceModel) {

		alDistanceModel (distanceModel);

	}


	HL_PRIM void HL_NAME(hl_al_distance_model) (int distanceModel) {

		alDistanceModel (distanceModel);

	}


	void lime_al_doppler_factor (float factor) {

		alDopplerFactor (factor);

	}


	HL_PRIM void HL_NAME(hl_al_doppler_factor) (float factor) {

		alDopplerFactor (factor);

	}


	void lime_al_doppler_velocity (float velocity) {

		alDopplerVelocity (velocity);

	}


	HL_PRIM void HL_NAME(hl_al_doppler_velocity) (float velocity) {

		alDopplerVelocity (velocity);

	}


	void lime_al_effectf (value effect, int param, float value) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)val_data (effect);
		alEffectf (id, param, value);
		#endif

	}


	HL_PRIM void HL_NAME(hl_al_effectf) (HL_CFFIPointer* effect, int param, float value) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)effect->ptr;
		alEffectf (id, param, value);
		#endif

	}


	void lime_al_effectfv (value effect, int param, value values) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)val_data (effect);

		if (!val_is_null (values)) {

			int size = val_array_size (values);
			ALfloat *data = new ALfloat[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALfloat)val_float (val_array_i (values, i));

			}

			alEffectfv (id, param, data);
			delete[] data;

		}
		#endif

	}


	HL_PRIM void HL_NAME(hl_al_effectfv) (HL_CFFIPointer* effect, int param, varray* values) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)effect->ptr;

		if (values) {

			int size = values->size;
			alEffectfv (id, param, hl_aptr (values, float));

		}
		#endif

	}


	void lime_al_effecti (value effect, int param, int value) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)val_data (effect);
		alEffecti (id, param, value);
		#endif

	}


	HL_PRIM void HL_NAME(hl_al_effecti) (HL_CFFIPointer* effect, int param, int value) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)effect->ptr;
		alEffecti (id, param, value);
		#endif

	}


	void lime_al_effectiv (value effect, int param, value values) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)val_data (effect);

		if (!val_is_null (values)) {

			int size = val_array_size (values);
			ALint* data = new ALint[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALint)val_int (val_array_i (values, i));

			}

			alEffectiv (id, param, data);
			delete[] data;

		}
		#endif

	}


	HL_PRIM void HL_NAME(hl_al_effectiv) (HL_CFFIPointer* effect, int param, varray* values) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)effect->ptr;

		if (values) {

			alEffectiv (id, param, hl_aptr (values, int));

		}
		#endif

	}


	void lime_al_enable (int capability) {

		alEnable (capability);

	}


	HL_PRIM void HL_NAME(hl_al_enable) (int capability) {

		alEnable (capability);

	}


	void lime_al_filteri (value filter, int param, value val) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)val_data (filter);
		ALuint data = 0;

		data = val_int (val);

		alFilteri (id, param, data);
		#endif

	}


	HL_PRIM void HL_NAME(hl_al_filteri) (HL_CFFIPointer* filter, int param, int val) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)filter->ptr;
		ALuint data = 0;

		data = val;

		alFilteri (id, param, data);
		#endif

	}


	void lime_al_filterf (value filter, int param, float value) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)val_data (filter);
		alFilterf (id, param, value);
		#endif

	}


	HL_PRIM void HL_NAME(hl_al_filterf) (HL_CFFIPointer* filter, int param, float value) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)filter->ptr;
		alFilterf (id, param, value);
		#endif

	}


	value lime_al_gen_aux () {

		alGetError ();

		#ifdef LIME_OPENALSOFT
		ALuint aux = 0;
		alGenAuxiliaryEffectSlots ((ALuint)1, &aux);

		if (alGetError () == AL_NO_ERROR) {

			return al_object (AL_OBJECT_AUXILIARY_EFFECT_SLOT, aux);

		}
		#endif

		return alloc_null ();

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_al_gen_aux) () {

		alGetError ();

		#ifdef LIME_OPENALSOFT
		ALuint aux = 0;
		alGenAuxiliaryEffectSlots ((ALuint)1, &aux);

		if (alGetError () == AL_NO_ERROR) {

			return hl_al_object (AL_OBJECT_AUXILIARY_EFFECT_SLOT, aux);

		}
		#endif

		return 0;

	}


	value lime_al_gen_buffer () {

		alGetError ();

		ALuint buffer = 0;
		alGenBuffers ((ALuint)1, &buffer);

		if (alGetError () == AL_NO_ERROR) {

			return al_object (AL_OBJECT_BUFFER, buffer);

		} else {

			return alloc_null ();

		}

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_al_gen_buffer) () {

		alGetError ();

		ALuint buffer = 0;
		alGenBuffers ((ALuint)1, &buffer);

		if (alGetError () == AL_NO_ERROR) {

			return hl_al_object (AL_OBJECT_BUFFER, buffer);

		} else {

			return 0;

		}

	}


	value lime_al_gen_buffers (int n) {

		alGetError ();

		ALuint* buffers = new ALuint[n];
		alGenBuffers (n, buffers);

		if (alGetError () == AL_NO_ERROR) {

			value result = alloc_array (n);

			for (int i = 0; i < n; i++) {

				val_array_set_i (result, i, al_object (AL_OBJECT_BUFFER, buffers[i]));

			}

			delete[] buffers;
			return result;

		} else {

			delete[] buffers;
			return alloc_null ();

		}

	}


	HL_PRIM varray* HL_NAME(hl_al_gen_buffers) (int n) {

		alGetError ();

		ALuint* buffers = new ALuint[n];
		alGenBuffers (n, buffers);

		if (alGetError () == AL_NO_ERROR) {

			varray* result = hl_alloc_array (&hlt_dyn, n);
			HL_CFFIPointer** resultData = hl_aptr (result, HL_CFFIPointer*);

			for (int i = 0; i < n; i++) {

				*resultData++ = hl_al_object (AL_OBJECT_BUFFER, buffers[i]);

			}

			delete[] buffers;
			return result;

		} else {

			delete[] buffers;
			return NULL;

		}

	}


	value lime_al_gen_effect () {

		alGetError ();

		#ifdef LIME_OPENALSOFT
		ALuint effect = 0;
		alGenEffects ((ALuint)1, &effect);

		if (alGetError () == AL_NO_ERROR) {

			return al_object (AL_OBJECT_EFFECT, effect);

		}
		#endif

		return alloc_null ();

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_al_gen_effect) () {

		alGetError ();

		#ifdef LIME_OPENALSOFT
		ALuint effect = 0;
		alGenEffects ((ALuint)1, &effect);

		if (alGetError () == AL_NO_ERROR) {

			return hl_al_object (AL_OBJECT_EFFECT, effect);

		}
		#endif

		return NULL;

	}


	value lime_al_gen_filter () {

		alGetError ();

		#ifdef LIME_OPENALSOFT
		ALuint filter = 0;
		alGenFilters ((ALuint)1, &filter);

		if (alGetError () == AL_NO_ERROR) {

			return al_object (AL_OBJECT_FILTER, filter);

		}
		#endif

		return alloc_null ();

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_al_gen_filter) () {

		alGetError ();

		#ifdef LIME_OPENALSOFT
		ALuint filter = 0;
		alGenFilters ((ALuint)1, &filter);

		if (alGetError () == AL_NO_ERROR) {

			return hl_al_object (AL_OBJECT_FILTER, filter);

		}
		#endif

		return NULL;

	}


	value lime_al_gen_source () {

		alGetError ();

		ALuint source = 0;
		alGenSources ((ALuint)1, &source);

		if (alGetError () == AL_NO_ERROR) {

			return al_object (AL_OBJECT_SOURCE, source);

		} else {

			return alloc_null ();

		}

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_al_gen_source) () {

		alGetError ();

		ALuint source = 0;
		alGenSources ((ALuint)1, &source);

		if (alGetError () == AL_NO_ERROR) {

			return hl_al_object (AL_OBJECT_SOURCE, source);

		} else {

			return NULL;

		}

	}


	value lime_al_gen_sources (int n) {

		alGetError ();

		ALuint* sources = new ALuint[n];
		alGenSources (n, sources);

		if (alGetError () == AL_NO_ERROR) {

			value result = alloc_array (n);

			for (int i = 0; i < n; i++) {

				val_array_set_i (result, i, al_object (AL_OBJECT_SOURCE, sources[i]));

			}

			delete[] sources;
			return result;

		} else {

			delete[] sources;
			return alloc_null ();

		}

	}


	HL_PRIM varray* HL_NAME(hl_al_gen_sources) (int n) {

		alGetError ();

		ALuint* sources = new ALuint[n];
		alGenSources (n, sources);

		if (alGetError () == AL_NO_ERROR) {

			varray* result = hl_alloc_array (&hlt_dyn, n);
			HL_CFFIPointer** resultData = hl_aptr (result, HL_CFFIPointer*);

			for (int i = 0; i < n; i++) {

				*resultData++ = hl_al_object (AL_OBJECT_SOURCE, sources[i]);

			}

			delete[] sources;
			return result;

		} else {

			delete[] sources;
			return NULL;

		}

	}


	bool lime_al_get_boolean (int param) {

		return alGetBoolean (param);

	}


	HL_PRIM bool HL_NAME(hl_al_get_boolean) (int param) {

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


	HL_PRIM varray* HL_NAME(hl_al_get_booleanv) (int param, int count) {

		varray* result = hl_alloc_array (&hlt_bool, count);
		alGetBooleanv (param, (ALboolean*)hl_aptr (result, bool));
		return result;

	}


	value lime_al_get_buffer3f (value buffer, int param) {

		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		ALfloat val1 = 0, val2 = 0, val3 = 0;

		alGetBuffer3f (id, param, &val1, &val2, &val3);

		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_float (val1));
		val_array_set_i (result, 1, alloc_float (val2));
		val_array_set_i (result, 2, alloc_float (val3));
		return result;

	}


	HL_PRIM varray* HL_NAME(hl_al_get_buffer3f) (HL_CFFIPointer* buffer, int param) {

		ALuint id = (ALuint)(uintptr_t)buffer->ptr;
		varray* result = hl_alloc_array (&hlt_f32, 3);
		alGetBuffer3f (id, param, &hl_aptr (result, float)[0], &hl_aptr (result, float)[1], &hl_aptr (result, float)[2]);
		return result;

	}


	value lime_al_get_buffer3i (value buffer, int param) {

		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		ALint val1 = 0, val2 = 0, val3 = 0;

		alGetBuffer3i (id, param, &val1, &val2, &val3);

		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_int (val1));
		val_array_set_i (result, 1, alloc_int (val2));
		val_array_set_i (result, 2, alloc_int (val3));
		return result;

	}


	HL_PRIM varray* HL_NAME(hl_al_get_buffer3i) (HL_CFFIPointer* buffer, int param) {

		ALuint id = (ALuint)(uintptr_t)buffer->ptr;
		varray* result = hl_alloc_array (&hlt_i32, 3);

		alGetBuffer3i (id, param, &hl_aptr (result, int)[0], &hl_aptr (result, int)[2], &hl_aptr (result, int)[3]);
		return result;

	}


	float lime_al_get_bufferf (value buffer, int param) {

		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		ALfloat data = 0;
		alGetBufferf (id, param, &data);
		return data;

	}


	HL_PRIM float HL_NAME(hl_al_get_bufferf) (HL_CFFIPointer* buffer, int param) {

		ALuint id = (ALuint)(uintptr_t)buffer->ptr;
		ALfloat data = 0;
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


	HL_PRIM varray* HL_NAME(hl_al_get_bufferfv) (HL_CFFIPointer* buffer, int param, int count) {

		ALuint id = (ALuint)(uintptr_t)buffer->ptr;
		varray* result = hl_alloc_array (&hlt_f32, count);
		alGetBufferfv (id, param, hl_aptr (result, float));
		return result;

	}


	int lime_al_get_bufferi (value buffer, int param) {

		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		ALint data = 0;
		alGetBufferi (id, param, &data);
		return data;

	}


	HL_PRIM int HL_NAME(hl_al_get_bufferi) (HL_CFFIPointer* buffer, int param) {

		ALuint id = (ALuint)(uintptr_t)buffer->ptr;
		ALint data = 0;
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


	HL_PRIM varray* HL_NAME(hl_al_get_bufferiv) (HL_CFFIPointer* buffer, int param, int count) {

		ALuint id = (ALuint)(uintptr_t)buffer->ptr;
		varray* result = hl_alloc_array (&hlt_i32, count);
		alGetBufferiv (id, param, hl_aptr (result, int));
		return result;

	}


	double lime_al_get_double (int param) {

		return alGetDouble (param);

	}


	HL_PRIM double HL_NAME(hl_al_get_double) (int param) {

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


	HL_PRIM varray* HL_NAME(hl_al_get_doublev) (int param, int count) {

		varray* result = hl_alloc_array (&hlt_f64, count);
		alGetDoublev (param, hl_aptr (result, double));
		return result;

	}


	int lime_al_get_enum_value (HxString ename) {

		return alGetEnumValue (ename.__s);

	}


	HL_PRIM int HL_NAME(hl_al_get_enum_value) (hl_vstring* ename) {

		return alGetEnumValue (ename ? hl_to_utf8 (ename->bytes) : NULL);

	}


	int lime_al_get_error () {

		return read_al_error ();

	}


	HL_PRIM int HL_NAME(hl_al_get_error) () {

		return read_al_error ();

	}


	int lime_al_get_filteri (value filter, int param) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)val_data (filter);
		ALint data = 0;
		alGetFilteri (id, param, &data);
		return data;
		#else
		return 0;
		#endif

	}


	HL_PRIM int HL_NAME(hl_al_get_filteri) (HL_CFFIPointer* filter, int param) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)filter->ptr;
		ALint data = 0;
		alGetFilteri (id, param, &data);
		return data;
		#else
		return 0;
		#endif

	}


	float lime_al_get_float (int param) {

		return alGetFloat (param);

	}


	HL_PRIM float HL_NAME(hl_al_get_float) (int param) {

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


	HL_PRIM varray* HL_NAME(hl_al_get_floatv) (int param, int count) {

		varray* result = hl_alloc_array (&hlt_f32, count);
		alGetFloatv (param, hl_aptr (result, float));
		return result;

	}


	int lime_al_get_integer (int param) {

		return alGetInteger (param);

	}


	HL_PRIM int HL_NAME(hl_al_get_integer) (int param) {

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


	HL_PRIM varray* HL_NAME(hl_al_get_integerv) (int param, int count) {

		varray* result = hl_alloc_array (&hlt_i32, count);
		alGetIntegerv (param, hl_aptr (result, int));
		return result;

	}


	value lime_al_get_listener3f (int param) {

		ALfloat val1 = 0, val2 = 0, val3 = 0;

		alGetListener3f (param, &val1, &val2, &val3);

		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_float (val1));
		val_array_set_i (result, 1, alloc_float (val2));
		val_array_set_i (result, 2, alloc_float (val3));
		return result;

	}


	HL_PRIM varray* HL_NAME(hl_al_get_listener3f) (int param) {

		varray* result = hl_alloc_array (&hlt_f32, 3);
		alGetListener3f (param, &hl_aptr (result, float)[0], &hl_aptr (result, float)[2], &hl_aptr (result, float)[3]);
		return result;

	}


	value lime_al_get_listener3i (int param) {

		ALint val1 = 0, val2 = 0, val3 = 0;

		alGetListener3i (param, &val1, &val2, &val3);

		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_int (val1));
		val_array_set_i (result, 1, alloc_int (val2));
		val_array_set_i (result, 2, alloc_int (val3));
		return result;

	}


	HL_PRIM varray* HL_NAME(hl_al_get_listener3i) (int param) {

		varray* result = hl_alloc_array (&hlt_i32, 3);
		alGetListener3i (param, &hl_aptr (result, int)[0], &hl_aptr (result, int)[2], &hl_aptr (result, int)[3]);
		return result;

	}


	float lime_al_get_listenerf (int param) {

		ALfloat data = 0;
		alGetListenerf (param, &data);
		return data;

	}


	HL_PRIM float HL_NAME(hl_al_get_listenerf) (int param) {

		ALfloat data = 0;
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


	HL_PRIM varray* HL_NAME(hl_al_get_listenerfv) (int param, int count) {

		varray* result = hl_alloc_array (&hlt_f32, count);
		alGetListenerfv (param, hl_aptr (result, float));
		return result;

	}


	int lime_al_get_listeneri (int param) {

		ALint data = 0;
		alGetListeneri (param, &data);
		return data;

	}


	HL_PRIM int HL_NAME(hl_al_get_listeneri) (int param) {

		ALint data = 0;
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


	HL_PRIM varray* HL_NAME(hl_al_get_listeneriv) (int param, int count) {

		varray* result = hl_alloc_array (&hlt_i32, count);
		alGetListeneriv (param, hl_aptr (result, int));
		return result;

	}


	double lime_al_get_proc_address (HxString fname) {

		return (uintptr_t)alGetProcAddress (fname.__s);

	}


	HL_PRIM double HL_NAME(hl_al_get_proc_address) (hl_vstring* fname) {

		return (uintptr_t)alGetProcAddress (fname ? hl_to_utf8 (fname->bytes) : NULL);

	}


	value lime_al_get_source3f (value source, int param) {

		ALuint id = (ALuint)(uintptr_t)val_data (source);
		ALfloat val1 = 0, val2 = 0, val3 = 0;

		alGetSource3f (id, param, &val1, &val2, &val3);

		value result = alloc_array (3);
		val_array_set_i (result, 0, alloc_float (val1));
		val_array_set_i (result, 1, alloc_float (val2));
		val_array_set_i (result, 2, alloc_float (val3));
		return result;

	}


	HL_PRIM varray* HL_NAME(hl_al_get_source3f) (HL_CFFIPointer* source, int param) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;
		varray* result = hl_alloc_array (&hlt_f32, 3);
		alGetSource3f (id, param, &hl_aptr (result, float)[0], &hl_aptr (result, float)[2], &hl_aptr (result, float)[3]);
		return result;

	}


	value lime_al_get_source3i (value source, int param) {

		ALuint id = (ALuint)(uintptr_t)val_data (source);
		ALint val1 = 0, val2 = 0, val3 = 0;

		alGetSource3i (id, param, &val1, &val2, &val3);

		value result = alloc_array (3);
		val_array_set_i (result, 1, alloc_int (val1));
		val_array_set_i (result, 2, alloc_int (val2));
		val_array_set_i (result, 3, alloc_int (val3));
		return result;

	}


	HL_PRIM varray* HL_NAME(hl_al_get_source3i) (HL_CFFIPointer* source, int param) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;
		varray* result = hl_alloc_array (&hlt_i32, 3);
		alGetSource3i (id, param, &hl_aptr (result, int)[0], &hl_aptr (result, int)[2], &hl_aptr (result, int)[3]);
		return result;

	}


	// The source latency parameters write two values, whatever count asks for
	#define LIME_AL_SOURCEDV_MAX 2


	value lime_al_get_sourcedv_soft (value source, int param, int count) {

		ALdouble values[LIME_AL_SOURCEDV_MAX] = { 0, 0 };
		if (count < 0) count = 0;

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		alGetSourcedvSOFT (id, param, values);
		#endif

		value result = alloc_array (count);

		for (int i = 0; i < count; i++) {

			val_array_set_i (result, i, alloc_float (i < LIME_AL_SOURCEDV_MAX ? values[i] : 0));

		}

		return result;

	}


	HL_PRIM varray* HL_NAME(hl_al_get_sourcedv_soft) (HL_CFFIPointer* source, int param, int count) {

		ALdouble values[LIME_AL_SOURCEDV_MAX] = { 0, 0 };
		if (count < 0) count = 0;

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)source->ptr;
		alGetSourcedvSOFT (id, param, values);
		#endif

		varray* result = hl_alloc_array (&hlt_f64, count);
		double* data = hl_aptr (result, double);

		for (int i = 0; i < count; i++) {

			data[i] = i < LIME_AL_SOURCEDV_MAX ? values[i] : 0;

		}

		return result;

	}


	float lime_al_get_sourcef (value source, int param) {

		ALuint id = (ALuint)(uintptr_t)val_data (source);
		ALfloat data = 0;
		alGetSourcef (id, param, &data);
		return data;

	}


	HL_PRIM float HL_NAME(hl_al_get_sourcef) (HL_CFFIPointer* source, int param) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;
		ALfloat data = 0;
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


	HL_PRIM varray* HL_NAME(hl_al_get_sourcefv) (HL_CFFIPointer* source, int param, int count) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;
		varray* result = hl_alloc_array (&hlt_f32, count);
		alGetSourcefv (id, param, hl_aptr (result, float));
		return result;

	}


	value lime_al_get_sourcei (value source, int param) {

		ALuint id = (ALuint)(uintptr_t)val_data (source);
		ALint data = 0;
		alGetSourcei (id, param, &data);

		if (param == AL_BUFFER) {

			return al_buffer_object (data);

		} else {

			return alloc_int (data);

		}

	}


	HL_PRIM vdynamic* HL_NAME(hl_al_get_sourcei) (HL_CFFIPointer* source, int param) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;
		ALint data = 0;
		alGetSourcei (id, param, &data);

		if (param == AL_BUFFER) {

			return (vdynamic*)hl_al_buffer_object (data);

		} else {

			vdynamic* result = hl_alloc_dynamic (&hlt_i32);
			result->v.i = data;
			return result;

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


	HL_PRIM varray* HL_NAME(hl_al_get_sourceiv) (HL_CFFIPointer* source, int param, int count) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;
		varray* result = hl_alloc_array (&hlt_i32, count);
		alGetSourceiv (id, param, hl_aptr (result, int));
		return result;

	}


	value lime_al_get_string (int param) {

		const char* result = alGetString (param);
		return result ? alloc_string (result) : alloc_null ();

	}


	HL_PRIM vbyte* HL_NAME(hl_al_get_string) (int param) {

		const char* result = alGetString (param);
		int length = strlen (result);
		char* _result = (char*)malloc (length + 1);
		strcpy (_result, result);
		return (vbyte*)_result;

	}


	bool lime_al_is_aux (value aux) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)val_data (aux);
		return alIsAuxiliaryEffectSlot (id);
		#else
		return false;
		#endif

	}


	HL_PRIM bool HL_NAME(hl_al_is_aux) (HL_CFFIPointer* aux) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)aux->ptr;
		return alIsAuxiliaryEffectSlot (id);
		#else
		return false;
		#endif

	}


	bool lime_al_is_buffer (value buffer) {

		ALuint id = (ALuint)(uintptr_t)val_data (buffer);
		return alIsBuffer (id);

	}


	HL_PRIM bool HL_NAME(hl_al_is_buffer) (HL_CFFIPointer* buffer) {

		ALuint id = (ALuint)(uintptr_t)buffer->ptr;
		return alIsBuffer (id);

	}


	bool lime_al_is_effect (value effect) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)val_data (effect);
		return alIsEffect (id);
		#else
		return false;
		#endif

	}


	HL_PRIM bool HL_NAME(hl_al_is_effect) (HL_CFFIPointer* effect) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)effect->ptr;
		return alIsEffect (id);
		#else
		return false;
		#endif

	}


	bool lime_al_is_enabled (int capability) {

		return alIsEnabled (capability);

	}


	HL_PRIM bool HL_NAME(hl_al_is_enabled) (int capability) {

		return alIsEnabled (capability);

	}


	bool lime_al_is_extension_present (HxString extname) {

		#ifdef LIME_OPENALSOFT
		return alIsExtensionPresent (extname.__s);
		#else
		return false;
		#endif

	}


	HL_PRIM bool HL_NAME(hl_al_is_extension_present) (hl_vstring* extname) {

		#ifdef LIME_OPENALSOFT
		return alIsExtensionPresent (extname ? hl_to_utf8 (extname->bytes) : NULL);
		#else
		return false;
		#endif

	}


	bool lime_alc_is_extension_present (value device, HxString extname) {

		#ifdef LIME_OPENALSOFT
		ALCdevice* alcDevice = val_is_null (device) ? NULL : (ALCdevice*)val_data (device);
		return extname.__s ? alcIsExtensionPresent (alcDevice, extname.__s) : false;
		#else
		return false;
		#endif

	}


	HL_PRIM bool HL_NAME(hl_alc_is_extension_present) (HL_CFFIPointer* device, hl_vstring* extname) {

		#ifdef LIME_OPENALSOFT
		ALCdevice* alcDevice = device ? (ALCdevice*)device->ptr : NULL;
		return extname ? alcIsExtensionPresent (alcDevice, hl_to_utf8 (extname->bytes)) : false;
		#else
		return false;
		#endif

	}


	bool lime_al_is_filter (value filter) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)val_data (filter);
		return alIsSource (id);
		#else
		return false;
		#endif

	}


	HL_PRIM bool HL_NAME(hl_al_is_filter) (HL_CFFIPointer* filter) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)filter->ptr;
		return alIsSource (id);
		#else
		return false;
		#endif

	}


	bool lime_al_is_source (value source) {

		ALuint id = (ALuint)(uintptr_t)val_data (source);
		return alIsSource (id);

	}


	HL_PRIM bool HL_NAME(hl_al_is_source) (HL_CFFIPointer* source) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;
		return alIsSource (id);

	}


	void lime_al_listener3f (int param, float value1, float value2, float value3) {

		alListener3f (param, value1, value2, value3);

	}


	HL_PRIM void HL_NAME(hl_al_listener3f) (int param, float value1, float value2, float value3) {

		alListener3f (param, value1, value2, value3);

	}


	void lime_al_listener3i (int param, int value1, int value2, int value3) {

		alListener3i (param, value1, value2, value3);

	}


	HL_PRIM void HL_NAME(hl_al_listener3i) (int param, int value1, int value2, int value3) {

		alListener3i (param, value1, value2, value3);

	}


	void lime_al_listenerf (int param, float value1) {

		alListenerf (param, value1);

	}


	HL_PRIM void HL_NAME(hl_al_listenerf) (int param, float value1) {

		alListenerf (param, value1);

	}


	void lime_al_listenerfv (int param, value values) {

		if (!val_is_null (values)) {

			int size = val_array_size (values);
			ALfloat *data = new ALfloat[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALfloat)val_float (val_array_i (values, i));

			}

			alListenerfv (param, data);
			delete[] data;

		}

	}


	HL_PRIM void HL_NAME(hl_al_listenerfv) (int param, varray* values) {

		if (values) {

			int size = values->size;
			alListenerfv (param, hl_aptr (values, float));

		}

	}


	void lime_al_listeneri (int param, int value1) {

		alListeneri (param, value1);

	}


	HL_PRIM void HL_NAME(hl_al_listeneri) (int param, int value1) {

		alListeneri (param, value1);

	}


	void lime_al_listeneriv (int param, value values) {

		if (!val_is_null (values)) {

			int size = val_array_size (values);
			ALint* data = new ALint[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALint)val_int (val_array_i (values, i));

			}

			alListeneriv (param, data);
			delete[] data;

		}

	}


	HL_PRIM void HL_NAME(hl_al_listeneriv) (int param, varray* values) {

		if (values) {

			int size = values->size;
			alListeneriv (param, hl_aptr (values, int));

		}

	}


	void lime_al_remove_direct_filter (value source) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		alSourcei (id, AL_DIRECT_FILTER, AL_FILTER_NULL);
		#endif

	}


	HL_PRIM void HL_NAME(hl_al_remove_direct_filter) (HL_CFFIPointer* source) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)source->ptr;
		alSourcei (id, AL_DIRECT_FILTER, AL_FILTER_NULL);
		#endif

	}


	void lime_al_remove_send (value source, int index) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)val_data (source);
		alSource3i (id, AL_AUXILIARY_SEND_FILTER, AL_EFFECTSLOT_NULL, index, 0);
		#endif

	}


	HL_PRIM void HL_NAME(hl_al_remove_send) (HL_CFFIPointer* source, int index) {

		#ifdef LIME_OPENALSOFT
		ALuint id = (ALuint)(uintptr_t)source->ptr;
		alSource3i (id, AL_AUXILIARY_SEND_FILTER, AL_EFFECTSLOT_NULL, index, 0);
		#endif

	}


	void lime_al_source_pause (value source) {

		ALuint id = (ALuint)(uintptr_t)val_data (source);
		alSourcePause (id);

	}


	HL_PRIM void HL_NAME(hl_al_source_pause) (HL_CFFIPointer* source) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;
		alSourcePause (id);

	}


	void lime_al_source_pausev (int n, value sources) {

		if (!val_is_null (sources)) {

			int size = val_array_size (sources);
			ALuint* data = new ALuint[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALuint)(uintptr_t)val_data (val_array_i (sources, i));

			}

			alSourcePausev (n, data);
			delete[] data;

		}

	}


	HL_PRIM void HL_NAME(hl_al_source_pausev) (int n, varray* sources) {

		if (sources) {

			int size = sources->size;
			HL_CFFIPointer** sourcesData = hl_aptr (sources, HL_CFFIPointer*);
			ALuint* data = new ALuint[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALuint)(uintptr_t)(*sourcesData++)->ptr;

			}

			alSourcePausev (n, data);
			delete[] data;

		}

	}


	void lime_al_source_play (value source) {

		ALuint id = (ALuint)(uintptr_t)val_data (source);
		alSourcePlay (id);

	}


	HL_PRIM void HL_NAME(hl_al_source_play) (HL_CFFIPointer* source) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;
		alSourcePlay (id);

	}


	void lime_al_source_playv (int n, value sources) {

		if (!val_is_null (sources)) {

			int size = val_array_size (sources);
			ALuint* data = new ALuint[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALuint)(uintptr_t)val_data (val_array_i (sources, i));

			}

			alSourcePlayv (n, data);
			delete[] data;

		}

	}


	HL_PRIM void HL_NAME(hl_al_source_playv) (int n, varray* sources) {

		if (sources) {

			int size = sources->size;
			HL_CFFIPointer** sourcesData = hl_aptr (sources, HL_CFFIPointer*);
			ALuint* data = new ALuint[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALuint)(uintptr_t)(*sourcesData++)->ptr;

			}

			alSourcePlayv (n, data);
			delete[] data;

		}

	}


	void lime_al_source_queue_buffers (value source, int nb, value buffers) {

		ALuint id = (ALuint)(uintptr_t)val_data (source);

		if (!val_is_null (buffers)) {

			int size = val_array_size (buffers);
			ALuint* data = new ALuint[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALuint)(uintptr_t)val_data (val_array_i (buffers, i));

			}

			alSourceQueueBuffers (id, nb, data);
			delete[] data;

		}

	}


	HL_PRIM void HL_NAME(hl_al_source_queue_buffers) (HL_CFFIPointer* source, int nb, varray* buffers) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;

		if (buffers) {

			int size = buffers->size;
			HL_CFFIPointer** buffersData = hl_aptr (buffers, HL_CFFIPointer*);
			ALuint* data = new ALuint[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALuint)(uintptr_t)(*buffersData++)->ptr;

			}

			alSourceQueueBuffers (id, nb, data);
			delete[] data;

		}

	}


	void lime_al_source_rewind (value source) {

		ALuint id = (ALuint)(uintptr_t)val_data (source);
		alSourceRewind (id);

	}


	HL_PRIM void HL_NAME(hl_al_source_rewind) (HL_CFFIPointer* source) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;
		alSourceRewind (id);

	}


	void lime_al_source_rewindv (int n, value sources) {

		if (!val_is_null (sources)) {

			int size = val_array_size (sources);
			ALuint* data = new ALuint[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALuint)(uintptr_t)val_data (val_array_i (sources, i));

			}

			alSourceRewindv (n, data);
			delete[] data;

		}

	}


	HL_PRIM void HL_NAME(hl_al_source_rewindv) (int n, varray* sources) {

		if (sources) {

			int size = sources->size;
			HL_CFFIPointer** sourcesData = hl_aptr (sources, HL_CFFIPointer*);
			ALuint* data = new ALuint[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALuint)(uintptr_t)(*sourcesData++)->ptr;

			}

			alSourceRewindv (n, data);
			delete[] data;

		}

	}


	void lime_al_source_stop (value source) {

		ALuint id = (ALuint)(uintptr_t)val_data (source);
		alSourceStop (id);

	}


	HL_PRIM void HL_NAME(hl_al_source_stop) (HL_CFFIPointer* source) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;
		alSourceStop (id);

	}


	void lime_al_source_stopv (int n, value sources) {

		if (!val_is_null (sources)) {

			int size = val_array_size (sources);
			ALuint* data = new ALuint[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALuint)(uintptr_t)val_data (val_array_i (sources, i));

			}

			alSourceStopv (n, data);
			delete[] data;

		}

	}


	HL_PRIM void HL_NAME(hl_al_source_stopv) (int n, varray* sources) {

		if (sources) {

			int size = sources->size;
			HL_CFFIPointer** sourcesData = hl_aptr (sources, HL_CFFIPointer*);
			ALuint* data = new ALuint[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALuint)(uintptr_t)(*sourcesData++)->ptr;

			}

			alSourceStopv (n, data);
			delete[] data;

		}

	}


	static int unqueue_al_buffers (ALuint source, int nb, ALuint* buffers) {

		// OpenAL unqueues nothing when it refuses, such as for buffers that have
		// not played, and leaves the array as it was
		lock_al_gc ();

		ALint queued = 0;
		alGetSourcei (source, AL_BUFFERS_QUEUED, &queued);

		alSourceUnqueueBuffers (source, nb, buffers);

		ALint remaining = queued;
		alGetSourcei (source, AL_BUFFERS_QUEUED, &remaining);

		int count = queued - remaining;
		count = count < 0 ? 0 : (count > nb ? nb : count);

		// A buffer whose handle was collected while it was queued waits to be
		// deleted, and is taken back before anything can delete it
		collect_finalized_al ();
		claim_unreleased_al_buffers (buffers, count);

		al_gc_mutex.Unlock ();
		return count;

	}


	value lime_al_source_unqueue_buffers (value source, int nb) {

		ALuint id = (ALuint)(uintptr_t)val_data (source);
		ALuint* buffers = new ALuint[nb];
		int count = unqueue_al_buffers (id, nb, buffers);

		value result = alloc_array (count);

		for (int i = 0; i < count; i++) {

			val_array_set_i (result, i, al_buffer_object (buffers[i]));

		}

		delete[] buffers;
		return result;

	}


	HL_PRIM varray* HL_NAME(hl_al_source_unqueue_buffers) (HL_CFFIPointer* source, int nb) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;
		ALuint* buffers = new ALuint[nb];
		int count = unqueue_al_buffers (id, nb, buffers);

		varray* result = hl_alloc_array (&hlt_dyn, count);
		HL_CFFIPointer** resultData = hl_aptr (result, HL_CFFIPointer*);

		for (int i = 0; i < count; i++) {

			*resultData++ = hl_al_buffer_object (buffers[i]);

		}

		delete[] buffers;
		return result;

	}


	void lime_al_source3f (value source, int param, float value1, float value2, float value3) {

		ALuint id = (ALuint)(uintptr_t)val_data (source);
		alSource3f (id, param, value1, value2, value3);

	}


	HL_PRIM void HL_NAME(hl_al_source3f) (HL_CFFIPointer* source, int param, float value1, float value2, float value3) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;
		alSource3f (id, param, value1, value2, value3);

	}


	void lime_al_source3i (value source, int param, value value1, int value2, int value3) {

		ALuint id = (ALuint)(uintptr_t)val_data (source);
		ALuint data1 = 0;

		#ifdef LIME_OPENALSOFT
		if (param == AL_AUXILIARY_SEND_FILTER) {

			data1 = (ALuint)(uintptr_t)val_data (value1);

		} else {

			data1 = val_int (value1);

		}
		#else
		data1 = val_int (value1);
		#endif

		alSource3i (id, param, data1, value2, value3);

	}


	HL_PRIM void HL_NAME(hl_al_source3i) (HL_CFFIPointer* source, int param, vdynamic* value1, int value2, int value3) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;
		ALuint data1 = 0;

		#ifdef LIME_OPENALSOFT
		if (param == AL_AUXILIARY_SEND_FILTER) {

			data1 = (ALuint)(uintptr_t)((HL_CFFIPointer*)value1)->ptr;

		} else {

			data1 = value1->v.i;

		}
		#else
		data1 = value1->v.i;
		#endif

		alSource3i (id, param, data1, value2, value3);

	}


	void lime_al_sourcef (value source, int param, float value) {

		ALuint id = (ALuint)(uintptr_t)val_data (source);
		alSourcef (id, param, value);

	}


	HL_PRIM void HL_NAME(hl_al_sourcef) (HL_CFFIPointer* source, int param, float value) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;
		alSourcef (id, param, value);

	}


	void lime_al_sourcefv (value source, int param, value values) {

		ALuint id = (ALuint)(uintptr_t)val_data (source);

		if (!val_is_null (values)) {

			int size = val_array_size (values);
			ALfloat *data = new ALfloat[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALfloat)val_float (val_array_i (values, i));

			}

			alSourcefv (id, param, data);
			delete[] data;

		}

	}


	HL_PRIM void HL_NAME(hl_al_sourcefv) (HL_CFFIPointer* source, int param, varray* values) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;

		if (values) {

			int size = values->size;
			alSourcefv (id, param, hl_aptr (values, float));

		}

	}


	void lime_al_sourcei (value source, int param, value val) {

		ALuint id = (ALuint)(uintptr_t)val_data (source);
		ALuint data = 0;

		if (!val_is_null (val)) {

			#ifdef LIME_OPENALSOFT
			if (param == AL_BUFFER || param == AL_DIRECT_FILTER) {

				data = (ALuint)(uintptr_t)val_data (val);

			} else {

				data = val_int (val);

			}
			#else
			if (param == AL_BUFFER) {

				data = (ALuint)(uintptr_t)val_data (val);

			} else {

				data = val_int (val);

			}
			#endif

		}

		alSourcei (id, param, data);

	}


	HL_PRIM void HL_NAME(hl_al_sourcei) (HL_CFFIPointer* source, int param, vdynamic* val) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;
		ALuint data = 0;

		if (val) {

			#ifdef LIME_OPENALSOFT
			if (param == AL_BUFFER || param == AL_DIRECT_FILTER) {

				data = (ALuint)(uintptr_t)((HL_CFFIPointer*)val)->ptr;

			} else {

				data = val->v.i;

			}
			#else
			if (param == AL_BUFFER) {

				data = (ALuint)(uintptr_t)((HL_CFFIPointer*)val)->ptr;

			} else {

				data = val->v.i;

			}
			#endif

		}

		alSourcei (id, param, data);

	}


	void lime_al_sourceiv (value source, int param, value values) {

		ALuint id = (ALuint)(uintptr_t)val_data (source);

		if (!val_is_null (values)) {

			int size = val_array_size (values);
			ALint* data = new ALint[size];

			for (int i = 0; i < size; ++i) {

				data[i] = (ALint)val_int (val_array_i (values, i));

			}

			alSourceiv (id, param, data);
			delete[] data;

		}

	}


	HL_PRIM void HL_NAME(hl_al_sourceiv) (HL_CFFIPointer* source, int param, varray* values) {

		ALuint id = (ALuint)(uintptr_t)source->ptr;

		if (values) {

			int size = values->size;
			alSourceiv (id, param, hl_aptr (values, int));

		}

	}


	void lime_al_speed_of_sound (float speed) {

		alSpeedOfSound (speed);

	}


	HL_PRIM void HL_NAME(hl_al_speed_of_sound) (float speed) {

		alSpeedOfSound (speed);

	}


	bool lime_alc_close_device (value device) {

		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		forget_alc_device (alcDevice);

		return alcCloseDevice (alcDevice);

	}


	HL_PRIM bool HL_NAME(hl_alc_close_device) (HL_CFFIPointer* device) {

		ALCdevice* alcDevice = (ALCdevice*)device->ptr;
		forget_alc_device (alcDevice);

		return alcCloseDevice (alcDevice);

	}


	value lime_alc_create_context (value device, value attrlist) {

		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		ALCint* list = NULL;

		if (!val_is_null (attrlist)) {

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

		return alc_object (alcContext);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_alc_create_context) (HL_CFFIPointer* device, varray* attrlist) {

		ALCdevice* alcDevice = (ALCdevice*)device->ptr;
		ALCcontext* alcContext = alcCreateContext (alcDevice, attrlist ? hl_aptr (attrlist, int) : NULL);

		return hl_alc_object (alcContext);

	}


	void lime_alc_destroy_context (value context) {

		destroy_alc_context ((ALCcontext*)val_data (context));

	}


	HL_PRIM void HL_NAME(hl_alc_destroy_context) (HL_CFFIPointer* context) {

		destroy_alc_context ((ALCcontext*)context->ptr);

	}


	value lime_alc_get_contexts_device (value context) {

		ALCcontext* alcContext = (ALCcontext*)val_data (context);
		return alc_object (alcGetContextsDevice (alcContext));

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_alc_get_contexts_device) (HL_CFFIPointer* context) {

		ALCcontext* alcContext = (ALCcontext*)context->ptr;
		return hl_alc_object (alcGetContextsDevice (alcContext));

	}


	value lime_alc_get_current_context () {

		return alc_object (alcGetCurrentContext ());

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_alc_get_current_context) () {

		return hl_alc_object (alcGetCurrentContext ());

	}


	int lime_alc_get_error (value device) {

		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		return alcGetError (alcDevice);

	}


	HL_PRIM int HL_NAME(hl_alc_get_error) (HL_CFFIPointer* device) {

		ALCdevice* alcDevice = (ALCdevice*)device->ptr;
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


	HL_PRIM varray* HL_NAME(hl_alc_get_integerv) (HL_CFFIPointer* device, int param, int size) {

		ALCdevice* alcDevice = (ALCdevice*)device->ptr;
		varray* result = hl_alloc_array (&hlt_i32, size);
		alcGetIntegerv (alcDevice, param, size, hl_aptr (result, int));
		return result;

	}


	value lime_alc_get_string (value device, int param) {

		ALCdevice* alcDevice = val_is_null (device) ? NULL : (ALCdevice*)val_data (device);
		const char* result = alcGetString (alcDevice, param);
		return result ? alloc_string (result) : alloc_null ();

	}


	HL_PRIM vbyte* HL_NAME(hl_alc_get_string) (HL_CFFIPointer* device, int param) {

		ALCdevice* alcDevice = device ? (ALCdevice*)device->ptr : NULL;
		const char* result = alcGetString (alcDevice, param);
		if (!result) return 0;
		int length = strlen (result);
		char* _result = (char*)malloc (length + 1);
		strcpy (_result, result);
		return (vbyte*)_result;

	}


	// Without a device, the device specifiers name every device, each ending in
	// a null character, and an empty name ends the list
	static int CountALCStrings (ALCdevice* device, int param, const char* result) {

		if (!result) return 0;
		if (device || (param != ALC_DEVICE_SPECIFIER && param != ALC_CAPTURE_DEVICE_SPECIFIER && param != ALC_ALL_DEVICES_SPECIFIER)) return 1;

		int count = 0;

		for (const char* name = result; *name; name += strlen (name) + 1) {

			count++;

		}

		return count;

	}


	value lime_alc_get_string_list (value device, int param) {

		ALCdevice* alcDevice = val_is_null (device) ? NULL : (ALCdevice*)val_data (device);
		const char* name = alcGetString (alcDevice, param);
		int count = CountALCStrings (alcDevice, param, name);

		value result = alloc_array (count);

		for (int i = 0; i < count; i++) {

			val_array_set_i (result, i, alloc_string (name));
			name += strlen (name) + 1;

		}

		return result;

	}


	HL_PRIM varray* HL_NAME(hl_alc_get_string_list) (HL_CFFIPointer* device, int param) {

		ALCdevice* alcDevice = device ? (ALCdevice*)device->ptr : NULL;
		const char* name = alcGetString (alcDevice, param);
		int count = CountALCStrings (alcDevice, param, name);

		varray* result = hl_alloc_array (&hlt_bytes, count);
		vbyte** resultData = hl_aptr (result, vbyte*);

		for (int i = 0; i < count; i++) {

			int length = strlen (name);
			*resultData++ = hl_copy_bytes ((const vbyte*)name, length + 1);
			name += length + 1;

		}

		return result;

	}


	bool lime_alc_make_context_current (value context) {

		ALCcontext* alcContext = (ALCcontext*)val_data (context);
		return alcMakeContextCurrent (alcContext);

	}


	HL_PRIM bool HL_NAME(hl_alc_make_context_current) (HL_CFFIPointer* context) {

		ALCcontext* alcContext = context ? (ALCcontext*)context->ptr : 0;
		return alcMakeContextCurrent (alcContext);

	}


	value lime_alc_open_device (HxString devicename) {

		ALCdevice* alcDevice = alcOpenDevice (devicename.__s);
		//TODO: Can we work out our own cleanup for openal?
		//atexit (lime_al_atexit);

		return alc_object (alcDevice);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_alc_open_device) (hl_vstring* devicename) {

		ALCdevice* alcDevice = alcOpenDevice (devicename ? (char*)hl_to_utf8 ((const uchar*)devicename->bytes) : 0);
		//TODO: Can we work out our own cleanup for openal?
		//atexit (lime_al_atexit);

		return hl_alc_object (alcDevice);

	}


	void lime_alc_pause_device (value device) {

		#ifdef LIME_OPENALSOFT
		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		alcDevicePauseSOFT (alcDevice);
		#endif

	}


	HL_PRIM void HL_NAME(hl_alc_pause_device) (HL_CFFIPointer* device) {

		#ifdef LIME_OPENALSOFT
		ALCdevice* alcDevice = (ALCdevice*)device->ptr;
		alcDevicePauseSOFT (alcDevice);
		#endif

	}


	void lime_alc_process_context (value context) {

		ALCcontext* alcContext = (ALCcontext*)val_data (context);
		alcProcessContext (alcContext);

	}


	HL_PRIM void HL_NAME(hl_alc_process_context) (HL_CFFIPointer* context) {

		ALCcontext* alcContext = (ALCcontext*)context->ptr;
		alcProcessContext (alcContext);

	}


	void lime_alc_resume_device (value device) {

		#ifdef LIME_OPENALSOFT
		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		alcDeviceResumeSOFT (alcDevice);
		#endif

	}


	HL_PRIM void HL_NAME(hl_alc_resume_device) (HL_CFFIPointer* device) {

		#ifdef LIME_OPENALSOFT
		ALCdevice* alcDevice = device ? (ALCdevice*)device->ptr : NULL;
		alcDeviceResumeSOFT (alcDevice);
		#endif

	}


	void lime_alc_suspend_context (value context) {

		ALCcontext* alcContext = (ALCcontext*)val_data (context);
		alcSuspendContext (alcContext);

	}


	HL_PRIM void HL_NAME(hl_alc_suspend_context) (HL_CFFIPointer* context) {

		ALCcontext* alcContext = context ? (ALCcontext*)context->ptr : NULL;
		alcSuspendContext (alcContext);

	}


	value lime_alc_capture_open_device (HxString devicename, int frequency, int format, int buffersize) {

		ALCdevice* alcDevice = alcCaptureOpenDevice (devicename.__s, frequency, format, buffersize);

		return alc_object (alcDevice);

	}


	HL_PRIM HL_CFFIPointer* HL_NAME(hl_alc_capture_open_device) (hl_vstring* devicename, int frequency, int format, int buffersize) {

		ALCdevice* alcDevice = alcCaptureOpenDevice (devicename ? (char*)hl_to_utf8 ((const uchar*)devicename->bytes) : 0, frequency, format, buffersize);

		return hl_alc_object (alcDevice);

	}


	bool lime_alc_capture_close_device (value device) {

		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		forget_alc_device (alcDevice);

		return alcCaptureCloseDevice (alcDevice);

	}


	HL_PRIM bool HL_NAME(hl_alc_capture_close_device) (HL_CFFIPointer* device) {

		ALCdevice* alcDevice = (ALCdevice*)device->ptr;
		forget_alc_device (alcDevice);

		return alcCaptureCloseDevice (alcDevice);

	}


	void lime_alc_capture_start (value device) {

		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		alcCaptureStart (alcDevice);

	}


	HL_PRIM void HL_NAME(hl_alc_capture_start) (HL_CFFIPointer* device) {

		ALCdevice* alcDevice = (ALCdevice*)device->ptr;
		alcCaptureStart (alcDevice);

	}


	void lime_alc_capture_stop (value device) {

		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		alcCaptureStop (alcDevice);

	}


	HL_PRIM void HL_NAME(hl_alc_capture_stop) (HL_CFFIPointer* device) {

		ALCdevice* alcDevice = (ALCdevice*)device->ptr;
		alcCaptureStop (alcDevice);

	}


	void lime_alc_capture_samples (value device, value buffer, int samples) {

		ALCdevice* alcDevice = (ALCdevice*)val_data (device);
		Bytes bytes (buffer);
		alcCaptureSamples (alcDevice, bytes.b, samples);

	}


	HL_PRIM void HL_NAME(hl_alc_capture_samples) (HL_CFFIPointer* device, Bytes* buffer, int samples) {

		ALCdevice* alcDevice = (ALCdevice*)device->ptr;
		alcCaptureSamples (alcDevice, buffer->b, samples);

	}




	DEFINE_PRIME3v (lime_al_auxf);
	DEFINE_PRIME3v (lime_al_auxfv);
	DEFINE_PRIME3v (lime_al_auxi);
	DEFINE_PRIME3v (lime_al_auxiv);
	DEFINE_PRIME5v (lime_al_buffer_data);
	DEFINE_PRIME5v (lime_al_buffer3f);
	DEFINE_PRIME5v (lime_al_buffer3i);
	DEFINE_PRIME3v (lime_al_bufferf);
	DEFINE_PRIME3v (lime_al_bufferfv);
	DEFINE_PRIME3v (lime_al_bufferi);
	DEFINE_PRIME3v (lime_al_bufferiv);
	DEFINE_PRIME0v (lime_al_cleanup);
	DEFINE_PRIME1v (lime_al_delete_auxiliary_effect_slot);
	DEFINE_PRIME1v (lime_al_delete_buffer);
	DEFINE_PRIME2v (lime_al_delete_buffers);
	DEFINE_PRIME1v (lime_al_delete_effect);
	DEFINE_PRIME1v (lime_al_delete_filter);
	DEFINE_PRIME1v (lime_al_delete_source);
	DEFINE_PRIME2v (lime_al_delete_sources);
	DEFINE_PRIME1v (lime_al_disable);
	DEFINE_PRIME1v (lime_al_distance_model);
	DEFINE_PRIME1v (lime_al_doppler_factor);
	DEFINE_PRIME1v (lime_al_doppler_velocity);
	DEFINE_PRIME3v (lime_al_effectf);
	DEFINE_PRIME3v (lime_al_effectfv);
	DEFINE_PRIME3v (lime_al_effecti);
	DEFINE_PRIME3v (lime_al_effectiv);
	DEFINE_PRIME1v (lime_al_enable);
	DEFINE_PRIME3v (lime_al_filteri);
	DEFINE_PRIME3v (lime_al_filterf);
	DEFINE_PRIME0 (lime_al_gen_aux);
	DEFINE_PRIME0 (lime_al_gen_buffer);
	DEFINE_PRIME1 (lime_al_gen_buffers);
	DEFINE_PRIME0 (lime_al_gen_effect);
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
	DEFINE_PRIME2 (lime_al_get_filteri);
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
	DEFINE_PRIME3 (lime_al_get_sourcedv_soft);
	DEFINE_PRIME2 (lime_al_get_sourcef);
	DEFINE_PRIME3 (lime_al_get_sourcefv);
	DEFINE_PRIME2 (lime_al_get_sourcei);
	DEFINE_PRIME3 (lime_al_get_sourceiv);
	DEFINE_PRIME1 (lime_al_get_string);
	DEFINE_PRIME1 (lime_al_is_aux);
	DEFINE_PRIME1 (lime_al_is_buffer);
	DEFINE_PRIME1 (lime_al_is_effect);
	DEFINE_PRIME1 (lime_al_is_enabled);
	DEFINE_PRIME1 (lime_al_is_extension_present);
	DEFINE_PRIME2 (lime_alc_is_extension_present);
	DEFINE_PRIME1 (lime_al_is_filter);
	DEFINE_PRIME1 (lime_al_is_source);
	DEFINE_PRIME4v (lime_al_listener3f);
	DEFINE_PRIME4v (lime_al_listener3i);
	DEFINE_PRIME2v (lime_al_listenerf);
	DEFINE_PRIME2v (lime_al_listenerfv);
	DEFINE_PRIME2v (lime_al_listeneri);
	DEFINE_PRIME2v (lime_al_listeneriv);
	DEFINE_PRIME1v (lime_al_remove_direct_filter);
	DEFINE_PRIME2v (lime_al_remove_send);
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
	DEFINE_PRIME2 (lime_alc_get_string_list);
	DEFINE_PRIME1 (lime_alc_make_context_current);
	DEFINE_PRIME1 (lime_alc_open_device);
	DEFINE_PRIME1v (lime_alc_pause_device);
	DEFINE_PRIME1v (lime_alc_process_context);
	DEFINE_PRIME1v (lime_alc_resume_device);
	DEFINE_PRIME1v (lime_alc_suspend_context);
	DEFINE_PRIME4 (lime_alc_capture_open_device);
	DEFINE_PRIME1 (lime_alc_capture_close_device);
	DEFINE_PRIME1v (lime_alc_capture_start);
	DEFINE_PRIME1v (lime_alc_capture_stop);
	DEFINE_PRIME3v (lime_alc_capture_samples);


	#define _TBYTES _OBJ (_I32 _BYTES)
	#define _TCFFIPOINTER _DYN
	#define _TDEVICE _ABSTRACT (alc_device)
	#define _TCONTEXT _ABSTRACT (alc_context)

	#define _TARRAYBUFFER _TBYTES
	#define _TARRAYBUFFERVIEW _OBJ (_I32 _TARRAYBUFFER _I32 _I32 _I32 _I32)

	DEFINE_HL_PRIM (_VOID, hl_al_auxf, _TCFFIPOINTER _I32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_al_auxfv, _TCFFIPOINTER _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_al_auxi, _TCFFIPOINTER _I32 _DYN);
	DEFINE_HL_PRIM (_VOID, hl_al_auxiv, _TCFFIPOINTER _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_al_buffer_data, _TCFFIPOINTER _I32 _TARRAYBUFFERVIEW _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_al_buffer3f, _TCFFIPOINTER _I32 _F32 _F32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_al_buffer3i, _TCFFIPOINTER _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_al_bufferf, _TCFFIPOINTER _I32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_al_bufferfv, _TCFFIPOINTER _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_al_bufferi, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_al_bufferiv, _TCFFIPOINTER _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_al_cleanup, _NO_ARG);
	DEFINE_HL_PRIM (_VOID, hl_al_delete_auxiliary_effect_slot, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_al_delete_buffer, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_al_delete_buffers, _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_al_delete_effect, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_al_delete_filter, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_al_delete_source, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_al_delete_sources, _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_al_disable, _I32);
	DEFINE_HL_PRIM (_VOID, hl_al_distance_model, _I32);
	DEFINE_HL_PRIM (_VOID, hl_al_doppler_factor, _F32);
	DEFINE_HL_PRIM (_VOID, hl_al_doppler_velocity, _F32);
	DEFINE_HL_PRIM (_VOID, hl_al_effectf, _TCFFIPOINTER _I32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_al_effectfv, _TCFFIPOINTER _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_al_effecti, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_al_effectiv, _TCFFIPOINTER _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_al_enable, _I32);
	DEFINE_HL_PRIM (_VOID, hl_al_filteri, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_al_filterf, _TCFFIPOINTER _I32 _F32);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_al_gen_aux, _NO_ARG);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_al_gen_buffer, _NO_ARG);
	DEFINE_HL_PRIM (_ARR, hl_al_gen_buffers, _I32);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_al_gen_effect, _NO_ARG);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_al_gen_filter, _NO_ARG);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_al_gen_source, _NO_ARG);
	DEFINE_HL_PRIM (_ARR, hl_al_gen_sources, _I32);
	DEFINE_HL_PRIM (_BOOL, hl_al_get_boolean, _I32);
	DEFINE_HL_PRIM (_ARR, hl_al_get_booleanv, _I32 _I32);
	DEFINE_HL_PRIM (_ARR, hl_al_get_buffer3f, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_ARR, hl_al_get_buffer3i, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_F32, hl_al_get_bufferf, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_ARR, hl_al_get_bufferfv, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_I32, hl_al_get_bufferi, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_ARR, hl_al_get_bufferiv, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_F64, hl_al_get_double, _I32);
	DEFINE_HL_PRIM (_ARR, hl_al_get_doublev, _I32 _I32);
	DEFINE_HL_PRIM (_I32, hl_al_get_enum_value, _STRING);
	DEFINE_HL_PRIM (_I32, hl_al_get_error, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_al_get_filteri, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_F32, hl_al_get_float, _I32);
	DEFINE_HL_PRIM (_ARR, hl_al_get_floatv, _I32 _I32);
	DEFINE_HL_PRIM (_I32, hl_al_get_integer, _I32);
	DEFINE_HL_PRIM (_ARR, hl_al_get_integerv, _I32 _I32);
	DEFINE_HL_PRIM (_ARR, hl_al_get_listener3f, _I32);
	DEFINE_HL_PRIM (_ARR, hl_al_get_listener3i, _I32);
	DEFINE_HL_PRIM (_F32, hl_al_get_listenerf, _I32);
	DEFINE_HL_PRIM (_ARR, hl_al_get_listenerfv, _I32 _I32);
	DEFINE_HL_PRIM (_I32, hl_al_get_listeneri, _I32);
	DEFINE_HL_PRIM (_ARR, hl_al_get_listeneriv, _I32 _I32);
	DEFINE_HL_PRIM (_F64, hl_al_get_proc_address, _STRING);
	DEFINE_HL_PRIM (_ARR, hl_al_get_source3f, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_ARR, hl_al_get_source3i, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_ARR, hl_al_get_sourcedv_soft, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_F32, hl_al_get_sourcef, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_ARR, hl_al_get_sourcefv, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_DYN, hl_al_get_sourcei, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_ARR, hl_al_get_sourceiv, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_BYTES, hl_al_get_string, _I32);
	DEFINE_HL_PRIM (_BOOL, hl_al_is_aux, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_al_is_buffer, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_al_is_effect, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_al_is_enabled, _I32);
	DEFINE_HL_PRIM (_BOOL, hl_al_is_extension_present, _STRING);
	DEFINE_HL_PRIM (_BOOL, hl_alc_is_extension_present, _TCFFIPOINTER _STRING);
	DEFINE_HL_PRIM (_BOOL, hl_al_is_filter, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_BOOL, hl_al_is_source, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_al_listener3f, _I32 _F32 _F32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_al_listener3i, _I32 _I32 _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_al_listenerf, _I32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_al_listenerfv, _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_al_listeneri, _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_al_listeneriv, _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_al_remove_direct_filter, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_al_remove_send, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_al_source_pause, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_al_source_pausev, _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_al_source_play, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_al_source_playv, _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_al_source_queue_buffers, _TCFFIPOINTER _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_al_source_rewind, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_al_source_rewindv, _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_al_source_stop, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_al_source_stopv, _I32 _ARR);
	DEFINE_HL_PRIM (_ARR, hl_al_source_unqueue_buffers, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_VOID, hl_al_source3f, _TCFFIPOINTER _I32 _F32 _F32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_al_source3i, _TCFFIPOINTER _I32 _DYN _I32 _I32);
	DEFINE_HL_PRIM (_VOID, hl_al_sourcef, _TCFFIPOINTER _I32 _F32);
	DEFINE_HL_PRIM (_VOID, hl_al_sourcefv, _TCFFIPOINTER _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_al_sourcei, _TCFFIPOINTER _I32 _DYN);
	DEFINE_HL_PRIM (_VOID, hl_al_sourceiv, _TCFFIPOINTER _I32 _ARR);
	DEFINE_HL_PRIM (_VOID, hl_al_speed_of_sound, _F32);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_alc_create_context, _TCFFIPOINTER _ARR);
	DEFINE_HL_PRIM (_BOOL, hl_alc_close_device, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_alc_destroy_context, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_alc_get_contexts_device, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_alc_get_current_context, _NO_ARG);
	DEFINE_HL_PRIM (_I32, hl_alc_get_error, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_ARR, hl_alc_get_integerv, _TCFFIPOINTER _I32 _I32);
	DEFINE_HL_PRIM (_BYTES, hl_alc_get_string, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_ARR, hl_alc_get_string_list, _TCFFIPOINTER _I32);
	DEFINE_HL_PRIM (_BOOL, hl_alc_make_context_current, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_alc_open_device, _STRING);
	DEFINE_HL_PRIM (_VOID, hl_alc_pause_device, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_alc_process_context, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_alc_resume_device, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_alc_suspend_context, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_TCFFIPOINTER, hl_alc_capture_open_device, _STRING _I32 _I32 _I32);
	DEFINE_HL_PRIM (_BOOL, hl_alc_capture_close_device, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_alc_capture_start, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_alc_capture_stop, _TCFFIPOINTER);
	DEFINE_HL_PRIM (_VOID, hl_alc_capture_samples, _TCFFIPOINTER _TBYTES _I32);


}


extern "C" int lime_openal_register_prims () {

	return 0;

}
