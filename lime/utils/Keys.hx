package lime.utils;

enum KeyValue {
    unknown;
    backspace;
    tab;
    enter;
    meta;
    shift;
    leftctrl;
    leftalt;
    capslock;
    escape;
    space;

    left;
    up;
    right;
    down;

    key_0; 
    key_1;
    key_2;
    key_3;
    key_4;
    key_5;
    key_6;
    key_7;
    key_8;
    key_9;

    key_A;
    key_B;
    key_C;
    key_D;
    key_E;
    key_F;
    key_G;
    key_H;
    key_I;
    key_J;
    key_K;
    key_L;
    key_M;
    key_N;
    key_O;
    key_P;
    key_Q;
    key_R;
    key_S;
    key_T;
    key_U;
    key_V;
    key_W;
    key_X;
    key_Y;
    key_Z;

    equals;
    minus;
    tilde;
}

class Keys {

    static inline var _backspace: Int = 8;
    static inline var _tab      : Int = 9;
    static inline var _enter    : Int = 13;
    static inline var _meta     : Int = 15;
    static inline var _shift    : Int = 16;
    static inline var _leftctrl : Int = 17;
    static inline var _leftalt  : Int = 18;
    static inline var _capslock : Int = 19;
    static inline var _escape   : Int = 27;
    static inline var _space    : Int = 32;

    static inline var _left     : Int = 37;
    static inline var _up       : Int = 38;
    static inline var _right    : Int = 39;    
    static inline var _down     : Int = 40;

    static inline var _key_0 : Int = 48;
    static inline var _key_1 : Int = 49;
    static inline var _key_2 : Int = 50;
    static inline var _key_3 : Int = 51;
    static inline var _key_4 : Int = 52;
    static inline var _key_5 : Int = 53;
    static inline var _key_6 : Int = 54;
    static inline var _key_7 : Int = 55;
    static inline var _key_8 : Int = 56;
    static inline var _key_9 : Int = 57;

    static inline var _key_A : Int = 97;
    static inline var _key_B : Int = 98;
    static inline var _key_C : Int = 99;
    static inline var _key_D : Int = 100;
    static inline var _key_E : Int = 101;
    static inline var _key_F : Int = 102;
    static inline var _key_G : Int = 103;
    static inline var _key_H : Int = 104;
    static inline var _key_I : Int = 105;
    static inline var _key_J : Int = 106;
    static inline var _key_K : Int = 107;
    static inline var _key_L : Int = 108;
    static inline var _key_M : Int = 109;
    static inline var _key_N : Int = 110;
    static inline var _key_O : Int = 111;
    static inline var _key_P : Int = 112;
    static inline var _key_Q : Int = 113;
    static inline var _key_R : Int = 114;
    static inline var _key_S : Int = 115;
    static inline var _key_T : Int = 116;
    static inline var _key_U : Int = 117;
    static inline var _key_V : Int = 118;
    static inline var _key_W : Int = 119;
    static inline var _key_X : Int = 120;
    static inline var _key_Y : Int = 121;
    static inline var _key_Z : Int = 122;

    static inline var _equals   : Int = 187;
    static inline var _minus    : Int = 189;
    static inline var _tilde    : Int = 192;

    public var tab 		: Int = _tab;
    public var enter 	: Int = _enter;
    public var meta 	: Int = _meta;
    public var shift 	: Int = _shift;
    public var leftctrl : Int = _leftctrl;
    public var leftalt  : Int = _leftalt;
    public var capslock : Int = _capslock;
    public var escape   : Int = _escape;
    public var space 	: Int = _space;

    public var left 	: Int = _left;
    public var up 		: Int = _up;
    public var right 	: Int = _right;    
    public var down 	: Int = _down;

    public var key_0 : Int = _key_0;
    public var key_1 : Int = _key_1;
    public var key_2 : Int = _key_2;
    public var key_3 : Int = _key_3;
    public var key_4 : Int = _key_4;
    public var key_5 : Int = _key_5;
    public var key_6 : Int = _key_6;
    public var key_7 : Int = _key_7;
    public var key_8 : Int = _key_8;
    public var key_9 : Int = _key_9;

