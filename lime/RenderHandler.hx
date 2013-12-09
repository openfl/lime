package lime;

import lime.Lime;
import lime.utils.Libs;

    //Import GL 
import lime.gl.GL;
import lime.gl.GLBuffer;
import lime.gl.GLProgram; 
    
    //utils
import lime.utils.Float32Array;

    //geometry
import lime.geometry.Matrix3D;


#if lime_html5

    import js.Browser;
    import js.html.CanvasElement;


enum BrowserLike {
    unknown;
    chrome;
    firefox;
    opera;
    ie;
    safari;
}

#end //lime_html5


class RenderHandler {
        
    public var lib : Lime;
    public function new( _lib:Lime ) { lib = _lib; }

    public var __handle : Dynamic;

        //direct_renderer_handle for drawing
    public var direct_renderer_handle : Dynamic;

    #if lime_html5
        public var requestAnimFrame : Dynamic;
        public var browser : BrowserLike;
        public var canvas_position : Dynamic;
    #end //lime_html5
    
    
    @:noCompletion private function __onRender(rect:Dynamic):Void {
        

    }

    public function startup() { 

        #if lime_native

            __handle = lime_get_frame_stage( lib.window_handle );

                //Set up the OpenGL View
            direct_renderer_handle = lime_direct_renderer_create();

                //Add this to the main stage, so it will render
            lime_doc_add_child( __handle, direct_renderer_handle );

                //Set this handle to the real view with a render function
            lime_direct_renderer_set( direct_renderer_handle, on_render );

        #end //lime_native

        #if lime_html5
                //default to 0,0
            canvas_position = {x:0, y:0};

                //default to unknown
            browser = BrowserLike.unknown;

            var _window_handle : js.html.CanvasElement = cast lib.window_handle;
            direct_renderer_handle = _window_handle.getContextWebGL({ alpha:false, premultipliedAlpha:false });

                //for use with mouseoffsets and so on
            update_canvas_position();

            if(direct_renderer_handle == null) {
                throw "WebGL is required to run this";
            } 

            lime.gl.GL.limeContext = direct_renderer_handle;

            requestAnimFrame = js.Browser.window.requestAnimationFrame;
            
            if(requestAnimFrame != null) {
                browser = BrowserLike.chrome;
            } else {
                
                var _firefox = untyped js.Browser.window.mozRequestAnimationFrame;
                var _safari = untyped js.Browser.window.webkitRequestAnimationFrame;
                var _opera = untyped js.Browser.window.oRequestAnimationFrame;

                if(_firefox) {
                    browser = BrowserLike.firefox;
                } else if(_safari) {
                    browser = BrowserLike.safari;
                } else if(_opera){
                    browser = BrowserLike.opera;
                }

            } //else there is no RequestAnimationFrame

        #end //lime_html5

            //Done.
        lib._debug(':: lime :: \t RenderHandler Initialized.');
    }


    public function shutdown() {
        lib._debug(':: lime :: \t RenderHandler shut down.');
    }

    public function on_resize(_event:Dynamic) {

        #if lime_html5
            update_canvas_position();
        #end //lime_html5
        
        if(lib.host.onresize != null) {
            lib.host.onresize(_event);
        }

    } //on_resize
    
#if lime_html5
    
    public function update_canvas_position() {
        // see the following link for this implementation
        // http://www.quirksmode.org/js/findpos.html

        var curleft = 0;
        var curtop = 0;

            //start at the canvas
        var _obj : Dynamic = lib.window_handle;
        var _has_parent : Bool = true;
        var _max_count = 0;

        while(_has_parent == true) {

            _max_count++;
            
            if(_max_count > 30) {
                _has_parent = false;
                break;
            } //prevent rogue endless loops

            if(_obj.offsetParent) {

                    //it still has an offset parent, add it up
                curleft += _obj.offsetLeft;
                curtop += _obj.offsetTop;

                    //then move onto the parent 
                _obj = _obj.offsetParent;

            } else {
                    //we are done
                _has_parent = false;

            }
        } //while

        canvas_position = { x:curleft, y:curtop };
    }

    public function _requestAnimFrame(callback:Dynamic) {

        if(browser == BrowserLike.chrome) {

            requestAnimFrame(callback);

        } else  //chrome
        if(browser == BrowserLike.firefox) {

            untyped {
                js.Browser.window.mozRequestAnimationFrame(callback);
            }

        } else //firefox
        if(browser == BrowserLike.safari) {

            untyped {
                js.Browser.window.webkitRequestAnimationFrame(callback);
            }

        } else //safari
        if(browser == BrowserLike.opera) {

            untyped {
                js.Browser.window.oRequestAnimationFrame(callback);
            }

        } else { //opera

            js.Browser.window.setTimeout(function(){
                callback();
            }, 16);

        } //no RAF? fall back to setTimeout for now
    }
#end //lime_html5

    public function request_render() {

        #if lime_native
            lime_stage_request_render();
        #end
    }

    public function render() : Bool {

        if( !lib.window.active ) {
            return false;
        }

        #if lime_html5
           
            on_render(null);
            _requestAnimFrame( lib.on_update );
            
            return true;
        #end

        #if lime_native 
            lime_render_stage( lib.view_handle );
        #end //lime_native

        return true;
    }

    public function on_render(rect:Dynamic):Void {

        if( lib.host.render != null ) {
            lib.host.render();
        }

    } //on_render


//lime functions
#if lime_native
    private static var lime_get_frame_stage          = Libs.load("lime","lime_get_frame_stage",    1);    
    private static var lime_stage_request_render     = Libs.load("lime","lime_stage_request_render", 0);
    private static var lime_render_stage             = Libs.load("lime","lime_render_stage", 1);
    private static var lime_doc_add_child            = Libs.load("lime","lime_doc_add_child", 2);
    private static var lime_direct_renderer_create   = Libs.load("lime","lime_direct_renderer_create", 0);
    private static var lime_direct_renderer_set      = Libs.load("lime","lime_direct_renderer_set", 2);
    private static var lime_stage_set_next_wake      = Libs.load("lime","lime_stage_set_next_wake", 2);    
#end //lime_native

} 

    