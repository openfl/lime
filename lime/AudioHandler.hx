package lime;

import lime.utils.Libs;


class SoundTransform {
   public var pan:Float;
   public var volume:Float;

   public function new(vol:Float = 1.0, panning:Float = 0.0) {
      volume = vol;
      pan = panning;
   }

   public function clone() {
      return new SoundTransform(volume, pan);
   }
}

class Sound {
	public var handle : Dynamic;
	public var sound : Dynamic;

	@:isVar public var volume(default, set) : Float = 1.0;
	@:isVar public var pan(default, set) : Float = 0.0;

	private var _transform:SoundTransform;

	public function new(_handle:Dynamic, ?_sound:Dynamic = null){
		handle = _handle;
		sound = _sound;
			//reuse.
		_transform = new SoundTransform(volume,pan);
	}

	public function play(?_loops:Int = 0, ?_start:Float = 0.0) {
		sound = null;
		
		#if lime_native		
			sound = nme_sound_channel_create(handle, _start, _loops, _transform);
		#end //lime_native
	}

	public function stop() {
		if(sound != null) {

			#if lime_native		
				nme_sound_channel_stop(sound);
			#end //lime_native
			
			sound = null;
		}
	}

	public function set_volume(_v:Float) : Float {
		_transform.volume = _v;

		#if lime_native
			nme_sound_channel_set_transform(sound,_transform);
		#end //lime_native

		return volume = _v;
	}
	public function set_pan(_p:Float) : Float {
		_transform.pan = _p;
	
		#if lime_native
			nme_sound_channel_set_transform(sound,_transform);
		#end //lime_native

		return pan = _p;
	}

#if lime_native
   private static var nme_sound_channel_create = Libs.load("nme","nme_sound_channel_create", 4);
   private static var nme_sound_channel_stop = Libs.load("nme","nme_sound_channel_stop", 1);
   private static var nme_sound_channel_set_transform = Libs.load("nme","nme_sound_channel_set_transform", 2);
#end //lime_native

}

class AudioHandler {
	
	public var lib : LiME;
    public function new( _lib:LiME ) { lib = _lib; }

    public var sounds : Map<String, Sound>;
	public function startup() {
		//test audio junks

		sounds = new Map();		
	}

	public function create_sound(_name:String, _file:String, ?_music:Bool = false ) {
		
		if(sounds.exists(_name)) {
			throw ">>> Named sounds are not allowed to have duplicate names";
		}

		#if lime_native
			var _handle = nme_sound_from_file( nme.AssetData.path.get(_file), _music);
			var _sound = new Sound(_handle);
			sounds.set(_name, _sound);
		#end //lime_native
	}
	
#if lime_native
   private static var nme_sound_from_file = Libs.load("nme","nme_sound_from_file", 2);
   private static var nme_sound_from_data = Libs.load("nme","nme_sound_from_data", 3);
#end //lime_native

}