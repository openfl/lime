package lime;

import lime.LiME;

class InputHandler {

    public var lib : LiME;
    public function new( _lib:LiME ) { lib = _lib; }

    public function startup() {
        lib._debug(':: lime :: \t InputHandler Initialized.');

        #if lime_html5
            //on html5 we need to listen for events on the canvas
            //lib.window_handle = canvas element
            lib.window_handle.addEventListener('contextmenu', function(e){
                e.preventDefault();
            });

            lib.window_handle.addEventListener('mousedown', function(e){
                e.preventDefault();
                lime_mousedown(e);
            });
            lib.window_handle.addEventListener('mousemove', function(e){
                e.preventDefault();
                lime_mousemove(e);
            });
            lib.window_handle.addEventListener('mouseup', function(e){
                e.preventDefault();
                lime_mouseup(e);
            });

            js.Browser.document.addEventListener('keydown', function(e){
                e.value = e.which+32;
                lime_onkeydown(e);
            });
            js.Browser.document.addEventListener('keyup', function(e){
                e.value = e.which+32;
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
        if(lib.host.onkeydown != null) {
            lib.host.onkeydown(_event);
        }
        //nmeOnKey(_event, KeyboardEvent.KEY_DOWN);
    }

    public function lime_onkeyup(_event:Dynamic) {
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
    
    public function lime_mousemove(_event:Dynamic) {        
        if(lib.host.onmousemove != null) {
            lib.host.onmousemove(_event);
        }
        //nmeOnMouse(_event, MouseEvent.MOUSE_MOVE, true);
    }

    public function lime_mousedown(_event:Dynamic) {
        if(lib.host.onmousedown != null) {
            lib.host.onmousedown(_event);
        }
        //nmeOnMouse(_event, MouseEvent.MOUSE_DOWN, true);
    }

    public function lime_mouseclick(_event:Dynamic) {
        if(lib.host.onmouseclick != null) {
            lib.host.onmouseclick(_event);
        }
        //nmeOnMouse(_event, MouseEvent.CLICK, true);
    }

    public function lime_mouseup(_event:Dynamic) {
        if(lib.host.onmouseup != null) {
            lib.host.onmouseup(_event);
        }
        //nmeOnMouse(_event, MouseEvent.MOUSE_UP, true);
    }

//Touch

    
    public function lime_touchbegin(_event:Dynamic) {
        if(lib.host.ontouchbegin != null) {
            lib.host.ontouchbegin(_event);
        }
            //var touchInfo = new TouchInfo();
            //nmeTouchInfo.set(_event.value, touchInfo);
            //nmeOnTouch(_event, TouchEvent.TOUCH_BEGIN, touchInfo);
            //// trace("etTouchBegin : " + _event.value + "   " + _event.x + "," + _event.y+ " OBJ:" + _event.id + " sizeX:" + _event.sx + " sizeY:" + _event.sy );
            //if ((_event.flags & 0x8000) > 0)
            //  nmeOnMouse(_event, MouseEvent.MOUSE_DOWN, false);   
    }

    public function lime_touchmove(_event:Dynamic) {
        if(lib.host.ontouchmove != null) {
            lib.host.ontouchmove(_event);
        }
            //var touchInfo = nmeTouchInfo.get(_event.value);
             //nmeOnTouch(_event, TouchEvent.TOUCH_MOVE, touchInfo);        
    }

    public function lime_touchend(_event:Dynamic) {
        if(lib.host.ontouchend != null) {
            lib.host.ontouchend(_event);
        }
        //var touchInfo = nmeTouchInfo.get(_event.value);
        //nmeOnTouch(_event, TouchEvent.TOUCH_END, touchInfo);
        //nmeTouchInfo.remove(_event.value);
        //// trace("etTouchEnd : " + _event.value + "   " + _event.x + "," + _event.y + " OBJ:" + _event.id + " sizeX:" + _event.sx + " sizeY:" + _event.sy );
        //if ((_event.flags & 0x8000) > 0)
        //  nmeOnMouse(_event, MouseEvent.MOUSE_UP, false);     
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

}