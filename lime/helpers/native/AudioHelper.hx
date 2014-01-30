package lime.helpers.native;

import lime.utils.Libs;
import lime.Lime;

#if (!audio_thread_disabled)
    #if neko
        import neko.vm.Thread;
        import neko.vm.Mutex;
    #else
        import cpp.vm.Thread;
        import cpp.vm.Mutex;
    #end 
#end //audio_thread_disabled

import lime.helpers.AudioHelper.Sound;

class AudioHelper {
 
    var lib : Lime;

#if (!audio_thread_disabled)
    
    @:noCompletion public static var audio_state:AudioThreadState;
    @:noCompletion public static var audio_message_check_complete = 1;    
    @:noCompletion public static var audio_thread_is_idle:Bool = true;
    @:noCompletion public static var audio_thread_running:Bool = false;

#end    

    public function new( _lib:Lime ) {

        lib = _lib;        

    } //new

    @:noCompletion public function startup() {

        #if (!audio_thread_disabled)

            audio_state = new AudioThreadState ();
            audio_thread_running = true;
            audio_thread_is_idle = false;
            audio_state.main_thread = Thread.current ();
            audio_state.audio_thread = Thread.create( audio_thread_handler );

        #end //#(!audio_thread_disabled && lime_native)

    } //startup
    
    @:noCompletion public function update() {

         

    } //update

    @:noCompletion public function shutdown() {

         #if (!audio_thread_disabled)

            audio_thread_running = false;

        #end //(!audio_thread_disabled && lime_native)

    } //shutdown

    public function create( _name:String, _file:String, ?_music:Bool = false ) {

        var _handle = lime_sound_from_file( lime.AssetData.path.get(_file), _music );
        
        return new Sound(_name, _handle, _music);

    } //create

#if (!audio_thread_disabled)

    public function audio_thread_handler() {
        
        #if debug
            lib._debug("lime: Audio background thread started.");
        #end //debug

        var thread_message : Dynamic;
        while (audio_thread_running) {      
            
            thread_message = Thread.readMessage (false);

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

        #if debug
            lib._debug("lime: Audio background thread shutdown.");
        #end //debug
        
    }
    
#end //(!audio_thread_disabled)

#if lime_native
   private static var lime_sound_from_file = Libs.load("lime","lime_sound_from_file", 2);
   private static var lime_sound_from_data = Libs.load("lime","lime_sound_from_data", 3);
#end //lime_native

} //AudioHelper


#if (!audio_thread_disabled)

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
                    AudioHelper.audio_thread_is_idle = false;
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
                        AudioHelper.audio_thread_is_idle = true;
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

#end // (!audio_thread_disabled)