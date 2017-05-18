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

import sys.FileSystem;
using haxelib.client.Vcs;

interface IVcs {
	var name(default, null):String;
	var directory(default, null):String;
	var executable(default, null):String;
	var available(get, null):Bool;
	var settings(default, null):Settings;

	/**
		Clone repo into `libPath`.
	**/
	function clone(libPath:String, vcsPath:String, ?branch:String, ?version:String):Void;

	/**
		Update to HEAD repo contains in CWD or CWD/`Vcs.directory`.
		CWD must be like "...haxelib-repo/lib/git" for Git.
		Returns `true` if update successful.
	**/
	function update(libName:String):Bool;
}


@:enum abstract VcsID(String) to String {
	var Hg = "hg";
	var Git = "git";
}

enum VcsError {
	VcsUnavailable(vcs:Vcs);
	CantCloneRepo(vcs:Vcs, repo:String, ?stderr:String);
	CantCheckoutBranch(vcs:Vcs, branch:String, stderr:String);
	CantCheckoutVersion(vcs:Vcs, version:String, stderr:String);
}


typedef Settings = {
	@:optional var flat:Bool;
	@:optional var debug:Bool;
	@:optional var quiet:Bool;
}


class Vcs implements IVcs {
	static var reg:Map<VcsID, Vcs>;

	public var name(default, null):String;
	public var directory(default, null):String;
	public var executable(default, null):String;
	public var settings(default, null):Settings;

	public var available(get, null):Bool;

	var availabilityChecked = false;
	var executableSearched = false;

	public static function initialize(settings:Settings) {
		if (reg == null) {
			reg = [
				VcsID.Git => new Git(settings),
				VcsID.Hg => new Mercurial(settings)
			];
		} else {
			if (reg.get(VcsID.Git) == null)
				reg.set(VcsID.Git, new Git(settings));
			if (reg.get(VcsID.Hg) == null)
				reg.set(VcsID.Hg, new Mercurial(settings));
		}
	}


	function new(executable:String, directory:String, name:String, settings:Settings) {
		this.name = name;
		this.directory = directory;
		this.executable = executable;
		this.settings = {
			flat: settings.flat != null ? settings.flat : false,
			debug: settings.debug != null ? settings.debug : false,
			quiet: settings.quiet != null ? settings.quiet : false
		}

		if (settings.debug) {
			this.settings.quiet = false;
		}
	}


	public static function get(id:VcsID, settings:Settings):Null<Vcs> {
		initialize(settings);
		return reg.get(id);
	}

	static function set(id:VcsID, vcs:Vcs, settings:Settings, ?rewrite:Bool):Void {
		initialize(settings);
		var existing = reg.get(id) != null;
		if (!existing || rewrite)
			reg.set(id, vcs);
	}

	public static function getVcsForDevLib(libPath:String, settings:Settings):Null<Vcs> {
		initialize(settings);
		for (k in reg.keys()) {
			if (FileSystem.exists(libPath + "/" + k) && FileSystem.isDirectory(libPath + "/" + k))
				return reg.get(k);
		}
		return null;
	}

	function sure(commandResult:{code:Int, out:String}):Void {
		switch (commandResult) {
			case {code: 0}: //pass
			case {code: code, out:out}:
				if (!settings.debug) 
					Sys.stderr().writeString(out);
				Sys.exit(code);
		}
	}

    function command(cmd:String, args:Array<String>):{
    	code: Int,
    	out: String
    } {
        var p = try {
        	new sys.io.Process(cmd, args);
        } catch(e:Dynamic) {
        	return {
        		code: -1,
        		out: Std.string(e)
        	}
        }
        var out = p.stdout.readAll().toString();
        var err = p.stderr.readAll().toString();
        if (settings.debug && out != "")
        	Sys.println(out);
        if (settings.debug && err != "")
        	Sys.stderr().writeString(err);
        var code = p.exitCode();
        var ret = {
            code: code,
            out: code == 0 ? out : err
        };
        p.close();
        return ret;
    }

	function searchExecutable():Void {
		executableSearched = true;
	}

	function checkExecutable():Bool {
		available = (executable != null) && try command(executable, []).code == 0 catch(_:Dynamic) false;
		availabilityChecked = true;

		if (!available && !executableSearched)
			searchExecutable();

		return available;
	}

	@:final function get_available():Bool {
		if (!availabilityChecked)
			checkExecutable();
		return available;
	}

	public function clone(libPath:String, vcsPath:String, ?branch:String, ?version:String):Void {
		throw "This method must be overriden.";
	}

	public function update(libName:String):Bool {
		throw "This method must be overriden.";
	}
}


class Git extends Vcs {

	public function new(settings:Settings)
		super("git", "git", "Git", settings);

	override function checkExecutable():Bool {
		// with `help` cmd because without any cmd `git` can return exit-code = 1.
		available = (executable != null) && try command(executable, ["help"]).code == 0 catch(_:Dynamic) false;
		availabilityChecked = true;

		if (!available && !executableSearched)
			searchExecutable();

		return available;
	}

