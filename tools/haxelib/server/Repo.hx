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
package haxelib.server;

import haxe.io.*;
import neko.Web;
import sys.io.*;
import sys.*;

import haxelib.Data;
import haxelib.SemVer;
import haxelib.server.Paths.*;
import haxelib.server.SiteDb;
import haxelib.server.FileStorage;

class Repo implements SiteApi {

	static function run() {
		FileSystem.createDirectory(TMP_DIR);

		var ctx = new haxe.remoting.Context();
		ctx.addObject("api", new Repo());

		if( haxe.remoting.HttpConnection.handleRequest(ctx) )
			return;
		else
			throw "Invalid remoting call";
	}

	public function new() {}

	public function search( word : String ) : List<{ id : Int, name : String }> {
		return Project.containing(word);
	}

	public function infos( project : String ) : ProjectInfos {
		var p = Project.manager.select($name == project);
		if( p == null )
			throw "No such Project : "+project;
		var vl = Version.manager.search($project == p.id);

		var sumDownloads = function(version:Version, total:Int) return total += version.downloads;
		var totalDownloads = Lambda.fold(vl, sumDownloads, 0);

		return {
			name : p.name,
			curversion : if( p.versionObj == null ) null else p.versionObj.toSemver(),
			desc : p.description,
			versions:
				[for ( v in vl ) {
					name : v.toSemver(),
					comments : v.comments,
					downloads : v.downloads,
					date : v.date
				}],
			owner : p.ownerObj.name,
			website : p.website,
			license : p.license,
			downloads : totalDownloads,
			tags : Tag.manager.search($project == p.id).map(function(t) return t.tag),
		};
	}

	public function getLatestVersion( project : String ) : SemVer {
		var p = Project.manager.select($name == project);
		if( p == null )
			throw "No such Project : "+project;

		var vl = Version.manager.unsafeObjects('SELECT * FROM Version WHERE project = ${p.id} ORDER BY major DESC, minor DESC, patch DESC, ifnull(preview, 100) DESC, previewNum DESC LIMIT 1', false);
		return vl.first().toSemver();
	}

	public function user( name : String ) : UserInfos {
		var u = User.manager.search($name == name).first();
		if( u == null )
			throw "No such user : "+name;
		var pl = Project.manager.search($owner == u.id);
		var projects = new Array();
		for( p in pl )
			projects.push(p.name);
		return {
			name : u.name,
			fullname : u.fullname,
			email : u.email,
			projects : projects,
		};
	}

	public function register( name : String, pass : String, mail : String, fullname : String ) : Void {
		if( name.length < 3 )
			throw "User name must be at least 3 characters";
		if( !Data.alphanum.match(name) )
			throw "Invalid user name, please use alphanumeric characters";
		if( User.manager.count($name == name) > 0 )
			throw 'User name "$name" is already taken';
		var u = new User();
		u.name = name;
		u.pass = pass;
		u.email = mail;
		u.fullname = fullname;
		u.insert();
	}

	public function isNewUser( name : String ) : Bool {
		return User.manager.select($name == name) == null;
	}

	public function checkDeveloper( prj : String, user : String ) : Void {
		var p = Project.manager.search({ name : prj }).first();
		if( p == null )
			return;
		for( d in Developer.manager.search({ project : p.id }) )
			if( d.userObj.name == user )
				return;
		throw "User '"+user+"' is not a developer of project '"+prj+"'";
	}

	public function checkPassword( user : String, pass : String ) : Bool {
		var u = User.manager.search({ name : user }).first();
		return u != null && u.pass == pass;
	}

	public function getSubmitId() : String {
		return Std.string(Std.random(100000000));
	}

