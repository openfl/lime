package system;

#if (lime_cffi && !macro && linux && !android)
import haxe.io.Path;
import lime.system.CFFI;
import sys.FileSystem;
import sys.io.File;
#end
import utest.Assert;
import utest.Test;

/**
	The Linux desktop and documents folders, which the desktop names in the user's language in
	$XDG_CONFIG_HOME/user-dirs.dirs, or ~/.config/user-dirs.dirs, as `XDG_DESKTOP_DIR="$HOME/Bureau"`
	(#1481). A folder is "$HOME/..." or an absolute path, in quotes, a line starting with # is a
	comment, and the last line for a folder wins. Without one, they are $HOME/Desktop and
	$HOME/Documents.

	`System.desktopDirectory` and `System.documentsDirectory` read each folder once and keep it, so
	these tests ask the native getter they read it from, with XDG_CONFIG_HOME set to a folder of
	their own.
**/
class UserDirectoryTest extends Test
{
	#if (lime_cffi && !macro && linux && !android)
	// SystemDirectory's DESKTOP and DOCUMENTS, as System passes them
	private static inline var DESKTOP = 2;
	private static inline var DOCUMENTS = 3;

	private var configHome:String;
	private var home:String;
	private var previousConfigHome:Null<String>;
	#end

	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro && linux && !android)
	public function setup():Void
	{
		home = Sys.getEnv("HOME");
		previousConfigHome = Sys.getEnv("XDG_CONFIG_HOME");

		var temp = Sys.getEnv("TMPDIR");
		if (temp == null || temp == "") temp = "/tmp";

		configHome = Path.join([temp, "lime-test-user-dirs-" + Std.random(0x3FFFFFFF)]);
		FileSystem.createDirectory(configHome);
		Sys.putEnv("XDG_CONFIG_HOME", configHome);
	}

	public function teardown():Void
	{
		Sys.putEnv("XDG_CONFIG_HOME", previousConfigHome);

		var file = Path.join([configHome, "user-dirs.dirs"]);
		if (FileSystem.exists(file)) FileSystem.deleteFile(file);
		FileSystem.deleteDirectory(configHome);
	}

	public function testADesktopUnderHomeIsTheDesktop():Void
	{
		write('XDG_DESKTOP_DIR="$$HOME/Bureau"');

		Assert.equals(home + "/Bureau", directory(DESKTOP));
		Assert.equals(home + "/Documents", directory(DOCUMENTS), "the documents folder, which the file doesn't name");
	}

	public function testAnAbsoluteDocumentsFolderIsTheDocumentsFolder():Void
	{
		var documents = Path.join([configHome, "Mes documents"]);
		write('XDG_DOCUMENTS_DIR="' + documents + '"');

		Assert.equals(documents, directory(DOCUMENTS));
	}

	public function testACommentedOutLineIsNotRead():Void
	{
		write('# XDG_DESKTOP_DIR="$$HOME/Bureau"');

		Assert.equals(home + "/Desktop", directory(DESKTOP));
	}

	public function testARelativeFolderIsNotRead():Void
	{
		write('XDG_DOCUMENTS_DIR="Mes documents"');

		Assert.equals(home + "/Documents", directory(DOCUMENTS));
	}

	public function testAFolderWithoutItsClosingQuoteIsNotRead():Void
	{
		write('XDG_DESKTOP_DIR="$$HOME/Bureau');

		Assert.equals(home + "/Desktop", directory(DESKTOP));
	}

	public function testTheLastLineForAFolderWins():Void
	{
		write('XDG_DESKTOP_DIR="$$HOME/Bureau"\nXDG_DESKTOP_DIR="$$HOME/Escritorio"');

		Assert.equals(home + "/Escritorio", directory(DESKTOP));
	}

	public function testWithoutTheFileTheFoldersHaveTheirEnglishNames():Void
	{
		Assert.equals(home + "/Desktop", directory(DESKTOP));
		Assert.equals(home + "/Documents", directory(DOCUMENTS));
	}

	private function write(lines:String):Void
	{
		File.saveContent(Path.join([configHome, "user-dirs.dirs"]), lines + "\n");
	}

	private static function directory(type:Int):String
	{
		return CFFI.stringValue(@:privateAccess lime._internal.backend.native.NativeCFFI.lime_system_get_directory(type, null, null));
	}
	#end
}
