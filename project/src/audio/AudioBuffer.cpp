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
		data = new Bytes ();
		sampleRate = 0;
		
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
		
		mValue = alloc_empty_object ();
		alloc_field (mValue, id_bitsPerSample, alloc_int (bitsPerSample));
		alloc_field (mValue, id_channels, alloc_int (channels));
		alloc_field (mValue, id_data, data ? data->Value () : alloc_null ());
		alloc_field (mValue, id_sampleRate, alloc_int (sampleRate));
		return mValue;
		
	}
	
	
}