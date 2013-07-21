package lime;

import lime.LiME;


class InputHandler {

    public var lib : LiME;
    public function new( _lib:LiME ) { lib = _lib; }

    public var touch_map:Map<Int, Dynamic>;
    public var down_keys : Map<Int,Bool>;

    public function startup() {
        lib._debug(':: lime :: \t InputHandler Initialized.');

        touch_map = new Map<Int, Dynamic>();
        down_keys = new Map();

        #if lime_html5
            //on html5 we need to listen for events on the canvas
            //lib.window_handle = canvas element
            lib.window_handle.addEventListener('contextmenu', function(e){
                e.preventDefault();
            }); //contextmenu

                //todo:better forward (more info passed on)
            lib.window_handle.addEventListener('mousedown', function(e){

                e.preventDefault();     

                lime_mousedown({
                    x:e.pageX - lib.render.canvas_position.x, 
                    y:e.pageY - lib.render.canvas_position.y, 
                    button:e.button
                }); //mousedown

            }); //mousedown

            lib.window_handle.addEventListener('mousemove', function(e){

                e.preventDefault();

                lime_mousemove({
                    x:e.pageX - lib.render.canvas_position.x, 
                    y:e.pageY - lib.render.canvas_position.y, 
                    button:e.button
                }); //lime_mousemove

            }); //mousemove

            lib.window_handle.addEventListener('mouseup', function(e){

                e.preventDefault();

                lime_mouseup({
                    x:e.pageX - lib.render.canvas_position.x, 
                    y:e.pageY - lib.render.canvas_position.y, 
                    button:e.button
                }); //lime_mouseup

            }); //mouseup

            js.Browser.document.addEventListener('keydown', function(e){
                if (e.keyCode >= 65 && e.keyCode <= 122) {
                    e.value = e.which+32;
                } else {
                    e.value = e.which;
                }
                
                lime_onkeydown(e);
            });
            js.Browser.document.addEventListener('keyup', function(e){
                if (e.keyCode >= 65 && e.keyCode <= 122) {
                    e.value = e.which+32;
                } else {
                    e.value = e.which;
                }

                lime_onkeyup(e);
            });
        #end //lime_html5
    }

    public function shutdown() {
        lib._debug(':: lime :: \t InputHandler shut down.');
    }

    public function process() {
        
    }    

//Keyboard

    public function lime_onchar(_event:Dynamic) {
        if(lib.host.onchar != null) {
            lib.host.onchar(_event);
        }

        lime_onkeydown(_event);
        //if (onKey != null) {
        //  untyped onKey(_event.code, _event.down, _event.char, _event.flags);
        //}     
    }

    
    public function lime_onkeydown(_event:Dynamic) {
        
        if(lib.host.onkeydown != null && !down_keys.exists(_event.value)) {
            down_keys.set(_event.value, true);
            lib.host.onkeydown(_event);
        }
        //nmeOnKey(_event, KeyboardEvent.KEY_DOWN);
    }

    public function lime_onkeyup(_event:Dynamic) {
        down_keys.remove(_event.value);
        if(lib.host.onkeyup != null) {
            lib.host.onkeyup(_event);
        }
        //nmeOnKey(_event, KeyboardEvent.KEY_UP);
    }

    public function lime_gotinputfocus(_event:Dynamic) {
        if(lib.host.ongotinputfocus != null) {
            lib.host.ongotinputfocus(_event);
        }
        //var evt = new Event(FocusEvent.FOCUS_IN);
        //nmeDispatchEvent(evt);        
    }   

    public function lime_lostinputfocus(_event:Dynamic) {
        if(lib.host.onlostinputfocus != null) {
            lib.host.onlostinputfocus(_event);
        }
        //var evt = new Event(FocusEvent.FOCUS_OUT);
        //nmeDispatchEvent(evt);
    }

//Mouse
    private function mouse_button_from_id(id:Int) : Dynamic {
        switch(id){
            case 0 : return MouseButton.left;
            case 1 : return MouseButton.middle;
            case 2 : return MouseButton.right;
            case 3 : return MouseButton.wheel_down;
            case 4 : return MouseButton.wheel_up;
            default : return id;
        }
    }

    public function lime_mousemove(_event:Dynamic) {        
        
        if(lib.host.onmousemove != null) {
            lib.host.onmousemove({
                button : MouseButton.move,
                state : MouseState.down,
                x : _event.x,
                y : _event.y,
                flags : _event.flags,
                ctrl_down :  (_event.flags & efCtrlDown > 0),
                alt_down :   (_event.flags & efAltDown > 0),
                shift_down : (_event.flags & efShiftDown > 0),
                meta_down :  (_event.flags & efCommandDown > 0)                
            });
        } //if host onmousemove

    } //lime_mousemove

    public function lime_mousedown(_event:Dynamic) {

        if(lib.host.onmousedown != null) {
            lib.host.onmousedown({
                button : mouse_button_from_id(_event.value),
                state : MouseState.down,
                x : _event.x,
                y : _event.y,
                flags : _event.flags,
                ctrl_down :  (_event.flags & efCtrlDown > 0),
                alt_down :   (_event.flags & efAltDown > 0),
                shift_down : (_event.flags & efShiftDown > 0),
                meta_down :  (_event.flags & efCommandDown > 0)
            });
        } //if host onmousedown
        
    } //lime_mousedown

