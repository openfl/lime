package lime;

import lime.LiME;
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
        
    public var lib : LiME;
    public function new( _lib:LiME ) { lib = _lib; }

        //direct_renderer_handle for drawing
    public var direct_renderer_handle : Dynamic;

    #if lime_html5
        public var requestAnimFrame : Dynamic;
        public var browser : BrowserLike;
        public var canvas_position : Dynamic;
    #end //lime_html5
    
    public function startup() { 

        #if lime_native

                //Set up the OpenGL View
            direct_renderer_handle = nme_direct_renderer_create();

                //Add this to the main stage, so it will render
            nme_doc_add_child( lib.view_handle, direct_renderer_handle );

                //Set this handle to the real view with a render function
            nme_direct_renderer_set( direct_renderer_handle, on_render );

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

            lime.gl.GL.nmeContext = direct_renderer_handle;

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
        //todo: more things?
    }
    
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

    public function render() {

        #if lime_html5
            on_render();
            _requestAnimFrame( lib.on_update );
            return true;
        #end      

        #if lime_native 
            nme_render_stage( lib.view_handle );
        #end //lime_native

    }

    public function on_render() {

        if( lib.host.render != null ) {
            lib.host.render();
        }
       
    } //on_render

    public function next_wake(f:Float = 0) {

        if(lib.shutting_down) return;

        #if lime_native
                //todo - sleep a tiny amount to not use 100% cpu
            nme_stage_set_next_wake( lib.view_handle , 0.001 );
        #end //lime_native
    }

//nme functions
#if lime_native
    private static var nme_render_stage             = Libs.load("nme","nme_render_stage", 1);
    private static var nme_doc_add_child            = Libs.load("nme","nme_doc_add_child", 2);
    private static var nme_direct_renderer_create   = Libs.load("nme","nme_direct_renderer_create", 0);
    private static var nme_direct_renderer_set      = Libs.load("nme","nme_direct_renderer_set", 2);
    private static var nme_stage_set_next_wake      = Libs.load("nme","nme_stage_set_next_wake", 2);    
#end //lime_native

} 

    