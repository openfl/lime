package snake.http;

import haxe.Exception;
import haxe.io.Input;
import haxe.io.Output;
import haxe.io.Path;
import snake.socket.BaseServer;
import sys.FileSystem;
import sys.io.File;
import sys.io.FileInput;
import sys.net.Host;
#if (eval && (haxe_ver >= 4.2))
import snake._internal.net.Socket as Socket;
#else
import sys.net.Socket;
#end

class SimpleHTTPRequestHandler extends BaseHTTPRequestHandler {
	private var directory:String;
	private var extensionsMap:Map<String, String> = [
		'.gz' => 'application/gzip',
		'.Z' => 'application/octet-stream',
		'.bz2' => 'application/x-bzip2',
		'.xz' => 'application/x-xz',
	];
	private var indexPages:Array<String> = ["index.html", "index.htm"];

	/**
		Constructor.
	**/
	public function new(request:Socket, clientAddress:{host:Host, port:Int}, server:BaseServer, ?directory:String) {
		this.directory = directory;
		super(request, clientAddress, server);
	}

	override private function setup():Void {
		super.setup();
		if (directory == null) {
			directory = Sys.getCwd();
		} else if (!Path.isAbsolute(directory)) {
			directory = Path.join([Sys.getCwd(), directory]);
		}
		if (!FileSystem.exists(directory)) {
			throw new Exception("directory does not exist");
		}
		if (!FileSystem.isDirectory(directory)) {
			throw new Exception("not a directory");
		}
		serverVersion = 'SimpleHTTP/${BaseHTTPRequestHandler.getLibraryVersion()}';
		commandHandlers.set("GET", do_GET);
		commandHandlers.set("HEAD", do_HEAD);
	}

	/**
		Serve a GET request.
	**/
	private function do_GET():Void {
		var f = sendHead();
		if (f != null) {
			try {
				copyFile(f, wfile);
			} catch (e:Exception) {
				// haxe doesn't have finally, so we need to close the input
				// and rethrow the exception
				f.close();
				throw e;
			}
			f.close();
		}
	}

	/**
		Serve a HEAD request.
	**/
	private function do_HEAD():Void {
		var f = sendHead();
		if (f != null) {
			f.close();
		}
	}

	/**
		Common code for GET and HEAD commands.

		This sends the response code and MIME headers.

		Return value is either a file object (which has to be copied
		to the outputfile by the caller unless the command was HEAD,
		and must be closed by the caller under all circumstances), or
		None, in which case the caller has nothing further to do.
	**/
	private function sendHead():Input {
		var translatedPath = translatePath(path);
		var f:FileInput = null;
		if (FileSystem.exists(translatedPath) && FileSystem.isDirectory(translatedPath)) {
			if (!StringTools.endsWith(translatedPath, "/")) {
				// redirect browser - doing basically what apache does
				sendResponse(HTTPStatus.MOVED_PERMANENTLY);
				// TODO: this may not be what Python is actually doing
				var newURL = translatedPath.substr(0, translatedPath.length - 1);
				sendHeader("Location", newURL);
				sendHeader("Content-Length", "0");
				endHeaders();
				return null;
			}
			var foundIndexPage = false;
			for (index in indexPages) {
				index = Path.join([translatedPath, index]);
				if (FileSystem.exists(translatedPath)) {
					translatedPath = index;
					foundIndexPage = true;
					break;
				}
			}
			if (!foundIndexPage) {
				return listDirectory(translatedPath);
			}
		}
		var ctype = guessType(translatedPath);

		// check for trailing "/" which should return 404. See Issue17324
		// The test for this was added in test_httpserver.py
		// However, some OS platforms accept a trailingSlash as a filename
		// See discussion on python-dev and Issue34711 regarding
		// parsing and rejection of filenames with a trailing slash
		if (StringTools.endsWith(translatedPath, "/")) {
			sendError(HTTPStatus.NOT_FOUND, "File not found");
			return null;
		}

		try {
			f = File.read(translatedPath, true);
		} catch (e:Exception) {
			sendError(HTTPStatus.NOT_FOUND, "File not found");
			return null;
		}

		try {
			var fs = FileSystem.stat(translatedPath);
			sendResponse(HTTPStatus.OK);
			sendHeader("Content-type", ctype);
			sendHeader("Content-Length", Std.string(fs.size));
			sendHeader("Last-Modified", dateTimeString(fs.mtime));
			endHeaders();
			return f;
		} catch (e:Exception) {
			f.close();
			throw e;
		}
	}