	public function processSubmit( id : String, user : String, pass : String ) : String {
		var tmpFile = Path.join([TMP_DIR_NAME, Std.parseInt(id)+".tmp"]);
		return FileStorage.instance.readFile(
			tmpFile,
			function(path):String {
				var file = try sys.io.File.read(path,true) catch( e : Dynamic ) throw "Invalid file id #"+id;
				var zip = try haxe.zip.Reader.readZip(file) catch( e : Dynamic ) { file.close(); neko.Lib.rethrow(e); };
				file.close();

				var infos = Data.readInfos(zip,true);
				var u = User.manager.search({ name : user }).first();
				if( u == null || u.pass != pass )
					throw "Invalid username or password";

				var devs = infos.contributors.map(function(user) {
					var u = User.manager.search({ name : user }).first();
					if( u == null )
						throw "Unknown user '"+user+"'";
					return u;
				});

				var tags = Lambda.array(infos.tags);
				tags.sort(Reflect.compare);

				var p = Project.manager.search({ name : infos.name }).first();

				// create project if needed
				if( p == null ) {
					p = new Project();
					p.name = infos.name;
					p.description = infos.description;
					p.website = infos.url;
					p.license = infos.license;
					p.ownerObj = u;
					p.insert();
					for( u in devs ) {
						var d = new Developer();
						d.userObj = u;
						d.projectObj = p;
						d.insert();
					}
					for( tag in tags ) {
						var t = new Tag();
						t.tag = tag;
						t.projectObj = p;
						t.insert();
					}
				}

				// check submit rights
				var pdevs = Developer.manager.search({ project : p.id });
				var isdev = false;
				for( d in pdevs )
					if( d.userObj.id == u.id ) {
						isdev = true;
						break;
					}
				if( !isdev )
					throw "You are not a developer of this project";

				var otags = Tag.manager.search({ project : p.id });
				var curtags = otags.map(function(t) return t.tag).join(":");

				var devsChanged = (pdevs.length != devs.length);
				if (!devsChanged) { // same length, check whether elements are the same
					for (d in pdevs) {
						var exists = Lambda.exists(devs, function(u) return u.id == d.userObj.id);
						if (!exists) {
							devsChanged = true;
							break;
						}
					}
				}

				// update public infos
				if( devsChanged || infos.description != p.description || p.website != infos.url || p.license != infos.license || tags.join(":") != curtags ) {
					if( u.id != p.ownerObj.id )
						throw "Only project owner can modify project infos";
					p.description = infos.description;
					p.website = infos.url;
					p.license = infos.license;
					p.update();
					if( devsChanged ) {
						for( d in pdevs )
							d.delete();
						for( u in devs ) {
							var d = new Developer();
							d.userObj = u;
							d.projectObj = p;
							d.insert();
						}
					}
					if( tags.join(":") != curtags ) {
						for( t in otags )
							t.delete();
						for( tag in tags ) {
							var t = new Tag();
							t.tag = tag;
							t.projectObj = p;
							t.insert();
						}
					}
				}

				// look for current version
				var current = null;
				for( v in Version.manager.search({ project : p.id }) )
					if( v.name == infos.version ) {
						current = v;
						break;
					}

				// update documentation
				var doc = null;
				var docXML = Data.readDoc(zip);
				if( docXML != null ) {
					try {
						var p = new haxe.rtti.XmlParser();
						p.process(Xml.parse(docXML).firstElement(),null);
						p.sort();
						var roots = new Array();
						for( x in p.root )
							switch( x ) {
							case TPackage(name,_,_):
								switch( name ) {
								case "flash","sys","cs","java","haxe","js","neko","cpp","php","python": // don't include haXe core types
								default: roots.push(x);
								}
							default:
								// don't include haXe root types
							}
						var s = new haxe.Serializer();
						s.useEnumIndex = true;
						s.useCache = true;
						s.serialize(roots);
						doc = s.toString();
					} catch ( e:Dynamic ) {
						// If documentation can't be generated, ignore it.
					}
				}

				// update file
				var fileName = Data.fileName(p.name, infos.version);
				var storage = FileStorage.instance;
				storage.importFile(path, Path.join([Paths.REP_DIR_NAME, fileName]), true);
				storage.deleteFile(tmpFile);

				var semVer = SemVer.ofString(infos.version);

				// update existing version
				if( current != null ) {
					current.documentation = doc;
					current.comments = infos.releasenote;
					current.update();
					return "Version "+current.name+" (id#"+current.id+") updated";
				}

				// add new version
				var v = new Version();
				v.projectObj = p;
				v.major = semVer.major;
				v.minor = semVer.minor;
				v.patch = semVer.patch;
				v.preview = semVer.preview;
				v.previewNum = semVer.previewNum;

				v.comments = infos.releasenote;
				v.downloads = 0;
				v.date = Date.now().toString();
				v.documentation = doc;
				v.insert();

				// p.versionObj is the one shown on the website
				if (p.versionObj == null || p.versionObj.toSemver() < v.toSemver()) {
					p.versionObj = v;
				}

				p.update();
				return "Version " + v.toSemver() + " (id#" + v.id + ") added";
			}
		);
	}

	public function postInstall( project : String, version : String ) {
		var p = Project.manager.select($name == project);
		if( p == null )
			throw "No such Project : " + project;

		var version = SemVer.ofString(version);
		// don't use macro select because of
		// https://github.com/HaxeFoundation/haxe/issues/4931
		// and https://github.com/HaxeFoundation/haxe/issues/4932
		var v = Version.manager.dynamicSearch({
			project: p.id,
			major: version.major,
			minor: version.minor,
			patch: version.patch,
			preview: if (version.preview == null) null else version.preview.getIndex(),
			previewNum: version.previewNum
		}).first();

		if( v == null )
			throw "No such Version : " + version;
		v.downloads++;
		v.update();
		p.downloads++;
		p.update();
	}

	static function main() {
		var error = null;
		SiteDb.init();
		try {
			run();
		} catch( e : Dynamic ) {
			error = { e : e };
		}
		SiteDb.cleanup();
		if( error != null )
			neko.Lib.rethrow(error.e);
	}

}
