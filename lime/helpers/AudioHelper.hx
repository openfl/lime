package lime.helpers;

import lime.AudioHandler;
import lime.utils.Libs;

#if lime_html5
    typedef AudioHelper = lime.helpers.html5.AudioHelper;
#else
    typedef AudioHelper = lime.helpers.native.AudioHelper;
#end 

class Sound {

    public var name : String;
    public var handle : Dynamic;
    public var channel : Dynamic;

    public var looping : Bool = false;
    public var playing : Bool = false;
    public var ismusic : Bool = false;

    var on_complete_handler : Sound->Void;

    @:isVar public var volume(default, set) : Float = 1.0;
    @:isVar public var pan(default, set) : Float = 0.0;
    @:isVar public var position(get, set) : Float = 0.0;

    var plays_total : Int = 0;
    var plays_remain : Int = 0;

 #if (!audio_thread_disabled && lime_native)
    @:noCompletion private var added_to_thread:Bool;
 #end  

    private var transform:SoundTransform;

    public function new( _name:String, _handle:Dynamic, ?_music:Bool = false, ?_sound:Dynamic = null ) {

        name = _name;
        handle = _handle;
        channel = _sound;
        ismusic = _music;

            //reuse.
        transform = new SoundTransform(volume,pan);

    }

    public function play( ?_number_of_times:Int = 1, ?_start:Float = 0.0) {
          
        plays_total = _number_of_times;
        plays_remain = _number_of_times;        

            //don't try play 0 times for logical consistency
        if(_number_of_times == 0) return;

            // -1 is commnly meant as infinite loop, 
            //but .loop() should be called instead since it will do the extra setup
        if(_number_of_times == -1) {
            looping = true;
        }

            //set playing flag
        playing = true;

        #if lime_native     

            channel = null;  
            
            if(_number_of_times == -1) {
                _number_of_times = 1;
            }
                //on native, the sound api matches flash where loop is play, loop ... n so it's "one too many" 
                // for play (number of times). for this reason we send it in as number - 1        
            channel = lime_sound_channel_create(handle, _start, _number_of_times - 1, transform);

        #end //lime_native

        #if lime_html5

            AudioHelper.soundManager.play( name, {
                onfinish : function(){ 
                    do_on_complete();
                }
            });

        #end //lime_html5

    } //play

    public function stop() {   

        playing = false;
        looping = false;

        #if lime_native

            if(channel != null) {

                #if (!audio_thread_disabled && lime_native)
                    if( ismusic ) {
                        AudioHelper.audio_state.remove(this);
                    }
                #end

                lime_sound_channel_stop(channel);
                
                channel = null;

            } //channel != null

        #end //lime_native

        #if lime_html5

            AudioHelper.soundManager.stop( name );

        #end //lime_html5
    }

    @:noCompletion public function do_on_complete() {

            //looping is explicit so just keep playing
            //until they call stop
        if(looping) {

            play();
            return;

        } //looping

        #if lime_html5

            if(!looping) {                
                plays_remain--;
                if(plays_remain > 0) {
                    play( plays_remain );
                    return;
                }
            } //looping

        #end //lime_html5

        playing = false;
        channel = null;

        if(on_complete_handler != null) {
            on_complete_handler( this );
        }

    } //do_on_complete

    public function on_complete(_function:Sound->Void) { 
        on_complete_handler = _function;
    } //on_complete setter

    @:noCompletion public function do_check_complete ():Bool {

        #if lime_native

            if( lime_sound_channel_is_complete(channel) ) {                
                return true;
            }

        #end
        
        return false;
        
    } //do_check_complete

    @:noCompletion public function check_complete() {

        #if (!audio_thread_disabled && lime_native)

            if (added_to_thread || (channel != null && ismusic)) {
                
                if (!added_to_thread) {
                    AudioHelper.audio_state.add( this );
                    added_to_thread = true;
                }

                AudioHelper.audio_state.audio_thread.sendMessage( AudioHelper.audio_message_check_complete );

                return false;
            
            } else {
                if( do_check_complete() ) {
                    do_on_complete();
                    return true;
                } else {
                    return false;
                }
            }

        #else
            
            if( do_check_complete() ) {
                do_on_complete();
                return true;
            }

        #end
        
        return false;

    } //check_complete

    function set_volume(_v:Float) : Float {

        transform.volume = _v;

        #if lime_native
            lime_sound_channel_set_transform(channel,transform);
        #end //lime_native

        #if lime_html5
            AudioHelper.soundManager.setVolume(name, _v * 100);
        #end //lime_html5

        return volume = _v;
    }

    function set_pan(_p:Float) : Float {

        transform.pan = _p;
    
        #if lime_native
            lime_sound_channel_set_transform(channel,transform);
        #end //lime_native

        #if lime_html5
            AudioHelper.soundManager.setPan(name, _p * 100);
        #end //lime_html5

        return pan = _p;
    }

    function set_position(_p:Float) : Float {
    
        #if lime_native
            lime_sound_channel_set_position(channel, _p);
        #end //lime_native

        #if lime_html5
            AudioHelper.soundManager.setPosition(name, _p);
        #end //lime_html5

        return position = _p;
    }

    function get_position() : Float {
    
        #if lime_native
            position = lime_sound_channel_get_position(channel);
        #end //lime_native

        #if lime_html5
            position = handle.position;
        #end //lime_html5

        return position;
    }

#if lime_native

    private static var lime_sound_channel_is_complete   = Libs.load( "lime", "lime_sound_channel_is_complete", 1);
    private static var lime_sound_channel_create        = Libs.load( "lime", "lime_sound_channel_create", 4);
    private static var lime_sound_channel_stop          = Libs.load( "lime", "lime_sound_channel_stop", 1);
    private static var lime_sound_channel_set_transform = Libs.load( "lime", "lime_sound_channel_set_transform", 2);
    private static var lime_sound_channel_get_position  = Libs.load( "lime", "lime_sound_channel_get_position", 1);
    private static var lime_sound_channel_set_position  = Libs.load( "lime", "lime_sound_channel_set_position", 2);

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
