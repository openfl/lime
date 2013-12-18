
    //Ported and modified from OpenFL samples
    //underscorediscovery

import lime.AudioHandler.Sound;
import lime.utils.Assets;
import lime.Lime;

    //Import GL stuff from lime
import lime.gl.GL;

//Press any key to reset the music
//Click to play a sound

class Main {

	public var lib : Lime;

    	//Some value to mess with the clear color
    private var red_value : Float = 1.0;
    private var red_direction : Int = 1;
    private var dt : Float = 0.016;
    private var end_dt : Float = 0;

	public function new() { }

	public function ready( _lime : Lime ) {

            //Store a reference
        lib = _lime;

			// Init the shaders and view
		init();
        
	} //ready


    public function init() {

        lib.audio.create('music', 'assets/ambience.ogg', true );
        lib.audio.create('sound', 'assets/sound.ogg', false);
        lib.audio.create('sound_wav', 'assets/sound.wav', false);

        lib.audio.get('music').play(5);
        lib.audio.get('music').on_complete(function(sound:Sound){
            trace("music complete!");
        });
       
    } //init

        //Called each frame by lime for logic (called before render)
	public function update() {

        dt = haxe.Timer.stamp() - end_dt;
        end_dt = haxe.Timer.stamp();

			//an awful magic number to change the value slowly
		red_value += (red_direction * 0.3) * dt;

		if(red_value >= 1) {
			red_value = 1;
			red_direction = -red_direction;
		} else if(red_value <= 0) {
			red_value = 0;
			red_direction = -red_direction;
		}

	} //update

        //Called by lime 
    public function onmousemove(_event:Dynamic) {
    }
        //Called by lime 
    public function onmousedown(_event:Dynamic) {
        lib.audio.get('sound').play(3,0);        
    }
        //Called by lime 
    public function onmouseup(_event:Dynamic) {
    }
        //Called by lime 
    public function onkeydown(_event:Dynamic) {
        lib.audio.get('music').position = 0.0;
    }    
        //Called by lime 
    public function onkeyup(_event:Dynamic) {
    }


        //Called by lime
	public function render() {

 			//Set the viewport for GL
 		GL.viewport( 0, 0, lib.config.width, lib.config.height );

            //Set the clear color to a weird color that bounces around
        GL.clearColor( red_value, red_value*0.5, red_value*0.3, 1);
        	//Clear the buffers
        GL.clear( GL.COLOR_BUFFER_BIT | GL.DEPTH_BUFFER_BIT  );
                
        

	} //render


} //Main