	/**
		Helper to produce a directory listing (absent index.html).

		Return value is either a file object, or None (indicating an
		error).  In either case, the headers are sent, making the
		interface the same as for sendHead().
	**/
	private function listDirectory(translatedPath:String):Input {
		// TODO: implement directory listing
		sendError(HTTPStatus.NOT_FOUND, "File not found");
		return null;
	}

	/**
		Translate a /-separated PATH to the local filename syntax.

		Components that mean special things to the local file system
		(e.g. drive or directory names) are ignored.  (XXX They should
		probably be diagnosed.)
	**/
	private function translatePath(path:String):String {
		// abandon query parameters
		var queryIndex = path.indexOf("?");
		if (queryIndex != -1) {
			path = path.substr(0, queryIndex);
		}
		var hashIndex = path.indexOf("#");
		if (hashIndex != -1) {
			path = path.substr(0, hashIndex);
		}
		// Don't forget explicit trailing slash when normalizing. Issue17324
		var trailingSlash = StringTools.endsWith(path, "/");
		if (trailingSlash) {
			path = path.substr(0, path.length - 1);
		}
		path = Path.normalize(path);
		var words = path.split('/');
		words = words.filter(word -> word.length > 0);
		path = directory;
		for (word in words) {
			if (word == "." || word == "..") {
				// Ignore components that are not a simple file/directory name
				continue;
			}
			var dirname = Path.directory(word);
			if (dirname == "." || dirname == "..") {
				continue;
			}
			path = Path.join([path, word]);
		}
		if (trailingSlash) {
			path += "/";
		}
		return path;
	}

	private function copyFile(src:Input, dst:Output):Void {
		dst.writeInput(src);
	}

	private function guessType(path:String):String {
		var ext = '.' + Path.extension(path);
		if (extensionsMap.exists(ext)) {
			return extensionsMap.get(ext);
		}
		var lowerExt = ext.toLowerCase();
		if (extensionsMap.exists(lowerExt)) {
			return extensionsMap.get(lowerExt);
		}
		var guess = MimeTypes.guessFileType(path);
		if (guess != null) {
			return guess;
		}
		return 'application/octet-stream';
	}
}

