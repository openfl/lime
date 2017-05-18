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
package haxelib;

import haxe.ds.Option;
import haxe.zip.Reader;
import haxe.zip.Entry;
import haxe.Json;
import haxelib.Validator;

using StringTools;

typedef UserInfos = {
	var name : String;
	var fullname : String;
	var email : String;
	var projects : Array<String>;
}

typedef VersionInfos = {
	var date : String;
	var name : SemVer;//TODO: this should eventually be called `number`
	var downloads : Int;
	var comments : String;
}

typedef ProjectInfos = {
	var name : String;
	var desc : String;
	var website : String;
	var owner : String;
	var license : String;
	var curversion : String;
	var downloads : Int;
	var versions : Array<VersionInfos>;
	var tags : List<String>;
}

abstract DependencyVersion(String) to String from SemVer {
	inline function new(s:String)
		this = s;

	@:to function toValidatable():Validatable
		return
			if (this == '') { validate: function () return None }
			else @:privateAccess new SemVer(this);

	static public function isValid(s:String)
		return new DependencyVersion(s).toValidatable().validate() == None;

	static public var DEFAULT(default, null) = new DependencyVersion('');
}

abstract Dependencies(Dynamic<DependencyVersion>) from Dynamic<DependencyVersion> {
	@:to public function toArray():Array<Dependency> {
		var fields = Reflect.fields(this);
		fields.sort(Reflect.compare);
		
		var result:Array<Dependency> = new Array<Dependency>();
		
		for (f in fields) {
			var value:String = Reflect.field(this, f);

			var isGit = value != null && (value + "").startsWith("git:"); 
			
			if ( !isGit )
			{
				result.push ({
					name: f,
					type: (DependencyType.Haxelib : DependencyType),
					version: (cast value : DependencyVersion),
					url: (null : String),
					subDir: (null : String),
					branch: (null : String),
				});
			}
			else
			{
				value = value.substr(4);
				var urlParts = value.split("#");
				var url = urlParts[0];
				var branch = urlParts.length > 1 ? urlParts[1] : null;
				
				result.push ({
					name: f,
					type: (DependencyType.Git : DependencyType),
					version: (DependencyVersion.DEFAULT : DependencyVersion),
					url: (url : String),
					subDir: (null : String),
					branch: (branch : String),
				});
			}
			
			
		}
		
		return result;
	}
	public inline function iterator()
		return toArray().iterator();
}

@:enum abstract DependencyType(String) {
	var Haxelib = null;
	var Git = 'git';
	var Mercurial = 'hg';
}

typedef Dependency = {
	name : String,
	?version : DependencyVersion,
	?type: DependencyType,
	?url: String,
	?subDir: String,
	?branch: String,
}

typedef Infos = {
	// IMPORTANT: if you change this or its fields types,
	// make sure to update `schema.json` file accordingly,
	// and make an update PR to https://github.com/SchemaStore/schemastore
	var name : ProjectName;
	@:optional var url : String;
	@:optional var description : String;
	var license : License;
	var version : SemVer;
	@:optional var classPath : String;
	var releasenote : String;
	@:requires('Specify at least one contributor' => _.length > 0)
	var contributors : Array<String>;
	@:optional var tags : Array<String>;
	@:optional var dependencies : Dependencies;
	@:optional var main:String;
}

@:enum abstract License(String) to String {
	var Gpl = 'GPL';
	var Lgpl = 'LGPL';
	var Mit = 'MIT';
	var Bsd = 'BSD';
	var Public = 'Public';
	var Apache = 'Apache';
}

abstract ProjectName(String) to String {
	static var RESERVED_NAMES = ["haxe", "all"];
	static var RESERVED_EXTENSIONS = ['.zip', '.hxml'];
	inline function new(s:String)
		this = s;

	@:to function toValidatable():Validatable
		return {
			validate:
				function ():Option<String> {
					for (r in rules)
						if (!r.check(this))
							return Some(r.msg.replace('%VALUE', '`' + Json.stringify(this) + '`'));
						return None;
				}
		}

	static var rules = {//using an array because order might matter
		var a = new Array<{ msg: String, check:String->Bool }>();

		function add(m, r)
			a.push( { msg: m, check: r } );

		add("%VALUE is not a String", Std.is.bind(_, String));
		add("%VALUE is too short", function (s) return s.length >= 3);
		add("%VALUE contains invalid characters", Data.alphanum.match);
		add("%VALUE is a reserved name", function(s) return RESERVED_NAMES.indexOf(s.toLowerCase()) == -1);
		add("%VALUE ends with a reserved suffix", function(s) {
			s = s.toLowerCase();
			for (ext in RESERVED_EXTENSIONS)
				if (s.endsWith(ext)) return false;
			return true;
		});

		a;
	}

	public function validate()
		return toValidatable().validate();

	static public function ofString(s:String)
		return switch new ProjectName(s) {
			case _.toValidatable().validate() => Some(e): throw e;
			case v: v;
		}

	static public var DEFAULT(default, null) = new ProjectName('unknown');
}

