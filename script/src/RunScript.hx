import haxe.io.Eof;
import haxe.Http;
import haxe.io.Path;
import haxe.Json;
import neko.Lib;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;


#if pathtools
import helpers.PathHelper;
import helpers.FileHelper;
#end 

import project.Haxelib;

class RunScript {
	
	public static function process_command( args:Array<String> ) {
			//fetch the commands
		var command = args[0];
		var data = args[1];
		var data2 = (args.length > 2) ? args[2] : '';

		#if pathtools
		switch(command) {
			
//create			
			case "create":

				var sample = data;
				var name = data2;

				var samples_path = PathHelper.getHaxelib (new Haxelib("luxe")) + 'project_templates/';
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
						trace(' - Done!');
					}
				} else {
					throw "Sample project not found at : " + sample_path;
				}

				return true;

//buildto
			case "copy":
				var target = data;
				var dest = data2;
					//lab copy html5 ~/Sven/Sites/out
				var bin_dir = (target == 'html5') ? 'bin/' + target + '/bin' : 'bin/' + target + '/cpp/bin/';
				var bin_path = cwd + bin_dir;

				if(FileSystem.exists(bin_path)) {
					trace(' - copying build output from ' + bin_path + ' to ' + dest);
					FileHelper.recursiveCopy(bin_path, dest);
					trace(' - Done!');
				} else {
					throw "Cannot copy build output, did you run build/test first? looking for : " + bin_path;
				}

				return true;
			default:
				return false;
		}#end

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
			
			#if pathtools
				Sys.println("\tcreate <sample> <?name> \n\t  Create a copy of <sample> inside present working directory");
				Sys.println("\tcopy <target> <output_folder> \n\t  Copy the bin folder for <target> to <output_folder>");
			#end

			Sys.println("");
			return 0;
		} //if we have enough args

		return 0;
	}
}
