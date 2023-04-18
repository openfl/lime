#include <media/AudioBuffer.h>


namespace lime {


	static int id_bitsPerSample;
	static int id_channels;
	static int id_data;
	static int id_sampleRate;
	static bool init = false;


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
			// data = new ArrayBufferView ();
			sampleRate = 0;

		}

		// _value = audioBuffer;

	}


	AudioBuffer::~AudioBuffer () {

		if (data) {

			delete data;

		}

	}


	value AudioBuffer::Value () {

		return Value (alloc_empty_object ());

	}


	value AudioBuffer::Value (value audioBuffer) {

		if (!init) {

			id_bitsPerSample = val_id ("bitsPerSample");
			id_channels = val_id ("channels");
			id_data = val_id ("data");
			id_sampleRate = val_id ("sampleRate");
			init = true;

		}

		alloc_field (audioBuffer, id_bitsPerSample, alloc_int (bitsPerSample));
		alloc_field (audioBuffer, id_channels, alloc_int (channels));
		alloc_field (audioBuffer, id_data, data ? data->Value (val_field (audioBuffer, id_data)) : alloc_null ());
		alloc_field (audioBuffer, id_sampleRate, alloc_int (sampleRate));
		return audioBuffer;

	}


}