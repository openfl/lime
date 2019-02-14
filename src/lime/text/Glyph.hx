package lime.text;

abstract Glyph(Int) from Int to Int from UInt to UInt
{
	public function new(i:Int)
	{
		this = i;
	}
}
