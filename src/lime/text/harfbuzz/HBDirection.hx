package lime.text.harfbuzz;


@:enum abstract HBDirection(Int) from Int to Int {
	
	public var INVALID = 0;
	public var LTR = 4;
	public var RTL = 5;
	public var TTB = 6;
	public var BTT = 7;
	
}