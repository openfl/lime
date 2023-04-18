package lime.media.openal;

#if (!lime_doc_gen || lime_openal)
import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFIPointer;
import lime.utils.ArrayBufferView;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
class AL
{
	public static inline var NONE:Int = 0;
	public static inline var FALSE:Int = 0;
	public static inline var TRUE:Int = 1;
	public static inline var SOURCE_RELATIVE:Int = 0x202;
	public static inline var CONE_INNER_ANGLE:Int = 0x1001;
	public static inline var CONE_OUTER_ANGLE:Int = 0x1002;
	public static inline var PITCH:Int = 0x1003;
	public static inline var POSITION:Int = 0x1004;
	public static inline var DIRECTION:Int = 0x1005;
	public static inline var VELOCITY:Int = 0x1006;
	public static inline var LOOPING:Int = 0x1007;
	public static inline var BUFFER:Int = 0x1009;
	public static inline var GAIN:Int = 0x100A;
	public static inline var MIN_GAIN:Int = 0x100D;
	public static inline var MAX_GAIN:Int = 0x100E;
	public static inline var ORIENTATION:Int = 0x100F;
	public static inline var SOURCE_STATE:Int = 0x1010;
	public static inline var INITIAL:Int = 0x1011;
	public static inline var PLAYING:Int = 0x1012;
	public static inline var PAUSED:Int = 0x1013;
	public static inline var STOPPED:Int = 0x1014;
	public static inline var BUFFERS_QUEUED:Int = 0x1015;
	public static inline var BUFFERS_PROCESSED:Int = 0x1016;
	public static inline var REFERENCE_DISTANCE:Int = 0x1020;
	public static inline var ROLLOFF_FACTOR:Int = 0x1021;
	public static inline var CONE_OUTER_GAIN:Int = 0x1022;
	public static inline var MAX_DISTANCE:Int = 0x1023;
	public static inline var SEC_OFFSET:Int = 0x1024;
	public static inline var SAMPLE_OFFSET:Int = 0x1025;
	public static inline var BYTE_OFFSET:Int = 0x1026;
	public static inline var SOURCE_TYPE:Int = 0x1027;
	public static inline var STATIC:Int = 0x1028;
	public static inline var STREAMING:Int = 0x1029;
	public static inline var UNDETERMINED:Int = 0x1030;
	public static inline var FORMAT_MONO8:Int = 0x1100;
	public static inline var FORMAT_MONO16:Int = 0x1101;
	public static inline var FORMAT_STEREO8:Int = 0x1102;
	public static inline var FORMAT_STEREO16:Int = 0x1103;
	public static inline var FREQUENCY:Int = 0x2001;
	public static inline var BITS:Int = 0x2002;
	public static inline var CHANNELS:Int = 0x2003;
	public static inline var SIZE:Int = 0x2004;
	public static inline var NO_ERROR:Int = 0;
	public static inline var INVALID_NAME:Int = 0xA001;
	public static inline var INVALID_ENUM:Int = 0xA002;
	public static inline var INVALID_VALUE:Int = 0xA003;
	public static inline var INVALID_OPERATION:Int = 0xA004;
	public static inline var OUT_OF_MEMORY:Int = 0xA005;
	public static inline var VENDOR:Int = 0xB001;
	public static inline var VERSION:Int = 0xB002;
	public static inline var RENDERER:Int = 0xB003;
	public static inline var EXTENSIONS:Int = 0xB004;
	public static inline var DOPPLER_FACTOR:Int = 0xC000;
	public static inline var SPEED_OF_SOUND:Int = 0xC003;
	public static inline var DOPPLER_VELOCITY:Int = 0xC001;
	public static inline var DISTANCE_MODEL:Int = 0xD000;
	public static inline var INVERSE_DISTANCE:Int = 0xD001;
	public static inline var INVERSE_DISTANCE_CLAMPED:Int = 0xD002;
	public static inline var LINEAR_DISTANCE:Int = 0xD003;
	public static inline var LINEAR_DISTANCE_CLAMPED:Int = 0xD004;
	public static inline var EXPONENT_DISTANCE:Int = 0xD005;
	public static inline var EXPONENT_DISTANCE_CLAMPED:Int = 0xD006;
	/* Listener properties. */
	public static inline var METERS_PER_UNIT:Int = 0x20004;
	/* Source properties. */
	public static inline var DIRECT_FILTER:Int = 0x20005;
	public static inline var AUXILIARY_SEND_FILTER:Int = 0x20006;
	public static inline var AIR_ABSORPTION_FACTOR:Int = 0x20007;
	public static inline var ROOM_ROLLOFF_FACTOR:Int = 0x20008;
	public static inline var CONE_OUTER_GAINHF:Int = 0x20009;
	public static inline var DIRECT_FILTER_GAINHF_AUTO:Int = 0x2000A;
	public static inline var AUXILIARY_SEND_FILTER_GAIN_AUTO:Int = 0x2000B;
	public static inline var AUXILIARY_SEND_FILTER_GAINHF_AUTO:Int = 0x2000C;
	/* Effect properties. */
	/* Reverb effect parameters */
	public static inline var REVERB_DENSITY:Int = 0x0001;
	public static inline var REVERB_DIFFUSION:Int = 0x0002;
	public static inline var REVERB_GAIN:Int = 0x0003;
	public static inline var REVERB_GAINHF:Int = 0x0004;
	public static inline var REVERB_DECAY_TIME:Int = 0x0005;
	public static inline var REVERB_DECAY_HFRATIO:Int = 0x0006;
	public static inline var REVERB_REFLECTIONS_GAIN:Int = 0x0007;
	public static inline var REVERB_REFLECTIONS_DELAY:Int = 0x0008;
	public static inline var REVERB_LATE_REVERB_GAIN:Int = 0x0009;
	public static inline var REVERB_LATE_REVERB_DELAY:Int = 0x000A;
	public static inline var REVERB_AIR_ABSORPTION_GAINHF:Int = 0x000B;
	public static inline var REVERB_ROOM_ROLLOFF_FACTOR:Int = 0x000C;
	public static inline var REVERB_DECAY_HFLIMIT:Int = 0x000D;
	/* EAX Reverb effect parameters */ // Windows only... ?
	public static inline var EAXREVERB_DENSITY:Int = 0x0001;
	public static inline var EAXREVERB_DIFFUSION:Int = 0x0002;
	public static inline var EAXREVERB_GAIN:Int = 0x0003;
	public static inline var EAXREVERB_GAINHF:Int = 0x0004;
	public static inline var EAXREVERB_GAINLF:Int = 0x0005;
	public static inline var EAXREVERB_DECAY_TIME:Int = 0x0006;
	public static inline var EAXREVERB_DECAY_HFRATIO:Int = 0x0007;
	public static inline var EAXREVERB_DECAY_LFRATIO:Int = 0x0008;
	public static inline var EAXREVERB_REFLECTIONS_GAIN:Int = 0x0009;
	public static inline var EAXREVERB_REFLECTIONS_DELAY:Int = 0x000A;
	public static inline var EAXREVERB_REFLECTIONS_PAN:Int = 0x000B;
	public static inline var EAXREVERB_LATE_REVERB_GAIN:Int = 0x000C;
	public static inline var EAXREVERB_LATE_REVERB_DELAY:Int = 0x000D;
	public static inline var EAXREVERB_LATE_REVERB_PAN:Int = 0x000E;
	public static inline var EAXREVERB_ECHO_TIME:Int = 0x000F;
	public static inline var EAXREVERB_ECHO_DEPTH:Int = 0x0010;
	public static inline var EAXREVERB_MODULATION_TIME:Int = 0x0011;
	public static inline var EAXREVERB_MODULATION_DEPTH:Int = 0x0012;
	public static inline var EAXREVERB_AIR_ABSORPTION_GAINHF:Int = 0x0013;
	public static inline var EAXREVERB_HFREFERENCE:Int = 0x0014;
	public static inline var EAXREVERB_LFREFERENCE:Int = 0x0015;
	public static inline var EAXREVERB_ROOM_ROLLOFF_FACTOR:Int = 0x0016;
	public static inline var EAXREVERB_DECAY_HFLIMIT:Int = 0x0017;
	/* Chorus effect parameters */
	public static inline var CHORUS_WAVEFORM:Int = 0x0001;
	public static inline var CHORUS_PHASE:Int = 0x0002;
	public static inline var CHORUS_RATE:Int = 0x0003;
	public static inline var CHORUS_DEPTH:Int = 0x0004;
	public static inline var CHORUS_FEEDBACK:Int = 0x0005;
	public static inline var CHORUS_DELAY:Int = 0x0006;
	/* Distortion effect parameters */
	public static inline var DISTORTION_EDGE:Int = 0x0001;
	public static inline var DISTORTION_GAIN:Int = 0x0002;
	public static inline var DISTORTION_LOWPASS_CUTOFF:Int = 0x0003;
	public static inline var DISTORTION_EQCENTER:Int = 0x0004;
	public static inline var DISTORTION_EQBANDWIDTH:Int = 0x0005;
	/* Echo effect parameters */
	public static inline var ECHO_DELAY:Int = 0x0001;
	public static inline var ECHO_LRDELAY:Int = 0x0002;
	public static inline var ECHO_DAMPING:Int = 0x0003;
	public static inline var ECHO_FEEDBACK:Int = 0x0004;
	public static inline var ECHO_SPREAD:Int = 0x0005;
	/* Flanger effect parameters */
	public static inline var FLANGER_WAVEFORM:Int = 0x0001;
	public static inline var FLANGER_PHASE:Int = 0x0002;
	public static inline var FLANGER_RATE:Int = 0x0003;
	public static inline var FLANGER_DEPTH:Int = 0x0004;
	public static inline var FLANGER_FEEDBACK:Int = 0x0005;
	public static inline var FLANGER_DELAY:Int = 0x0006;
	/* Frequency shifter effect parameters */
	public static inline var FREQUENCY_SHIFTER_FREQUENCY:Int = 0x0001;
	public static inline var FREQUENCY_SHIFTER_LEFT_DIRECTION:Int = 0x0002;
	public static inline var FREQUENCY_SHIFTER_RIGHT_DIRECTION:Int = 0x0003;
	/* Vocal morpher effect parameters */
	public static inline var VOCAL_MORPHER_PHONEMEA:Int = 0x0001;
	public static inline var VOCAL_MORPHER_PHONEMEA_COARSE_TUNING:Int = 0x0002;
	public static inline var VOCAL_MORPHER_PHONEMEB:Int = 0x0003;
	public static inline var VOCAL_MORPHER_PHONEMEB_COARSE_TUNING:Int = 0x0004;
	public static inline var VOCAL_MORPHER_WAVEFORM:Int = 0x0005;
	public static inline var VOCAL_MORPHER_RATE:Int = 0x0006;
	/* Pitchshifter effect parameters */
	public static inline var PITCH_SHIFTER_COARSE_TUNE:Int = 0x0001;
	public static inline var PITCH_SHIFTER_FINE_TUNE:Int = 0x0002;
	/* Ringmodulator effect parameters */
	public static inline var RING_MODULATOR_FREQUENCY:Int = 0x0001;
	public static inline var RING_MODULATOR_HIGHPASS_CUTOFF:Int = 0x0002;
	public static inline var RING_MODULATOR_WAVEFORM:Int = 0x0003;
	/* Autowah effect parameters */
	public static inline var AUTOWAH_ATTACK_TIME:Int = 0x0001;
	public static inline var AUTOWAH_RELEASE_TIME:Int = 0x0002;
	public static inline var AUTOWAH_RESONANCE:Int = 0x0003;
	public static inline var AUTOWAH_PEAK_GAIN:Int = 0x0004;
	/* Compressor effect parameters */
	public static inline var COMPRESSOR_ONOFF:Int = 0x0001;
	/* Equalizer effect parameters */
	public static inline var EQUALIZER_LOW_GAIN:Int = 0x0001;
	public static inline var EQUALIZER_LOW_CUTOFF:Int = 0x0002;
	public static inline var EQUALIZER_MID1_GAIN:Int = 0x0003;
	public static inline var EQUALIZER_MID1_CENTER:Int = 0x0004;
	public static inline var EQUALIZER_MID1_WIDTH:Int = 0x0005;
	public static inline var EQUALIZER_MID2_GAIN:Int = 0x0006;
	public static inline var EQUALIZER_MID2_CENTER:Int = 0x0007;
	public static inline var EQUALIZER_MID2_WIDTH:Int = 0x0008;
	public static inline var EQUALIZER_HIGH_GAIN:Int = 0x0009;
	public static inline var EQUALIZER_HIGH_CUTOFF:Int = 0x000A;
	/* Effect type */
	public static inline var EFFECT_FIRST_PARAMETER:Int = 0x0000;
	public static inline var EFFECT_LAST_PARAMETER:Int = 0x8000;
	public static inline var EFFECT_TYPE:Int = 0x8001;
	/* Effect types, used with the AL_EFFECT_TYPE property */
	public static inline var EFFECT_NULL:Int = 0x0000;
	public static inline var EFFECT_EAXREVERB:Int = 0x8000;
	public static inline var EFFECT_REVERB:Int = 0x0001;
	public static inline var EFFECT_CHORUS:Int = 0x0002;
	public static inline var EFFECT_DISTORTION:Int = 0x0003;
	public static inline var EFFECT_ECHO:Int = 0x0004;
	public static inline var EFFECT_FLANGER:Int = 0x0005;
	public static inline var EFFECT_FREQUENCY_SHIFTER:Int = 0x0006;
	public static inline var EFFECT_VOCAL_MORPHER:Int = 0x0007;
	public static inline var EFFECT_PITCH_SHIFTER:Int = 0x0008;
	public static inline var EFFECT_RING_MODULATOR:Int = 0x0009;
	public static inline var FFECT_AUTOWAH:Int = 0x000A;
	public static inline var EFFECT_COMPRESSOR:Int = 0x000B;
	public static inline var EFFECT_EQUALIZER:Int = 0x000C;
	/* Auxiliary Effect Slot properties. */
	public static inline var EFFECTSLOT_EFFECT:Int = 0x0001;
	public static inline var EFFECTSLOT_GAIN:Int = 0x0002;
	public static inline var EFFECTSLOT_AUXILIARY_SEND_AUTO:Int = 0x0003;
	/* NULL Auxiliary Slot ID to disable a source send. */
	// public static inline var EFFECTSLOT_NULL:Int = 0x0000;		//Use removeSend instead
	/* Filter properties. */
	/* Lowpass filter parameters */
	public static inline var LOWPASS_GAIN:Int = 0x0001; /*Not exactly a lowpass. Apparently it's a shelf*/
	public static inline var LOWPASS_GAINHF:Int = 0x0002;
	/* Highpass filter parameters */
	public static inline var HIGHPASS_GAIN:Int = 0x0001;
	public static inline var HIGHPASS_GAINLF:Int = 0x0002;
	/* Bandpass filter parameters */
	public static inline var BANDPASS_GAIN:Int = 0x0001;
	public static inline var BANDPASS_GAINLF:Int = 0x0002;
	public static inline var BANDPASS_GAINHF:Int = 0x0003;
	/* Filter type */
	public static inline var FILTER_FIRST_PARAMETER:Int = 0x0000; /*This is not even in the documentation*/
	public static inline var FILTER_LAST_PARAMETER:Int = 0x8000; /*This one neither*/
	public static inline var FILTER_TYPE:Int = 0x8001;
	/* Filter types, used with the AL_FILTER_TYPE property */
	public static inline var FILTER_NULL:Int = 0x0000;
	public static inline var FILTER_LOWPASS:Int = 0x0001;
	public static inline var FILTER_HIGHPASS:Int = 0x0002;
	public static inline var FILTER_BANDPASS:Int = 0x0003;

