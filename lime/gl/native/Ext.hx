package lime.gl.native;

import lime.utils.Libs;

class Ext {

    public static function drawBuffers( n:Int, buffers:Int ){ 
        #if luxe_gl_extensions
            return lime_gl_ext_draw_buffers( n, buffers );
        #end
    }

    private static function load(inName:String, inArgCount:Int):Dynamic {
        try {
            return Libs.load("lime", inName, inArgCount);
        } catch(e:Dynamic) {
            trace(e); return null;
        }
    } //load

    public static inline var COLOR_ATTACHMENT0     = 0x8CE0;
    public static inline var COLOR_ATTACHMENT1     = 0x8CE1;
    public static inline var COLOR_ATTACHMENT2     = 0x8CE2;
    public static inline var COLOR_ATTACHMENT3     = 0x8CE3;
    public static inline var COLOR_ATTACHMENT4     = 0x8CE4;
    public static inline var COLOR_ATTACHMENT5     = 0x8CE5;
    public static inline var COLOR_ATTACHMENT6     = 0x8CE6;
    public static inline var COLOR_ATTACHMENT7     = 0x8CE7;
    public static inline var COLOR_ATTACHMENT8     = 0x8CE8;
    public static inline var COLOR_ATTACHMENT9     = 0x8CE9;
    public static inline var COLOR_ATTACHMENT10    = 0x8CEA;
    public static inline var COLOR_ATTACHMENT11    = 0x8CEB;
    public static inline var COLOR_ATTACHMENT12    = 0x8CEC;
    public static inline var COLOR_ATTACHMENT13    = 0x8CED;
    public static inline var COLOR_ATTACHMENT14    = 0x8CEE;
    public static inline var COLOR_ATTACHMENT15    = 0x8CEF;

    public static inline var DRAW_BUFFER0          = 0x8825;
    public static inline var DRAW_BUFFER1          = 0x8826;
    public static inline var DRAW_BUFFER2          = 0x8827;
    public static inline var DRAW_BUFFER3          = 0x8828;
    public static inline var DRAW_BUFFER4          = 0x8829;
    public static inline var DRAW_BUFFER5          = 0x882A;
    public static inline var DRAW_BUFFER6          = 0x882B;
    public static inline var DRAW_BUFFER7          = 0x882C;
    public static inline var DRAW_BUFFER8          = 0x882D;
    public static inline var DRAW_BUFFER9          = 0x882E;
    public static inline var DRAW_BUFFER10         = 0x882F;
    public static inline var DRAW_BUFFER11         = 0x8830;
    public static inline var DRAW_BUFFER12         = 0x8831;
    public static inline var DRAW_BUFFER13         = 0x8832;
    public static inline var DRAW_BUFFER14         = 0x8833;
    public static inline var DRAW_BUFFER15         = 0x8834;

    public static inline var MAX_COLOR_ATTACHMENTS = 0x8CDF;
    public static inline var MAX_DRAW_BUFFERS      = 0x8824;

#if luxe_gl_extensions
    private static var lime_gl_ext_draw_buffers = load("lime_gl_ext_draw_buffers", 2);
#end 

}

