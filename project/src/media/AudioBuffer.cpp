#include <media/AudioBuffer.h>


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
		_buffer = 0;
		_value = 0;
		
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
		
		_buffer = 0;
		_value = audioBuffer;
		
	}
	
	
	AudioBuffer::AudioBuffer (HL_AudioBuffer* audioBuffer) {
		
		bitsPerSample = audioBuffer->bitsPerSample;
		channels = audioBuffer->channels;
		data = new ArrayBufferView (audioBuffer->data);
		sampleRate = audioBuffer->sampleRate;
		_buffer = audioBuffer;
		_value = 0;
		
	}
	
	
	AudioBuffer::~AudioBuffer () {
		
		delete data;
		
	}
	
	
	void* AudioBuffer::Value () {
		
		if (_buffer) {
			
			_buffer->bitsPerSample = bitsPerSample;
			_buffer->channels = channels;
			//data
			_buffer->sampleRate = sampleRate;
			return _buffer;
			
		} else {
			
			if (!init) {
				
				id_bitsPerSample = val_id ("bitsPerSample");
				id_channels = val_id ("channels");
				id_data = val_id ("data");
				id_sampleRate = val_id ("sampleRate");
				init = true;
				
			}
			
			if (val_is_null (_value)) {
				
				_value = alloc_empty_object ();
				
			}
			
			alloc_field (_value, id_bitsPerSample, alloc_int (bitsPerSample));
			alloc_field (_value, id_channels, alloc_int (channels));
			alloc_field (_value, id_data, data ? data->Value () : alloc_null ());
			alloc_field (_value, id_sampleRate, alloc_int (sampleRate));
			return _value;
			
		}
		
	}
	
	
}