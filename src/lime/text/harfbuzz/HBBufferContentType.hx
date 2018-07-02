package lime.text.harfbuzz;


@:enum abstract HBBufferContentType(Int) from Int to Int {
	
	public var INVALID = 0;
	public var UNICODE = 1;
	public var GLYPHS = 2;
	
}