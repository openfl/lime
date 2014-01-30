package lime.helpers.html5;

import lime.Lime;

import lime.helpers.AudioHelper.Sound;

class AudioHelper {
 
    var lib : Lime;

    public var ready : Bool = false;
    public static var soundManager : Dynamic;

    public function new( _lib:Lime ) {

        lib = _lib;

    } //new

    @:noCompletion public function startup() {

            //init sound manager
        soundManager = untyped js.Browser.window.soundManager;
        if(soundManager != null) {
            soundManager.setup({
                url: './lib/soundmanager/swf/',
                flashVersion: 9, 
                debugMode : false,
                preferFlash: true,
                onready : function() { ready = true; }
            });
        }

    }

    public function create( _name:String, _file:String, ?_music:Bool = false ) : Sound {

        var _sound_handle = soundManager.createSound({

            url: _file,
            id: _name,                
            autoLoad : true,
            autoPlay : false,
            multiShot : !_music,
            stream : _music

        });

        return new Sound(_name, _sound_handle, _music);

    } //create 

    @:noCompletion public function shutdown() {

        soundManager.stopAll();

    }

    @:noCompletion public function update() {
        
    }


} //AudioHelper