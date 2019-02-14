package;

import haxe.macro.Compiler;

class AliasScript
{
	public static function main()
	{
		var args = ["run", Compiler.getDefine("command")].concat(Sys.args());
		Sys.exit(Sys.command("haxelib", args));
	}
}
