package lime;

import lime.Lime;
import lime.RenderHandler;
import lime.helpers.Keys;
import lime.helpers.InputHelper;

class InputHandler {

    public var lib : Lime;

        //the active touches at any point
    public var touches_active : Map<Int, Dynamic>;

        //this is a code/scan specific key repeat map
    public var keys_down : Map<Int, Bool>;
        //this is the enum based flags for keypressed/keyreleased/keydown
    public var key_value_down : Map<KeyValue, Bool>;
    public var key_value_pressed : Map<KeyValue, Bool>;
    public var key_value_released : Map<KeyValue, Bool>;
        //previous move x/y
    public var last_mouse_x : Int = 0;
    public var last_mouse_y : Int = 0;
        
        //input helper for diff platforms
    public var helper : InputHelper;

    public function new( _lib:Lime ) {

        lib = _lib; 

        helper = new InputHelper( lib );

    } //new

//Public facing API

//Down / Pressed / Released helpers

    public function keypressed( _value:KeyValue ) {
        return key_value_pressed.exists(_value);
    } //keypressed

    public function keyreleased( _value:KeyValue ) {
        return key_value_released.exists(_value);
    } //keyreleased

    public function keydown( _value:KeyValue ) {
       return key_value_down.exists(_value);
    } //keydown

//Internal API

    @:noCompletion public function startup() {

        #if debug
            lib._debug(':: lime :: \t InputHandler Initialized.');
        #end //debug

        touches_active = new Map<Int, Dynamic>();
        keys_down = new Map();
    
        key_value_pressed = new Map();        
        key_value_down = new Map();
        key_value_released = new Map();

       helper.startup();

    } //startup

    @:noCompletion public function shutdown() {
        
        #if debug
            lib._debug(':: lime :: \t InputHandler shut down.');
        #end //debug

    } //shutdown

    @:noCompletion public function update() {

            //update any helper stuff
        helper.update();

            //remove any stale key pressed value
            //unless it wasn't alive for a full frame yet,
            //then flag it so that it may be
        for(_value in key_value_pressed.keys()){

            var _flag : Bool = key_value_pressed.get(_value);            
            if(_flag){
                key_value_pressed.remove(_value);
            } else {
                key_value_pressed.set(_value, true);
            }

        } //each pressed_value

            //remove any stale key released value
            //unless it wasn't alive for a full frame yet,
            //then flag it so that it may be
        for(_value in key_value_released.keys()){

            var _flag : Bool = key_value_released.get(_value);            
            if(_flag){
                key_value_released.remove(_value);
            } else {
                key_value_released.set(_value, true);
            }

        } //each pressed_value

    } //update

//Keyboard

    @:noCompletion public function lime_onchar(_event:Dynamic) {

        if(lib.host.onchar != null) {
            lib.host.onchar({
                raw : _event,
                code : _event.code,
                char : _event.code,
                value : _event.value,
                flags : _event.flags,
                key : lime.helpers.Keys.toKeyValue(_event)
            });
        }

        _event.char = _event.code;

        lime_onkeydown( _event );
        
    } //lime_onchar

    
    @:noCompletion public function lime_onkeydown(_event:Dynamic) {

        if(lib.host.onkeydown != null && !keys_down.exists(_event.value)) {

            var _keyvalue = lime.helpers.Keys.toKeyValue(_event);
            
            keys_down.set(_event.value, true);

                //flag the key as pressed, but unprocessed (false)
            key_value_pressed.set(_keyvalue, false);
                //flag it as down, because keyup removes it
            key_value_down.set(_keyvalue, true);

                //some characters can come directly, not via the onchar,
                //but we want end user to only require one check,
                //if(event.char != 0) { //printable key } else { //other keys }
            if(_event.char == null) {
                _event.char = 0;
            }

            lib.host.onkeydown({
                raw : _event,
                code : _event.code,
                char : _event.char,
                value : _event.value,
                flags : _event.flags,
                key : _keyvalue,
                ctrl_down :  (_event.flags & efCtrlDown > 0),
                alt_down :   (_event.flags & efAltDown > 0),
                shift_down : (_event.flags & efShiftDown > 0),
                meta_down :  (_event.flags & efCommandDown > 0)
            });

        } //key is down and !repeated

    } //lime_onkeydown

