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

import sys.db.*;
import sys.db.Types;
import haxelib.server.Paths.*;

class User extends Object {

	public var id : SId;
	public var name : String;
	public var fullname : String;
	public var email : String;
	public var pass : String;

}

class Project extends Object {

	public var id : SId;
	public var name : String;
	public var description : String;
	public var website : String;
	public var license : String;
	public var downloads : Int = 0;
	@:relation(owner) public var ownerObj : User;
	@:relation(version) public var versionObj : SNull<Version>;

	static public function containing( word:String ) : List<{ id: Int, name: String }> {
		var ret = new List();
		word = '%$word%';
		for (project in manager.search($name.like(word) || $description.like(word)))
			ret.push( { id: project.id, name: project.name } );
		return ret;
	}

	static public function allByName() {
		//TODO: Propose SPOD patch to support manager.search(true, { orderBy: name.toLowerCase() } );
		return manager.unsafeObjects('SELECT * FROM Project ORDER BY LOWER(name)', false);
	}

}

class Tag extends Object {

	public var id : SId;
	public var tag : String;
	@:relation(project) public var projectObj : Project;

	static public function topTags( n : Int ) : List<{ tag:String, count: Int }> {
		return cast Manager.cnx.request("SELECT tag, COUNT(*) as count FROM Tag GROUP BY tag ORDER BY count DESC LIMIT " + n).results();
	}

}

class Version extends Object {

	public var id : SId;
	@:relation(project) public var projectObj : Project;
	public var major : Int;
	public var minor : Int;
	public var patch : Int;
	public var preview : SNull<SEnum<SemVer.Preview>>;
	public var previewNum : SNull<Int>;
	@:skip public var name(get, never):String;
	function get_name():String return toSemver();

	public function toSemver():SemVer {
		return {
			major: this.major,
			minor: this.minor,
			patch: this.patch,
			preview: this.preview,
			previewNum: this.previewNum,
		}
	}
	public var date : String; // sqlite does not have a proper 'date' type
	public var comments : String;
	public var downloads : Int;
	public var documentation : SNull<String>;

	static public function latest( n : Int ) {
		return manager.search(1 == 1, { orderBy: -date, limit: n } );
	}

	static public function byProject( p : Project ) {
		return manager.search($project == p.id, { orderBy: -date } );
	}

}

@:id(user,project)
class Developer extends Object {

	@:relation(user) public var userObj : User;
	@:relation(project) public var projectObj : Project;

}

class SiteDb {
	static var db : Connection;
	//TODO: this whole configuration business is rather messy to say the least

	static public function init() {
		db =
			if (Sys.getEnv("HAXELIB_DB_HOST") != null)
				Mysql.connect({
					"host":     Sys.getEnv("HAXELIB_DB_HOST"),
					"port":     Std.parseInt(Sys.getEnv("HAXELIB_DB_PORT")),
					"database": Sys.getEnv("HAXELIB_DB_NAME"),
					"user":     Sys.getEnv("HAXELIB_DB_USER"),
					"pass":     Sys.getEnv("HAXELIB_DB_PASS"),
					"socket":   null
				});
			else if (sys.FileSystem.exists(DB_CONFIG))
				Mysql.connect(haxe.Json.parse(sys.io.File.getContent(DB_CONFIG)));
			else
				Sqlite.open(DB_FILE);

		Manager.cnx = db;
		Manager.initialize();

		var managers:Array<Manager<Dynamic>> = [
			User.manager,
			Project.manager,
			Tag.manager,
			Version.manager,
			Developer.manager
		];
		for (m in managers)
			if (!TableCreate.exists(m))
				TableCreate.create(m);
	}

	static public function cleanup() {
		db.close();
		Manager.cleanup();
	}
}
