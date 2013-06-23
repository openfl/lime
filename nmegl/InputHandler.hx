package nmegl;

import nmegl.NMEGL;

class InputHandler {

    public var lib : NMEGL;
    public function new( _lib:NMEGL ) { lib = _lib; }

    public function startup() {
        lib._debug(':: NMEGL :: \t InputHandler Initialized.');
    }

    public function shutdown() {
        lib._debug(':: NMEGL :: \t InputHandler shut down.');
    }

    public function process() {
        
    }    

//Keyboard

    public function core_onchar(_event:Dynamic) {
        //if (onKey != null) {
        //  untyped onKey(_event.code, _event.down, _event.char, _event.flags);
        //}     
    }

    public function core_onkeydown(_event:Dynamic) {
        //nmeOnKey(_event, KeyboardEvent.KEY_DOWN);
    }

    public function core_onkeyup(_event:Dynamic) {
        //nmeOnKey(_event, KeyboardEvent.KEY_UP);
    }

    public function core_gotinputfocus(_event:Dynamic) {
        //var evt = new Event(FocusEvent.FOCUS_IN);
        //nmeDispatchEvent(evt);        
    }   

    public function core_lostinputfocus(_event:Dynamic) {
        //var evt = new Event(FocusEvent.FOCUS_OUT);
        //nmeDispatchEvent(evt);
    }

//Mouse
    
    public function core_mousemove(_event:Dynamic) {
        //nmeOnMouse(_event, MouseEvent.MOUSE_MOVE, true);
    }

    public function core_mousedown(_event:Dynamic) {
        //nmeOnMouse(_event, MouseEvent.MOUSE_DOWN, true);
    }

    public function core_mouseclick(_event:Dynamic) {
        //nmeOnMouse(_event, MouseEvent.CLICK, true);
    }

    public function core_mouseup(_event:Dynamic) {
        //nmeOnMouse(_event, MouseEvent.MOUSE_UP, true);
    }

//Touch

    
    public function core_touchbegin(_event:Dynamic) {
            //var touchInfo = new TouchInfo();
            //nmeTouchInfo.set(_event.value, touchInfo);
            //nmeOnTouch(_event, TouchEvent.TOUCH_BEGIN, touchInfo);
            //// trace("etTouchBegin : " + _event.value + "   " + _event.x + "," + _event.y+ " OBJ:" + _event.id + " sizeX:" + _event.sx + " sizeY:" + _event.sy );
            //if ((_event.flags & 0x8000) > 0)
            //  nmeOnMouse(_event, MouseEvent.MOUSE_DOWN, false);   
    }

    public function core_touchmove(_event:Dynamic) {
            //var touchInfo = nmeTouchInfo.get(_event.value);
             //nmeOnTouch(_event, TouchEvent.TOUCH_MOVE, touchInfo);        
    }

    public function core_touchend(_event:Dynamic) {
        //var touchInfo = nmeTouchInfo.get(_event.value);
        //nmeOnTouch(_event, TouchEvent.TOUCH_END, touchInfo);
        //nmeTouchInfo.remove(_event.value);
        //// trace("etTouchEnd : " + _event.value + "   " + _event.x + "," + _event.y + " OBJ:" + _event.id + " sizeX:" + _event.sx + " sizeY:" + _event.sy );
        //if ((_event.flags & 0x8000) > 0)
        //  nmeOnMouse(_event, MouseEvent.MOUSE_UP, false);     
    }

    public function core_touchtap(_event:Dynamic) {
        //nmeOnTouchTap(_event.TouchEvent.TOUCH_TAP);
    }

//Joystick

    public function core_joyaxismove(_event:Dynamic) {
        //nmeOnJoystick(_event, JoystickEvent.AXIS_MOVE);
    }

    public function core_joyballmove(_event:Dynamic) {
        //nmeOnJoystick(_event, JoystickEvent.BALL_MOVE);
    }

    public function core_joyhatmove(_event:Dynamic) {
        //nmeOnJoystick(_event, JoystickEvent.HAT_MOVE);
    }

    public function core_joybuttondown(_event:Dynamic) {
        //nmeOnJoystick(_event, JoystickEvent.BUTTON_DOWN);
    }

    public function core_joybuttonup(_event:Dynamic) {
        //nmeOnJoystick(_event, JoystickEvent.BUTTON_UP);
    }

}