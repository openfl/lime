package nmegl;

import nmegl.NMEGL;
import nmegl.utils.Libs;

    //Import GL 
import nmegl.gl.GL;
import nmegl.gl.GLBuffer;
import nmegl.gl.GLProgram; 
    
    //utils
import nmegl.utils.Float32Array;

    //geometry
import nmegl.geometry.Matrix3D;

class RenderHandler {
        
    public var lib : NMEGL;
    public function new( _lib:NMEGL ) { lib = _lib; }

        //direct_renderer_handle for NME
    public var direct_renderer_handle : Dynamic;

    public function startup() {

            //Set up the OpenGL View
        direct_renderer_handle = nme_direct_renderer_create();

            //Add this to the main stage, so it will render
        nme_doc_add_child( lib.stage_handle, direct_renderer_handle );

            //Set this handle to the real view with a render function
        nme_direct_renderer_set( direct_renderer_handle, on_render );        

            //Done.
        lib._debug(':: NMEGL :: \t RenderHandler Initialized.');
    }

    public function shutdown() {
        lib._debug(':: NMEGL :: \t RenderHandler shut down.');
    }

    public function on_render() {
        if( lib.host.render != null ) {
            lib.host.render();
        }
    }

//nme functions
    private static var nme_doc_add_child            = Libs.load("nme","nme_doc_add_child", 2);
    private static var nme_direct_renderer_create   = Libs.load("nme","nme_direct_renderer_create", 0);
    private static var nme_direct_renderer_set      = Libs.load("nme","nme_direct_renderer_set", 2);

} 

    