	override function searchExecutable():Void {
		super.searchExecutable();

		if (available)
			return;

		// if we have already msys git/cmd in our PATH
		var match = ~/(.*)git([\\|\/])cmd$/;
		for (path in Sys.getEnv("PATH").split(";")) {
			if (match.match(path.toLowerCase())) {
				var newPath = match.matched(1) + executable + match.matched(2) + "bin";
				Sys.putEnv("PATH", Sys.getEnv("PATH") + ";" + newPath);
			}
		}

		if (checkExecutable())
			return;

		// look at a few default paths
		for (path in ["C:\\Program Files (x86)\\Git\\bin", "C:\\Progra~1\\Git\\bin"]) {
			if (FileSystem.exists(path)) {
				Sys.putEnv("PATH", Sys.getEnv("PATH") + ";" + path);
				if (checkExecutable())
					return;
			}
		}
	}

	override public function update(libName:String):Bool {
		if (
			command(executable, ["diff", "--exit-code"]).code != 0
			||
			command(executable, ["diff", "--cached", "--exit-code"]).code != 0
		) {
			if (Cli.ask("Reset changes to " + libName + " " + name + " repo so we can pull latest version?")) {
				sure(command(executable, ["reset", "--hard"]));
			} else {
				if (!settings.quiet)
					Sys.println(name + " repo left untouched");
				return false;
			}
		}

		var code = command(executable, ["pull"]).code;
		// But if before we pulled specified branch/tag/rev => then possibly currently we haxe "HEAD detached at ..".
		if (code != 0) {
			// get parent-branch:
			var branch = command(executable, ["show-branch"]).out;
			var regx = ~/\[([^]]*)\]/;
			if (regx.match(branch))
				branch = regx.matched(1);

			sure(command(executable, ["checkout", branch, "--force"]));
			sure(command(executable, ["pull"]));
		}
		return true;
	}

	override public function clone(libPath:String, url:String, ?branch:String, ?version:String):Void {
		var oldCwd = Sys.getCwd();

		var vcsArgs = ["clone", url, libPath];

		if (settings == null || !settings.flat)
			vcsArgs.push('--recursive');

		//TODO: move to Vcs.run(vcsArgs)
		//TODO: use settings.quiet
		if (command(executable, vcsArgs).code != 0)
			throw VcsError.CantCloneRepo(this, url/*, ret.out*/);


		Sys.setCwd(libPath);
		
		if (version != null && version != "") {
			var ret = command(executable, ["checkout", "tags/" + version]);
			if (ret.code != 0)
				throw VcsError.CantCheckoutVersion(this, version, ret.out);
		} else if (branch != null) {
			var ret = command(executable, ["checkout", branch]);
			if (ret.code != 0)
				throw VcsError.CantCheckoutBranch(this, branch, ret.out);
		}

		// return prev. cwd:
		Sys.setCwd(oldCwd);
	}
}


class Mercurial extends Vcs {

	public function new(settings:Settings)
		super("hg", "hg", "Mercurial", settings);

	override function searchExecutable():Void {
		super.searchExecutable();

		if (available)
			return;

		// if we have already msys git/cmd in our PATH
		var match = ~/(.*)hg([\\|\/])cmd$/;
		for(path in Sys.getEnv("PATH").split(";")) {
			if(match.match(path.toLowerCase())) {
				var newPath = match.matched(1) + executable + match.matched(2) + "bin";
				Sys.putEnv("PATH", Sys.getEnv("PATH") + ";" + newPath);
			}
		}
		checkExecutable();
	}

	override public function update(libName:String):Bool {
		command(executable, ["pull"]);
		var summary = command(executable, ["summary"]).out;
		var diff = command(executable, ["diff", "-U", "2", "--git", "--subrepos"]);
		var status = command(executable, ["status"]);

		// get new pulled changesets:
		// (and search num of sets)
		summary = summary.substr(0, summary.length - 1);
		summary = summary.substr(summary.lastIndexOf("\n") + 1);
		// we don't know any about locale then taking only Digit-exising:s
		var changed = ~/(\d)/.match(summary);
		if (changed && !settings.quiet)
			// print new pulled changesets:
			Sys.println(summary);


		if (diff.code + status.code + diff.out.length + status.out.length != 0) {
			if (!settings.quiet)
				Sys.println(diff.out);
			if (Cli.ask("Reset changes to " + libName + " " + name + " repo so we can update to latest version?")) {
				sure(command(executable, ["update", "--clean"]));
			} else {
				changed = false;
				if (!settings.quiet)
					Sys.println(name + " repo left untouched");
			}
		} else if (changed) {
			sure(command(executable, ["update"]));
		}

		return changed;
	}

	override public function clone(libPath:String, url:String, ?branch:String, ?version:String):Void {
		var vcsArgs = ["clone", url, libPath];

		if (branch != null) {
			vcsArgs.push("--branch");
			vcsArgs.push(branch);
		}

		if (version != null) {
			vcsArgs.push("--rev");
			vcsArgs.push(version);
		}

		if (command(executable, vcsArgs).code != 0)
			throw VcsError.CantCloneRepo(this, url/*, ret.out*/);
	}
}
