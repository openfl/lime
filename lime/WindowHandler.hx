package lime;

import lime.LiME;
import lime.utils.Libs;
import lime.Constants;

class WindowHandler {

    public var lib : LiME;
    public function new( _lib:LiME ) { lib = _lib; }

        //if the core is active
    public var active : Bool = false;
    	//if the window is invalidated
    public var invalidated : Bool = false;

    public function startup() {
        
        lib._debug(':: lime :: \t WindowHandler Initializing...');

        #if lime_native
            nme_create_main_frame( 
                lib.on_window_ready, 
                lib.config.width,               //width
                lib.config.height,              //height
                    Window.RESIZABLE | 
                    Window.HARDWARE | 
                    // Window.VSYNC | 
                    Window.HW_AA | 
                    // Window.HW_AA_HIRES | 
                    Window.ALLOW_SHADERS | 
                    Window.REQUIRE_SHADERS | 
                    Window.DEPTH_BUFFER | 
                    Window.STENCIL_BUFFER ,     //flags
                lib.config.title,               //title
                null                            //icon

            ); //nme_create_main_frame
        #end


        #if lime_html5 
            
            var handle = null;

            untyped {
                js.Browser.document.body.onload = function (_) {
                    var handle = js.Browser.document.getElementById('lime_canvas');
                    lib.on_window_ready( handle ); 
                }
           }
            
        #end //lime_html5
    }

    public function shutdown() {

        #if lime_native            
            nme_close();
        #end

        lib._debug(':: lime :: \t WindowHandler shut down.');
    }

    public function ready() {
            //todo, neaten
        #if lime_native        
            lib.view_handle = nme_get_frame_stage( lib.window_handle );
        #end //lime_native

    }

    public function post_ready() {
        
        #if lime_native
                //Set the stage handler for NME to send us events
            nme_set_stage_handler(lib.view_handle, lib.on_lime_event, lib.config.width, lib.config.height);
        #end

        #if lime_html5  
            //start the run loop on html5, as there is no
            //window creation callback there.
            js.Browser.window.requestAnimationFrame(lib.on_update);
        #end         

        lib._debug(':: lime :: \t WindowHandler Initialized.');
    }    

    	//Invalidate the window (forcing a redraw on next update)
    public function invalidate() : Void {
        invalidated = true;
    } //invalidate

    public function set_active( _active : Bool ) {

        active = _active;

    	if(_active == false) {

                //A window deactivate event comes through after we shut
                //down the window, so if that is the case handle it by cleaning
                //up the remaining values that we have reference to
    		if(lib.has_shutdown) {
    			lib.cleanup();
    		} //has_shutdown

    	} //if _active == false
    	
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
    private static var nme_set_stage_handler        = Libs.load("nme","nme_set_stage_handler",  4);
    private static var nme_get_frame_stage          = Libs.load("nme","nme_get_frame_stage",    1);    
    private static var nme_create_main_frame        = Libs.load("nme","nme_create_main_frame", -1);        
    private static var nme_pause_animation          = Libs.load("nme","nme_pause_animation",    0);
    private static var nme_resume_animation         = Libs.load("nme","nme_resume_animation",   0);
    private static var nme_terminate                = Libs.load("nme","nme_terminate", 0);
    private static var nme_close                    = Libs.load("nme","nme_close", 0);

}