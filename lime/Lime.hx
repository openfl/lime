package lime;

import lime.utils.Libs;

import lime.Constants;
import lime.RenderHandler;
import lime.AudioHandler;
import lime.InputHandler;
import lime.WindowHandler;

import haxe.Timer;

class Lime {

        //The host class of the application
    public var host : Dynamic;
        //the config passed to us on creation
	public var config : Dynamic;

        //The handlers for the messages from lime
    public var audio    : AudioHandler;
    public var input    : InputHandler;
    public var render   : RenderHandler;
	public var window 	: WindowHandler;

//lime specifics

		//the handle to the window from lime
    public var window_handle : Dynamic;
    	//the handle to the lime stage
    public var view_handle : Dynamic;

// timing

    public var frame_rate (default, set): Float;
    public var render_request_function:Void -> Void; 

    var frame_period : Float = 0.0;
    var last_render_time : Float = 0.0;
    @:noCompletion public static var early_wakeup = 0.005;
    private function set_frame_rate (value:Float):Float {
        
        frame_rate = value;
        frame_period = (frame_rate <= 0 ? frame_rate : 1.0 / frame_rate);
        
            _debug(':: lime :: frame rate set to ' + frame_rate);

        return value;
        
    }
    
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

    	_debug(':: lime :: initializing - ');
        _debug(':: lime :: Creating window at ' + config.width + 'x' + config.height);

            //default to 60 fps
        if( config.fps != null ) {
            if(Std.is(config.fps, String)) {   
                frame_rate = Std.parseFloat( config.fps );
            } else {
                frame_rate = config.fps;
            }
        } else { //config.fps
            frame_rate = 60;    
        }

        #if android
            render_request_function = lime_stage_request_render;
        #else
            render_request_function = null;
        #end //android


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
        lime.AssetData.initialize();

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

        var result = 0.0;
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
                _event.result = 1;
                input.lime_onchar(_event);

            case SystemEvents.keydown:
                
                #if android
                    if(_event.value == 27) {
                        _event.result = 1;
                    }
                #end //android

                input.lime_onkeydown(_event);

            case SystemEvents.keyup:
                
                #if android
                    if(_event.value == 27) {
                        _event.result = 1;
                    }
                #end //android

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

    //gamepad/joystick

            case SystemEvents.joyaxismove:
                input.lime_gamepadaxis(_event);

            case SystemEvents.joyballmove:
                input.lime_gamepadball(_event);

            case SystemEvents.joyhatmove:
                input.lime_gamepadhat(_event);

            case SystemEvents.joybuttondown:
                input.lime_gamepadbuttondown(_event);

            case SystemEvents.joybuttonup:
                input.lime_gamepadbuttonup(_event);

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
                window.on_redraw(_event);

            case SystemEvents.shouldrotate:
                window.on_should_rotate(_event);

    //System
            case SystemEvents.syswm:
                on_syswm(_event);

            case SystemEvents.change:
                on_change(_event);

        }

            return __updateNextWake();

    } //on_lime_event

    	//Handle system/window messages
    public function on_syswm(ev:Dynamic) {
        _debug('syswm event');
    } //on_syswm    

    public function on_change(ev:Dynamic) {
        _debug('change event');
    } //on_syswm


    	//Called when updated by the lime/sdl runtime
    public function on_update(_event) { 

        _debug('on_update ' + Timer.stamp(), true, false); 

        #if lime_native
            Timer.__checkTimers();            
        #end

            //process any audio
        audio.update();

        if(!has_shutdown) {

            #if lime_native
                var do_update = __checkRender();
            #else 
                var do_update = true;
            #end

            if(do_update) {

                if( host.update != null) {
                    host.update();
                }
            
                perform_render();

            } //do_update?

        } // if !has_shutdown

        return true;

    } //on_update


    public function perform_render() {

        if (render_request_function != null) {
            render_request_function();
        } else {
            render.render();
        }

    } //perform render

    @:noCompletion private function __checkRender():Bool {
        
        #if emscripten 
            render.render();
            return true;
        #end

        if (frame_rate > 0) {
            
            var now = haxe.Timer.stamp();
            if (now >= last_render_time + frame_period) {
                
                last_render_time = now;
                
                return true;

            } //if now >= last + frame_period
            
        } else {

            return true;

        }

        return false;
        
    } //__checkRender

    
    @:noCompletion public function __updateNextWake():Float {
        
        #if lime_native

            var nextWake = haxe.Timer.__nextWake (315000000.0);
            
            nextWake = __nextFrameDue( nextWake );
            lime_stage_set_next_wake( view_handle, nextWake );
            
            return nextWake;

        #else 
            return null;
        #end 

        
    }

    @:noCompletion private function __nextFrameDue( _otherTimers:Float ) {
        
        if(has_shutdown) {
            return _otherTimers;
        }

        if (!window.active) { // && pauseWhenDeactivated
            return _otherTimers;
        }
        
        if(frame_rate > 0) {

            var next = last_render_time + frame_period - haxe.Timer.stamp() - early_wakeup;
            if (next < _otherTimers) {
                return next;
            }

        } //frame_rate
        
        return _otherTimers;

    } //__nextFrameDue

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

#if lime_native
    private static var lime_stage_request_render = Libs.load("lime","lime_stage_request_render", 0);
    private static var lime_stage_set_next_wake  = Libs.load("lime","lime_stage_set_next_wake", 2);        
#end 
    
}


