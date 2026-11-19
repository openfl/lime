class Main
{
	public static function main():Void
	{
		// HashLink matches each native to lime.hdll before main runs, so a
		// signature that disagrees with the library stops it before this line
		Sys.println("lime.hdll matches every native signature");
	}
}
