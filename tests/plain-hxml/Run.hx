import sys.FileSystem;
import sys.io.File;
import sys.io.Process;

/**
	Builds a HashLink app with a plain hxml and runs it against the lime.hdll
	in ndll. Run it from this folder with `haxe --run Run`.
**/
class Run
{
	static inline var LIME = "../..";
	static inline var EXPECTED = "lime.hdll matches every native signature";

	public static function main():Void
	{
		var platform = switch (Sys.systemName())
		{
			case "Windows": "Windows64";
			case "Linux": "Linux64";
			case "Mac": isArm64() ? "MacArm64" : "Mac64";
			case other: fail('HashLink is not supported on $other');
		}

		if (FileSystem.exists("bin")) removeDirectory("bin");
		FileSystem.createDirectory("bin");

		if (Sys.command("haxe", ["build.hxml"]) != 0) fail("The plain hxml build failed");

		copyFile('$LIME/ndll/$platform/lime.hdll', "bin/lime.hdll");
		var runtime = '$LIME/templates/bin/hl/$platform';
		if (!FileSystem.exists(runtime)) fail('$runtime is missing, so HashLink has not been built for $platform');
		for (file in FileSystem.readDirectory(runtime))
		{
			if (!FileSystem.isDirectory('$runtime/$file')) copyFile('$runtime/$file', 'bin/$file');
		}

		var hl = "hl.exe";
		if (platform != "Windows64")
		{
			hl = "hl";
			Sys.command("chmod", ["+x", "bin/hl"]);
		}

		// The app runs from bin, where HashLink finds hlboot.dat and lime.hdll
		var cwd = Sys.getCwd();
		Sys.setCwd("bin");
		var process = new Process(haxe.io.Path.join([Sys.getCwd(), hl]), []);
		var output = process.stdout.readAll().toString() + process.stderr.readAll().toString();
		var code = process.exitCode();
		process.close();
		Sys.setCwd(cwd);

		Sys.println(StringTools.trim(output));
		if (code != 0 || output.indexOf(EXPECTED) == -1) fail('HashLink exited with $code before main ran');
		Sys.println("Plain hxml HashLink build loads lime.hdll");
	}

	static function isArm64():Bool
	{
		var process = new Process("uname", ["-m"]);
		var machine = StringTools.trim(process.stdout.readAll().toString());
		process.close();
		return machine == "arm64";
	}

	static function copyFile(source:String, destination:String):Void
	{
		if (!FileSystem.exists(source)) fail('$source does not exist');
		File.copy(source, destination);
	}

	static function removeDirectory(path:String):Void
	{
		for (file in FileSystem.readDirectory(path))
		{
			var child = '$path/$file';
			if (FileSystem.isDirectory(child)) removeDirectory(child) else FileSystem.deleteFile(child);
		}
		FileSystem.deleteDirectory(path);
	}

	static function fail(message:String):Dynamic
	{
		Sys.println(message);
		Sys.exit(1);
		return null;
	}
}
