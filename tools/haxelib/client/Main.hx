/*
 * Copyright (C)2005-2016 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
package haxelib.client;

import haxe.crypto.Md5;
import haxe.*;
import haxe.io.BytesOutput;
import haxe.io.Path;
import haxe.zip.*;
import sys.io.File;
import sys.FileSystem;
import sys.io.*;
import haxe.ds.Option;
import haxelib.client.Cli.ask;
import haxelib.client.FsUtils.*;
import haxelib.client.Vcs;

using StringTools;
using Lambda;
using haxelib.Data;

private enum CommandCategory {
	Basic;
	Information;
	Development;
	Miscellaneous;
	Deprecated(msg:String);
}

class SiteProxy extends haxe.remoting.Proxy<haxelib.SiteApi> {
}

class ProgressOut extends haxe.io.Output {

	var o : haxe.io.Output;
	var cur : Int;
	var startSize : Int;
	var max : Null<Int>;
	var start : Float;

	public function new(o, currentSize) {
		this.o = o;
		startSize = currentSize;
		cur = currentSize;
		start = Timer.stamp();
	}

	function report(n) {
		cur += n;
		if( max == null )
			Sys.print(cur+" bytes\r");
		else
			Sys.print(cur+"/"+max+" ("+Std.int((cur*100.0)/max)+"%)\r");
	}

	public override function writeByte(c) {
		o.writeByte(c);
		report(1);
	}

	public override function writeBytes(s,p,l) {
		var r = o.writeBytes(s,p,l);
		report(r);
		return r;
	}

	public override function close() {
		super.close();
		o.close();
		var time = Timer.stamp() - start;
		var downloadedBytes = cur - startSize;
		var speed = (downloadedBytes / time) / 1024;
		time = Std.int(time * 10) / 10;
		speed = Std.int(speed * 10) / 10;
		Sys.print("Download complete : "+downloadedBytes+" bytes in "+time+"s ("+speed+"KB/s)\n");
	}

	public override function prepare(m) {
		max = m + startSize;
	}

}

class ProgressIn extends haxe.io.Input {

	var i : haxe.io.Input;
	var pos : Int;
	var tot : Int;

	public function new( i, tot ) {
		this.i = i;
		this.pos = 0;
		this.tot = tot;
	}

	public override function readByte() {
		var c = i.readByte();
		report(1);
		return c;
	}

	public override function readBytes(buf,pos,len) {
		var k = i.readBytes(buf,pos,len);
		report(k);
		return k;
	}

	function report( nbytes : Int ) {
		pos += nbytes;
		Sys.print( Std.int((pos * 100.0) / tot) + "%\r" );
	}

}

class Main {
	static inline var HAXELIB_LIBNAME = "haxelib";

	static var VERSION = SemVer.ofString('3.3.0');
	static var REPNAME = "lib";
	static var REPODIR = ".haxelib";
	static var SERVER = {
		host : "lib.haxe.org",
		port : 80,
		dir : "",
		url : "index.n",
		apiVersion : "3.0",
	};
	static var IS_WINDOWS = (Sys.systemName() == "Windows");

	var argcur : Int;
	var args : Array<String>;
	var commands : List<{ name : String, doc : String, f : Void -> Void, net : Bool, cat : CommandCategory }>;
	var siteUrl : String;
	var site : SiteProxy;
	var isHaxelibRun : Bool;
	var alreadyUpdatedVcsDependencies:Map<String,String> = new Map<String,String>();


	function new() {
		args = Sys.args();
		isHaxelibRun = (Sys.getEnv("HAXELIB_RUN_NAME") == HAXELIB_LIBNAME);

		if (isHaxelibRun)
			Sys.setCwd(args.pop());

		commands = new List();
		addCommand("install", install, "install a given library, or all libraries from a hxml file", Basic);
		addCommand("update", update, "update a single library (if given) or all installed libraries", Basic);
		addCommand("remove", remove, "remove a given library/version", Basic, false);
		addCommand("list", list, "list all installed libraries", Basic, false);
		addCommand("set", set, "set the current version for a library", Basic, false);

		addCommand("search", search, "list libraries matching a word", Information);
		addCommand("info", info, "list information on a given library", Information);
		addCommand("user", user, "list information on a given user", Information);
		addCommand("config", config, "print the repository path", Information, false);
		addCommand("path", path, "give paths to libraries", Information, false);
		addCommand("version", version, "print the currently used haxelib version", Information, false);
		addCommand("help", usage, "display this list of options", Information, false);

		addCommand("submit", submit, "submit or update a library package", Development);
		addCommand("register", register, "register a new user", Development);
		addCommand("dev", dev, "set the development directory for a given library", Development, false);
		//TODO: generate command about VCS by Vcs.getAll()
		addCommand("git", vcs.bind(VcsID.Git), "use Git repository as library", Development);
		addCommand("hg", vcs.bind(VcsID.Hg), "use Mercurial (hg) repository as library", Development);

		addCommand("setup", setup, "set the haxelib repository path", Miscellaneous, false);
		addCommand("newrepo", newRepo, "create a new local repository", Miscellaneous, false);
		addCommand("deleterepo", deleteRepo, "delete the local repository", Miscellaneous, false);
		addCommand("convertxml", convertXml, "convert haxelib.xml file to haxelib.json", Miscellaneous);
		addCommand("run", run, "run the specified library with parameters", Miscellaneous, false);
		addCommand("proxy", proxy, "setup the Http proxy", Miscellaneous);

		// deprecated commands
		addCommand("local", local, "install the specified package locally", Deprecated("Use `haxelib install <file>` instead"), false);
		addCommand("selfupdate", updateSelf, "update haxelib itself", Deprecated('Use `haxelib --global update $HAXELIB_LIBNAME` instead'));

		initSite();
	}

	function checkUpdate() {
		var latest = try site.getLatestVersion(HAXELIB_LIBNAME) catch (_:Dynamic) null;
		if (latest != null && latest > VERSION)
			print('\nA new version ($latest) of haxelib is available.\nDo `haxelib --global update $HAXELIB_LIBNAME` to get the latest version.\n');
	}

	function initSite() {
		siteUrl = "http://" + SERVER.host + ":" + SERVER.port + "/" + SERVER.dir;
		var remotingUrl =  siteUrl + "api/" + SERVER.apiVersion + "/" + SERVER.url;
		site = new SiteProxy(haxe.remoting.HttpConnection.urlConnect(remotingUrl).api);
	}

	function param( name, ?passwd ) {
		if( args.length > argcur )
			return args[argcur++];
		Sys.print(name+" : ");
		if( passwd ) {
			var s = new StringBuf();
			do switch Sys.getChar(false) {
				case 10, 13: break;
				case c: s.addChar(c);
			}
			while (true);
			print("");
			return s.toString();
		}
		return Sys.stdin().readLine();
	}

	function paramOpt() {
		if( args.length > argcur )
			return args[argcur++];
		return null;
	}

	function addCommand( name, f, doc, cat, ?net = true ) {
		commands.add({ name : name, doc : doc, f : f, net : net, cat : cat });
	}

	function version() {
		print(VERSION);
	}

	function usage() {
		var cats = [];
		var maxLength = 0;
		for( c in commands ) {
			if (c.name.length > maxLength) maxLength = c.name.length;
			if (c.cat.match(Deprecated(_))) continue;
			var i = c.cat.getIndex();
			if (cats[i] == null) cats[i] = [c];
			else cats[i].push(c);
		}

		print("Haxe Library Manager " + VERSION + " - (c)2006-2016 Haxe Foundation");
		print("  Usage: haxelib [command] [options]");

		for (cat in cats) {
			print("  " + cat[0].cat.getName());
			for (c in cat) {
				print("    " + StringTools.rpad(c.name, " ", maxLength) + ": " +c.doc);
			}
		}

		print("  Available switches");
		for (f in Reflect.fields(ABOUT_SETTINGS))
			print('    --' + f.rpad(' ', maxLength-2) + ": " + Reflect.field(ABOUT_SETTINGS, f));
	}
	static var ABOUT_SETTINGS = {
		global : "force global repo if a local one exists",
		debug  : "run in debug mode, imply not --quiet",
		quiet  : "print less messages, imply not --debug",
		flat   : "do not use --recursive cloning for git",
		always : "answer all questions with yes",
		never  : "answer all questions with no",
		system : "run bundled haxelib version instead of latest update",
	}

	var settings: {
		debug  : Bool,
		quiet  : Bool,
		flat   : Bool,
		always : Bool,
		never  : Bool,
		global : Bool,
		system : Bool,
	};
	function process() {
		argcur = 0;
		var rest = [];
		settings = {
			debug: false,
			quiet: false,
			always: false,
			never: false,
			flat: false,
			global: false,
			system: false,
		};

		function parseSwitch(s:String) {
			return
				if (s.startsWith('--'))
					Some(s.substr(2));
				else if (s.startsWith('-'))
					Some(s.substr(1));
				else
					None;
		}

		while ( argcur < args.length) {
			var a = args[argcur++];
			switch( a ) {
				case '-cwd':
					var dir = args[argcur++];
					if (dir == null) {
						print("Missing directory argument for -cwd");
						Sys.exit(1);
					}
					try {
						Sys.setCwd(dir);
					} catch (e:String) {
						if (e == "std@set_cwd") {
							print("Directory " + dir + " unavailable");
							Sys.exit(1);
						}
						neko.Lib.rethrow(e);
					}
				case "-notimeout":
					haxe.remoting.HttpConnection.TIMEOUT = 0;
				case "-R":
					var path = args[argcur++];
					var r = ~/^(http:\/\/)?([^:\/]+)(:[0-9]+)?\/?(.*)$/;
					if( !r.match(path) )
						throw "Invalid repository format '"+path+"'";
					SERVER.host = r.matched(2);
					if( r.matched(3) != null )
						SERVER.port = Std.parseInt(r.matched(3).substr(1));
					SERVER.dir = r.matched(4);
					if (SERVER.dir.length > 0 && !SERVER.dir.endsWith("/")) SERVER.dir += "/";
					initSite();
				case "--debug":
					settings.debug = true;
					settings.quiet = false;
				case "--quiet":
					settings.debug = false;
					settings.quiet = true;
				case parseSwitch(_) => Some(s) if (Reflect.hasField(settings, s)):
					//if (!Reflect.hasField(settings, s)) {
						//print('unknown switch $a');
						//Sys.exit(1);
					//}
					Reflect.setField(settings, s, true);
				case 'run':
					rest = rest.concat(args.slice(argcur - 1));
					break;
				default:
					rest.push(a);
			}
		}

		if (!isHaxelibRun && !settings.system) {
			var rep = try getGlobalRepository() catch (_:Dynamic) null;
			if (rep != null && FileSystem.exists(rep + HAXELIB_LIBNAME)) {
				argcur = 0; // send all arguments
				doRun(rep, HAXELIB_LIBNAME, null);
				return;
			}
		}

		Cli.defaultAnswer =
			switch [settings.always, settings.never] {
				case [true, true]:
					print('--always and --never are mutually exclusive');
					Sys.exit(1);
					null;
				case [true, _]: true;
				case [_, true]: false;
				default: null;
			}

		argcur = 0;
		args = rest;

		var cmd = args[argcur++];
		if( cmd == null ) {
			usage();
			Sys.exit(1);
		}
		if (cmd == "upgrade") cmd = "update"; // TODO: maybe we should have some alias system
		for( c in commands )
			if( c.name == cmd ) {
				switch (c.cat) {
					case Deprecated(message):
						Sys.println('Warning: Command `$cmd` is deprecated and will be removed in future. $message.');
					default:
				}
				try {
					if( c.net ) {
						loadProxy();
						checkUpdate();
					}
					c.f();
				} catch( e : Dynamic ) {
					if( e == "std@host_resolve" ) {
						print("Host "+SERVER.host+" was not found");
						print("Please ensure that your internet connection is on");
						print("If you don't have an internet connection or if you are behing a proxy");
						print("please download manually the file from http://lib.haxe.org/files/3.0/");
						print("and run 'haxelib local <file>' to install the Library.");
						print("You can also setup the proxy with 'haxelib proxy'.");
						Sys.exit(1);
					}
					if( e == "Blocked" ) {
						print("Http connection timeout. Try running haxelib -notimeout <command> to disable timeout");
						Sys.exit(1);
					}
					if( e == "std@get_cwd" ) {
						print("Error: Current working directory is unavailable");
						Sys.exit(1);
					}
					if( settings.debug )
						neko.Lib.rethrow(e);
					print("Error: " + Std.string(e));
					Sys.exit(1);
				}
				return;
			}
		print("Unknown command "+cmd);
		usage();
		Sys.exit(1);
	}

	inline function createHttpRequest(url:String):Http {
		var req = new Http(url);
		if (haxe.remoting.HttpConnection.TIMEOUT == 0)
			req.cnxTimeout = 0;
		return req;
	}

	// ---- COMMANDS --------------------

 	function search() {
		var word = param("Search word");
		var l = site.search(word);
		for( s in l )
			print(s.name);
		print(l.length+" libraries found");
	}

	function info() {
		var prj = param("Library name");
		var inf = site.infos(prj);
		print("Name: "+inf.name);
		print("Tags: "+inf.tags.join(", "));
		print("Desc: "+inf.desc);
		print("Website: "+inf.website);
		print("License: "+inf.license);
		print("Owner: "+inf.owner);
		print("Version: "+inf.getLatest());
		print("Releases: ");
		if( inf.versions.length == 0 )
			print("  (no version released yet)");
		for( v in inf.versions )
			print("   "+v.date+" "+v.name+" : "+v.comments);
	}

	function user() {
		var uname = param("User name");
		var inf = site.user(uname);
		print("Id: "+inf.name);
		print("Name: "+inf.fullname);
		print("Mail: "+inf.email);
		print("Libraries: ");
		if( inf.projects.length == 0 )
			print("  (no libraries)");
		for( p in inf.projects )
			print("  "+p);
	}

	function register() {
		doRegister(param("User"));
		print("Registration successful");
	}

	function doRegister(name) {
		var email = param("Email");
		var fullname = param("Fullname");
		var pass = param("Password",true);
		var pass2 = param("Confirm",true);
		if( pass != pass2 )
			throw "Password does not match";
		pass = Md5.encode(pass);
		site.register(name,pass,email,fullname);
		return pass;
	}

	function zipDirectory(root:String):List<Entry> {
		var ret = new List<Entry>();
		function seek(dir:String) {
			for (name in FileSystem.readDirectory(dir)) if (!name.startsWith('.')) {
				var full = '$dir/$name';
				if (FileSystem.isDirectory(full)) seek(full);
				else {
					var blob = File.getBytes(full);
					var entry:Entry = {
						fileName: full.substr(root.length+1),
						fileSize : blob.length,
						fileTime : FileSystem.stat(full).mtime,
						compressed : false,
						dataSize : blob.length,
						data : blob,
						crc32: haxe.crypto.Crc32.make(blob),
					};
					Tools.compress(entry, 9);
					ret.push(entry);
				}
			}
		}
		seek(root);
		return ret;
	}

	function submit() {
		var file = param("Package");

		var data, zip;
		if (FileSystem.isDirectory(file)) {
			zip = zipDirectory(file);
			var out = new BytesOutput();
			new Writer(out).write(zip);
			data = out.getBytes();
		} else {
			data = File.getBytes(file);
			zip = Reader.readZip(new haxe.io.BytesInput(data));
		}

		var infos = Data.readInfos(zip,true);
		Data.checkClassPath(zip, infos);

		var user:String = infos.contributors[0];

		if (infos.contributors.length > 1)
			do {
				print("Which of these users are you: " + infos.contributors);
				user = param("User");
			} while ( infos.contributors.indexOf(user) == -1 );

		var password;
		if( site.isNewUser(user) ) {
			print("This is your first submission as '"+user+"'");
			print("Please enter the following information for registration");
			password = doRegister(user);
		} else {
			password = readPassword(user);
		}
		site.checkDeveloper(infos.name,user);

		// check dependencies validity
		for( d in infos.dependencies ) {
			var infos = site.infos(d.name);
			if( d.version == "" )
				continue;
			var found = false;
			for( v in infos.versions )
				if( v.name == d.version ) {
					found = true;
					break;
				}
			if( !found )
				throw "Library " + d.name + " does not have version " + d.version;
		}

		// check if this version already exists

		var sinfos = try site.infos(infos.name) catch( _ : Dynamic ) null;
		if( sinfos != null )
			for( v in sinfos.versions )
				if( v.name == infos.version && !ask("You're about to overwrite existing version '"+v.name+"', please confirm") )
					throw "Aborted";

		// query a submit id that will identify the file
		var id = site.getSubmitId();

		// directly send the file data over Http
		var h = createHttpRequest("http://"+SERVER.host+":"+SERVER.port+"/"+SERVER.url);
		h.onError = function(e) throw e;
		h.onData = print;
		h.fileTransfer("file",id,new ProgressIn(new haxe.io.BytesInput(data),data.length),data.length);
		print("Sending data.... ");
		h.request(true);

		// processing might take some time, make sure we wait
		print("Processing file.... ");
		if (haxe.remoting.HttpConnection.TIMEOUT != 0) // don't ignore -notimeout
			haxe.remoting.HttpConnection.TIMEOUT = 1000;
		// ask the server to register the sent file
		var msg = site.processSubmit(id,user,password);
		print(msg);
	}

	function readPassword(user:String, prompt = "Password"):String {
		var password = Md5.encode(param(prompt,true));
		var attempts = 5;
		while (!site.checkPassword(user, password)) {
			print('Invalid password for $user');
			if (--attempts == 0)
				throw 'Failed to input correct password';
			password = Md5.encode(param('$prompt ($attempts more attempt${attempts == 1 ? "" : "s"})', true));
		}
		return password;
	}

	function install() {
		var rep = getRepository();

		var prj = param("Library name or hxml file:");

		// No library given, install libraries listed in *.hxml in given directory
		if( prj == "all") {
			installFromAllHxml(rep);
			return;
		}

		if( sys.FileSystem.exists(prj) && !sys.FileSystem.isDirectory(prj) ) {
			// *.hxml provided, install all libraries/versions in this hxml file
			if( prj.endsWith(".hxml") ) {
				installFromHxml(rep, prj);
				return;
			}
			// *.zip provided, install zip as haxe library
			if (prj.endsWith(".zip")) {
				doInstallFile(rep, prj, true, true);
				return;
			}
			
			if ( prj.endsWith("haxelib.json") )
			{
				installFromHaxelibJson( rep, prj);
				return;
			}
		}

		// Name provided that wasn't a local hxml or zip, so try to install it from server
		var inf = site.infos(prj);
		var reqversion = paramOpt();
		var version = getVersion(inf, reqversion);
		doInstall(rep,inf.name,version,version == inf.getLatest());
	}

	function getVersion( inf:ProjectInfos, ?reqversion:String ) {
		if( inf.versions.length == 0 )
			throw "The library "+inf.name+" has not yet released a version";
		var version = if( reqversion != null ) reqversion else inf.getLatest();
		var found = false;
		for( v in inf.versions )
			if( v.name == version ) {
				found = true;
				break;
			}
		if( !found )
			throw "No such version "+version+" for library "+inf.name;

		return version;
	}

	function installFromHxml( rep:String, path:String ) {
		var targets  = [
			'-java ' => 'hxjava',
			'-cpp ' => 'hxcpp',
			'-cs ' => 'hxcs',
		];
		var libsToInstall = new Map<String, {name:String,version:String,type:String,url:String,branch:String,subDir:String}>();

		function processHxml(path) {
			var hxml = sys.io.File.getContent(path);
			var lines = hxml.split("\n");
			for (l in lines) {
				l = l.trim();
				for (target in targets.keys())
					if (l.startsWith(target)) {
						var lib = targets[target];
						if (!libsToInstall.exists(lib))
							libsToInstall[lib] = { name: lib, version: null, type:"haxelib", url: null, branch: null, subDir: null }
					}

				if (l.startsWith("-lib"))
				{
					var key = l.substr(5).trim();
					var parts = ~/:/.split(key);
					var libName = parts[0];
					var libVersion:String = null;
					var branch:String = null;
					var url:String = null;
					var subDir:String = null;
					var type:String;
					
					if ( parts.length > 1 )
					{
						if ( parts[1].startsWith("git:") )
						{
							
							type = "git";
							var urlParts = parts[1].substr(4).split("#");
							url = urlParts[0];
							branch = urlParts.length > 1 ? urlParts[1] : null;
						}
						else
						{
							type = "haxelib";
							libVersion = parts[1];
						}
					}
					else
					{
						type = "haxelib";
					}

					switch libsToInstall[key] {
						case null, { version: null } :
							libsToInstall.set(key, { name:libName, version:libVersion, type: type, url: url, subDir: subDir, branch: branch } );
						default:
					}
				}

				if (l.endsWith(".hxml"))
					processHxml(l);
			}
		}
		processHxml(path);

		if (libsToInstall.empty())
			return;

		// Check the version numbers are all good
		// TODO: can we collapse this into a single API call?  It's getting too slow otherwise.
		print("Loading info about the required libraries");
		for (l in libsToInstall)
		{
			if ( l.type == "git" )
			{
				// Do not check git repository infos
				continue;
			}
			var inf = site.infos(l.name);
			l.version = getVersion(inf, l.version);
		}

		// Print a list with all the info
		print("Haxelib is going to install these libraries:");
		for (l in libsToInstall) {
			var vString = (l.version == null) ? "" : " - " + l.version;
			print("  " + l.name + vString);
		}

		// Install if they confirm
		if (ask("Continue?")) {
			for (l in libsToInstall) {
				if ( l.type == "haxelib" )
					doInstall(rep, l.name, l.version, true);
				else if ( l.type == "git" )
					useVcs(VcsID.Git, function(vcs) doVcsInstall(rep, vcs, l.name, l.url, l.branch, l.subDir, l.version));
				else if ( l.type == "hg" )
					useVcs(VcsID.Hg, function(vcs) doVcsInstall(rep, vcs, l.name, l.url, l.branch, l.subDir, l.version));
			}
		}
	}
	
	function installFromHaxelibJson( rep:String, path:String )
	{
		doInstallDependencies(rep, Data.readData(File.getContent(path), false).dependencies);
	}

	function installFromAllHxml(rep:String) {
		var cwd = Sys.getCwd();
		var hxmlFiles = sys.FileSystem.readDirectory(cwd).filter(function (f) return f.endsWith(".hxml"));
		if (hxmlFiles.length > 0) {
			for (file in hxmlFiles) {
				print('Installing all libraries from $file:');
				installFromHxml(rep, cwd + file);
			}
		} else {
			print("No hxml files found in the current directory.");
		}
	}

	function doInstall( rep, project, version, setcurrent ) {
		// check if exists already
		if( FileSystem.exists(rep+Data.safe(project)+"/"+Data.safe(version)) ) {
			print("You already have "+project+" version "+version+" installed");
			setCurrent(rep,project,version,true);
			return;
		}

		// download to temporary file
		var filename = Data.fileName(project,version);
		var filepath = rep+filename;
		var out = try File.append(filepath,true) catch (e:Dynamic) throw 'Failed to write to $filepath: $e';
		out.seek(0, SeekEnd);

		var h = createHttpRequest(siteUrl+Data.REPOSITORY+"/"+filename);

		var currentSize = out.tell();
		if (currentSize > 0)
			h.addHeader("range", "bytes="+currentSize + "-");

		var progress = new ProgressOut(out, currentSize);

		var has416Status = false;
		h.onStatus = function(status) {
			// 416 Requested Range Not Satisfiable, which means that we probably have a fully downloaded file already
			if (status == 416) has416Status = true;
		};
		h.onError = function(e) {
			progress.close();

			// if we reached onError, because of 416 status code, it's probably okay and we should try unzipping the file
			if (!has416Status) {
				FileSystem.deleteFile(filepath);
				throw e;
			}
		};
		print("Downloading "+filename+"...");
		h.customRequest(false,progress);

		doInstallFile(rep,filepath, setcurrent);
		try {
			site.postInstall(project, version);
		} catch (e:Dynamic) {}
	}

	function doInstallFile(rep,filepath,setcurrent,nodelete = false) {
		// read zip content
		var f = File.read(filepath,true);
		var zip = try {
			Reader.readZip(f);
		} catch (e:Dynamic) {
			f.close();
			// file is corrupted, remove it
			if (!nodelete)
				FileSystem.deleteFile(filepath);
			neko.Lib.rethrow(e);
			throw e;
		}
		f.close();
		var infos = Data.readInfos(zip,false);
		print('Installing ${infos.name}...');
		// create directories
		var pdir = rep + Data.safe(infos.name);
		safeDir(pdir);
		pdir += "/";
		var target = pdir + Data.safe(infos.version);
		safeDir(target);
		target += "/";

		// locate haxelib.json base path
		var basepath = Data.locateBasePath(zip);

		// unzip content
		var entries = [for (entry in zip) if (entry.fileName.startsWith(basepath)) entry];
		var total = entries.length;
		for (i in 0...total) {
			var zipfile = entries[i];
			var n = zipfile.fileName;
			// remove basepath
			n = n.substr(basepath.length,n.length-basepath.length);
			if( n.charAt(0) == "/" || n.charAt(0) == "\\" || n.split("..").length > 1 )
				throw "Invalid filename : "+n;

			if (!settings.debug) {
				var percent = Std.int((i / total) * 100);
				Sys.print('${i + 1}/$total ($percent%)\r');
			}

			var dirs = ~/[\/\\]/g.split(n);
			var path = "";
			var file = dirs.pop();
			for( d in dirs ) {
				path += d;
				safeDir(target+path);
				path += "/";
			}
			if( file == "" ) {
				if( path != "" && settings.debug ) print("  Created "+path);
				continue; // was just a directory
			}
			path += file;
			if (settings.debug)
				print("  Install "+path);
			var data = Reader.unzip(zipfile);
			File.saveBytes(target+path,data);
		}

		// set current version
		if( setcurrent || !FileSystem.exists(pdir+".current") ) {
			File.saveContent(pdir + ".current", infos.version);
			print("  Current version is now "+infos.version);
		}

		// end
		if( !nodelete )
			FileSystem.deleteFile(filepath);
		print("Done");

		// process dependencies
		doInstallDependencies(rep, infos.dependencies);

		return infos;
	}

	function doInstallDependencies( rep:String, dependencies:Array<Dependency> ) {
		for( d in dependencies ) {
			if( d.version == "" ) {
				var pdir = rep + Data.safe(d.name);
				var dev = try getDev(pdir) catch (_:Dynamic) null;

				if (dev != null) { // no version specified and dev set, no need to install dependency
					continue;
				}
			}

			if( d.version == "" && d.type == DependencyType.Haxelib )
				d.version = site.getLatestVersion(d.name);
			print("Installing dependency "+d.name+" "+d.version);

			switch d.type {
				case Haxelib:
					doInstall(rep, d.name, d.version, false);
				case Git:
					useVcs(VcsID.Git, function(vcs) doVcsInstall(rep, vcs, d.name, d.url, d.branch, d.subDir, d.version));
				case Mercurial:
					useVcs(VcsID.Hg, function(vcs) doVcsInstall(rep, vcs, d.name, d.url, d.branch, d.subDir, d.version));
			}
		}
	}

	static public function getConfigFile():String {
		var home = null;
		if (IS_WINDOWS) {
			home = Sys.getEnv("USERPROFILE");
			if (home == null) {
				var drive = Sys.getEnv("HOMEDRIVE");
				var path = Sys.getEnv("HOMEPATH");
				if (drive != null && path != null)
					home = drive + path;
			}
			if (home == null)
				throw "Could not determine home path. Please ensure that USERPROFILE or HOMEDRIVE+HOMEPATH environment variables are set.";
		} else {
			home = Sys.getEnv("HOME");
			if (home == null)
				throw "Could not determine home path. Please ensure that HOME environment variable is set.";
		}
		return Path.addTrailingSlash(home) + ".haxelib";
	}

	function getGlobalRepositoryPath(create = false):String {
		// first check the env var
		var rep = Sys.getEnv("HAXELIB_PATH");
		if (rep != null)
			return rep.trim();

		// try to read from user config
		rep = try File.getContent(getConfigFile()).trim() catch (_:Dynamic) null;
		if (rep != null)
			return rep;

		if (!IS_WINDOWS) {
			// on unixes, try to read system-wide config
			rep = try File.getContent("/etc/.haxelib").trim() catch (_:Dynamic) null;
			if (rep == null)
				throw "This is the first time you are runing haxelib. Please run `haxelib setup` first";
		} else {
			// on windows, try to use haxe installation path
			rep = getWindowsDefaultGlobalRepositoryPath();
			if (create)
				try safeDir(rep) catch(e:Dynamic) throw 'Error accessing Haxelib repository: $e';
		}

		return rep;
	}

	// The Windows haxe installer will setup %HAXEPATH%. We will default haxelib repo to %HAXEPATH%/lib.
	// When there is no %HAXEPATH%, we will use a "haxelib" directory next to the config file, ".haxelib".
	function getWindowsDefaultGlobalRepositoryPath():String {
		var haxepath = Sys.getEnv("HAXEPATH");
		if (haxepath != null)
			return Path.addTrailingSlash(haxepath.trim()) + REPNAME;
		else
			return Path.join([Path.directory(getConfigFile()), "haxelib"]);
	}

	function getSuggestedGlobalRepositoryPath():String {
		if (IS_WINDOWS)
			return getWindowsDefaultGlobalRepositoryPath();

		return if (FileSystem.exists("/usr/share/haxe")) // for Debian
			'/usr/share/haxe/$REPNAME'
		else if (Sys.systemName() == "Mac") // for newer OSX, where /usr/lib is not writable
			'/usr/local/lib/haxe/$REPNAME'
		else
			'/usr/lib/haxe/$REPNAME'; // for other unixes
	}

	function getRepository():String {
		if (!settings.global && FileSystem.exists(REPODIR) && FileSystem.isDirectory(REPODIR))
			return Path.addTrailingSlash(FileSystem.fullPath(REPODIR));
		else
			return getGlobalRepository();
	}

	function getGlobalRepository():String {
		var rep = getGlobalRepositoryPath(true);
		if (!FileSystem.exists(rep))
			throw "haxelib Repository " + rep + " does not exist. Please run `haxelib setup` again.";
		else if (!FileSystem.isDirectory(rep))
			throw "haxelib Repository " + rep + " exists, but is a file, not a directory. Please remove it and run `haxelib setup` again.";
		return Path.addTrailingSlash(rep);
	}

	function setup() {
		var rep = try getGlobalRepositoryPath() catch (_:Dynamic) null;

		var configFile = getConfigFile();

		if (args.length <= argcur) {
			if (rep == null)
				rep = getSuggestedGlobalRepositoryPath();
			print("Please enter haxelib repository path with write access");
			print("Hit enter for default (" + rep + ")");
		}

		var line = param("Path");
		if (line != "")
			rep = line;

		rep = try FileSystem.fullPath(rep) catch (_:Dynamic) rep;

		if (isSamePath(rep, configFile))
			throw "Can't use "+rep+" because it is reserved for config file";

		safeDir(rep);
		File.saveContent(configFile, rep);

		print("haxelib repository is now " + rep);
	}

	function config() {
		print(getRepository());
	}

	function getCurrent( dir ) {
		return (FileSystem.exists(dir+"/.dev")) ? "dev" : File.getContent(dir + "/.current").trim();
	}

	function getDev( dir ) {
		return File.getContent(dir + "/.dev").trim();
	}

	function matchVersion( version, other ) {
		if (version == "" || version == null)
			return true;
		if (other == "" || other == null)
			return false;
		var filter = version.replace(".","\\.").replace("*",".*");
		return new EReg("^"+filter,"i").match(other);
	}

	function getVersionDir( version, dev, dir ) {
		if ( dev != null ) {
			var json = try File.getContent(dev+"/"+Data.JSON) catch( e : Dynamic ) null;
			var inf = Data.readData(json, false);
			if ( version == "dev" || matchVersion(version, inf.version) ) {
				return dev;
			}
		}
		var matches = [];
		for( v in FileSystem.readDirectory(dir) ) {
			if( v.charAt(0) == "." )
				continue;
			v = Data.unsafe(v);
			var semver = try SemVer.ofString(v) catch (_:Dynamic) null;
			if (semver != null && matchVersion(version, semver))
				matches.push(semver);
		}
		var best = null;
		for( match in matches ) {
			if (best == null || match > best) {
				best = match;
			}
		}
		return if (best != null) dir + "/" + Data.safe(best) else null;
	}

	function list() {
		var rep = getRepository();
		var folders = FileSystem.readDirectory(rep);
		var filter = paramOpt();
		if ( filter != null )
			folders = folders.filter( function (f) return f.toLowerCase().indexOf(filter.toLowerCase()) > -1 );
		var all = [];
		for( p in folders ) {
			if( p.charAt(0) == "." )
				continue;

			var current = try getCurrent(rep + p) catch(e:Dynamic) continue;
			var dev = try getDev(rep + p) catch( e : Dynamic ) null;

			var semvers = [];
			var others = [];
			for( v in FileSystem.readDirectory(rep+p) ) {
				if( v.charAt(0) == "." )
					continue;
				v = Data.unsafe(v);
				var semver = try SemVer.ofString(v) catch (_:Dynamic) null;
				if (semver != null)
					semvers.push(semver);
				else
					others.push(v);
			}

			if (semvers.length > 0)
				semvers.sort(SemVer.compare);

			var versions = [];
			for (v in semvers)
				versions.push((v : String));
			for (v in others)
				versions.push(v);

			if (dev == null) {
				for (i in 0...versions.length) {
					var v = versions[i];
					if (v == current)
						versions[i] = '[$v]';
				}
			} else {
				versions.push("[dev:"+dev+"]");
			}

			all.push(Data.unsafe(p) + ": "+versions.join(" "));
		}
		all.sort(function(s1, s2) return Reflect.compare(s1.toLowerCase(), s2.toLowerCase()));
		for (p in all) {
			print(p);
		}
	}

	function update() {
		var rep = getRepository();

		var prj = paramOpt();
		if (prj != null) {
			prj = projectNameToDir(rep, prj); // get project name in proper case
			if (!updateByName(rep, prj))
				print(prj + " is up to date");
			return;
		}

		var state = { rep : rep, prompt : true, updated : false };
		for( p in FileSystem.readDirectory(state.rep) ) {
			if( p.charAt(0) == "." || !FileSystem.isDirectory(state.rep+"/"+p) )
				continue;
			var p = Data.unsafe(p);
			print("Checking " + p);
			try {
				doUpdate(p, state);
			} catch (e:VcsError) {
				if (!e.match(VcsUnavailable(_)))
					neko.Lib.rethrow(e);
			}
		}
		if( state.updated )
			print("Done");
		else
			print("All libraries are up-to-date");
	}

	function projectNameToDir( rep:String, project:String ) {
		var p = project.toLowerCase();
		var l = FileSystem.readDirectory(rep).filter(function (dir) return dir.toLowerCase() == p);

		switch (l) {
			case []: return project;
			case [dir]: return Data.unsafe(dir);
			case _: throw "Several name case for library " + project;
		}
	}

	function updateByName(rep:String, prj:String) {
		var state = { rep : rep, prompt : false, updated : false };
		doUpdate(prj,state);
		return state.updated;
	}

	function doUpdate( p : String, state : { updated : Bool, rep : String, prompt : Bool } ) {
		var pdir = state.rep + Data.safe(p);

		var vcs = Vcs.getVcsForDevLib(pdir, settings);
		if(vcs != null) {
			if(!vcs.available)
				throw VcsError.VcsUnavailable(vcs);

			var oldCwd = Sys.getCwd();
			Sys.setCwd(pdir + "/" + vcs.directory);
			var success = vcs.update(p);

			state.updated = success;
			Sys.setCwd(oldCwd);
		} else {
			var latest = try site.getLatestVersion(p) catch( e : Dynamic ) { Sys.println(e); return; };

			if( !FileSystem.exists(pdir+"/"+Data.safe(latest)) ) {
				if( state.prompt ) {
					if (!ask("Update "+p+" to "+latest))
						return;
				}
				doInstall(state.rep, p, latest,true);
				state.updated = true;
			} else
				setCurrent(state.rep, p, latest, true);
		}
	}

	function remove() {
		var rep = getRepository();
		var prj = param("Library");
		var version = paramOpt();
		var pdir = rep + Data.safe(prj);
		if( version == null ) {
			if( !FileSystem.exists(pdir) )
				throw "Library "+prj+" is not installed";

			if (prj == HAXELIB_LIBNAME && isHaxelibRun) {
				print('Error: Removing "$HAXELIB_LIBNAME" requires the --system flag');
				Sys.exit(1);
			}

			deleteRec(pdir);
			print("Library "+prj+" removed");
			return;
		}

		var vdir = pdir + "/" + Data.safe(version);
		if( !FileSystem.exists(vdir) )
			throw "Library "+prj+" does not have version "+version+" installed";

		var cur = File.getContent(pdir + "/.current").trim(); // set version regardless of dev
		if( cur == version )
			throw "Can't remove current version of library "+prj;
		var dev = try getDev(pdir) catch (_:Dynamic) null; // dev is checked here
		if( dev == vdir )
			throw "Can't remove dev version of library "+prj;
		deleteRec(vdir);
		print("Library "+prj+" version "+version+" removed");
	}

	function set() {
		setCurrent(getRepository(), param("Library"), param("Version"), false);
	}

	function setCurrent( rep : String, prj : String, version : String, doAsk : Bool ) {
		var pdir = rep + Data.safe(prj);
		var vdir = pdir + "/" + Data.safe(version);
		if( !FileSystem.exists(vdir) ){
			print("Library "+prj+" version "+version+" is not installed");
			if(ask("Would you like to install it?"))
				doInstall(rep, prj, version, true);
			return;
		}
		if( File.getContent(pdir + "/.current").trim() == version )
			return;
		if( doAsk && !ask("Set "+prj+" to version "+version) )
			return;
		File.saveContent(pdir+"/.current",version);
		print("Library "+prj+" current version is now "+version);
	}

	function checkRec( rep : String, prj : String, version : String, l : List<{ project : String, version : String, dir : String, info : Infos }> ) {
		var pdir = rep + Data.safe(prj);
		if( !FileSystem.exists(pdir) )
			throw "Library "+prj+" is not installed : run 'haxelib install "+prj+"'";
		var version = if( version != null ) version else getCurrent(pdir);

		var dev = try getDev(pdir) catch (_:Dynamic) null;
		var vdir = try getVersionDir(version,dev,pdir) catch (_:Dynamic) null;

		if( vdir != null && !FileSystem.exists(vdir) )
			throw "Library "+prj+" version "+version+" is not installed";

		for( p in l )
			if( p.project == prj ) {
				if( p.version == version )
					return;
				throw "Library "+prj+" has two version included "+version+" and "+p.version;
			}
		var json = try File.getContent(vdir+"/"+Data.JSON) catch( e : Dynamic ) null;
		var inf = Data.readData(json,false);
		l.add({ project : prj, version : version, dir : Path.addTrailingSlash(vdir), info: inf });
		for( d in inf.dependencies )
			if( !Lambda.exists(l, function(e) return e.project == d.name) )
				checkRec(rep,d.name,if( d.version == "" ) null else d.version,l);
	}

	function path() {
		var rep = getRepository();
		var list = new List();
		while( argcur < args.length ) {
			var a = args[argcur++].split(":");
			checkRec(rep, a[0],a[1],list);
		}
		for( d in list ) {
			var ndir = d.dir + "ndll";
			if (FileSystem.exists(ndir))
				Sys.println('-L $ndir/');

			try {
				var f = File.getContent(d.dir + "extraParams.hxml");
				Sys.println(f.trim());
			} catch(_:Dynamic) {}

			var dir = d.dir;
			if (d.info.classPath != "") {
				var cp = d.info.classPath;
				dir = Path.addTrailingSlash( d.dir + cp );
			}
			Sys.println(dir);

			Sys.println("-D " + d.project + "="+d.info.version);
		}
	}

	function dev() {
		var rep = getRepository();
		var project = param("Library");
		var dir = paramOpt();
		var proj = rep + Data.safe(project);
		if( !FileSystem.exists(proj) ) {
			FileSystem.createDirectory(proj);
		}
		var devfile = proj+"/.dev";
		if( dir == null ) {
			if( FileSystem.exists(devfile) )
				FileSystem.deleteFile(devfile);
			print("Development directory disabled");
		}
		else {
			while ( dir.endsWith("/") || dir.endsWith("\\") ) {
				dir = dir.substr(0,-1);
			}
			if (!FileSystem.exists(dir)) {
				print('Directory $dir does not exist');
			} else {
				dir = FileSystem.fullPath(dir);
				try {
					File.saveContent(devfile, dir);
					print("Development directory set to "+dir);
				}
				catch (e:Dynamic) {
					print('Could not write to $devfile');
				}
			}

		}
	}


	function removeExistingDevLib(proj:String):Void {
		//TODO: ask if existing repo have changes.

		// find existing repo:
		var vcs = Vcs.getVcsForDevLib(proj, settings);
		// remove existing repos:
		while(vcs != null) {
			deleteRec(proj + "/" + vcs.directory);
			vcs = Vcs.getVcsForDevLib(proj, settings);
		}
	}

	inline function useVcs(id:VcsID, fn:Vcs->Void):Void {
		// Prepare check vcs.available:
		var vcs = Vcs.get(id, settings);
		if(vcs == null || !vcs.available)
			throw 'Could not use $id, please make sure it is installed and available in your PATH.';
		return fn(vcs);
	}

	function vcs(id:VcsID) {
		var rep = getRepository();
		useVcs(id, function(vcs) doVcsInstall(rep, vcs, param("Library name"), param(vcs.name + " path"), paramOpt(), paramOpt(), paramOpt()));
	}

	function doVcsInstall(rep:String, vcs:Vcs, libName:String, url:String, branch:String, subDir:String, version:String) {
		
		var proj = rep + Data.safe(libName);

		var libPath = proj + "/" + vcs.directory;
		
		var jsonPath = libPath + "/haxelib.json";
		
		if ( FileSystem.exists(proj + "/" + Data.safe(vcs.directory)) ) {
			print("You already have "+libName+" version "+vcs.directory+" installed.");
			
			var wasUpdated = this.alreadyUpdatedVcsDependencies.exists(libName);
			var currentBranch = if (wasUpdated) this.alreadyUpdatedVcsDependencies.get(libName) else null;
			
			if (branch != null && (!wasUpdated || (wasUpdated && currentBranch != branch))
				&& ask("Overwrite branch: " + (currentBranch == null?"<unspecified>":"\"" + currentBranch + "\"") + " with \"" + branch + "\""))
			{
				deleteRec(libPath);
				this.alreadyUpdatedVcsDependencies.set(libName, branch);
			}
			else
			{
				if (!wasUpdated)
				{
					print("Updating " + libName+" version " + vcs.directory + " ...");
					this.alreadyUpdatedVcsDependencies.set(libName, branch);
					updateByName(rep, libName);
					setCurrent(rep, libName, vcs.directory, true);
					
					if(FileSystem.exists(jsonPath))
						doInstallDependencies(rep, Data.readData(File.getContent(jsonPath), false).dependencies);
				}
				return;
			}
		}

		print("Installing " +libName + " from " +url + ( branch != null ? " branch: " + branch : "" ));
		
		try {
			vcs.clone(libPath, url, branch, version);
		} catch(error:VcsError) {
			deleteRec(libPath);
			var message = switch(error) {
				case VcsUnavailable(vcs):
					'Could not use ${vcs.executable}, please make sure it is installed and available in your PATH.';
				case CantCloneRepo(vcs, repo, stderr):
					'Could not clone ${vcs.name} repository' + (stderr != null ? ":\n" + stderr : ".");
				case CantCheckoutBranch(vcs, branch, stderr):
					'Could not checkout branch, tag or path "$branch": ' + stderr;
				case CantCheckoutVersion(vcs, version, stderr):
					'Could not checkout tag "$version": ' + stderr;
			};
			throw message;
		}

		// finish it!
		if (subDir != null) {
			libPath += "/" + subDir;
			File.saveContent(proj + "/.dev", libPath);
			print("Development directory set to "+libPath);
		} else {
			File.saveContent(proj + "/.current", vcs.directory);
			print("Library "+libName+" current version is now "+vcs.directory);
		}

		this.alreadyUpdatedVcsDependencies.set(libName, branch);

		if(FileSystem.exists(jsonPath))
			doInstallDependencies(rep, Data.readData(File.getContent(jsonPath), false).dependencies);
	}


	function run() {
		var rep = getRepository();
		var project = param("Library");
		var temp = project.split(":");
		doRun(rep, temp[0], temp[1]);
	}

	function doRun( rep:String, project:String, version:String ) {
		var pdir = rep + Data.safe(project);
		if( !FileSystem.exists(pdir) )
			throw "Library "+project+" is not installed";
		pdir += "/";
		if (version == null)
			version = getCurrent(pdir);
		var dev = try getDev(pdir) catch ( e : Dynamic ) null;
		var vdir = dev != null ? dev : pdir + Data.safe(version);

		var infos =
			try
				Data.readData(File.getContent(vdir + '/haxelib.json'), false)
			catch (e:Dynamic)
				throw 'Error parsing haxelib.json for $project@$version: $e';

		args.push(Sys.getCwd());
		Sys.setCwd(vdir);

		var callArgs =
			if (infos.main == null) {
				if( !FileSystem.exists('$vdir/run.n') )
					throw 'Library $project version $version does not have a run script';
				["neko", vdir + "/run.n"];
			} else {
				var deps = infos.dependencies.toArray();
				deps.push( { name: project, version: DependencyVersion.DEFAULT } );
				var args = [];
				for (d in deps) {
					args.push('-lib');
					args.push(d.name + if (d.version == '') '' else ':${d.version}');
				}
				args.unshift('haxe');
				args.push('--run');
				args.push(infos.main);
				args;
			}

		for (i in argcur...args.length)
			callArgs.push(args[i]);

		Sys.putEnv("HAXELIB_RUN", "1");
		Sys.putEnv("HAXELIB_RUN_NAME", project);
		var cmd = callArgs.shift();
 		Sys.exit(Sys.command(cmd, callArgs));
	}

	function proxy() {
		var rep = getRepository();
		var host = param("Proxy host");
		if( host == "" ) {
			if( FileSystem.exists(rep + "/.proxy") ) {
				FileSystem.deleteFile(rep + "/.proxy");
				print("Proxy disabled");
			} else
				print("No proxy specified");
			return;
		}
		var port = Std.parseInt(param("Proxy port"));
		var authName = param("Proxy user login");
		var authPass = authName == "" ? "" : param("Proxy user pass");
		var proxy = {
			host : host,
			port : port,
			auth : authName == "" ? null : { user : authName, pass : authPass },
		};
		Http.PROXY = proxy;
		print("Testing proxy...");
		try Http.requestUrl("http://www.google.com") catch( e : Dynamic ) {
			print("Proxy connection failed");
			return;
		}
		File.saveContent(rep + "/.proxy", haxe.Serializer.run(proxy));
		print("Proxy setup done");
	}

	function loadProxy() {
		var rep = getRepository();
		try Http.PROXY = haxe.Unserializer.run(File.getContent(rep + "/.proxy")) catch( e : Dynamic ) { };
	}

	function convertXml() {
		var cwd = Sys.getCwd();
		var xmlFile = cwd + "haxelib.xml";
		var jsonFile = cwd + "haxelib.json";

		if (!FileSystem.exists(xmlFile)) {
			print('No `haxelib.xml` file was found in the current directory.');
			Sys.exit(0);
		}

		var xmlString = File.getContent(xmlFile);
		var json = ConvertXml.convert(xmlString);
		var jsonString = ConvertXml.prettyPrint(json);

		File.saveContent(jsonFile, jsonString);
		print('Saved to $jsonFile');
	}

	function newRepo() {
		var path = #if (haxe_ver >= 3.2) FileSystem.absolutePath(REPODIR) #else REPODIR #end;
		var created = FsUtils.safeDir(path, true);
		if (created)
			print('Local repository created ($path)');
		else
			print('Local repository already exists ($path)');
	}

	function deleteRepo() {
		var path = #if (haxe_ver >= 3.2) FileSystem.absolutePath(REPODIR) #else REPODIR #end;
		var deleted = FsUtils.deleteRec(path);
		if (deleted)
			print('Local repository deleted ($path)');
		else
			print('No local repository found ($path)');
	}

	// ----------------------------------

	inline function print(str)
		Sys.println(str);

	static function main() {
		new Main().process();
	}


	// deprecated commands
	function local() {
		doInstallFile(getRepository(), param("Package"), true, true);
	}

	function updateSelf() {
		updateByName(getGlobalRepository(), HAXELIB_LIBNAME);
	}
}
