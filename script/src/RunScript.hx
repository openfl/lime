import haxe.io.Eof;
import haxe.Http;
import haxe.io.Path;
import haxe.Json;
import neko.Lib;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

import helpers.*;
import project.Haxelib;

class RunScript {
	
	public static function process_command( args:Array<String> ) {
			//fetch the commands
		var command = args[0];
		var data = args[1];
		var data2 = (args.length > 2) ? args[2] : '';

		switch(command) {
			case "create":
				var sample = data;
				var name = data2;

				var samples_path = PathHelper.getHaxelib (new Haxelib ("haxelab")) + 'samples/';
				var sample_path = samples_path + sample + '/';

				if(FileSystem.exists(sample_path)) {
						//now check if they can make this here
					var output_folder = (name!='') ? name : sample;
					var output_path = cwd + output_folder;

					if(FileSystem.exists(output_path)) {
						throw "Cannot create `" + sample + "` here, as that folder already exists!";
					} else {
						trace(' - creating template at ' + output_path);
						FileHelper.recursiveCopy(sample_path, output_path);
						trace('Done!');
					}
				} else {
					throw "Sample project not found at : " + sample_path;
				}

				return true;
			default:
				return false;
		}

		return false;
	}

	public static var cwd : String = './';
	public static function main() {
			//take all args and forward them to build tools
		var args = Sys.args();
			//get the current folder
		cwd = args[args.length-1];
			//remove the CWD from the args
		args = args.splice(0,args.length-1);

		if(args.length-1 > 0) {

			var local_command = process_command(args);
			
			if(!local_command) {
				
					//make a full command line
				var full_args = [ "run", "openfl-tools" ].concat(args);
					//enforce the folder to the current on
				Sys.setCwd(cwd);
					//and then execute
				return Sys.command("haxelib", full_args);
			}

		} else {
			Sys.println("");
			Sys.println("  lime build tools 1.0.1");
			Sys.println("    commands : ");
			Sys.println("\ttest <target> \n\t  Build and run");
			Sys.println("\tbuild <target> \n\t  Build");
			Sys.println("\tcreate <sample> <?name> \n\t  Create a copy of <sample> inside pwd");
			Sys.println("");
			return 0;
		} //if we have enough args

		return 0;
	}
}
