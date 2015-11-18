package lime.audio.openal;


import lime.utils.ArrayBufferView;

#if ((haxe_ver >= 3.2) && cpp)
import cpp.Float32;
#else
typedef Float32 = Float;
#end

#if !macro
@:build(lime.system.CFFI.build())
#end


class AL {
	
	
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
	
	
	public static function bufferData (buffer:Int, format:Int, data:ArrayBufferView, size:Int, freq:Int):Void {
		
		#if ((cpp || neko) && lime_openal && !macro)
		lime_al_buffer_data (buffer, format, data.buffer, size, freq);
		#elseif (nodejs && lime_openal && !macro)
		lime_al_buffer_data (buffer, format, data, size, freq);
		#elseif (nodejs && lime_openal && !macro)
		lime_al_buffer_data (buffer, format, data, size, freq);
		#end
		
	}
	
	
	public static function buffer3f (buffer:Int, param:Int, value1:Float, value2:Float, value3:Float):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_buffer3f (buffer, param, value1, value2, value3);
		#end
		
	}
	
	
	public static function buffer3i (buffer:Int, param:Int, value1:Int, value2:Int, value3:Int):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_buffer3i (buffer, param, value1, value2, value3);
		#end
		
	}
	
	
	public static function bufferf (buffer:Int, param:Int, value:Float):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_bufferf (buffer, param, value);
		#end
		
	}
	
	
	public static function bufferfv (buffer:Int, param:Int, values:Array<Float>):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_bufferfv (buffer, param, values);
		#end
		
	}
	
	
	public static function bufferi (buffer:Int, param:Int, value:Int):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_bufferi (buffer, param, value);
		#end
		
	}
	
	
	public static function bufferiv (buffer:Int, param:Int, values:Array<Int>):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_bufferiv (buffer, param, values);
		#end
		
	}
	
	
	public static function deleteBuffer (buffer:Int):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_delete_buffer (buffer);
		#end
		
	}
	
	
	public static function deleteBuffers (buffers:Array<Int>):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_delete_buffers (buffers.length, buffers);
		#end
		
	}
	
	
	public static function deleteSource (source:Int):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_delete_source (source);
		#end
		
	}
	
	
	public static function deleteSources (sources:Array<Int>):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_delete_sources (sources.length, sources);
		#end
		
	}
	
	
	public static function disable (capability:Int):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_disable (capability);
		#end
		
	}
	
	
	public static function distanceModel (distanceModel:Int):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_distance_model (distanceModel);
		#end
		
	}
	
	
	public static function dopplerFactor (value:Float):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_doppler_factor (value);
		#end
		
	}
	
	
	public static function dopplerVelocity (value:Float):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_doppler_velocity (value);
		#end
		
	}
	
	
	public static function enable (capability:Int):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_enable (capability);
		#end
		
	}
	
	
	public static function genSource ():Int {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_gen_source ();
		#else
		return 0;
		#end
		
	}
	
	
	public static function genSources (n:Int):Array<Int> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_gen_sources (n);
		#else
		return null;
		#end
		
	}
	
	
	public static function genBuffer ():Int {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_gen_buffer ();
		#else
		return 0;
		#end
		
	}
	
	
	public static function genBuffers (n:Int):Array<Int> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_gen_buffers (n);
		#else
		return null;
		#end
		
	}
	
	
	public static function getBoolean (param:Int):Bool {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_boolean (param);
		#else
		return false;
		#end
		
	}
	
	
	public static function getBooleanv (param:Int, count:Int = 1):Array<Bool> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_booleanv (param, 1);
		#else
		return null;
		#end
		
	}
	
	
	public static function getBuffer3f (buffer:Int, param:Int):Array<Float> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_buffer3f (buffer, param);
		#else
		return null;
		#end
		
	}
	
	
	public static function getBuffer3i (buffer:Int, param:Int):Array<Int> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_buffer3i (buffer, param);
		#else
		return null;
		#end
		
	}
	
	
	public static function getBufferf (buffer:Int, param:Int):Float {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_bufferf (buffer, param);
		#else
		return 0;
		#end
		
	}
	
	
	public static function getBufferfv (buffer:Int, param:Int, count:Int = 1):Array<Float> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_bufferfv (buffer, param, count);
		#else
		return null;
		#end
		
	}
	
	
	public static function getBufferi (buffer:Int, param:Int):Int {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_bufferi (buffer, param);
		#else
		return 0;
		#end
		
	}
	
	
	public static function getBufferiv (buffer:Int, param:Int, count:Int = 1):Array<Int> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_bufferiv (buffer, param, count);
		#else
		return null;
		#end
		
	}
	
	
	public static function getDouble (param:Int):Float {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_double (param);
		#else
		return 0;
		#end
		
	}
	
	
	public static function getDoublev (param:Int, count:Int = 1):Array<Float> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_doublev (param, count);
		#else
		return null;
		#end
		
	}
	
	
	public static function getEnumValue (ename:String):Int {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_enum_value (ename);
		#else
		return 0;
		#end
		
	}
	
	
	public static function getError ():Int {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_error ();
		#else
		return 0;
		#end
		
	}
	
	
	public static function getErrorString ():String {
		
		return switch (getError ()) {
			
			case INVALID_NAME: "INVALID_NAME: Invalid parameter name";
			case INVALID_ENUM: "INVALID_ENUM: Invalid enum value";
			case INVALID_VALUE: "INVALID_VALUE: Invalid parameter value";
			case INVALID_OPERATION: "INVALID_OPERATION: Illegal operation or call";
			case OUT_OF_MEMORY: "OUT_OF_MEMORY: OpenAL has run out of memory";
			default: "";
			
		}
		
	}
	
	
	public static function getFloat (param:Int):Float {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_float (param);
		#else
		return 0;
		#end
		
	}
	
	
	public static function getFloatv (param:Int, count:Int = 1):Array<Float> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_floatv (param, count);
		#else
		return null;
		#end
		
	}
	
	
	public static function getInteger (param:Int):Int {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_integer (param);
		#else
		return 0;
		#end
		
	}
	
	
	public static function getIntegerv (param:Int, count:Int = 1):Array<Int> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_integerv (param, count);
		#else
		return null;
		#end
		
	}
	
	
	public static function getListener3f (param:Int):Array<Float> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_listener3f (param);
		#else
		return null;
		#end
		
	}
	
	
	public static function getListener3i (param:Int):Array<Int> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_listener3i (param);
		#else
		return null;
		#end
		
	}
	
	
	public static function getListenerf (param:Int):Float {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_listenerf (param);
		#else
		return 0;
		#end
		
	}
	
	
	public static function getListenerfv (param:Int, count:Int = 1):Array<Float> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_listenerfv (param, count);
		#else
		return null;
		#end
		
	}
	
	
	public static function getListeneri (param:Int):Int {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_listeneri (param);
		#else
		return 0;
		#end
		
	}
	
	
	public static function getListeneriv (param:Int, count:Int = 1):Array<Int> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_listeneriv (param, count);
		#else
		return null;
		#end
		
	}
	
	
	public static function getProcAddress (fname:String):Dynamic {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_proc_address (fname);
		#else
		return null;
		#end
		
	}
	
	
	public static function getSource3f (source:Int, param:Int):Array<Float> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_source3f (source, param);
		#else
		return null;
		#end
		
	}
	
	
	public static function getSourcef (source:Int, param:Int):Float {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_sourcef (source, param);
		#else
		return 0;
		#end
		
	}
	
	
	public static function getSource3i (source:Int, param:Int):Array<Int> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_source3i (source, param);
		#else
		return null;
		#end
		
	}
	
	
	public static function getSourcefv (source:Int, param:Int, count:Int = 1):Array<Float> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_sourcefv (source, param, count);
		#else
		return null;
		#end
		
	}
	
	
	public static function getSourcei (source:Int, param:Int):Int {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_sourcei (source, param);
		#else
		return 0;
		#end
		
	}
	
	
	public static function getSourceiv (source:Int, param:Int, count:Int = 1):Array<Int> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_sourceiv (source, param, count);
		#else
		return null;
		#end
		
	}
	
	
	public static function getString (param:Int):String {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_get_string (param);
		#else
		return null;
		#end
		
	}
	
	
	public static function isBuffer (buffer:Int):Bool {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_is_buffer (buffer);
		#else
		return false;
		#end
		
	}	
	
	
	public static function isEnabled (capability:Int):Bool {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_is_enabled (capability);
		#else
		return false;
		#end
		
	}
	
	
	public static function isExtensionPresent (extname:String):Bool {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_is_extension_present (extname);
		#else
		return false;
		#end
		
	}
	
	
	public static function isSource (source:Int):Bool {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_is_source (source);
		#else
		return false;
		#end
		
	}
	
	
	public static function listener3f (param:Int, value1:Float, value2:Float, value3:Float):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_listener3f (param, value1, value2, value3);
		#end
		
	}
	
	
	public static function listener3i (param:Int, value1:Int, value2:Int, value3:Int):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_listener3i (param, value1, value2, value3);
		#end
		
	}
	
	
	public static function listenerf (param:Int, value:Float):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_listenerf (param, value);
		#end
		
	}
	
	
	public static function listenerfv (param:Int, values:Array<Float>):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_listenerfv (param, values);
		#end
		
	}
	
	
	public static function listeneri (param:Int, value:Int):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_listeneri (param, value);
		#end
		
	}
	
	
	public static function listeneriv (param:Int, values:Array<Int>):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_listeneriv (param, values);
		#end
		
	}
	
	
	public static function source3f (source:Int, param:Int, value1:Float, value2:Float, value3:Float):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_source3f (source, param, value1, value2, value3);
		#end
		
	}
	
	
	public static function source3i (source:Int, param:Int, value1:Int, value2:Int, value3:Int):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_source3i (source, param, value1, value2, value3);
		#end
		
	}
	
	
	public static function sourcef (source:Int, param:Int, value:Float):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_sourcef (source, param, value);
		#end
		
	}
	
	
	public static function sourcefv (source:Int, param:Int, values:Array<Float>):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_sourcefv (source, param, values);
		#end
		
	}
	
	
	public static function sourcei (source:Int, param:Int, value:Int):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_sourcei (source, param, value);
		#end
		
	}
	
	
	public static function sourceiv (source:Int, param:Int, values:Array<Int>):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_sourceiv (source, param, values);
		#end
		
	}
	
	
	public static function sourcePlay (source:Int):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_source_play (source);
		#end
		
	}
	
	
	public static function sourcePlayv (sources:Array<Int>):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_source_playv (sources.length, sources);
		#end
		
	}
	
	
	public static function sourceStop (source:Int):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_source_stop (source);
		#end
		
	}
	
	
	public static function sourceStopv (sources:Array<Int>):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_source_stopv (sources.length, sources);
		#end
		
	}
	
	
	public static function sourceRewind (source:Int):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_source_rewind (source);
		#end
		
	}
	
	
	public static function sourceRewindv (sources:Array<Int>):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_source_rewindv (sources.length, sources);
		#end
		
	}
	
	
	public static function sourcePause (source:Int):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_source_pause (source);
		#end
		
	}
	
	
	public static function sourcePausev (sources:Array<Int>):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_source_pausev (sources.length, sources);
		#end
		
	}
	
	
	public static function sourceQueueBuffer (source:Int, buffer:Int):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_source_queue_buffers (source, 1, [ buffer ]);
		#end
		
	}
	
	
	public static function sourceQueueBuffers (source:Int, nb:Int, buffers:Array<Int>):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_source_queue_buffers (source, nb, buffers);
		#end
		
	}
	
	
	public static function sourceUnqueueBuffer (source:Int):Int {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		var res = lime_al_source_unqueue_buffers (source, 1);
		return res[0];
		#else
		return 0;
		#end
		
	}
	
	
	public static function sourceUnqueueBuffers (source:Int, nb:Int):Array<Int> {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		return lime_al_source_unqueue_buffers (source, nb);
		#else
		return null;
		#end
		
	}
	
	
	public static function speedOfSound (value:Float):Void {
		
		#if ((cpp || neko || nodejs) && lime_openal && !macro)
		lime_al_speed_of_sound (value);
		#end
		
	}
	
	
	#if ((cpp || neko || nodejs) && lime_openal && !macro)
	@:cffi private static function lime_al_buffer_data (buffer:Int, format:Int, data:Dynamic, size:Int, freq:Int):Void;
	@:cffi private static function lime_al_buffer3f (buffer:Int, param:Int, value1:Float32, value2:Float32, value3:Float32):Void;
	@:cffi private static function lime_al_buffer3i (buffer:Int, param:Int, value1:Int, value2:Int, value3:Int):Void;
	@:cffi private static function lime_al_bufferf (buffer:Int, param:Int, value:Float32):Void;
	@:cffi private static function lime_al_bufferfv (buffer:Int, param:Int, values:Dynamic):Void;
	@:cffi private static function lime_al_bufferi (buffer:Int, param:Int, value:Int):Void;
	@:cffi private static function lime_al_bufferiv (buffer:Int, param:Int, values:Dynamic):Void;
	@:cffi private static function lime_al_delete_buffer (buffer:Int):Void;
	@:cffi private static function lime_al_delete_buffers (n:Int, buffers:Dynamic):Void;
	@:cffi private static function lime_al_delete_source (source:Int):Void;
	@:cffi private static function lime_al_delete_sources (n:Int, sources:Dynamic):Void;
	@:cffi private static function lime_al_disable (capability:Int):Void;
	@:cffi private static function lime_al_distance_model (distanceModel:Int):Void;
	@:cffi private static function lime_al_doppler_factor (value:Float32):Void;
	@:cffi private static function lime_al_doppler_velocity (value:Float32):Void;
	@:cffi private static function lime_al_enable (capability:Int):Void;
	@:cffi private static function lime_al_gen_source ():Int;
	@:cffi private static function lime_al_gen_sources (n:Int):Dynamic;
	@:cffi private static function lime_al_get_boolean (param:Int):Bool;
	@:cffi private static function lime_al_get_booleanv (param:Int, count:Int):Dynamic;
	@:cffi private static function lime_al_gen_buffer ():Int;
	@:cffi private static function lime_al_gen_buffers (n:Int):Dynamic;
	@:cffi private static function lime_al_get_buffer3f (buffer:Int, param:Int):Dynamic;
	@:cffi private static function lime_al_get_buffer3i (buffer:Int, param:Int):Dynamic;
	@:cffi private static function lime_al_get_bufferf (buffer:Int, param:Int):Float32;
	@:cffi private static function lime_al_get_bufferfv (buffer:Int, param:Int, count:Int):Dynamic;
	@:cffi private static function lime_al_get_bufferi (buffer:Int, param:Int):Int;
	@:cffi private static function lime_al_get_bufferiv (buffer:Int, param:Int, count:Int):Dynamic;
	@:cffi private static function lime_al_get_double (param:Int):Float;
	@:cffi private static function lime_al_get_doublev (param:Int, count:Int):Dynamic;
	@:cffi private static function lime_al_get_enum_value (ename:String):Int;
	@:cffi private static function lime_al_get_error ():Int;
	@:cffi private static function lime_al_get_float (param:Int):Float32;
	@:cffi private static function lime_al_get_floatv (param:Int, count:Int):Dynamic;
	@:cffi private static function lime_al_get_integer (param:Int):Int;
	@:cffi private static function lime_al_get_integerv (param:Int, count:Int):Dynamic;
	@:cffi private static function lime_al_get_listener3f (param:Int):Dynamic;
	@:cffi private static function lime_al_get_listener3i (param:Int):Dynamic;
	@:cffi private static function lime_al_get_listenerf (param:Int):Float32;
	@:cffi private static function lime_al_get_listenerfv (param:Int, count:Int):Dynamic;
	@:cffi private static function lime_al_get_listeneri (param:Int):Int;
	@:cffi private static function lime_al_get_listeneriv (param:Int, count:Int):Dynamic;
	@:cffi private static function lime_al_get_proc_address (fname:String):Float;
	@:cffi private static function lime_al_get_source3f (source:Int, param:Int):Dynamic;
	@:cffi private static function lime_al_get_source3i (source:Int, param:Int):Dynamic;
	@:cffi private static function lime_al_get_sourcef (source:Int, param:Int):Float32;
	@:cffi private static function lime_al_get_sourcefv (source:Int, param:Int, count:Int):Dynamic;
	@:cffi private static function lime_al_get_sourcei (source:Int, param:Int):Int;
	@:cffi private static function lime_al_get_sourceiv (source:Int, param:Int, count:Int):Dynamic;
	@:cffi private static function lime_al_get_string (param:Int):Dynamic;
	@:cffi private static function lime_al_is_buffer (buffer:Int):Bool;
	@:cffi private static function lime_al_is_enabled (capability:Int):Bool;
	@:cffi private static function lime_al_is_extension_present (extname:String):Bool;
	@:cffi private static function lime_al_is_source (source:Int):Bool;
	@:cffi private static function lime_al_listener3f (param:Int, value1:Float32, value2:Float32, value3:Float32):Void;
	@:cffi private static function lime_al_listener3i (param:Int, value1:Int, value2:Int, value3:Int):Void;
	@:cffi private static function lime_al_listenerf (param:Int, value1:Float32):Void;
	@:cffi private static function lime_al_listenerfv (param:Int, values:Dynamic):Void;
	@:cffi private static function lime_al_listeneri (param:Int, value1:Int):Void;
	@:cffi private static function lime_al_listeneriv (param:Int, values:Dynamic):Void;
	@:cffi private static function lime_al_source_pause (source:Int):Void;
	@:cffi private static function lime_al_source_pausev (n:Int, sources:Dynamic):Void;
	@:cffi private static function lime_al_source_play (source:Int):Void;
	@:cffi private static function lime_al_source_playv (n:Int, sources:Dynamic):Void;
	@:cffi private static function lime_al_source_queue_buffers (source:Int, nb:Int, buffers:Dynamic):Void;
	@:cffi private static function lime_al_source_rewind (source:Int):Void;
	@:cffi private static function lime_al_source_rewindv (n:Int, sources:Dynamic):Void;
	@:cffi private static function lime_al_source_stop (source:Int):Void;
	@:cffi private static function lime_al_source_stopv (n:Int, sources:Dynamic):Void;
	@:cffi private static function lime_al_source_unqueue_buffers (source:Int, nb:Int):Dynamic;
	@:cffi private static function lime_al_source3f (source:Int, param:Int, value1:Float32, value2:Float32, value3:Float32):Void;
	@:cffi private static function lime_al_source3i (source:Int, param:Int, value1:Int, value2:Int, value3:Int):Void;
	@:cffi private static function lime_al_sourcef (source:Int, param:Int, value:Float32):Void;
	@:cffi private static function lime_al_sourcefv (source:Int, param:Int, values:Dynamic):Void;
	@:cffi private static function lime_al_sourcei (source:Int, param:Int, value:Int):Void;
	@:cffi private static function lime_al_sourceiv (source:Int, param:Int, values:Dynamic):Void;
	@:cffi private static function lime_al_speed_of_sound (speed:Float32):Void;
	#end
	
	
}