    @:noCompletion public function lime_onkeyup(_event:Dynamic) {
        
        var _keyvalue = lime.helpers.Keys.toKeyValue(_event);

            //no longer flagged as down
        keys_down.remove(_event.value);    
            
            //flag it as released but unprocessed
        key_value_released.set(_keyvalue, false);
            //remove the down flag
        key_value_down.remove(_keyvalue);

            //pass to the host
        if(lib.host.onkeyup != null) {

            lib.host.onkeyup({
                raw : _event,
                code : _event.code,
                char : _event.char,
                value : _event.value,
                flags : _event.flags,
                key : _keyvalue,
                ctrl_down :  (_event.flags & efCtrlDown > 0),
                alt_down :   (_event.flags & efAltDown > 0),
                shift_down : (_event.flags & efShiftDown > 0),
                meta_down :  (_event.flags & efCommandDown > 0)
            });

        } //lib.host.onkeyup != null
        
    } //lime_onkeyup

    @:noCompletion public function lime_gotinputfocus(_event:Dynamic) {

            //pass to the host
        if(lib.host.ongotinputfocus != null) {

            lib.host.ongotinputfocus({
                raw : _event,
                code : _event.code,
                char : _event.char,
                value : _event.value,
                flags : _event.flags,
                key : lime.helpers.Keys.toKeyValue(_event),
                ctrl_down :  (_event.flags & efCtrlDown > 0),
                alt_down :   (_event.flags & efAltDown > 0),
                shift_down : (_event.flags & efShiftDown > 0),
                meta_down :  (_event.flags & efCommandDown > 0)
            });

        } //host.ongotinputfocus

    } //lime_onkeyup

    @:noCompletion public function lime_lostinputfocus(_event:Dynamic) {

            //pass to the host
        if(lib.host.onlostinputfocus != null) {

            lib.host.onlostinputfocus({
                raw : _event,
                code : _event.code,
                char : _event.char,
                value : _event.value,
                flags : _event.flags,
                key : lime.helpers.Keys.toKeyValue(_event),
                ctrl_down :  (_event.flags & efCtrlDown > 0),
                alt_down :   (_event.flags & efAltDown > 0),
                shift_down : (_event.flags & efShiftDown > 0),
                meta_down :  (_event.flags & efCommandDown > 0)
            });

        } //host.onlostinputfocus
        
    } //lime_lostinputfocus

//Mouse

    @:noCompletion public function mouse_button_from_id( id:Int ) : Dynamic {
        
        switch(id) {

            case 0 : return MouseButton.left;
            case 1 : return MouseButton.middle;
            case 2 : return MouseButton.right;
            case 3 : return MouseButton.wheel_down;
            case 4 : return MouseButton.wheel_up;

            default : return id;
        
        } //switch id

    } //mouse_button_from_id

    @:noCompletion public function lime_mousemove( _event:Dynamic, ?_pass_through:Bool=false ) : Void {
        
        var deltaX = _event.x - last_mouse_x;
        var deltaY = _event.y - last_mouse_y;

        last_mouse_x = _event.x;
        last_mouse_y = _event.y;

            //locked cursor gives us the delta directly from sdl
        #if lime_native
            if(lib.window.cursor_locked) {
                deltaX = _event.deltaX;
                deltaY = _event.deltaY;
            }
        #end //lime_native

        if(lib.host.onmousemove != null) {

            var _mouse_event = _event;

            if(!_pass_through) {

                _mouse_event = {
                    raw : _event,
                    button : MouseButton.move,
                    state : MouseState.down,
                    x : _event.x,
                    y : _event.y,
                    deltaX : deltaX,
                    deltaY : deltaY,
                    flags : _event.flags,
                    ctrl_down :  (_event.flags & efCtrlDown > 0),
                    alt_down :   (_event.flags & efAltDown > 0),
                    shift_down : (_event.flags & efShiftDown > 0),
                    meta_down :  (_event.flags & efCommandDown > 0)                
                };
            
            } //_pass_through

            lib.host.onmousemove( _mouse_event );

        } //if host onmousemove

    } //lime_mousemove

    @:noCompletion public function lime_mousedown( _event:Dynamic, ?_pass_through:Bool=false ) : Void {

        if(lib.host.onmousedown != null) {

            var _mouse_event = _event;

            if(!_pass_through) {

                _mouse_event = {
                    raw : _event,
                    button : mouse_button_from_id(_event.value),
                    state : MouseState.down,
                    x : _event.x,
                    y : _event.y,
                    flags : _event.flags,
                    ctrl_down :  (_event.flags & efCtrlDown > 0),
                    alt_down :   (_event.flags & efAltDown > 0),
                    shift_down : (_event.flags & efShiftDown > 0),
                    meta_down :  (_event.flags & efCommandDown > 0)
                }; //

            } //_pass_through

            lib.host.onmousedown( _mouse_event );

        } //if host onmousedown
        
    } //lime_mousedown

