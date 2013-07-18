package lime;

import lime.utils.Libs;

import lime.Constants;
import lime.RenderHandler;
import lime.AudioHandler;
import lime.InputHandler;
import lime.WindowHandler;

import haxe.Timer;

class LiME {

        //The host class of the application
    public var host : Dynamic;
        //the config passed to us on creation
	public var config : Dynamic;

        //The handlers for the messages from NME
    public var audio    : AudioHandler;
    public var input    : InputHandler;
    public var render   : RenderHandler;
	public var window 	: WindowHandler;

//nme specifics

		//the handle to the window from nme
    public var window_handle : Dynamic;
    	//the handle to the nme stage
    public var view_handle : Dynamic;

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

            //Create our window handler class, 
            //this will handle initialization
        window = new WindowHandler( this );
        window.startup();         
       	
    } //init
    
        //This gets called once the create_main_frame call inside new() 
        //comes back with our window

    public function on_window_ready( handle:Dynamic ) {
    
            //Store a reference to the handle            
        window_handle = handle;
            
            //do any on ready initialization for the window
        window.ready();

            //For the asset class to keep lists and such
        nme.AssetData.initialize();

            //Create our input message handler class 
        input = new InputHandler( this );
        input.startup();         

            //Create our audio message handler class
        audio = new AudioHandler( this );
        audio.startup();         

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

            //if any post ready things that need 
            //to happen, do it here.
       window.post_ready();      

    } //on_window_ready

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

            //Flag it
        has_shutdown = true;

        _debug(':: lime :: Goodbye.');
    }

    public function cleanup() {
        render = null;
        input = null;
        window = null;
    }

    public function on_lime_event( _event:Dynamic ) : Dynamic {

        var event_type:Int = Std.int(Reflect.field(_event, "type"));
        
        if(event_type != SystemEvents.poll) {
            _debug('event_from_stage : ' + event_type, true, true);
        }

        switch(event_type) {

    //Main run loop

            case SystemEvents.poll:
                on_update(_event);

            case SystemEvents.quit: 
                shutdown();

    //keyboard
            case SystemEvents.char:
                input.lime_onchar(_event);

            case SystemEvents.keydown:
                input.lime_onkeydown(_event);

            case SystemEvents.keyup:
                input.lime_onkeyup(_event);
                
            case SystemEvents.gotinputfocus:
            	input.lime_gotinputfocus(_event);

            case SystemEvents.lostinputfocus:
            	input.lime_lostinputfocus(_event);

    //mouse             
            case SystemEvents.mousemove:
                input.lime_mousemove(_event);

            case SystemEvents.mousedown:
            	input.lime_mousedown(_event);

            case SystemEvents.mouseclick:
            	input.lime_mouseclick(_event);

            case SystemEvents.mouseup:
            	input.lime_mouseup(_event);
                

    //touch
            case SystemEvents.touchbegin:
               	input.lime_touchbegin(_event);

            case SystemEvents.touchmove:
                input.lime_touchmove(_event);

            case SystemEvents.touchend:
                input.lime_touchend(_event);

            case SystemEvents.touchtap:
                input.lime_touchtap(_event);

    //joystick

            case SystemEvents.joyaxismove:
                input.lime_joyaxismove(_event);

            case SystemEvents.joyballmove:
                input.lime_joyballmove(_event);

            case SystemEvents.joyhatmove:
                input.lime_joyhatmove(_event);

            case SystemEvents.joybuttondown:
                input.lime_joybuttondown(_event);

            case SystemEvents.joybuttonup:
                input.lime_joybuttonup(_event);

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

    } //on_lime_event

    	//Handle system/window messages
    public function on_syswm(ev:Dynamic) {
        _debug('syswm event');
    } //on_syswm    

    public function on_change(ev:Dynamic) {
        _debug('change event');
    } //on_syswm


    	//Called when updated by the nme/sdl runtime
    public function on_update(_event) { 

        _debug('on_update ' + Timer.stamp(), true, true); 

            //Keep the Timers updated. todo, tidy.
        #if lime_native
            Timer.nmeCheckTimers();
        #end

        if(!has_shutdown) {

            if(host.update != null) {
                host.update();
            }

            do_render(_event);


        } // if !has_shutdown

        return true;
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
    
        render.render();
           //make sure the c++ knows our sleep time
        // render.next_wake();


    } //do_render    

//Noisy stuff

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