class Data {

	public static var JSON(default, null) = "haxelib.json";
	public static var DOCXML(default, null) = "haxedoc.xml";
	public static var REPOSITORY(default, null) = "files/3.0";
	public static var alphanum(default, null) = ~/^[A-Za-z0-9_.-]+$/;


	public static function safe( name : String ) {
		if( !alphanum.match(name) )
			throw "Invalid parameter : "+name;
		return name.split(".").join(",");
	}

	public static function unsafe( name : String ) {
		return name.split(",").join(".");
	}

	public static function fileName( lib : String, ver : String ) {
		return safe(lib)+"-"+safe(ver)+".zip";
	}

	static public function getLatest(info:ProjectInfos, ?preview:SemVer.Preview->Bool):Null<SemVer> {
		if (info.versions.length == 0) return null;
		if (preview == null)
			preview = function (p) return p == null;

		var versions = info.versions.copy();
		versions.sort(function (a, b) return -SemVer.compare(a.name, b.name));

		for (v in versions)
			if (preview(v.name.preview)) return v.name;

		return versions[0].name;
	}

	/**
		Return the directory that contains *haxelib.json*.
		If it is at the root, `""`.
		If it is in a folder, the path including a trailing slash is returned.
	*/
	public static function locateBasePath( zip : List<Entry> ):String {
		var f = getJson(zip);
		return f.fileName.substr(0, f.fileName.length - JSON.length);
	}

	static function getJson(zip:List<Entry>)
		return switch topmost(zip, fileNamed(JSON)) {
			case Some(f): f;
			default: throw 'No $JSON found';
		}

	static function fileNamed(name:String)
		return function (f:Entry) return f.fileName.endsWith(name);

	static function topmost(zip:List<Entry>, predicate:Entry->Bool):Option<Entry> {
		var best:Entry = null,
			bestDepth = 0xFFFF;

		for (f in zip)
			if (predicate(f)) {
				var depth = f.fileName.replace('\\', '/').split('/').length;//TODO: consider Path.normalize
				if ((depth == bestDepth && f.fileName < best.fileName) || depth < bestDepth) {
					best = f;
					bestDepth = depth;
				}
			}

		return
			if (best == null)
				None;
			else
				Some(best);
	}

	public static function readDoc( zip : List<Entry> ) : Null<String>
		return switch topmost(zip, fileNamed(DOCXML)) {
			case Some(f): Reader.unzip(f).toString();
			case None: null;
		}


	public static function readInfos( zip : List<Entry>, check : Bool ) : Infos
		return readData(Reader.unzip(getJson(zip)).toString(), check);

	public static function checkClassPath( zip : List<Entry>, infos : Infos ) {
		if ( infos.classPath != "" ) {
			var basePath = Data.locateBasePath(zip);
			var cp = basePath + infos.classPath;

			for( f in zip ) {
				if( StringTools.startsWith(f.fileName,cp) )
					return;
			}
			throw 'Class path `${infos.classPath}` not found';
		}
	}

	public static function readData( jsondata: String, check : Bool ) : Infos {
		var doc:Infos =
			try Json.parse(jsondata)
			catch ( e : Dynamic )
				if (check)
					throw 'JSON parse error: $e';
				else {
					name : ProjectName.DEFAULT,
					url : '',
					version : SemVer.DEFAULT,
					releasenote: 'No haxelib.json found',
					license: Mit,
					description: 'No haxelib.json found',
					contributors: [],
				}

		if (check)
			Validator.validate(doc);
		else {
			if (!doc.version.valid)
				doc.version = SemVer.DEFAULT;
		}

		//TODO: we have really weird ways to go about nullability and defaults

		if (doc.dependencies == null)
			doc.dependencies = {};

		for (dep in doc.dependencies)
			if (!DependencyVersion.isValid(dep.version))
				Reflect.setField(doc.dependencies, dep.name, DependencyVersion.DEFAULT);//TODO: this is pure evil

		if (doc.classPath == null)
			doc.classPath = '';

		if (doc.name.validate() != None)
			doc.name = ProjectName.DEFAULT;

		if (doc.description == null)
			doc.description = '';

    if (doc.tags == null)
      doc.tags = [];

		if (doc.url == null)
			doc.url = '';

		return doc;
	}
}