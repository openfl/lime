package lime.graphics.console; #if lime_console


@:enum abstract Primitive (cpp.UInt32) {

	var Point			= 0;
	var Line			= 1;
	var LineStrip		= 2;
	var Triangle		= 3;
	var TriangleStrip	= 4;
	
}


#else


enum Primitive {

	Point;
	Line;
	LineStrip;
	Triangle;
	TriangleStrip;

}


#end