    @:noCompletion public function lime_mouseclick( _event:Dynamic, ?_pass_through:Bool=false ) : Void {
        
        if(lib.host.onmouseclick != null) {

            var _mouse_event = _event;

            if(!_pass_through) {

                _mouse_event = {
                    raw : _event,
                    button : _event.value,
                    state : MouseState.down,
                    x : _event.x,
                    y : _event.y,
                    flags : _event.flags,
                    ctrl_down :  (_event.flags & efCtrlDown > 0),
                    alt_down :   (_event.flags & efAltDown > 0),
                    shift_down : (_event.flags & efShiftDown > 0),
                    meta_down :  (_event.flags & efCommandDown > 0)                
                };          

            } //_pass_through

            lib.host.onmouseclick( _mouse_event );

        } //if host onmouseclick

    } //lime_mouseclick

    @:noCompletion public function lime_mouseup( _event:Dynamic, ?_pass_through:Bool=false ) : Void {
        
        if(lib.host.onmouseup != null) {

            var _mouse_event = _event;
            var _button = mouse_button_from_id(_event.value);

                //on native platforms, the wheel can come from mouseup events
                //so we watch for those and forward it to wheel instead
            if( _button == MouseButton.wheel_down || _button == MouseButton.wheel_up ) {
                
                return lime_mousewheel( _event, _pass_through);

            } //wheel event


            if(!_pass_through) {

               _mouse_event = {
                    raw : _event,
                    button : _button,
                    state : MouseState.up,
                    x : _event.x,
                    y : _event.y,
                    flags : _event.flags,
                    ctrl_down :  (_event.flags & efCtrlDown > 0),
                    alt_down :   (_event.flags & efAltDown > 0),
                    shift_down : (_event.flags & efShiftDown > 0),
                    meta_down :  (_event.flags & efCommandDown > 0)                
                };

            } //pass through

            
            lib.host.onmouseup( _mouse_event );

        } //if host onmouseup

    } //lime_mouseup

    @:noCompletion public function lime_mousewheel( _event:Dynamic, ?_pass_through:Bool=false ) : Void {
        
        if(lib.host.onmousewheel != null) {

            var _mouse_event = _event;

            if(!_pass_through) {

               _mouse_event = {
                    raw : _event,
                    button : mouse_button_from_id(_event.value),
                    state : MouseState.wheel,
                    x : _event.x,
                    y : _event.y,
                    flags : _event.flags,
                    ctrl_down :  (_event.flags & efCtrlDown > 0),
                    alt_down :   (_event.flags & efAltDown > 0),
                    shift_down : (_event.flags & efShiftDown > 0),
                    meta_down :  (_event.flags & efCommandDown > 0)                
                };

            } //pass through

            lib.host.onmousewheel( _mouse_event );

        } //if host onmouseup  

    } //lime_mousewheel

//Touch

    @:noCompletion public function lime_touchbegin(_event:Dynamic) : Void {
 
        var touch_item = {
            state : TouchState.begin,
            flags : _event.flags,
            ID : _event.value,
            x : _event.x,
            y : _event.y
        };

            //store the touch in the set
        touches_active.set( touch_item.ID, touch_item );

            //forward to the host
        if(lib.host.ontouchbegin != null) {
            lib.host.ontouchbegin( touch_item );
        }

            //forward the down event
        if ((_event.flags & 0x8000) > 0) {
            lime_mousedown(_event);
        }

    } //lime_touchbegin

    @:noCompletion public function lime_touchmove(_event:Dynamic) : Void {

            //Get the touch item from the set
        var touch_item = touches_active.get( _event.value );
            //Update the values
        touch_item.x = _event.x;
        touch_item.y = _event.y;
        touch_item.state = TouchState.move;
        touch_item.flags = _event.flags;

            //Call the host function
        if(lib.host.ontouchmove != null) {
            lib.host.ontouchmove(touch_item);
        }

    } //lime_touchmove

    @:noCompletion public function lime_touchend(_event:Dynamic) : Void {  

        //Get the touch item from the set
        var touch_item = touches_active.get( _event.value );
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
        touches_active.remove(_event.value);

    } //lime_touchend

