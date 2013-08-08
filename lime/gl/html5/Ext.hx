package lime.gl.html5;


class Ext {

    public static function drawBuffers( n:Int, buffers:Int ){

    	if(ext_draw_buffers == null) {
    		ext_draw_buffers = GL.getExtension('EXT_draw_buffers');
    		if(ext_draw_buffers == null) {
    			ext_draw_buffers = GL.getExtension('WEBGL_draw_buffers');
    			if(ext_draw_buffers == null) {
    				throw "Attemping to use GL.Ext.drawBuffers when it is not found in this browser.";
    			}
    		}
    	}

        return ext_draw_buffers( n, buffers );
    }

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
    
    private static var ext_draw_buffers : Dynamic = null;
}