    public function lime_mouseclick(_event:Dynamic) {
        if(lib.host.onmouseclick != null) {
            lib.host.onmouseclick({
                button : _event.value,
                state : MouseState.down,
                x : _event.x,
                y : _event.y,
                flags : _event.flags,
                ctrl_down :  (_event.flags & efCtrlDown > 0),
                alt_down :   (_event.flags & efAltDown > 0),
                shift_down : (_event.flags & efShiftDown > 0),
                meta_down :  (_event.flags & efCommandDown > 0)                
            });
        } //if host onmouseclick

    } //lime_mouseclick

    public function lime_mouseup(_event:Dynamic) {
        if(lib.host.onmouseup != null) {
            lib.host.onmouseup({
                button : mouse_button_from_id(_event.value),
                state : MouseState.up,
                x : _event.x,
                y : _event.y,
                flags : _event.flags,
                ctrl_down :  (_event.flags & efCtrlDown > 0),
                alt_down :   (_event.flags & efAltDown > 0),
                shift_down : (_event.flags & efShiftDown > 0),
                meta_down :  (_event.flags & efCommandDown > 0)                
            });
        } //if host onmouseup  

    } //lime_mouseup

//Touch

    public function lime_touchbegin(_event:Dynamic) {
 
        var touch_item = {
            state : TouchState.begin,
            flags : _event.flags,
            ID : _event.value,
            x : _event.x,
            y : _event.y
        };

            //store the touch in the set
        touch_map.set( touch_item.ID, touch_item );

            //forward to the host
        if(lib.host.ontouchbegin != null) {
            lib.host.ontouchbegin( touch_item );
        }

            //forward the down event
        if ((_event.flags & 0x8000) > 0) {
            lime_mousedown(_event);
        }

    }

    public function lime_touchmove(_event:Dynamic) {

            //Get the touch item from the set
        var touch_item = touch_map.get( _event.value );
            //Update the values
        touch_item.x = _event.x;
        touch_item.y = _event.y;
        touch_item.state = TouchState.move;
        touch_item.flags = _event.flags;

            //Call the host function
        if(lib.host.ontouchmove != null) {
            lib.host.ontouchmove(touch_item);
        }

    }

    public function lime_touchend(_event:Dynamic) {  

        //Get the touch item from the set
        var touch_item = touch_map.get( _event.value );
            //Update the values
        touch_item.x = _event.x;
        touch_item.y = _event.y;
        touch_item.state = TouchState.end;
        touch_item.flags = _event.flags;

        if(lib.host.ontouchend != null) {
            lib.host.ontouchend(touch_item);
        }

            //Forward the up event
        if ((_event.flags & 0x8000) > 0) {
            lime_mouseup(_event);
        }   

            //remove it from the map
        touch_map.remove(_event.value);

    }

    public function lime_touchtap(_event:Dynamic) {
        if(lib.host.ontouchtap != null) {
            lib.host.ontouchtap(_event);
        }
        //nmeOnTouchTap(_event.TouchEvent.TOUCH_TAP);
    }

//Joystick

    public function lime_joyaxismove(_event:Dynamic) {
        if(lib.host.onjoyaxismove != null) {
            lib.host.onjoyaxismove(_event);
        }
        //nmeOnJoystick(_event, JoystickEvent.AXIS_MOVE);
    }

    public function lime_joyballmove(_event:Dynamic) {
        if(lib.host.onjoyballmove != null) {
            lib.host.onjoyballmove(_event);
        }
        //nmeOnJoystick(_event, JoystickEvent.BALL_MOVE);
    }

    public function lime_joyhatmove(_event:Dynamic) {
        if(lib.host.onjoyhatmove != null) {
            lib.host.onjoyhatmove(_event);
        }
        //nmeOnJoystick(_event, JoystickEvent.HAT_MOVE);
    }

    public function lime_joybuttondown(_event:Dynamic) {
        if(lib.host.onjoybuttondown != null) {
            lib.host.onjoybuttondown(_event);
        }
        //nmeOnJoystick(_event, JoystickEvent.BUTTON_DOWN);
    }

    public function lime_joybuttonup(_event:Dynamic) {
        if(lib.host.onjoybuttonup != null) {
            lib.host.onjoybuttonup(_event);
        }
        //nmeOnJoystick(_event, JoystickEvent.BUTTON_UP);
    }

    
    private static var efLeftDown = 0x0001;
    private static var efShiftDown = 0x0002;
    private static var efCtrlDown = 0x0004;
    private static var efAltDown = 0x0008;
    private static var efCommandDown = 0x0010;


}


enum TouchState {
    begin;
    move;
    end;
}

enum MouseState {
    down;
    move;
    up;
}

enum MouseButton {
    move;
    left;
    middle;
    right;
    wheel_up;
    wheel_down;
}

typedef TouchEvent = {
    var state : TouchState;
    var flags : Int;
    var ID : Int;
    var x : Float;
    var y : Float;
};

typedef MouseEvent = { 
    var state : MouseState;
    var flags : Int;
    var button : MouseButton;
    var x : Float;
    var y : Float;
}

typedef GamepadEvent = { 

}