private class MimeTypes {
	private static var typesMap:Map<String, String> = [
		'.js' => 'text/javascript',
		'.mjs' => 'text/javascript',
		'.json' => 'application/json',
		'.webmanifest' => 'application/manifest+json',
		'.doc' => 'application/msword',
		'.dot' => 'application/msword',
		'.wiz' => 'application/msword',
		'.nq' => 'application/n-quads',
		'.nt' => 'application/n-triples',
		'.bin' => 'application/octet-stream',
		'.a' => 'application/octet-stream',
		'.dll' => 'application/octet-stream',
		'.exe' => 'application/octet-stream',
		'.o' => 'application/octet-stream',
		'.obj' => 'application/octet-stream',
		'.so' => 'application/octet-stream',
		'.oda' => 'application/oda',
		'.pdf' => 'application/pdf',
		'.p7c' => 'application/pkcs7-mime',
		'.ps' => 'application/postscript',
		'.ai' => 'application/postscript',
		'.eps' => 'application/postscript',
		'.trig' => 'application/trig',
		'.m3u' => 'application/vnd.apple.mpegurl',
		'.m3u8' => 'application/vnd.apple.mpegurl',
		'.xls' => 'application/vnd.ms-excel',
		'.xlb' => 'application/vnd.ms-excel',
		'.ppt' => 'application/vnd.ms-powerpoint',
		'.pot' => 'application/vnd.ms-powerpoint',
		'.ppa' => 'application/vnd.ms-powerpoint',
		'.pps' => 'application/vnd.ms-powerpoint',
		'.pwz' => 'application/vnd.ms-powerpoint',
		'.wasm' => 'application/wasm',
		'.bcpio' => 'application/x-bcpio',
		'.cpio' => 'application/x-cpio',
		'.csh' => 'application/x-csh',
		'.dvi' => 'application/x-dvi',
		'.gtar' => 'application/x-gtar',
		'.hdf' => 'application/x-hdf',
		'.h5' => 'application/x-hdf5',
		'.latex' => 'application/x-latex',
		'.mif' => 'application/x-mif',
		'.cdf' => 'application/x-netcdf',
		'.nc' => 'application/x-netcdf',
		'.p12' => 'application/x-pkcs12',
		'.pfx' => 'application/x-pkcs12',
		'.ram' => 'application/x-pn-realaudio',
		'.pyc' => 'application/x-python-code',
		'.pyo' => 'application/x-python-code',
		'.sh' => 'application/x-sh',
		'.shar' => 'application/x-shar',
		'.swf' => 'application/x-shockwave-flash',
		'.sv4cpio' => 'application/x-sv4cpio',
		'.sv4crc' => 'application/x-sv4crc',
		'.tar' => 'application/x-tar',
		'.tcl' => 'application/x-tcl',
		'.tex' => 'application/x-tex',
		'.texi' => 'application/x-texinfo',
		'.texinfo' => 'application/x-texinfo',
		'.roff' => 'application/x-troff',
		'.t' => 'application/x-troff',
		'.tr' => 'application/x-troff',
		'.man' => 'application/x-troff-man',
		'.me' => 'application/x-troff-me',
		'.ms' => 'application/x-troff-ms',
		'.ustar' => 'application/x-ustar',
		'.src' => 'application/x-wais-source',
		'.xsl' => 'application/xml',
		'.rdf' => 'application/xml',
		'.wsdl' => 'application/xml',
		'.xpdl' => 'application/xml',
		'.zip' => 'application/zip',
		'.3gp' => 'audio/3gpp',
		'.3gpp' => 'audio/3gpp',
		'.3g2' => 'audio/3gpp2',
		'.3gpp2' => 'audio/3gpp2',
		'.aac' => 'audio/aac',
		'.adts' => 'audio/aac',
		'.loas' => 'audio/aac',
		'.ass' => 'audio/aac',
		'.au' => 'audio/basic',
		'.snd' => 'audio/basic',
		'.mp3' => 'audio/mpeg',
		'.mp2' => 'audio/mpeg',
		'.opus' => 'audio/opus',
		'.aif' => 'audio/x-aiff',
		'.aifc' => 'audio/x-aiff',
		'.aiff' => 'audio/x-aiff',
		'.ra' => 'audio/x-pn-realaudio',
		'.wav' => 'audio/x-wav',
		'.avif' => 'image/avif',
		'.bmp' => 'image/bmp',
		'.gif' => 'image/gif',
		'.ief' => 'image/ief',
		'.jpg' => 'image/jpeg',
		'.jpe' => 'image/jpeg',
		'.jpeg' => 'image/jpeg',
		'.heic' => 'image/heic',
		'.heif' => 'image/heif',
		'.png' => 'image/png',
		'.svg' => 'image/svg+xml',
		'.tiff' => 'image/tiff',
		'.tif' => 'image/tiff',
		'.ico' => 'image/vnd.microsoft.icon',
		'.ras' => 'image/x-cmu-raster',
		'.pnm' => 'image/x-portable-anymap',
		'.pbm' => 'image/x-portable-bitmap',
		'.pgm' => 'image/x-portable-graymap',
		'.ppm' => 'image/x-portable-pixmap',
		'.rgb' => 'image/x-rgb',
		'.xbm' => 'image/x-xbitmap',
		'.xpm' => 'image/x-xpixmap',
		'.xwd' => 'image/x-xwindowdump',
		'.eml' => 'message/rfc822',
		'.mht' => 'message/rfc822',
		'.mhtml' => 'message/rfc822',
		'.nws' => 'message/rfc822',
		'.css' => 'text/css',
		'.csv' => 'text/csv',
		'.html' => 'text/html',
		'.htm' => 'text/html',
		'.n3' => 'text/n3',
		'.txt' => 'text/plain',
		'.bat' => 'text/plain',
		'.c' => 'text/plain',
		'.h' => 'text/plain',
		'.ksh' => 'text/plain',
		'.pl' => 'text/plain',
		'.srt' => 'text/plain',
		'.rtx' => 'text/richtext',
		'.tsv' => 'text/tab-separated-values',
		'.vtt' => 'text/vtt',
		'.py' => 'text/x-python',
		'.etx' => 'text/x-setext',
		'.sgm' => 'text/x-sgml',
		'.sgml' => 'text/x-sgml',
		'.vcf' => 'text/x-vcard',
		'.xml' => 'text/xml',
		'.mp4' => 'video/mp4',
		'.mpeg' => 'video/mpeg',
		'.m1v' => 'video/mpeg',
		'.mpa' => 'video/mpeg',
		'.mpe' => 'video/mpeg',
		'.mpg' => 'video/mpeg',
		'.mov' => 'video/quicktime',
		'.qt' => 'video/quicktime',
		'.webm' => 'video/webm',
		'.avi' => 'video/x-msvideo',
		'.movie' => 'video/x-sgi-movie',
	];

	public static function guessFileType(path:String):String {
		var ext = '.' + Path.extension(path);
		if (typesMap.exists(ext)) {
			return typesMap.get(ext);
		}
		var lowerExt = ext.toLowerCase();
		if (typesMap.exists(lowerExt)) {
			return typesMap.get(lowerExt);
		}
		return null;
	}
}
