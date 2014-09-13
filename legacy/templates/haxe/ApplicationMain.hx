import ::APP_MAIN::;

import lime.Lime;

class ApplicationMain {
        
    public static var _main_ : ::APP_MAIN::;
    public static var _lime : Lime;

    public static function main () {
            //Create the runtime
        _lime = new Lime();
            //Create the app class, give it to the bootstrapper
        _main_ = new ::APP_MAIN::();

        var config : LimeConfig = {
            host            : _main_,
            fullscreen      : ::WIN_FULLSCREEN::,
            resizable       : ::WIN_RESIZABLE::,
            borderless      : ::WIN_BORDERLESS::,
            antialiasing    : Std.int(::WIN_ANTIALIASING::),
            stencil_buffer  : ::WIN_STENCIL_BUFFER::,
            depth_buffer    : ::WIN_DEPTH_BUFFER::,
            vsync           : ::WIN_VSYNC::,
            fps             : Std.int(::WIN_FPS::),
            width           : Std.int(::WIN_WIDTH::), 
            height          : Std.int(::WIN_HEIGHT::), 
            orientation     : "::WIN_ORIENTATION::",
            title           : "::APP_TITLE::",
        };

            //Start up
        _lime.init( _main_, config );
    }
    
}