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

#end //lime_html5


class RenderHandler {
        
    public var lib : LiME;
    public function new( _lib:LiME ) { lib = _lib; }

        //direct_renderer_handle for drawing
    public var direct_renderer_handle : Dynamic;

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
            
            direct_renderer_handle = lib.window_handle.getContext('webgl');
            lime.gl.GL.nmeContext = direct_renderer_handle;

        #end //lime_html5

            //Done.
        lib._debug(':: lime :: \t RenderHandler Initialized.');
    }


    public function shutdown() {
        lib._debug(':: lime :: \t RenderHandler shut down.');
    }

    public function render() {

        #if lime_html5
            on_render();
            js.Browser.window.requestAnimationFrame(lib.on_update);
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
       
    }

//nme functions
#if lime_native
    private static var nme_render_stage             = Libs.load("nme","nme_render_stage", 1);
    private static var nme_doc_add_child            = Libs.load("nme","nme_doc_add_child", 2);
    private static var nme_direct_renderer_create   = Libs.load("nme","nme_direct_renderer_create", 0);
    private static var nme_direct_renderer_set      = Libs.load("nme","nme_direct_renderer_set", 2);

#end //lime_native

} 

    