    @:noCompletion public function lime_touchtap(_event:Dynamic) : Void {

        if(lib.host.ontouchtap != null) {
            lib.host.ontouchtap(_event);
        }

    } //lime_touchtap

//Gamepad

    @:noCompletion public function lime_gamepadaxis( _event:Dynamic, ?_pass_through:Bool=false ) : Void {
        
        if(lib.host.ongamepadaxis != null) {

            var _gamepad_event = _event;

            if(!_pass_through) {

                _gamepad_event = {
                    raw : _event,
                    axis : _event.code,
                    value : (_event.value / 32767),
                    gamepad : _event.id
                }

            } //pass through

            lib.host.ongamepadaxis( _gamepad_event );

        } //lib.host.ongamepadaxis != null

    } //lime_gamepadaxis

    @:noCompletion public function lime_gamepadbuttondown( _event:Dynamic, ?_pass_through:Bool=false ) : Void {
        
        if(lib.host.ongamepadbuttondown != null) {

            var _gamepad_event = _event;

            if(!_pass_through) {

                _gamepad_event = {
                    raw : _event,                        
                    state : ButtonState.down,
                    value : 0,
                    button : _event.code,
                    gamepad : _event.id
                };

            }

            lib.host.ongamepadbuttondown( _gamepad_event );

        }

    } //lime_gamepadbuttondown

    @:noCompletion public function lime_gamepadbuttonup( _event:Dynamic, ?_pass_through:Bool=false ) : Void {
        
        if(lib.host.ongamepadbuttonup != null) {
            
            var _gamepad_event = _event;

            if(!_pass_through) {

                _gamepad_event = {
                    raw : _event,
                    state : ButtonState.up,
                    value : 1,
                    button : _event.code,
                    gamepad : _event.id
                };

            }

            lib.host.ongamepadbuttonup( _gamepad_event );

        }

    } //lime_gamepadbuttonup

    @:noCompletion public function lime_gamepadball(_event:Dynamic) : Void {
        if(lib.host.ongamepadball != null) {
            lib.host.ongamepadball(_event);
        }
    } //lime_gamepadball

    @:noCompletion public function lime_gamepadhat(_event:Dynamic) : Void {
        if(lib.host.ongamepadhat != null) {
            lib.host.ongamepadhat(_event);
        }
    } //lime_gamepadhat
  
    public function lime_gamepaddeviceadded(_event:Dynamic) {
        if(lib.host.ongamepaddeviceadded != null) {
            lib.host.ongamepaddeviceadded(_event);
        }
    } //lime_gamepaddeviceadded

    public function lime_gamepaddeviceremoved(_event:Dynamic) {
        if(lib.host.ongamepaddeviceremoved != null) {
            lib.host.ongamepaddeviceremoved(_event);
        }
    } //lime_gamepaddeviceremoved

    private static var efLeftDown = 0x0001;
    private static var efShiftDown = 0x0002;
    private static var efCtrlDown = 0x0004;
    private static var efAltDown = 0x0008;
    private static var efCommandDown = 0x0010;

} //InputHandler


enum TouchState {
    begin;
    move;
    end;
}

enum MouseState {
    down;
    move;
    wheel;
    up;
}

enum ButtonState {
    down;
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

typedef KeyEvent = {
    var raw : Dynamic;
    var code : Int;
    var char : Int;
    var value : Int;
    var flags : Int;
    var key : lime.helpers.Keys.KeyValue;
    var shift_down : Bool;
    var ctrl_down : Bool;
    var alt_down : Bool;
    var meta_down : Bool;    
};

typedef TouchEvent = {
    var state : TouchState;
    var flags : Int;
    var ID : Int;
    var x : Float;
    var y : Float;
    var raw : Dynamic;
};

typedef MouseEvent = {
    var raw : Dynamic;
    var state : MouseState;
    var flags : Int;
    var button : MouseButton;
    var x : Float;
    var y : Float;
    var deltaX : Float;
    var deltaY : Float;
    var shift_down : Bool;
    var ctrl_down : Bool;
    var alt_down : Bool;
    var meta_down : Bool;
}

typedef GamepadEvent = { 
    var raw : Dynamic;
    var gamepad : Int;
}

typedef GamepadButtonEvent = { 
    var raw : Dynamic;
    var gamepad : Int;
    var button : Int;
    var value : Float;
    var state : ButtonState;
}

typedef GamepadAxisEvent = { 
    var raw : Dynamic;
    var gamepad : Int;
    var axis : Int;
    var value : Float;
}

