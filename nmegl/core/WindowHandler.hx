package nmegl.core;

import nmegl.NMEGL;

class WindowHandler {

    public var lib : NMEGL;
    public function new( _lib:NMEGL ) { lib = _lib; }


        //if the core is active
    public var active : Bool = false;
    	//if the window is invalidated
    public var invalidated : Bool = false;

    public function startup() {
        lib._debug(':: NMEGL :: \t WindowHandler Initialized.');
    }

    public function shutdown() {
        lib._debug(':: NMEGL :: \t WindowHandler shut down.');
    }

    public function process() {
        
    }    

    	//Invalidate the window (forcing a redraw on next update)
    public function invalidate() : Void {
        invalidated = true;
    } //invalidate

    public function set_active( _active : Bool ) {

        active = _active;

    	if(_active == false) {
    		if(lib.has_shutdown) {
    			lib.cleanup();
    		}
    	}
    	
    } //set_active

    public function on_redraw( _event:Dynamic ) {
    	lib.do_render(_event);
    } //on_redraw

	public function on_resize(_event:Dynamic) {
    	//nmeOnResize(_event.x, _event.y);
            //if (renderRequest == null)
            //  nmeRender(false);
    }    

    public function on_should_rotate( _event:Dynamic ) {
  		//if (shouldRotateInterface(_event.value))
		//  	_event.result = 2;
    } //on_redraw

    public function on_focus( _event:Dynamic ) { 
    } //on_focus

	 	//Called when the application wants to go to the background and stop
    public function on_pause() { 
        nme_pause_animation(); 
    } //on_pause

        //Called when the application resumes operation from the background
    public function on_resume() { 
        nme_resume_animation();  
    } //on_resume

        // Terminates the process straight away, bypassing graceful shutdown
    public function on_force_close() {  
        nme_terminate();
    } //on_force_close


//nme functions

    private static var nme_pause_animation          = Libs.load("nme","nme_pause_animation",    0);
    private static var nme_resume_animation         = Libs.load("nme","nme_resume_animation",   0);

    private static var nme_terminate                = Libs.load("nme","nme_terminate", 0);

}