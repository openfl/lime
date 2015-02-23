package lime.ui;


class KeyModifier {
	//SDLMod
	public static inline var NONE  = 0x0000;
	public static inline var LSHIFT= 0x0001;
	public static inline var RSHIFT= 0x0002;
	public static inline var LCTRL = 0x0040;
	public static inline var RCTRL = 0x0080;
	public static inline var LALT  = 0x0100;
	public static inline var RALT  = 0x0200;
	public static inline var LMETA = 0x0400;
	public static inline var RMETA = 0x0800;
	public static inline var NUM   = 0x1000;
	public static inline var CAPS  = 0x2000;
	public static inline var MODE  = 0x4000;

	public static inline var CTRL  = (LCTRL|RCTRL);
	public static inline var SHIFT = (LSHIFT|RSHIFT);
	public static inline var ALT   = (LALT|RALT);
	public static inline var META  = (LMETA|RMETA);
}
