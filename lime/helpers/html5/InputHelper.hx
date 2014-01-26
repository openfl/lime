package lime.helpers.html5;

import lime.InputHandler.MouseButton;
import lime.InputHandler.MouseState;
import lime.RenderHandler.BrowserLike;

import lime.Lime;

class InputHelper {
 
    var lib : Lime;

    public function new( _lib:Lime ) {

        lib = _lib;

    } //new

    public function startup() {

           //right click on the canvas should be canceled on browser
        lib.window_handle.addEventListener('contextmenu',   on_contextmenu );

            //mouse events bind to the lime element only, 
            //maybe this should be adjusted for mousemove?
        lib.window_handle.addEventListener('mousedown',     on_mousedown);
        lib.window_handle.addEventListener('mousemove',     on_mousemove);
        lib.window_handle.addEventListener('mouseup',       on_mouseup);

            //there are two kinds of scroll across browser, we handle both
        lib.window_handle.addEventListener('mousewheel',     on_mousewheel);
        lib.window_handle.addEventListener('DOMMouseScroll', on_mousewheel);

            //key input should be page wide, not just the lime element
        js.Browser.document.addEventListener('keydown', on_keydown);
        js.Browser.document.addEventListener('keyup',   on_keyup);

    } //startup

    function on_contextmenu( _event:Dynamic ) {
        
        _event.preventDefault();

    } //on_contextmenu

    function translate_wheel_direction( _event:Dynamic ) : Int {

            //browser variations
        var detail = _event.detail;
        var wheelDelta = _event.wheelDelta;
            
            // :todo: make inverted for mac?
        if(detail != null && detail != 0) return detail;
        if(wheelDelta != null && wheelDelta != 0) return wheelDelta;

            //fallback
        return 0;

    } //translate_wheel_direction

    function on_mousewheel( _event:Dynamic ) {

            //prevent page scroll when using the wheel 
        _event.preventDefault();
            //figure out what kind of event direction this is            
        var direction = translate_wheel_direction(_event);
            //clamp to only one scroll at a time to handle discrepencies in browser
        var delta = Math.max(-1, Math.min(1, direction));
        
        var wheel_dir : MouseButton;

        if(delta < 1) {
            wheel_dir = MouseButton.wheel_up; 
        } else {
            wheel_dir = MouseButton.wheel_down;
        }

            //pass the event to the lib
        lib.input.lime_mousewheel({

            raw : _event,
            button : wheel_dir,
            state : MouseState.wheel,
            x : _event.pageX - lib.render.canvas_position.x,
            y : _event.pageY - lib.render.canvas_position.y,
            flags : 0,
            ctrl_down : _event.ctrlKey,
            alt_down : _event.altKey,
            shift_down : _event.shiftKey,
            meta_down : _event.metaKey

        }, true);

    } //on_mousewheel

    function on_mousedown( _event:Dynamic ){

        _event.preventDefault();     

        lib.input.lime_mousedown({

            raw : _event,
            button : lib.input.mouse_button_from_id(_event.button),
            state : MouseState.down,
            x : _event.pageX - lib.render.canvas_position.x,
            y : _event.pageY - lib.render.canvas_position.y,
            flags : 0,
            ctrl_down : _event.ctrlKey,
            alt_down : _event.altKey,
            shift_down : _event.shiftKey,
            meta_down : _event.metaKey

        }, true); //mousedown, true to forward event directly

    } //on_mousedown

    function on_mousemove( _event:Dynamic ) {

        var deltaX = untyped _event.movementX;
        var deltaY = untyped _event.movementY;
        
        switch(lib.render.browser) {

            case BrowserLike.chrome, BrowserLike.safari, BrowserLike.opera:
                deltaX = untyped _event.webkitMovementX;
                deltaY = untyped _event.webkitMovementY;

            case BrowserLike.firefox:
                deltaX = untyped _event.mozMovementX;
                deltaY = untyped _event.mozMovementY;

            case BrowserLike.ie:
                //?

            default:
                deltaX = 0;
                deltaY = 0;

        } //switch brower type

        _event.preventDefault();

        lib.input.lime_mousemove({

            raw : _event,
            button : MouseButton.move,
            state : MouseState.move,
            x : _event.pageX - lib.render.canvas_position.x,
            y : _event.pageY - lib.render.canvas_position.y,
            deltaX : deltaX,
            deltaY : deltaY,
            flags : 0,
            ctrl_down : _event.ctrlKey,
            alt_down : _event.altKey,
            shift_down : _event.shiftKey,
            meta_down : _event.metaKey

        }, true); 

    } //on_mousemove

    function on_mouseup( _event:Dynamic ) {

            _event.preventDefault();

            lib.input.lime_mouseup({

                raw : _event,
                button : lib.input.mouse_button_from_id(_event.button),
                state : MouseState.up,
                x : _event.pageX - lib.render.canvas_position.x,
                y : _event.pageY - lib.render.canvas_position.y,
                flags : 0,
                ctrl_down : _event.ctrlKey,
                alt_down : _event.altKey,
                shift_down : _event.shiftKey,
                meta_down : _event.metaKey

            }, true); 

    } //on_mouseup

    function on_keydown( _event:Dynamic )  {

        if (_event.keyCode >= 65 && _event.keyCode <= 122) {
            _event.value = _event.which;
        } else {
            _event.value = _event.which;
        }
        
        lib.input.lime_onkeydown( _event );

    } //on_keydown

    function on_keyup( _event:Dynamic ) {

        if( _event.keyCode >= 65 && _event.keyCode <= 122 ) {
            _event.value = _event.which;
        } else {
            _event.value = _event.which;
        }

        lib.input.lime_onkeyup( _event );
            
    } //on_keyup

} //InputHelper