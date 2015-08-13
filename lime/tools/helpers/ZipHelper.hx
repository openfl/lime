package lime.tools.helpers;


import haxe.io.Bytes;
import haxe.io.Path;
import haxe.zip.Entry;
import haxe.zip.Writer;
import sys.io.File;
import sys.FileSystem;


class ZipHelper {
	
	
	public static function compress (path:String, targetPath:String = ""):Void {
		
		if (targetPath == "") {
			
			targetPath = path;
			
		}
		
		PathHelper.mkdir (Path.directory (targetPath));
		
		if (PlatformHelper.hostPlatform == WINDOWS || !FileSystem.isDirectory (path)) {
			
			var files = new List <Entry> ();
			
			if (FileSystem.isDirectory (path)) {
				
				readDirectory (path, "", files);
				
			} else {
				
				readFile (path, "", files);
				
			}
			
			var output = File.write (targetPath, true);
			
			/*if (Path.extension (path) == "crx") {
				
				var input = File.read (defines.get ("KEY_STORE"), true);
				var publicKey:Bytes = input.readAll ();
				input.close ();
				
				var signature = SHA1.encode ("this isn't working");
				
				output.writeString ("Cr24"); // magic number
				output.writeInt32 (Int32.ofInt (2)); // CRX file format version
				output.writeInt32 (Int32.ofInt (publicKey.length)); // public key length
				output.writeInt32 (Int32.ofInt (signature.length)); // signature length
				output.writeBytes (publicKey, 0, publicKey.length);
				output.writeString (signature);
				
				//output.writeBytes (); // public key contents "The contents of the author's RSA public key, formatted as an X509 SubjectPublicKeyInfo block. "
				//output.writeBytes (); // "The signature of the ZIP content using the author's private key. The signature is created using the RSA algorithm with the SHA-1 hash function."
				
			}*/
			
			LogHelper.info ("", " - \x1b[1mWriting file:\x1b[0m " + targetPath);
			
			var writer = new Writer (output);
			writer.write (cast files);
			output.close ();
			
		} else {
			
			ProcessHelper.runCommand (path, "zip", [ "-r", PathHelper.relocatePath (targetPath, path), "./" ]);
			
		}
		
	}
	
	
	private static function readDirectory (basePath:String, path:String, files:List<Entry>):Void {
		
		var directory = PathHelper.combine (basePath, path);
		
		for (file in FileSystem.readDirectory (directory)) {
			
			var fullPath = PathHelper.combine (directory, file);
			var childPath = PathHelper.combine (path, file);
			
			if (FileSystem.isDirectory (fullPath)) {
				
				readDirectory (basePath, childPath, files);
				
			} else {
				
				readFile (basePath, childPath, files);
				
			}
			
		}
		
	}
	
	
	private static function readFile (basePath:String, path:String, files:List<Entry>):Void {
		
		if (Path.extension (path) != "zip" && Path.extension (path) != "crx" && Path.extension (path) != "wgt") {
			
			var fullPath = PathHelper.combine (basePath, path);
			
			var name = path;
			//var date = FileSystem.stat (directory + "/" + file).ctime;
			var date = Date.now ();
			
			LogHelper.info ("", " - \x1b[1mCompressing file:\x1b[0m " + fullPath);
			
			var input = File.read (fullPath, true);
			var data = input.readAll ();
			input.close ();
			
			var entry:Entry = { fileName:name, fileSize:data.length, fileTime:date, compressed:false, dataSize:data.length, data:data, crc32:null };
			
			files.push (entry);
			
		}
		
	}
	

}
