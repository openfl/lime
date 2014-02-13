package lime;

import lime.utils.Libs;
import lime.helpers.AudioHelper;
import lime.helpers.AudioHelper.Sound;

class AudioHandler {
    
    public var lib : Lime;

    public var sounds : Map<String, Sound>;
    public var helper : lime.helpers.AudioHelper;

    public function new( _lib:Lime ) {
        lib = _lib;
            //create the helper, this defers based on platform inside AudioHelper
        helper = new AudioHelper( lib );
    }

    public function startup() {

        sounds = new Map();     

        helper.startup();        

    } //startup

    @:noCompletion public function shutdown() {
        
       helper.shutdown();

    } //shutdown

    @:noCompletion public function update() {
        
        helper.update();

        #if lime_native

            for(sound in sounds) {
                sound.check_complete();
            } //each sound

        #end //lime_native

    } //update

    public function create( _name:String, _file:String, ?_music:Bool = false ) : Sound {
        
        if( sounds.exists(_name) ) {
            throw "lime : audio : Named sounds are not allowed to have duplicate names for now";
        }        

        var sound_instance = helper.create( _name, _file, _music );

        if(sound_instance != null) {
            sounds.set( _name, sound_instance );
        }

        return sound_instance;

    } //create

        //fetch a named sound, or null if not found (see also exists)
    public function sound( _name:String ) : Sound {

        return sounds.get(_name);

    } //sound
        
    public function loop( _name:String ) : Void {

        var _sound = sound(_name);

        if(_sound != null) {
                //set the looping flag so it continues to loop
            _sound.looping = true;
                //:todo: start position for looping?
            _sound.play(); 

        } else {
            trace('Audio :: Sound does not exist, use Luxe.audio.create() first : ' + _name);
        }

    } //loop

    public function stop( _name:String ) : Void {

         var _sound = sound(_name);

        if(_sound != null) {
            _sound.stop();
        } else {
            trace('lime : audio : sound does not exist for stop(' + _name + '), use audio.create() first');
        }

    } //stop

    public function play( _name:String, ?_number_of_times:Int=1, ?_start_position_in_ms:Float = 0 ) : Void {

        var _sound = sound(_name);

        if(_sound != null) {
            _sound.play( _number_of_times , _start_position_in_ms );
        } else {
            trace('lime : audio : sound does not exist for play(' + _name + '), use audio.create() first');
        }

    } //play

        //true or false if a sound is playing
    public function playing( _name:String ) : Bool {

        var s = sound(_name);
        if(s != null) {
            return s.playing;
        }

        return false;

    } //playing

    public function exists( _name:String ) : Bool { 
        
        return sound( _name ) != null;

    } //exists

        //without expressing a value for volume, 
        //a sound will return it's volume
    public function volume( _name:String, ?_volume:Float = null ) : Float {

        var _sound = sound(_name);
        if(_sound == null) {
            trace('lime : audio : sound does not exist for volume(' + _name + '), use audio.create() first');
            return 0.0;
        }
            
        if(_volume != null) {
            _sound.volume = _volume;            
        }

        return _sound.volume;
            
    } //volume

        //without expressing a value for pan, 
        //a sound will return it's pan
    public function pan( _name:String, ?_pan:Float = null ) : Float  {

        var _sound = sound(_name);
        if(_sound == null) {
            trace('lime : audio : sound does not exist for pan(' + _name + '), use audio.create() first');
            return 0.0;
        }

        if(_pan != null) {
            _sound.pan = _pan;
        }

        return _sound.pan;

    } //pan

        //without expressing a value for position, 
        //a sound will return it's position
    public function position( _name:String, ?_pos:Float = null ) : Float {

        var _sound = sound(_name);
        if(_sound == null) {
            trace('lime : audio : sound does not exist for position(' + _name + '), use Luxe.audio.create() first');
            return 0.0;
        }

        if(_pos != null) {
            _sound.position = _pos;
        }

        return _sound.position;

    } //position

} //AudioHandler


