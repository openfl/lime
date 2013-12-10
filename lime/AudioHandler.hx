package lime;

import lime.utils.Libs;


#if (!audio_thread_disabled && lime_native)
    #if neko
        import neko.vm.Thread;
        import neko.vm.Mutex;
    #else
        import cpp.vm.Thread;
        import cpp.vm.Mutex;
    #end 
#end //audio_thread_disabled


class AudioHandler {
    
    public var lib : Lime;
    public function new( _lib:Lime ) { lib = _lib; }

#if (!audio_thread_disabled && lime_native)
    
    @:noCompletion public static var audio_state:AudioThreadState;

    @:noCompletion public static var audio_message_check_complete = 1;    
    @:noCompletion public static var audio_thread_is_idle:Bool = true;
    @:noCompletion public static var audio_thread_running:Bool = false;

#end        

    public var sounds : Map<String, Sound>;
    public function startup() {

        sounds = new Map();     

        #if (!audio_thread_disabled && lime_native)
            audio_state = new AudioThreadState ();
            audio_thread_running = true;
            audio_thread_is_idle = false;
            audio_state.main_thread = Thread.current ();
            audio_state.audio_thread = Thread.create( audio_thread_handler );
        #end //#(!audio_thread_disabled && lime_native)

    } //startup

    @:noCompletion public function update() {
        for(sound in sounds) {
            if(sound.ismusic) {
                sound.check_complete();
            }
        }
    }

    public function create(_name:String, _file:String, ?_music:Bool = false ) {
        
        if(sounds.exists(_name)) {
            throw ">>> Named sounds are not allowed to have duplicate names";
        }

        #if lime_native

            var _handle = lime_sound_from_file( lime.AssetData.path.get(_file), _music );
            var _sound = new Sound(_name, _handle, _music);

                sounds.set(_name, _sound);

        #end //lime_native
    }

    public function get( _name:String ) : Sound {
        return sounds.get(_name);
    }

#if (!audio_thread_disabled && lime_native)

    public function audio_thread_handler() {

        while (audio_thread_running) {      
            
            var thread_message:Dynamic = Thread.readMessage (false);
                
            if (thread_message == audio_message_check_complete) {
                audio_state.check();
            }
            
            if (!audio_thread_is_idle) {
                audio_state.update();
                Sys.sleep (0.01);
            } else {
                Sys.sleep (0.2);
            }
            
        }
        
        audio_thread_running = false;
        audio_thread_is_idle = true;
        
    }
    
#end //(!audio_thread_disabled && lime_native)

    
#if lime_native
   private static var lime_sound_from_file = Libs.load("lime","lime_sound_from_file", 2);
   private static var lime_sound_from_data = Libs.load("lime","lime_sound_from_data", 3);
#end //lime_native

} //AudioHandler


class Sound {

    public var name : String;
    public var handle : Dynamic;
	public var channel : Dynamic;
    public var ismusic : Bool = false;

    var on_complete_handler : Sound->Void;

	@:isVar public var volume(default, set) : Float = 1.0;
    @:isVar public var pan(default, set) : Float = 0.0;
	@:isVar public var position(get, set) : Float = 0.0;

#if (!audio_thread_disabled && lime_native)
    @:noCompletion private var added_to_thread:Bool;
#end 

	private var _transform:SoundTransform;

	public function new(_name:String, _handle:Dynamic, ?_music:Bool = false, ?_sound:Dynamic = null) {

        name = _name;
		handle = _handle;
		channel = _sound;
        ismusic = _music;

			//reuse.
		_transform = new SoundTransform(volume,pan);
	}

	public function play(?_loops:Int = 0, ?_start:Float = 0.0) {

		channel = null;
		
		#if lime_native		
			channel = lime_sound_channel_create(handle, _start, _loops, _transform);
		#end //lime_native
	}

	public function stop() {

		if(channel != null) {

            #if (!audio_thread_disabled && lime_native)
                if( ismusic ) {
                    AudioHandler.audio_state.remove(this);
                }
            #end

			#if lime_native		
				lime_sound_channel_stop(channel);
			#end //lime_native
			
			channel = null;
		}
	}

