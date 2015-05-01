package lime.graphics.cairo;


@:enum abstract Format(Int) {

	// must match cairo_format_t in cairo.h
	var ARGB32    = 0;
	var RGB24     = 1;
	var A8        = 2;
	var A1        = 3;
	var RGB16_565 = 4;
	var RGB30     = 5;

}

