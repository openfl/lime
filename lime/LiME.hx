package lime;

import lime.utils.Libs;

import lime.Constants;
import lime.RenderHandler;
import lime.InputHandler;
import lime.WindowHandler;

import haxe.Timer;

class LiME {

        //The host class of the application
    public var host : Dynamic;
        //the config passed to us on creation
	public var config : Dynamic;

        //The handlers for the messages from NME
    public var input   : InputHandler;
    public var render   : RenderHandler;
	public var window 	: WindowHandler;

//nme specifics

		//the handle to the window from nme
    public var mainframe_handle : Dynamic;
    	//the handle to the nme stage
    public var stage_handle : Dynamic;

//flags
	
	   //if we have started a shutdown
    public var shutting_down : Bool = false;
    public var has_shutdown : Bool = false;

    	//constructor
    public function new() {} //new

    	//Initialize
    public function init( _main_, _config : Dynamic ) {

        config = _config;
    	host = _main_;

    	_debug(':: lime :: initializing -');
        _debug(':: lime :: Creating window at ' + config.width + 'x' + config.height);

        nme_create_main_frame( 
            on_main_frame_created, 
            config.width,                   //width
            config.height,                  //height
                Window.RESIZABLE | 
                Window.HARDWARE | 
                Window.VSYNC | 
                Window.HW_AA | 
                Window.HW_AA_HIRES | 
                Window.ALLOW_SHADERS | 
                Window.REQUIRE_SHADERS | 
                Window.DEPTH_BUFFER | 
                Window.STENCIL_BUFFER ,     //flags
            config.title,                   //title
            null                            //icon

        ); //nme_create_main_frame
       	
    } //init
    
        //This gets called once the create_main_frame call inside new() 
        //comes back with our window

    private function on_main_frame_created( handle:Dynamic ) {
    
            //Store a reference to the handle            
        mainframe_handle = handle;
        stage_handle = nme_get_frame_stage( mainframe_handle );

            //Set the stage handler for NME to send us events
        nme_set_stage_handler(stage_handle, on_stage_event, config.width, config.height);

            //Create our input message handler class 
        input = new InputHandler( this );
        input.startup(); 

            //Create our window message handler class 
        window = new WindowHandler( this );
        window.startup(); 

            //Create our render message handler class
        render = new RenderHandler( this );
        render.startup();

            //Since we are done...
        window.set_active(true);

        _debug(':: lime :: Ready.');

           //Tell the host application we are ready
        if(host.ready != null) {
            host.ready(this);
        }

    } //on_main_frame_created

    public function shutdown() {        

        shutting_down = true;

            //tell the host game we are killing it
        if(host.shutdown != null) {
            host.shutdown();
        }

            //We don't want to process much now
        window.set_active(false);

    		//Order is imporant here too

        render.shutdown();
        input.shutdown();
        window.shutdown();

            //Ok kill it! 
            //Order matters for events coming
            //when things below are set to null.
        nme_close();

            //Flag it
        has_shutdown = true;

        _debug(':: lime :: Goodbye.');
    }

    public function cleanup() {
        render = null;
        input = null;
        window = null;
    }

    private function on_stage_event( _event:Dynamic ) : Dynamic {

        var event_type:Int = Std.int(Reflect.field(_event, "type"));
        
        _debug('event_from_stage : ' + event_type, true, true);

        switch(event_type) {

    //Main run loop

            case SystemEvents.poll:
                on_update(_event);

            case SystemEvents.quit: 
                shutdown();

    //keyboard
            case SystemEvents.char:
                input.core_onchar(_event);

            case SystemEvents.keydown:
                input.core_onkeydown(_event);

            case SystemEvents.keyup:
                input.core_onkeyup(_event);
                
            case SystemEvents.gotinputfocus:
            	input.core_gotinputfocus(_event);

            case SystemEvents.lostinputfocus:
            	input.core_lostinputfocus(_event);

    //mouse             
            case SystemEvents.mousemove:
                input.core_mousemove(_event);

            case SystemEvents.mousedown:
            	input.core_mousedown(_event);
                

            case SystemEvents.mouseclick:
            	input.core_mouseclick(_event);

            case SystemEvents.mouseup:
            	input.core_mouseup(_event);
                

    //touch
            case SystemEvents.touchbegin:
               	input.core_touchbegin(_event);

            case SystemEvents.touchmove:
                input.core_touchmove(_event);

            case SystemEvents.touchend:
                input.core_touchend(_event);

            case SystemEvents.touchtap:
                input.core_touchtap(_event);

    //joystick

            case SystemEvents.joyaxismove:
                input.core_joyaxismove(_event);

            case SystemEvents.joyballmove:
                input.core_joyballmove(_event);

            case SystemEvents.joyhatmove:
                input.core_joyhatmove(_event);

            case SystemEvents.joybuttondown:
                input.core_joybuttondown(_event);

            case SystemEvents.joybuttonup:
                input.core_joybuttonup(_event);

    //Window

            case SystemEvents.activate:
                window.set_active(true);

            case SystemEvents.deactivate:
                window.set_active(false);

            case SystemEvents.resize:
                window.on_resize(_event);

            case SystemEvents.focus:
                window.on_focus(_event);

            case SystemEvents.redraw:
                window.on_redraw(true);

            case SystemEvents.shouldrotate:
                window.on_should_rotate(_event);

    //System
            case SystemEvents.syswm:
                on_syswm(_event);

            case SystemEvents.change:
                on_change(_event);

        }
        
        return null;

    } //on_stage_event

    	//Handle system/window messages
    public function on_syswm(ev:Dynamic) {
        _debug('syswm event');
    } //on_syswm    

    public function on_change(ev:Dynamic) {
        _debug('change event');
    } //on_syswm


    	//Called when updated by the nme/sdl runtime
    public function on_update(_event:Dynamic) { 

        _debug('on_update ' + Timer.stamp(), true, true); 

        if(!has_shutdown) {
            
            if(host.update != null) {
                host.update();
            }

            do_render(_event);
        }

    } //on_update

    //Render the window
    public function do_render( _event:Dynamic ) {
        
        if( !window.active ) {
            return;
        }

        _debug("render!", true, true);

        if( window.invalidated ) {
            window.invalidated = false;
        }
    
        render.on_render();

        nme_render_stage( stage_handle );

    } //do_render    


//Noisy stuff

    	//import nme_library functions
    private static var nme_render_stage             = Libs.load("nme","nme_render_stage", 1);
    private static var nme_set_stage_handler        = Libs.load("nme","nme_set_stage_handler",  4);
    private static var nme_get_frame_stage          = Libs.load("nme","nme_get_frame_stage",    1);
    private static var nme_close                    = Libs.load("nme","nme_close", 0);

    private static var nme_create_main_frame        = Libs.load("nme","nme_create_main_frame", -1);        

   		//temporary debugging with verbosity options

	public var log : Bool = false;
    public var verbose : Bool = false;
    public var more_verbose : Bool = false;
    public function _debug(value:Dynamic, _verbose:Bool = false, _more_verbose:Bool = false) { 
        if(log) {            
            if(verbose && _verbose && !_more_verbose) {
                trace(value);
            } else 
            if(more_verbose && _more_verbose) {
                trace(value);
            } else {
                if(!_verbose && !_more_verbose) {
                    trace(value);
                }
            } //elses
        } //log
    } //_debug
}