    @:noCompletion public function do_on_complete() {
        if(on_complete_handler != null) {
            on_complete_handler(this);
        }
    }

    public function on_complete(_function:Sound->Void) {        
        on_complete_handler = _function;
    }


    @:noCompletion public function do_check_complete ():Bool {

        #if lime_native
            if( lime_sound_channel_is_complete(channel) ) {
                handle = null;
                channel = null;
                return true;
            }
        #end
        
        return false;
        
    } //do_check_complete

    @:noCompletion public function check_complete() {

        #if (!audio_thread_disabled && lime_native)

            if (added_to_thread || (channel != null && ismusic)) {
                
                if (!added_to_thread) {
                    trace('adding to a thread ' + name);
                    AudioHandler.audio_state.add( this );
                    added_to_thread = true;
                }

                AudioHandler.audio_state.audio_thread.sendMessage( AudioHandler.audio_message_check_complete );

                return false;
            }

        #else
            
            if( do_check_complete() ) {
                do_on_complete();
                return true;
            }

        #end
        
        return false;    
    }

	function set_volume(_v:Float) : Float {
		_transform.volume = _v;

		#if lime_native
			lime_sound_channel_set_transform(channel,_transform);
		#end //lime_native

		return volume = _v;
	}
    function set_pan(_p:Float) : Float {
        _transform.pan = _p;
    
        #if lime_native
            lime_sound_channel_set_transform(channel,_transform);
        #end //lime_native

        return pan = _p;
    }

    function set_position(_p:Float) : Float {
    
        #if lime_native
            lime_sound_channel_set_position(channel, _p);
        #end //lime_native

        return position = _p;
    }

	function get_position() : Float {
	
		#if lime_native
			position = lime_sound_channel_get_position(channel);
		#end //lime_native

		return position;
	}

#if lime_native
    private static var lime_sound_channel_is_complete = Libs.load ("lime", "lime_sound_channel_is_complete", 1);
    private static var lime_sound_channel_create = Libs.load("lime","lime_sound_channel_create", 4);
    private static var lime_sound_channel_stop = Libs.load("lime","lime_sound_channel_stop", 1);
    private static var lime_sound_channel_set_transform = Libs.load("lime","lime_sound_channel_set_transform", 2);
    private static var lime_sound_channel_get_position = Libs.load ("lime", "lime_sound_channel_get_position", 1);
    private static var lime_sound_channel_set_position = Libs.load ("lime", "lime_sound_channel_set_position", 2);    
#end //lime_native

}


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

} //SoundTransform



#if (!audio_thread_disabled && lime_native)

class AudioThreadState {
    
    public var audio_thread:Thread;
    public var sound_list:Map <Sound, Bool>;
    public var main_thread:Thread;
    public var mutex:Mutex;
    
    public function new () {
        mutex = new Mutex ();
        sound_list = new Map ();
    }
    
    public function add (sound:Sound):Void {
        
        mutex.acquire ();
            
            if (!sound_list.exists(sound)) {
                sound_list.set (sound, false);
                AudioHandler.audio_thread_is_idle = false;
            }
        
        mutex.release ();
        
    }
    
    public function check() {
        
        for (sound in sound_list.keys()) {

            var is_complete = sound_list.get(sound);
            if (is_complete) {
                sound.do_on_complete();
                
                mutex.acquire ();
                    sound_list.remove( sound );
                mutex.release ();
                
            } //isComplete
        }
            
    }
    
    public function remove( sound:Sound ):Void {
        
        mutex.acquire ();
        
            if( sound_list.exists(sound) ) {
                sound_list.remove(sound);           
                if (Lambda.count (sound_list) == 0) {
                    AudioHandler.audio_thread_is_idle = true;
                }
            }
            
        mutex.release ();
        
    }
    
    public function update() {
        
        mutex.acquire ();
            
            for (sound in sound_list.keys()) {
                var is_complete = sound.do_check_complete();
                sound_list.set( sound, is_complete );
            }
            
        mutex.release ();
        
    }
    
} //AudioThreadState

#end // (!audio_thread_disabled && lime_native)