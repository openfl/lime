package lime;

import lime.Lime;
import lime.utils.Libs;
import lime.Constants;


class WindowHandler {

    public var lib : Lime;
    public function new( _lib:Lime ) { lib = _lib; }

        //if the core is active
    public var active : Bool = false;
    	//if the window is invalidated
    public var invalidated : Bool = false;
        //if the cursor is constrained inside the window
    public var cursor_locked : Bool = false;
        //if the cursor is hidden or not
    public var cursor_visible : Bool = true;

    public function startup() {
        
        lib._debug(':: lime :: \t WindowHandler Initializing...');

        #if lime_native

            lime_create_main_frame(

                lib.on_window_ready, 
                lib.config.width,               //width
                lib.config.height,              //height
                                                //required flags

                    Window.HARDWARE             | 
                    Window.ALLOW_SHADERS        | 
                    Window.REQUIRE_SHADERS      | 

                                                //optional flags

                    ( lib.config.fullscreen         ? Window.FULLSCREEN     : 0) |  
                    ( lib.config.borderless         ? Window.BORDERLESS     : 0) |  
                    ( lib.config.resizable          ? Window.RESIZABLE      : 0) |  
                    ( lib.config.antialiasing == 2  ? Window.HW_AA          : 0) | 
                    ( lib.config.antialiasing == 4  ? Window.HW_AA_HIRES    : 0) | 
                    ( lib.config.depth_buffer       ? Window.DEPTH_BUFFER   : 0) | 
                    ( lib.config.stencil_buffer     ? Window.STENCIL_BUFFER : 0) |                      
                    ( lib.config.vsync              ? Window.VSYNC          : 0), 

                lib.config.title,               //title
                null                           //icon
                
            ); //lime_create_main_frame


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
            lime_close();
        #end

        lib._debug(':: lime :: \t WindowHandler shut down.');
    }

    public function ready() {

        #if lime_native
                //Fetch the stage handle
            lib.view_handle = lime_get_frame_stage( lib.window_handle );

                //Make sure that our configs are up to date with the actual screen resolution
                //not just the specified resolution in the project file
            lib.config.width = lime_stage_get_stage_width(lib.view_handle);
            lib.config.height = lime_stage_get_stage_height(lib.view_handle);

                //move the window based on xml flags
            if(lib.config.x != null && lib.config.y != null) {
                set_window_position(lib.config.x, lib.config.y);
            }

                //Update the touch support
            lib.config.multitouch_supported = lime_stage_get_multitouch_supported(lib.view_handle);
            lib.config.multitouch = true;
                //Enable it if needed
            lime_stage_set_multitouch_active(lib.view_handle, true);

        #end //lime_native


    }

