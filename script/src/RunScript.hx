import haxe.io.Eof;
import haxe.Http;
import haxe.io.Path;
import haxe.Json;
import neko.Lib;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;


class RunScript {	
	public static function main() {
			//take all args and forward them to build tools
		var args = Sys.args();
			//get the current folder
		var cwd = args[args.length-1];
			//remove it from the used args
		args = args.splice(0,args.length-1);
			//make a full command line
		var full_args = [ "run", "openfl-tools" ].concat(args);
			//enforce the folder to the current on
		Sys.setCwd(cwd);
			//and then execute
		return Sys.command("haxelib", full_args);
	}
}
