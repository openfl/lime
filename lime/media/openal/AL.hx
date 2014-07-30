package lime.media.openal;


import lime.system.System;
import lime.utils.Float32Array;


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
	
	
	
	public static function bufferData (buffer:Int, format:Int, data:Float32Array, size:Int, freq:Int):Void {
		
		lime_al_buffer_data (buffer, format, data.getByteBuffer (), size, freq);
		
	}
	
	
	public static function buffer3f (buffer:Int, param:Int, value1:Float, value2:Float, value3:Float):Void {
		
		lime_al_buffer3f (buffer, param, value1, value2, value3);
		
	}
	
	
	public static function buffer3i (buffer:Int, param:Int, value1:Int, value2:Int, value3:Int):Void {
		
		lime_al_buffer3i (buffer, param, value1, value2, value3);
		
	}
	
	
	public static function bufferf (buffer:Int, param:Int, value:Float):Void {
		
		lime_al_bufferf (buffer, param, value);
		
	}
	
	
	public static function bufferfv (buffer:Int, param:Int, values:Array<Float>):Void {
		
		lime_al_bufferfv (buffer, param, values);
		
	}
	
	
	public static function bufferi (buffer:Int, param:Int, value:Int):Void {
		
		lime_al_bufferi (buffer, param, value);
		
	}
	
	
	public static function bufferiv (buffer:Int, param:Int, values:Array<Int>):Void {
		
		lime_al_bufferiv (buffer, param, values);
		
	}
	
	
	public static function deleteBuffer (buffer:Int):Void {
		
		lime_al_delete_buffer (buffer);
		
	}
	
	
	public static function deleteBuffers (buffers:Array<Int>):Void {
		
		lime_al_delete_buffers (buffers.length, buffers);
		
	}
	
	
	public static function deleteSource (source:Int):Void {
		
		lime_al_delete_source (source);
		
	}
	
	
	public static function deleteSources (sources:Array<Int>):Void {
		
		lime_al_delete_sources (sources.length, sources);
		
	}
	
	
	public static function disable (capability:Int):Void {
		
		lime_al_disable (capability);
		
	}
	
	
	public static function distanceModel (distanceModel:Int):Void {
		
		lime_al_distance_model (distanceModel);
		
	}
	
	
	public static function dopplerFactor (value:Float):Void {
		
		lime_al_doppler_factor (value);
		
	}
	
	
	public static function dopplerVelocity (value:Float):Void {
		
		lime_al_doppler_velocity (value);
		
	}
	
	
	public static function enable (capability:Int):Void {
		
		lime_al_enable (capability);
		
	}
	
	
	public static function genSource ():Int {
		
		return lime_al_gen_source ();
		
	}
	
	
	public static function genSources (n:Int):Array<Int> {
		
		return lime_al_gen_sources (n);
		
	}
	
	
	public static function genBuffer ():Int {
		
		return lime_al_gen_buffer ();
		
	}
	
	
	public static function genBuffers (n:Int):Array<Int> {
		
		return lime_al_gen_buffers (n);
		
	}
	
	
	public static function getBoolean (param:Int):Bool {
		
		return lime_al_get_boolean (param);
		
	}
	
	
	public static function getBooleanv (param:Int, count:Int = 1 ):Array<Bool> {
		
		return lime_al_get_booleanv (param, count);
		
	}
	
	
	public static function getBuffer3f (buffer:Int, param:Int):Array<Float> {
		
		return lime_al_get_buffer3f (buffer, param);
		
	}
	
	
	public static function getBuffer3i (buffer:Int, param:Int):Array<Int> {
		
		return lime_al_get_buffer3i (buffer, param);
		
	}
	
	
	public static function getBufferf (buffer:Int, param:Int):Float {
		
		return lime_al_get_bufferf (buffer, param);
		
	}
	
	
	public static function getBufferfv (buffer:Int, param:Int, count:Int = 1):Array<Float> {
		
		return lime_al_get_bufferfv (buffer, param, count);
		
	}
	
	
	public static function getBufferi (buffer:Int, param:Int):Int {
		
		return lime_al_get_bufferi (buffer, param);
		
	}
	
	
	public static function getBufferiv (buffer:Int, param:Int, count:Int = 1):Array<Int> {
		
		return lime_al_get_bufferiv (buffer, param, count);
		
	}
	
	
	public static function getInteger (param:Int):Int {
		
		return lime_al_get_integer (param);
		
	}
	
	
	public static function getIntegerv (param:Int, count:Int = 1):Array<Int> {
		
		return lime_al_get_integerv (param, count);
		
	}
	
	
	public static function getFloat (param:Int):Float {
		
		return lime_al_get_float (param);
		
	}
	
	
	public static function getFloatv (param:Int, count:Int = 1):Array<Float> {
		
		return lime_al_get_floatv (param, count);
		
	}
	
	
	public static function getDouble (param:Int):Float {
		
		return lime_al_get_double (param);
		
	}
	
	
	public static function getDoublev (param:Int, count:Int = 1 ):Array<Float> {
		
		return lime_al_get_doublev (param, count);
		
	}
	
	
	public static function getEnumValue (ename:String):Int {
		
		return lime_al_get_enum_value (ename);
		
	}
	
	
	public static function getError ():Int {
		
		return lime_al_get_error ();
		
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
	
	
	public static function getListener3f (param:Int):Array<Float> {
		
		return lime_al_get_listener3f (param);
		
	}
	
	
	public static function getListener3i (param:Int):Array<Int> {
		
		return lime_al_get_listener3i (param);
		
	}
	
	
	public static function getListenerf (param:Int):Float {
		
		return lime_al_get_listenerf (param);
		
	}
	
	
	public static function getListenerfv (param:Int, count:Int = 1):Array<Float> {
		
		return lime_al_get_listenerfv (param, count);
		
	}
	
	
	public static function getListeneri (param:Int):Int {
		
		return lime_al_get_listeneri (param);
		
	}
	
	
	public static function getListeneriv (param:Int, count:Int = 1):Array<Int> {
		
		return lime_al_get_listeneriv (param, count);
		
	}
	
	
	public static function getProcAddress (fname:String):Dynamic {
		
		return null;
		
	}
	
	
	public static function getSource3f (source:Int, param:Int):Array<Float> {
		
		return lime_al_get_source3f (source, param);
		
	}
	
	
	public static function getSourcef (source:Int, param:Int):Float {
		
		return lime_al_get_sourcef (source, param);
		
	}
	
	
	public static function getSource3i (source:Int, param:Int):Array<Int> {
		
		return lime_al_get_source3i (source, param);
		
	}
	
	
	public static function getSourcefv (source:Int, param:Int):Array<Float> {
		
		return lime_al_get_sourcefv (source, param);
		
	}
	
	
	public static function getSourcei (source:Int, param:Int):Int {
		
		return lime_al_get_sourcei (source, param);
		
	}
	
	
	public static function getSourceiv (source:Int, param:Int, count:Int = 1):Array<Int> {
		
		return lime_al_get_sourceiv (source, param, count);
		
	}
	
	
	public static function getString (param:Int):String {
		
		return lime_al_get_string (param);
		
	}
	
	
	public static function isBuffer (buffer:Int):Bool {
		
		return lime_al_is_buffer (buffer);
		
	}	
	
	
	public static function isEnabled (capability:Int):Bool {
		
		return lime_al_is_enabled (capability);
		
	}
	
	
	public static function isExtensionPresent (extname:String):Bool {
		
		return lime_al_is_extension_present (extname);
		
	}
	
	
	public static function isSource (source:Int):Bool {
		
		return lime_al_is_source (source);
		
	}
	
	
	public static function listener3f (param:Int, value1:Float, value2:Float, value3:Float):Void {
		
		lime_al_listener3f (param, value1, value2, value3);
		
	}
	
	
	public static function listener3i (param:Int, value1:Int, value2:Int, value3:Int):Void {
		
		lime_al_listener3i (param, value1, value2, value3);
		
	}
	
	
	public static function listenerf (param:Int, value:Float):Void {
		
		lime_al_listenerf (param, value);
		
	}
	
	
	public static function listenerfv (param:Int, values:Array<Float>):Void {
		
		lime_al_listenerfv (param, values);
		
	}
	
	
	public static function listeneri (param:Int, value:Int):Void {
		
		lime_al_listeneri (param, value);
		
	}
	
	
	public static function listeneriv (param:Int, values:Array<Int>):Void {
		
		lime_al_listeneriv (param, values);
		
	}
	
	
	public static function source3f (source:Int, param:Int, value1:Float, value2:Float, value3:Float):Void {
		
		lime_al_source3f (source, param, value1, value2, value3);
		
	}
	
	
	public static function source3i (source:Int, param:Int, value1:Int, value2:Int, value3:Int):Void {
		
		lime_al_source3i (source, param, value1, value2, value3);
		
	}
	
	
	public static function sourcef (source:Int, param:Int, value:Float):Void {
		
		lime_al_sourcef (source, param, value);
		
	}
	
	
	public static function sourcefv (source:Int, param:Int, values:Array<Float>):Void {
		
		lime_al_sourcefv (source, param, values);
		
	}
	
	
	public static function sourcei (source:Int, param:Int, value:Int):Void {
		
		lime_al_sourcei (source, param, value);
		
	}
	
	
	public static function sourceiv (source:Int, param:Int, values:Array<Int>):Void {
		
		lime_al_sourceiv (source, param, values);
		
	}
	
	
	public static function sourcePlay (source:Int):Void {
		
		lime_al_source_play (source);
		
	}
	
	
	public static function sourcePlayv (sources:Array<Int>):Void {
		
		lime_al_source_playv (sources.length, sources);
		
	}
	
	
	public static function sourceStop (source:Int):Void {
		
		lime_al_source_stop (source);
		
	}
	
	
	public static function sourceStopv (sources:Array<Int>):Void {
		
		lime_al_source_stopv (sources.length, sources);
		
	}
	
	
	public static function sourceRewind (source:Int):Void {
		
		lime_al_source_rewind (source);
		
	}
	
	
	public static function sourceRewindv (sources:Array<Int>):Void {
		
		lime_al_source_rewindv (sources.length, sources);
		
	}
	
	
	public static function sourcePause (source:Int):Void {
		
		lime_al_source_pause (source);
		
	}
	
	
	public static function sourcePausev (sources:Array<Int>):Void {
		
		lime_al_source_pausev (sources.length, sources);
		
	}
	
	
	public static function sourceQueueBuffer (source:Int, buffer:Int):Void {
		
		lime_al_source_queue_buffers (source, 1, [ buffer ]);
		
	}
	
	
	public static function sourceQueueBuffers (source:Int, nb:Int, buffers:Array<Int>):Void {
		
		lime_al_source_queue_buffers (source, nb, buffers);
		
	}
	
	
	public static function sourceUnqueueBuffer (source:Int):Int {
		
		var res = lime_al_source_unqueue_buffers (source, 1);
		return res[0];
		
	}
	
	
	public static function sourceUnqueueBuffers (source:Int, nb:Int):Array<Int> {
		
		return lime_al_source_unqueue_buffers (source, nb);
		
	}
	
	
	public static function speedOfSound (value:Float):Void {
		
		lime_al_speed_of_sound (value);
		
	}
	
	
	private static var lime_al_buffer_data = System.load ("lime", "lime_al_buffer_data", 5);
	private static var lime_al_bufferf = System.load ("lime", "lime_al_bufferf", 3);
	private static var lime_al_buffer3f = System.load ("lime", "lime_al_buffer3f", 5);
	private static var lime_al_bufferfv = System.load ("lime", "lime_al_bufferfv", 3);
	private static var lime_al_bufferi = System.load ("lime", "lime_al_bufferi", 3);
	private static var lime_al_buffer3i = System.load ("lime", "lime_al_buffer3i", 5);
	private static var lime_al_bufferiv = System.load ("lime", "lime_al_bufferiv", 3);
	private static var lime_al_delete_buffer = System.load ("lime", "lime_al_delete_buffer", 1);
	private static var lime_al_delete_buffers = System.load ("lime", "lime_al_delete_buffers", 2);
	private static var lime_al_delete_source = System.load ("lime", "lime_al_delete_source", 1);
	private static var lime_al_delete_sources = System.load ("lime", "lime_al_delete_sources", 2);
	private static var lime_al_disable = System.load ("lime", "lime_al_disable", 1);
	private static var lime_al_distance_model = System.load ("lime", "lime_al_distance_model", 1);
	private static var lime_al_doppler_factor = System.load ("lime", "lime_al_doppler_factor", 1);
	private static var lime_al_doppler_velocity = System.load ("lime", "lime_al_doppler_velocity", 1);
	private static var lime_al_enable = System.load ("lime", "lime_al_enable", 1);
	private static var lime_al_gen_source = System.load ("lime", "lime_al_gen_source", 0);
	private static var lime_al_gen_sources = System.load ("lime", "lime_al_gen_sources", 1);
	private static var lime_al_gen_buffer = System.load ("lime", "lime_al_gen_buffer", 0);
	private static var lime_al_gen_buffers = System.load ("lime", "lime_al_gen_buffers", 1);
	private static var lime_al_get_buffer3f = System.load ("lime", "lime_al_get_buffer3f", 2);
	private static var lime_al_get_buffer3i = System.load ("lime", "lime_al_get_buffer3i", 2);
	private static var lime_al_get_bufferf = System.load ("lime", "lime_al_get_bufferf", 2);
	private static var lime_al_get_bufferfv = System.load ("lime", "lime_al_get_bufferfv", 3);
	private static var lime_al_get_bufferi = System.load ("lime", "lime_al_get_bufferi", 2);
	private static var lime_al_get_bufferiv = System.load ("lime", "lime_al_get_bufferiv", 3);
	private static var lime_al_get_boolean = System.load ("lime", "lime_al_get_boolean", 1);
	private static var lime_al_get_booleanv = System.load ("lime", "lime_al_get_booleanv", 2);
	private static var lime_al_get_double = System.load ("lime", "lime_al_get_double", 1);
	private static var lime_al_get_doublev = System.load ("lime", "lime_al_get_doublev", 2);
	private static var lime_al_get_enum_value = System.load ("lime", "lime_al_get_enum_value", 1);
	private static var lime_al_get_error = System.load ("lime", "lime_al_get_error", 0);
	private static var lime_al_get_float = System.load ("lime", "lime_al_get_float", 1);
	private static var lime_al_get_floatv = System.load ("lime", "lime_al_get_floatv", 2);
	private static var lime_al_get_integer = System.load ("lime", "lime_al_get_integer", 1);
	private static var lime_al_get_integerv = System.load ("lime", "lime_al_get_integerv", 2);
	private static var lime_al_get_listenerf = System.load ("lime", "lime_al_get_listenerf", 1);
	private static var lime_al_get_listener3f = System.load ("lime", "lime_al_get_listener3f", 1);
	private static var lime_al_get_listenerfv = System.load ("lime", "lime_al_get_listenerfv", 2);
	private static var lime_al_get_listeneri = System.load ("lime", "lime_al_get_listeneri", 1);
	private static var lime_al_get_listener3i = System.load ("lime", "lime_al_get_listener3i", 1);
	private static var lime_al_get_listeneriv = System.load ("lime", "lime_al_get_listeneriv", 2);
	private static var lime_al_get_proc_address = System.load ("lime", "lime_al_get_proc_address", 1);
	private static var lime_al_get_source3f = System.load ("lime", "lime_al_get_source3f", 2);
	private static var lime_al_get_source3i = System.load ("lime", "lime_al_get_source3i", 2);
	private static var lime_al_get_sourcef = System.load ("lime", "lime_al_get_sourcef", 2);
	private static var lime_al_get_sourcefv = System.load ("lime", "lime_al_get_sourcefv", 2);
	private static var lime_al_get_sourcei = System.load ("lime", "lime_al_get_sourcei", 2);
	private static var lime_al_get_sourceiv = System.load ("lime", "lime_al_get_sourceiv", 3);
	private static var lime_al_get_string = System.load ("lime", "lime_al_get_string", 1);
	private static var lime_al_is_buffer = System.load ("lime", "lime_al_is_buffer", 1);
	private static var lime_al_is_enabled = System.load ("lime", "lime_al_is_enabled", 1);
	private static var lime_al_is_extension_present = System.load ("lime", "lime_al_is_extension_present", 1);
	private static var lime_al_is_source = System.load ("lime", "lime_al_is_source", 1);
	private static var lime_al_listener3f = System.load ("lime", "lime_al_listener3f", 4);
	private static var lime_al_listener3i = System.load ("lime", "lime_al_listener3i", 4);
	private static var lime_al_listenerf = System.load ("lime", "lime_al_listenerf", 2);
	private static var lime_al_listenerfv = System.load ("lime", "lime_al_listenerfv", 2);
	private static var lime_al_listeneri = System.load ("lime", "lime_al_listeneri", 2);
	private static var lime_al_listeneriv = System.load ("lime", "lime_al_listeneriv", 2);
	private static var lime_al_source_play = System.load ("lime", "lime_al_source_play", 1);
	private static var lime_al_source_playv = System.load ("lime", "lime_al_source_playv", 2);
	private static var lime_al_source_stop = System.load ("lime", "lime_al_source_stop", 1);
	private static var lime_al_source_stopv = System.load ("lime", "lime_al_source_stopv", 2);
	private static var lime_al_source_rewind = System.load ("lime", "lime_al_source_rewind", 1);
	private static var lime_al_source_rewindv = System.load ("lime", "lime_al_source_rewindv", 2);
	private static var lime_al_source_pause = System.load ("lime", "lime_al_source_pause", 1);
	private static var lime_al_source_pausev = System.load ("lime", "lime_al_source_pausev", 2);
	private static var lime_al_source_queue_buffers = System.load ("lime", "lime_al_source_queue_buffers", 3);
	private static var lime_al_source_unqueue_buffers = System.load ("lime", "lime_al_source_unqueue_buffers", 2);
	private static var lime_al_source3f = System.load ("lime", "lime_al_source3f", 5);
	private static var lime_al_source3i = System.load ("lime", "lime_al_source3i", 5);
	private static var lime_al_sourcef = System.load ("lime", "lime_al_sourcef", 3);
	private static var lime_al_sourcefv = System.load ("lime", "lime_al_sourcefv", 3);
	private static var lime_al_sourcei = System.load ("lime", "lime_al_sourcei", 3);
	private static var lime_al_sourceiv = System.load ("lime", "lime_al_sourceiv", 3);
	private static var lime_al_speed_of_sound = System.load ("lime", "lime_al_speed_of_sound", 1);
	
	
}