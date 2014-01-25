package lime;

import lime.Lime;
import lime.RenderHandler;
import lime.helpers.Keys;

class InputHandler {

    public var lib : Lime;
    public var touch_map : Map<Int, Dynamic>;

        //this is a code/scan specific key repeate map
    public var keys_down : Map<Int, Bool>;
        //this is the enum based flags for keypressed/keyreleased/keydown
    public var key_value_down : Map<KeyValue, Bool>;
    public var key_value_pressed : Map<KeyValue, Bool>;
    public var key_value_released : Map<KeyValue, Bool>;

    public var last_mouse_x : Int = 0;
    public var last_mouse_y : Int = 0;
    
    public function new( _lib:Lime ) {

        lib = _lib; 

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

        lib._debug(':: lime :: \t InputHandler Initialized.');

        touch_map = new Map<Int, Dynamic>();
        keys_down = new Map();
    
        key_value_pressed = new Map();        
        key_value_down = new Map();
        key_value_released = new Map();

       #if lime_html5
            lime_apply_input_listeners();
       #end //lime_html5

    } //startup

    @:noCompletion public function shutdown() {
        
        lib._debug(':: lime :: \t InputHandler shut down.');

    } //shutdown

    @:noCompletion public function update() {

        for(_value in key_value_pressed.keys()){

            var _flag : Bool = key_value_pressed.get(_value);            
            if(_flag){
                key_value_pressed.remove(_value);
            } else {
                key_value_pressed.set(_value, true);
            }

        } //each pressed_value

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
                char : _event.char,
                value : _event.value,
                flags : _event.flags,
                key : lime.helpers.Keys.toKeyValue(_event)
            });
        }

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

    function mouse_button_from_id( id:Int ) : Dynamic {
        
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

        // trace("mouse moved, delta : " + deltaX + ' ' + deltaY);

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

            if(!_pass_through) {

               _mouse_event = {
                    raw : _event,
                    button : mouse_button_from_id(_event.value),
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
        touch_map.set( touch_item.ID, touch_item );

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

    } //lime_touchmove

    @:noCompletion public function lime_touchend(_event:Dynamic) : Void {  

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

    } //lime_touchend

    @:noCompletion public function lime_touchtap(_event:Dynamic) : Void {
        if(lib.host.ontouchtap != null) {
            lib.host.ontouchtap(_event);
        }
    } //lime_touchtap

//Gamepad

    @:noCompletion public function lime_gamepadaxis(_event:Dynamic) : Void {
        if(lib.host.ongamepadaxis != null) {
            lib.host.ongamepadaxis(_event);
        }
    } //lime_gamepadaxis

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

    @:noCompletion public function lime_gamepadbuttondown(_event:Dynamic) : Void {
        if(lib.host.ongamepadbuttondown != null) {
            lib.host.ongamepadbuttondown(_event);
        }
    } //lime_gamepadbuttondown

    @:noCompletion public function lime_gamepadbuttonup(_event:Dynamic) : Void {
        if(lib.host.ongamepadbuttonup != null) {
            lib.host.ongamepadbuttonup(_event);
        }
    } //lime_gamepadbuttonup

    function lime_apply_input_listeners() {

        #if lime_html5
            //on html5 we need to listen for events on the canvas
            //lib.window_handle = canvas element
            lib.window_handle.addEventListener('contextmenu', function(e){
                e.preventDefault();
            }); //contextmenu

            lib.window_handle.addEventListener('mousewheel', function(_event){

                var va = _event.wheelDelta;               
                var delta = Math.max(-1, Math.min(1, va));
                var wheel_dir = lime.InputHandler.MouseButton.wheel_down;
                if(delta < 1) {
                    wheel_dir = lime.InputHandler.MouseButton.wheel_up; 
                }
                    //todo:make inverted for mac only
                lime_mouseup({
                    raw : _event,
                    button : wheel_dir,
                    state : MouseState.down,
                    x : _event.pageX - lib.render.canvas_position.x,
                    y : _event.pageY - lib.render.canvas_position.y,
                    flags : 0,
                    ctrl_down : _event.ctrlKey,
                    alt_down : _event.altKey,
                    shift_down : _event.shiftKey,
                    meta_down : _event.metaKey
                }, true);

                _event.preventDefault();

            });

                lib.window_handle.addEventListener('DOMMouseScroll', function(_event){

                    var va = -_event.detail;             
                    var delta = Math.max(-1, Math.min(1, va));
                    var wheel_dir = lime.InputHandler.MouseButton.wheel_down;
                    if(delta < 1) {
                        wheel_dir = lime.InputHandler.MouseButton.wheel_up; 
                    }
                        //todo:make inverted for mac only
                    lime_mouseup({
                        raw : _event,
                        button : wheel_dir,
                        state : MouseState.down,
                        x : _event.pageX - lib.render.canvas_position.x,
                        y : _event.pageY - lib.render.canvas_position.y,
                        flags : 0,
                        ctrl_down : _event.ctrlKey,
                        alt_down : _event.altKey,
                        shift_down : _event.shiftKey,
                        meta_down : _event.metaKey
                    }, true);

                    _event.preventDefault();

                });

            lib.window_handle.addEventListener('mousedown', function(_event){

                _event.preventDefault();     

                lime_mousedown({
                    raw : _event,
                    button : mouse_button_from_id(_event.button),
                    state : MouseState.down,
                    x : _event.pageX - lib.render.canvas_position.x,
                    y : _event.pageY - lib.render.canvas_position.y,
                    flags : 0,
                    ctrl_down : _event.ctrlKey,
                    alt_down : _event.altKey,
                    shift_down : _event.shiftKey,
                    meta_down : _event.metaKey
                }, true); //mousedown, true to forward event directly

            }); //mousedown

            lib.window_handle.addEventListener('mousemove', function(_event){

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
                    default:
                        deltaX = 0;
                        deltaY = 0;
                }

                _event.preventDefault();

                lime_mousemove({
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
                }, true); //lime_mousemove

            }); //mousemove

            lib.window_handle.addEventListener('mouseup', function(_event){

                _event.preventDefault();

                lime_mouseup({
                    raw : _event,
                    button : mouse_button_from_id(_event.button),
                    state : MouseState.up,
                    x : _event.pageX - lib.render.canvas_position.x,
                    y : _event.pageY - lib.render.canvas_position.y,
                    flags : 0,
                    ctrl_down : _event.ctrlKey,
                    alt_down : _event.altKey,
                    shift_down : _event.shiftKey,
                    meta_down : _event.metaKey
                }, true); //lime_mouseup

            }); //mouseup

            js.Browser.document.addEventListener('keydown', function(e){
                if (e.keyCode >= 65 && e.keyCode <= 122) {
                    e.value = e.which;
                } else {
                    e.value = e.which;
                }
                
                lime_onkeydown(e);
            });
            js.Browser.document.addEventListener('keyup', function(e){
                if (e.keyCode >= 65 && e.keyCode <= 122) {
                    e.value = e.which;
                } else {
                    e.value = e.which;
                }

                lime_onkeyup(e);
            });
        #end //lime_html5    

    } //apply_input_listeners

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
}

