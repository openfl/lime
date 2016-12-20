#include <audio/AudioBuffer.h>


namespace lime {
	
	
	static int id_bitsPerSample;
	static int id_channels;
	static int id_data;
	static int id_sampleRate;
	static bool init = false;
	
	
	AudioBuffer::AudioBuffer () {
		
		bitsPerSample = 0;
		channels = 0;
		data = new ArrayBufferView ();
		sampleRate = 0;
		mValue = 0;
		
	}
	
	
	AudioBuffer::AudioBuffer (value audioBuffer) {
		
		if (!init) {
			
			id_bitsPerSample = val_id ("bitsPerSample");
			id_channels = val_id ("channels");
			id_data = val_id ("data");
			id_sampleRate = val_id ("sampleRate");
			init = true;
			
		}
		
		if (!val_is_null (audioBuffer)) {
			
			bitsPerSample = val_int (val_field (audioBuffer, id_bitsPerSample));
			channels = val_int (val_field (audioBuffer, id_channels));
			data = new ArrayBufferView (val_field (audioBuffer, id_data));
			sampleRate = val_int (val_field (audioBuffer, id_sampleRate));
			
		} else {
			
			bitsPerSample = 0;
			channels = 0;
			data = new ArrayBufferView ();
			sampleRate = 0;
			
		}
		
		mValue = audioBuffer;
		
	}
	
	
	AudioBuffer::~AudioBuffer () {
		
		delete data;
		
	}
	
	
	value AudioBuffer::Value () {
		
		if (!init) {
			
			id_bitsPerSample = val_id ("bitsPerSample");
			id_channels = val_id ("channels");
			id_data = val_id ("data");
			id_sampleRate = val_id ("sampleRate");
			init = true;
			
		}
		
		if (val_is_null (mValue)) {
			
			mValue = alloc_empty_object ();
			
		}
		
		alloc_field (mValue, id_bitsPerSample, alloc_int (bitsPerSample));
		alloc_field (mValue, id_channels, alloc_int (channels));
		alloc_field (mValue, id_data, data ? data->Value () : alloc_null ());
		alloc_field (mValue, id_sampleRate, alloc_int (sampleRate));
		return mValue;
		
	}
	
	
}