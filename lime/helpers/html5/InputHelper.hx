package lime.helpers.html5;

import lime.InputHandler.GamepadEvent;
import lime.InputHandler.GamepadButtonEvent;
import lime.InputHandler.GamepadAxisEvent;
import lime.InputHandler.ButtonState;
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
        lib.window_handle.addEventListener('contextmenu', on_contextmenu );

            //mouse events bind to the lime element only, 
            //maybe this should be adjusted for mousemove?
        lib.window_handle.addEventListener('mousedown', on_mousedown);
        lib.window_handle.addEventListener('mousemove', on_mousemove);
        lib.window_handle.addEventListener('mouseup',   on_mouseup);

            //there are two kinds of scroll across browser, we handle both
        lib.window_handle.addEventListener('mousewheel',     on_mousewheel);
        lib.window_handle.addEventListener('DOMMouseScroll', on_mousewheel);

            //key input should be page wide, not just the lime element
        js.Browser.document.addEventListener('keydown', on_keydown);
        js.Browser.document.addEventListener('keyup',   on_keyup);

            //handle any gamepad information, if the browser supports it
        startup_gamepads();

    } //startup

    @:noCompletion public function update() {
        if(gamepads_supported) {
            poll_gamepads();
        }
    }

    function fail_gamepads() {
        gamepads_supported = false;
        trace("lime : Gamepads are not supported in this browser :(");
    }


        //if gamepads are supported, the method to get them will 
        //be stored in this variable for reuse
    var gamepads_supported : Bool = false;

    function startup_gamepads() {

        active_gamepads = new Map();
        gamepads_supported = (get_gamepad_list != null);

    }

    function poll_gamepads() {
        
        var list = get_gamepad_list();
        if(list != null) {
            for(i in 0 ... list.length) {
                if( untyped list[i] != null ) {
                    handle_gamepad( untyped list[i] );
                }
            }
        }

    } //poll_gamepads

        //this will take some liberties for now
        //because chrome and firefox share the same spec for 
        //the most part and all future implementations should
        //follow spec too. If the spec changes we can adjust if needed
    var active_gamepads : Map<Int, HTML5Gamepad>;

    function handle_gamepad( _gamepad : Dynamic ) {
            
            //disconnected gamepads we don't need
        if(_gamepad == null) return;

            //check if this gamepad exists already
        if( !active_gamepads.exists( _gamepad.index ) ) {

                //if not we add it to the list
            active_gamepads.set( _gamepad.index, {
                id : _gamepad.id,
                index : _gamepad.index,                
                axes : cast _gamepad.axes,                
                buttons : cast _gamepad.buttons,                
                timestamp : _gamepad.timestamp
            });

                //fire an on connected event
            //  :todo:

        } else {
            
                //found in the list so we can update it if anything changed
            var gamepad = active_gamepads.get(_gamepad.index);
                //but only if the timestamp differs
            if(gamepad.timestamp != _gamepad.timestamp) {

                    //update the id if it changed
                if(gamepad.id != _gamepad.id) { gamepad.id = _gamepad.id; }
                    //update the timestamp
                gamepad.timestamp = _gamepad.timestamp;

                    //we store the list of changed indices
                    //so we can call the handler functions with each
                var axes_changed : Array<Int> = []; 
                var buttons_changed : Array<Int> = []; 
                    //the last known values
                var last_axes = gamepad.axes;
                var last_buttons = gamepad.buttons;
                    
                    //the new known values                
                var new_axes : Array<Float> = cast _gamepad.axes;
                var new_buttons : Array<Int> = cast _gamepad.buttons;

                    //check for axes changes
                var axis_index : Int = 0;
                for(axis in new_axes) {
                    
                    if(axis != last_axes[axis_index]) {
                        axes_changed.push(axis_index);
                        gamepad.axes[axis_index] = axis;
                    }

                    axis_index++;

                } //axis in new_axes

                    //check for button changes
                var button_index : Int = 0;
                for(button in new_buttons) {
                    
                    if(button != last_buttons[button_index]) {
                        buttons_changed.push(button_index);
                        gamepad.buttons[button_index] = button;
                    }

                    button_index++;

                } //button in new_buttons


                    //now forward any axis changes to the wrapper
                for(index in axes_changed) {
                    
                    lib.input.lime_gamepadaxis({
                        raw : gamepad,                        
                        axis : index,
                        value : new_axes[index],
                        gamepad : gamepad.index
                    }, true);

                } //for each axis changed

                    //then forward any button changes to the wrapper
                for(index in buttons_changed) {
                    
                    var _state = (new_buttons[index] == 0) ? ButtonState.up : ButtonState.down;
                    var _gamepad_event : GamepadButtonEvent = {
                        raw : gamepad,                        
                        state : _state,
                        value : new_buttons[index],
                        button : index,
                        gamepad : gamepad.index
                    };

                    if(_state == ButtonState.up) {
                        lib.input.lime_gamepadbuttonup( _gamepad_event, true );
                    } else {
                        lib.input.lime_gamepadbuttondown( _gamepad_event, true );
                    }                    

                } //for each button change

            } //timestamp changed

        } //exists

    } //handle_gamepad

        //It's really early for gamepads in browser, 
        // but we can still support them where they exist
    function get_gamepad_list() : Dynamic {

                //Modernizr is used to detect gamepad support
            var modernizr = untyped js.Browser.window.Modernizr;
            if(modernizr != null) {

                if(modernizr.gamepads == true) {

                        //try official api first
                    if( untyped js.Browser.navigator.getGamepads != null ) {
                        return untyped js.Browser.navigator.getGamepads();
                    }

                        //try newer webkit GetGamepads() function
                    if( untyped js.Browser.navigator.webkitGetGamepads != null ) {
                        return untyped js.Browser.navigator.webkitGetGamepads();
                    }

                        //if we make it here we failed support so fail out
                    fail_gamepads();

                } else {

                    fail_gamepads();

                }

            } //modernizr != null

        return null;

    } //get_gamepad_list

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


typedef HTML5Gamepad = {
    axes : Array<Float>,
    index : Int,
    buttons : Array<Int>,
    id : String,
    timestamp : Float
}