    public var key_A : Int = _key_A;
    public var key_B : Int = _key_B;
    public var key_C : Int = _key_C;
    public var key_D : Int = _key_D;
    public var key_E : Int = _key_E;
    public var key_F : Int = _key_F;
    public var key_G : Int = _key_G;
    public var key_H : Int = _key_H;
    public var key_I : Int = _key_I;
    public var key_J : Int = _key_J;
    public var key_K : Int = _key_K;
    public var key_L : Int = _key_L;
    public var key_M : Int = _key_M;
    public var key_N : Int = _key_N;
    public var key_O : Int = _key_O;
    public var key_P : Int = _key_P;
    public var key_Q : Int = _key_Q;
    public var key_R : Int = _key_R;
    public var key_S : Int = _key_S;
    public var key_T : Int = _key_T;
    public var key_U : Int = _key_U;
    public var key_V : Int = _key_V;
    public var key_W : Int = _key_W;
    public var key_X : Int = _key_X;
    public var key_Y : Int = _key_Y;
    public var key_Z : Int = _key_Z;

    public var equals 	: Int = _equals;
    public var minus 	: Int = _minus;
    public var tilde 	: Int = _tilde;

    public function new() {}
    public static function toKeyValue(_value:Int) : KeyValue {
        switch(_value) {
            case _backspace:
                return KeyValue.backspace;
            case _tab:
                return KeyValue.tab;
            case _enter:
                return KeyValue.enter;
            case _meta:
                return KeyValue.meta;
            case _shift:
                return KeyValue.shift;
            case _leftctrl:
                return KeyValue.leftctrl;
            case _leftalt:
                return KeyValue.leftalt;
            case _capslock:
                return KeyValue.capslock;
            case _escape:
                return KeyValue.escape;
            case _space:
                return KeyValue.space;

            case _left:
                return KeyValue.left;
            case _up:
                return KeyValue.up;
            case _right:
                return KeyValue.right;
            case _down:
                return KeyValue.down;

            case _key_0:
                return KeyValue.key_0; 
            case _key_1:
                return KeyValue.key_1;
            case _key_2:
                return KeyValue.key_2;
            case _key_3:
                return KeyValue.key_3;
            case _key_4:
                return KeyValue.key_4;
            case _key_5:
                return KeyValue.key_5;
            case _key_6:
                return KeyValue.key_6;
            case _key_7:
                return KeyValue.key_7;
            case _key_8:
                return KeyValue.key_8;
            case _key_9:
                return KeyValue.key_9;

            case _key_A:
                return KeyValue.key_A;
            case _key_B:
                return KeyValue.key_B;
            case _key_C:
                return KeyValue.key_C;
            case _key_D:
                return KeyValue.key_D;
            case _key_E:
                return KeyValue.key_E;
            case _key_F:
                return KeyValue.key_F;
            case _key_G:
                return KeyValue.key_G;
            case _key_H:
                return KeyValue.key_H;
            case _key_I:
                return KeyValue.key_I;
            case _key_J:
                return KeyValue.key_J;
            case _key_K:
                return KeyValue.key_K;
            case _key_L:
                return KeyValue.key_L;
            case _key_M:
                return KeyValue.key_M;
            case _key_N:
                return KeyValue.key_N;
            case _key_O:
                return KeyValue.key_O;
            case _key_P:
                return KeyValue.key_P;
            case _key_Q:
                return KeyValue.key_Q;
            case _key_R:
                return KeyValue.key_R;
            case _key_S:
                return KeyValue.key_S;
            case _key_T:
                return KeyValue.key_T;
            case _key_U:
                return KeyValue.key_U;
            case _key_V:
                return KeyValue.key_V;
            case _key_W:
                return KeyValue.key_W;
            case _key_X:
                return KeyValue.key_X;
            case _key_Y:
                return KeyValue.key_Y;
            case _key_Z:
                return KeyValue.key_Z;

            case _equals:
                return KeyValue.equals;
            case _minus:
                return KeyValue.minus;
            case _tilde:
                return KeyValue.tilde;

        } //switch

        return KeyValue.unknown;

    } //toKeyValue

} //Keys