    public function post_ready() {
        
        #if lime_native
                //Set the stage handler for lime to send us events
            lime_set_stage_handler(lib.view_handle, lib.on_lime_event, lib.config.width, lib.config.height);
        #end

        #if lime_html5  
            //start the run loop on html5, as there is no
            //window creation callback there.
            lib.render.render();
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

    public function set_cursor_visible(val:Bool = true) {
        
        #if lime_native
            if(lime_stage_show_cursor!=null) {
                lime_stage_show_cursor(lib.view_handle, val);
            }
        #end //lime_native

        cursor_visible = val;
    }

    public function constrain_cursor_to_window_frame( val:Bool = false ) {
        
        #if lime_native
            if(lime_stage_constrain_cursor_to_window_frame!=null) {
                lime_stage_constrain_cursor_to_window_frame(lib.view_handle, val);
            }
        #end //lime_native

        #if lime_html5
            html5_enable_pointerlock( val );
        #end //lime_html5

        cursor_locked = val;
    }

    public function set_window_position( x:Int, y:Int ) {
        #if lime_native
            lime_stage_set_window_position(lib.view_handle, x, y);
        #end //lime_native
    }

#if lime_html5

        //html5 api for querying html5
    private function html5_enable_pointerlock( val:Bool = false ) {

        var _normal : Bool = untyped __js__("'pointerLockElement' in document"); 
        var _firefox : Bool = untyped __js__("'mozPointerLockElement' in document");
        var _webkit : Bool = untyped __js__("'webkitPointerLockElement' in document");

        if(!_normal && !_firefox && !_webkit) {
            trace("Pointer lock is not supported by this browser yet, sorry!");
            return;
        }

        untyped __js__("
            var _element = document.getElementById('lime_canvas');
                _element.requestPointerLock =   _element.requestPointerLock ||
                                                _element.mozRequestPointerLock ||
                                                _element.webkitRequestPointerLock;

                // Ask the browser to release the pointer
                _element.exitPointerLock =  _element.exitPointerLock ||
                                            _element.mozExitPointerLock ||
                                            _element.webkitExitPointerLock;");

                // Ask the browser to lock the pointer

            if(val) {
                untyped __js__("if(_element.requestPointerLock) _element.requestPointerLock()");
            } else {
                untyped __js__("if(_element.exitPointerLock) _element.exitPointerLock()");
            }

    } //html5_enable_pointerlock

#end //lime_html5

    public function set_cursor_position_in_window(_x:Int = 0, _y:Int = 0) {
        #if lime_native
            if(lime_stage_set_cursor_position_in_window!=null) {
                lime_stage_set_cursor_position_in_window(lib.view_handle, _x, _y);
            }
            lib.input.last_mouse_x = _x;
            lib.input.last_mouse_y = _y;
        #end //lime_native
    }

    public function on_redraw( _event:Dynamic ) {
        trace(_event);
        lib.render.render();
    } //on_redraw

	public function on_resize(_event:Dynamic) {
            
            //make sure the view is informed
        lib.render.on_resize(_event);

        //todo:

    	//limeOnResize(_event.x, _event.y);
            //if (renderRequest == null)
            //  limeRender(false);
    }    

    public function on_should_rotate( _event:Dynamic ) {
  		//if (shouldRotateInterface(_event.value))
		//  	_event.result = 2;
    } //on_redraw

    public function on_focus( _event:Dynamic ) { 
        trace("focus");
        trace(_event);
    } //on_focus

	 	//Called when the application wants to go to the background and stop
    public function on_pause() { 
        #if lime_native
            lime_pause_animation(); 
        #end //lime_native
    } //on_pause

        //Called when the application resumes operation from the background
    public function on_resume() { 
        #if lime_native
            lime_resume_animation();  
         #end //lime_native
    } //on_resume

        // Terminates the process straight away, bypassing graceful shutdown
    public function on_force_close() {
        #if lime_native
            lime_terminate();
        #end //lime_native
    } //on_force_close

    public function openURL( _url:String ) {

        #if lime_native
            lime_get_url( _url );
        #end //lime_native

        #if lime_html5
        
            untyped __js__('
                var win = window.open( _url, "_blank" );
                win.focus();
            ');

        #end //lime_html5

    } //openURL

    public function fileDialogOpen(_title:String, _text:String) : String {
        #if lime_native
            return lime_file_dialog_open(_title, _text, []);
         #else
            return "";
        #end
    }
    public function fileDialogSave(_title:String, _text:String) : String {
        #if lime_native
            return lime_file_dialog_save(_title, _text, []);
        #else
            return "";
        #end
    }
    public function fileDialogFolder(_title:String, _text:String) : String {
        #if lime_native
            return lime_file_dialog_folder(_title, _text);
        #else
            return "";
        #end
    }

//lime functions
#if lime_native

    private static var lime_stage_get_stage_width    = Libs.load("lime","lime_stage_get_stage_width",  1);
    private static var lime_stage_get_stage_height   = Libs.load("lime","lime_stage_get_stage_height",  1);
    private static var lime_set_stage_handler        = Libs.load("lime","lime_set_stage_handler",  4);
    private static var lime_get_frame_stage          = Libs.load("lime","lime_get_frame_stage",    1);    
    private static var lime_create_main_frame        = Libs.load("lime","lime_create_main_frame", -1);        
    private static var lime_pause_animation          = Libs.load("lime","lime_pause_animation",    0);
    private static var lime_resume_animation         = Libs.load("lime","lime_resume_animation",   0);
    private static var lime_terminate                = Libs.load("lime","lime_terminate", 0);
    private static var lime_close                    = Libs.load("lime","lime_close", 0);
    private static var lime_get_url                  = Libs.load("lime","lime_get_url", 1);

        //File Dialogs
    private static var lime_file_dialog_save         = Libs.load("lime", "lime_file_dialog_save", 3);
    private static var lime_file_dialog_open         = Libs.load("lime", "lime_file_dialog_open", 3);
    private static var lime_file_dialog_folder       = Libs.load("lime", "lime_file_dialog_folder", 2);

        //Cursor and window control (desktop only obviously)
    private static var lime_stage_set_window_position                 = Libs.load("lime","lime_stage_set_window_position", 3);
    private static var lime_stage_show_cursor                         = Libs.load("lime","lime_stage_show_cursor", 2);
    private static var lime_stage_constrain_cursor_to_window_frame    = Libs.load("lime","lime_stage_constrain_cursor_to_window_frame", 2);
    private static var lime_stage_set_cursor_position_in_window       = Libs.load("lime","lime_stage_set_cursor_position_in_window", 3);

        //Multitouch
    private static var lime_stage_get_multitouch_supported   = Libs.load("lime","lime_stage_get_multitouch_supported",  1);
    private static var lime_stage_set_multitouch_active      = Libs.load("lime","lime_stage_set_multitouch_active",  2);

#end //lime_native

}