	public static function removeDirectFilter(source:ALSource)
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_remove_direct_filter(source);
		#end
	}

	public static function removeSend(source:ALSource, index:Int)
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_remove_send(source, index);
		#end
	}

	public static function auxf(aux:CFFIPointer, param:Int, value:Float):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_auxf(aux, param, value);
		#end
	}

	public static function auxfv(aux:CFFIPointer, param:Int, values:Array<Float>):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _values = new hl.NativeArray<hl.F32>(values.length);
		for (i in 0...values.length)
			_values[i] = values[i];
		var values = _values;
		#end
		NativeCFFI.lime_al_auxfv(aux, param, values);
		#end
	}

	public static function auxi(aux:CFFIPointer, param:Int, value:Dynamic):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_auxi(aux, param, value);
		#end
	}

	public static function auxiv(aux:CFFIPointer, param:Int, values:Array<Int>):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _values = new hl.NativeArray<Int>(values.length);
		for (i in 0...values.length)
			_values[i] = values[i];
		var values = _values;
		#end
		NativeCFFI.lime_al_auxiv(aux, param, values);
		#end
	}

	public static function bufferData(buffer:ALBuffer, format:Int, data:ArrayBufferView, size:Int, freq:Int):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_buffer_data(buffer, format, data, size, freq);
		#end
	}

	public static function buffer3f(buffer:ALBuffer, param:Int, value1:Float, value2:Float, value3:Float):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_buffer3f(buffer, param, value1, value2, value3);
		#end
	}

	public static function buffer3i(buffer:ALBuffer, param:Int, value1:Int, value2:Int, value3:Int):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_buffer3i(buffer, param, value1, value2, value3);
		#end
	}

	public static function bufferf(buffer:ALBuffer, param:Int, value:Float):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_bufferf(buffer, param, value);
		#end
	}

	public static function bufferfv(buffer:ALBuffer, param:Int, values:Array<Float>):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _values = new hl.NativeArray<hl.F32>(values.length);
		for (i in 0...values.length)
			_values[i] = values[i];
		var values = _values;
		#end
		NativeCFFI.lime_al_bufferfv(buffer, param, values);
		#end
	}

	public static function bufferi(buffer:ALBuffer, param:Int, value:Int):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_bufferi(buffer, param, value);
		#end
	}

	public static function bufferiv(buffer:ALBuffer, param:Int, values:Array<Int>):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _values = new hl.NativeArray<Int>(values.length);
		for (i in 0...values.length)
			_values[i] = values[i];
		var values = _values;
		#end
		NativeCFFI.lime_al_bufferiv(buffer, param, values);
		#end
	}

	public static function createAux():ALAuxiliaryEffectSlot
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_gen_aux();
		#else
		return null;
		#end
	}

	public static function createBuffer():ALBuffer
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_gen_buffer();
		#else
		return null;
		#end
	}

	public static function createEffect():ALEffect
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_gen_effect();
		#else
		return null;
		#end
	}

	public static function createFilter():ALFilter
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_gen_filter();
		#else
		return null;
		#end
	}

	public static function createSource():ALSource
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_gen_source();
		#else
		return null;
		#end
	}

	public static function deleteBuffer(buffer:ALBuffer):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_delete_buffer(buffer);
		#end
	}

	public static function deleteBuffers(buffers:Array<ALBuffer>):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _buffers = new hl.NativeArray<ALBuffer>(buffers.length);
		for (i in 0...buffers.length)
			_buffers[i] = buffers[i];
		var buffers = _buffers;
		#end
		NativeCFFI.lime_al_delete_buffers(buffers.length, buffers);
		#end
	}

	public static function deleteSource(source:ALSource):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_delete_source(source);
		#end
	}

	public static function deleteSources(sources:Array<ALSource>):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _sources = new hl.NativeArray<ALSource>(sources.length);
		for (i in 0...sources.length)
			_sources[i] = sources[i];
		var sources = _sources;
		#end
		NativeCFFI.lime_al_delete_sources(sources.length, sources);
		#end
	}

	public static function disable(capability:Int):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_disable(capability);
		#end
	}

	public static function distanceModel(distanceModel:Int):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_distance_model(distanceModel);
		#end
	}

	public static function dopplerFactor(value:Float):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_doppler_factor(value);
		#end
	}

	public static function dopplerVelocity(value:Float):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_doppler_velocity(value);
		#end
	}

	public static function effectf(effect:CFFIPointer, param:Int, value:Float):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_effectf(effect, param, value);
		#end
	}

	public static function effectfv(effect:CFFIPointer, param:Int, values:Array<Float>):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _values = new hl.NativeArray<hl.F32>(values.length);
		for (i in 0...values.length)
			_values[i] = values[i];
		var values = _values;
		#end
		NativeCFFI.lime_al_effectfv(effect, param, values);
		#end
	}

	public static function effecti(effect:CFFIPointer, param:Int, value:Int):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_effecti(effect, param, value);
		#end
	}

	public static function effectiv(effect:CFFIPointer, param:Int, values:Array<Int>):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _values = new hl.NativeArray<Int>(values.length);
		for (i in 0...values.length)
			_values[i] = values[i];
		var values = _values;
		#end
		NativeCFFI.lime_al_effectiv(effect, param, values);
		#end
	}

	public static function enable(capability:Int):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_enable(capability);
		#end
	}

	@:deprecated("genSource has been renamed to 'createSource' for consistency with OpenGL") public static function genSource():ALSource
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_gen_source();
		#else
		return null;
		#end
	}

	public static function genSources(n:Int):Array<ALSource>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_gen_sources(n);
		#if hl
		if (result == null) return [];
		var _result = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	@:deprecated("genBuffer has been renamed to 'createBuffer' for consistency with OpenGL") public static function genBuffer():ALBuffer
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_gen_buffer();
		#else
		return null;
		#end
	}

	public static function genBuffers(n:Int):Array<ALBuffer>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_gen_buffers(n);
		#if hl
		if (result == null) return [];
		var _result = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function getBoolean(param:Int):Bool
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_get_boolean(param);
		#else
		return false;
		#end
	}

	public static function getBooleanv(param:Int, count:Int = 1):Array<Bool>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_get_booleanv(param, 1);
		#if hl
		if (result == null) return [];
		var _result = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function getBuffer3f(buffer:ALBuffer, param:Int):Array<Float>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_get_buffer3f(buffer, param);
		#if hl
		if (result == null) return [];
		var _result:Array<Float> = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function getBuffer3i(buffer:ALBuffer, param:Int):Array<Int>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_get_buffer3i(buffer, param);
		#if hl
		if (result == null) return [];
		var _result = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function getBufferf(buffer:ALBuffer, param:Int):Float
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_get_bufferf(buffer, param);
		#else
		return 0;
		#end
	}

	public static function getBufferfv(buffer:ALBuffer, param:Int, count:Int = 1):Array<Float>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_get_bufferfv(buffer, param, count);
		#if hl
		if (result == null) return [];
		var _result:Array<Float> = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function getBufferi(buffer:ALBuffer, param:Int):Int
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_get_bufferi(buffer, param);
		#else
		return 0;
		#end
	}

	public static function getBufferiv(buffer:ALBuffer, param:Int, count:Int = 1):Array<Int>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_get_bufferiv(buffer, param, count);
		#if hl
		if (result == null) return [];
		var _result = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function getDouble(param:Int):Float
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_get_double(param);
		#else
		return 0;
		#end
	}

	public static function getDoublev(param:Int, count:Int = 1):Array<Float>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_get_doublev(param, count);
		#if hl
		if (result == null) return [];
		var _result:Array<Float> = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function getEnumValue(ename:String):Int
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_get_enum_value(ename);
		#else
		return 0;
		#end
	}

	public static function getError():Int
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_get_error();
		#else
		return 0;
		#end
	}

	public static function getErrorString():String
	{
		return switch (getError())
		{
			case INVALID_NAME: "INVALID_NAME: Invalid parameter name";
			case INVALID_ENUM: "INVALID_ENUM: Invalid enum value";
			case INVALID_VALUE: "INVALID_VALUE: Invalid parameter value";
			case INVALID_OPERATION: "INVALID_OPERATION: Illegal operation or call";
			case OUT_OF_MEMORY: "OUT_OF_MEMORY: OpenAL has run out of memory";
			default: "";
		}
	}

	public static function getFilteri(filter:ALFilter, param:Int):Int
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_get_filteri(filter, param);
		#else
		return 0;
		#end
	}

	public static function getFloat(param:Int):Float
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_get_float(param);
		#else
		return 0;
		#end
	}

	public static function getFloatv(param:Int, count:Int = 1):Array<Float>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_get_floatv(param, count);
		#if hl
		if (result == null) return [];
		var _result:Array<Float> = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function getInteger(param:Int):Int
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_get_integer(param);
		#else
		return 0;
		#end
	}

	public static function getIntegerv(param:Int, count:Int = 1):Array<Int>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_get_integerv(param, count);
		#if hl
		if (result == null) return [];
		var _result = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function getListener3f(param:Int):Array<Float>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_get_listener3f(param);
		#if hl
		if (result == null) return [];
		var _result:Array<Float> = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function getListener3i(param:Int):Array<Int>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_get_listener3i(param);
		#if hl
		if (result == null) return [];
		var _result = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function getListenerf(param:Int):Float
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_get_listenerf(param);
		#else
		return 0;
		#end
	}

	public static function getListenerfv(param:Int, count:Int = 1):Array<Float>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_get_listenerfv(param, count);
		#if hl
		if (result == null) return [];
		var _result:Array<Float> = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function getListeneri(param:Int):Int
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_get_listeneri(param);
		#else
		return 0;
		#end
	}

	public static function getListeneriv(param:Int, count:Int = 1):Array<Int>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_get_listeneriv(param, count);
		#if hl
		if (result == null) return [];
		var _result = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	@:dox(hide) @:noCompletion public static function getParameter(param:Int):Dynamic
	{
		// TODO, return any type value (similar to WebGL getParameter)
		return null;
	}

	public static function getProcAddress(fname:String):Dynamic
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_get_proc_address(fname);
		#else
		return null;
		#end
	}

	public static function getSource3f(source:ALSource, param:Int):Array<Float>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_get_source3f(source, param);
		#if hl
		if (result == null) return [];
		var _result:Array<Float> = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function getSourcef(source:ALSource, param:Int):Float
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_get_sourcef(source, param);
		#else
		return 0;
		#end
	}

	public static function getSource3i(source:ALSource, param:Int):Array<Int>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_get_source3i(source, param);
		#if hl
		if (result == null) return [];
		var _result = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function getSourcefv(source:ALSource, param:Int, count:Int = 1):Array<Float>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_get_sourcefv(source, param, count);
		#if hl
		if (result == null) return [];
		var _result:Array<Float> = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function getSourcei(source:ALSource, param:Int):Dynamic
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_get_sourcei(source, param);
		#else
		return 0;
		#end
	}

	public static function getSourceiv(source:ALSource, param:Int, count:Int = 1):Array<Int>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_get_sourceiv(source, param, count);
		#if hl
		if (result == null) return [];
		var _result = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function getString(param:Int):String
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_get_string(param);
		#if hl
		var result = @:privateAccess String.fromUTF8(result);
		#end
		return result;
		#else
		return null;
		#end
	}

	public static function isBuffer(buffer:ALBuffer):Bool
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_is_buffer(buffer);
		#else
		return false;
		#end
	}

	public static function isEnabled(capability:Int):Bool
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_is_enabled(capability);
		#else
		return false;
		#end
	}

	public static function isExtensionPresent(extname:String):Bool
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_is_extension_present(extname);
		#else
		return false;
		#end
	}

	public static function isAux(aux:ALAuxiliaryEffectSlot):Bool
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_is_aux(aux);
		#else
		return false;
		#end
	}

	public static function isEffect(effect:ALEffect):Bool
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_is_effect(effect);
		#else
		return false;
		#end
	}

	public static function isFilter(filter:ALFilter):Bool
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_is_filter(filter);
		#else
		return false;
		#end
	}

	public static function isSource(source:ALSource):Bool
	{
		#if (lime_cffi && lime_openal && !macro)
		return NativeCFFI.lime_al_is_source(source);
		#else
		return false;
		#end
	}

	public static function listener3f(param:Int, value1:Float, value2:Float, value3:Float):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_listener3f(param, value1, value2, value3);
		#end
	}

	public static function listener3i(param:Int, value1:Int, value2:Int, value3:Int):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_listener3i(param, value1, value2, value3);
		#end
	}

	public static function listenerf(param:Int, value:Float):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_listenerf(param, value);
		#end
	}

	public static function listenerfv(param:Int, values:Array<Float>):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _values = new hl.NativeArray<hl.F32>(values.length);
		for (i in 0...values.length)
			_values[i] = values[i];
		var values = _values;
		#end
		NativeCFFI.lime_al_listenerfv(param, values);
		#end
	}

	public static function listeneri(param:Int, value:Int):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_listeneri(param, value);
		#end
	}

	public static function listeneriv(param:Int, values:Array<Int>):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _values = new hl.NativeArray<Int>(values.length);
		for (i in 0...values.length)
			_values[i] = values[i];
		var values = _values;
		#end
		NativeCFFI.lime_al_listeneriv(param, values);
		#end
	}

	public static function source3f(source:ALSource, param:Int, value1:Float, value2:Float, value3:Float):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_source3f(source, param, value1, value2, value3);
		#end
	}

	public static function source3i(source:ALSource, param:Int, value1:Dynamic, value2:Int, value3:Int):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_source3i(source, param, value1, value2, value3);
		#end
	}

	public static function sourcef(source:ALSource, param:Int, value:Float):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_sourcef(source, param, value);
		#end
	}

	public static function sourcefv(source:ALSource, param:Int, values:Array<Float>):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _values = new hl.NativeArray<hl.F32>(values.length);
		for (i in 0...values.length)
			_values[i] = values[i];
		var values = _values;
		#end
		NativeCFFI.lime_al_sourcefv(source, param, values);
		#end
	}

	public static function sourcei(source:ALSource, param:Int, value:Dynamic):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_sourcei(source, param, value);
		#end
	}

	public static function filteri(filter:ALFilter, param:Int, value:Dynamic):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_filteri(filter, param, value);
		#end
	}

	public static function filterf(filter:ALFilter, param:Int, value:Float):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_filterf(filter, param, value);
		#end
	}

	public static function sourceiv(source:ALSource, param:Int, values:Array<Int>):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _values = new hl.NativeArray<Int>(values.length);
		for (i in 0...values.length)
			_values[i] = values[i];
		var values = _values;
		#end
		NativeCFFI.lime_al_sourceiv(source, param, values);
		#end
	}

	public static function sourcePlay(source:ALSource):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_source_play(source);
		#end
	}

	public static function sourcePlayv(sources:Array<ALSource>):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _sources = new hl.NativeArray<ALSource>(sources.length);
		for (i in 0...sources.length)
			_sources[i] = sources[i];
		var sources = _sources;
		#end
		NativeCFFI.lime_al_source_playv(sources.length, sources);
		#end
	}

	public static function sourceStop(source:ALSource):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_source_stop(source);
		#end
	}

	public static function sourceStopv(sources:Array<ALSource>):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _sources = new hl.NativeArray<ALSource>(sources.length);
		for (i in 0...sources.length)
			_sources[i] = sources[i];
		var sources = _sources;
		#end
		NativeCFFI.lime_al_source_stopv(sources.length, sources);
		#end
	}

	public static function sourceRewind(source:ALSource):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_source_rewind(source);
		#end
	}

	public static function sourceRewindv(sources:Array<ALSource>):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _sources = new hl.NativeArray<ALSource>(sources.length);
		for (i in 0...sources.length)
			_sources[i] = sources[i];
		var sources = _sources;
		#end
		NativeCFFI.lime_al_source_rewindv(sources.length, sources);
		#end
	}

	public static function sourcePause(source:ALSource):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_source_pause(source);
		#end
	}

	public static function sourcePausev(sources:Array<ALSource>):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _sources = new hl.NativeArray<ALSource>(sources.length);
		for (i in 0...sources.length)
			_sources[i] = sources[i];
		var sources = _sources;
		#end
		NativeCFFI.lime_al_source_pausev(sources.length, sources);
		#end
	}

	public static function sourceQueueBuffer(source:ALSource, buffer:ALBuffer):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var buffers:hl.NativeArray<ALBuffer> = new hl.NativeArray<ALBuffer>(1);
		buffers[0] = buffer;
		#else
		var buffers:Array<ALBuffer> = [buffer];
		#end
		NativeCFFI.lime_al_source_queue_buffers(source, 1, buffers);
		#end
	}

	public static function sourceQueueBuffers(source:ALSource, nb:Int, buffers:Array<ALBuffer>):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		#if hl
		var _buffers = new hl.NativeArray<ALBuffer>(buffers.length);
		for (i in 0...buffers.length)
			_buffers[i] = buffers[i];
		var buffers = _buffers;
		#end
		NativeCFFI.lime_al_source_queue_buffers(source, nb, buffers);
		#end
	}

	public static function sourceUnqueueBuffer(source:ALSource):ALBuffer
	{
		#if (lime_cffi && lime_openal && !macro)
		var res = NativeCFFI.lime_al_source_unqueue_buffers(source, 1);
		return res[0];
		#else
		return cast 0;
		#end
	}

	public static function sourceUnqueueBuffers(source:ALSource, nb:Int):Array<ALBuffer>
	{
		#if (lime_cffi && lime_openal && !macro)
		var result = NativeCFFI.lime_al_source_unqueue_buffers(source, nb);
		#if hl
		if (result == null) return [];
		var _result = [];
		for (i in 0...result.length)
			_result[i] = result[i];
		return _result;
		#else
		return result;
		#end
		#else
		return null;
		#end
	}

	public static function speedOfSound(value:Float):Void
	{
		#if (lime_cffi && lime_openal && !macro)
		NativeCFFI.lime_al_speed_of_sound(value);
		#end
	}
}
#end
