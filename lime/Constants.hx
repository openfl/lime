package lime;

    //Window constants
class Window {

	static public var FULLSCREEN      = 0x0001;
    static public var BORDERLESS      = 0x0002;
    static public var RESIZABLE       = 0x0004;
    static public var HARDWARE        = 0x0008;
    static public var VSYNC           = 0x0010;
    static public var HW_AA           = 0x0020;
    static public var HW_AA_HIRES     = 0x0060;
    static public var ALLOW_SHADERS   = 0x0080;
    static public var REQUIRE_SHADERS = 0x0100;
    static public var DEPTH_BUFFER    = 0x0200;
    static public var STENCIL_BUFFER  = 0x0400;
    
}

class SystemEvents {

    static public var char              = 1;
    static public var keydown           = 2;
    static public var keyup             = 3;
    static public var mousemove         = 4;
    static public var mousedown         = 5;
    static public var mouseclick        = 6;
    static public var mouseup           = 7;
    static public var resize            = 8;
    static public var poll              = 9;
    static public var quit              = 10;
    static public var focus             = 11;
    static public var shouldrotate      = 12;

    static public var redraw            = 14;
    static public var touchbegin        = 15;
    static public var touchmove         = 16;
    static public var touchend          = 17;
    static public var touchtap          = 18;
    static public var change            = 19;
    static public var activate          = 20;
    static public var deactivate        = 21;
    static public var gotinputfocus     = 22;
    static public var lostinputfocus    = 23;
    static public var joyaxismove       = 24;
    static public var joyballmove       = 25;
    static public var joyhatmove        = 26;
    static public var joybuttondown     = 27;
    static public var joybuttonup       = 28;
    static public var syswm             = 29;

}