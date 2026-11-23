import haxe.macro.Context;
import haxe.macro.Expr;

/**
	Where this checkout of Lime is, taken from the class path when the tests are compiled,
	so the tests find Lime's templates without `haxelib` or `lime setup`.
**/
class LimeRepo
{
	public static macro function path():Expr
	{
		var source = sys.FileSystem.fullPath(Context.resolvePath("lime/tools/HXProject.hx"));
		var root = haxe.io.Path.normalize(haxe.io.Path.join([haxe.io.Path.directory(source), "..", "..", ".."]));
		return macro $v{root};
	}
}
