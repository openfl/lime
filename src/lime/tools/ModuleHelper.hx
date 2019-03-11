package lime.tools;

#if !macro
import hxp.*;
import lime.tools.Dependency;
import lime.tools.HXProject;
import lime.tools.ModuleData;
import sys.io.File;
import sys.FileSystem;
class ModuleHelper
{
	public static function addModuleSource(source:String, moduleData:ModuleData, include:Array<String>, exclude:Array<String>, packageName:String = null)
	{
		if (!FileSystem.exists(source))
		{
			Log.error("Could not find module source \"" + source + "\"");
			return;
		}

		moduleData.haxeflags.push("-cp " + source);

		var path = source;

		if (packageName != null && packageName.length > 0)
		{
			path = Path.combine(source, StringTools.replace(packageName, ".", "/"));
		}

		parseModuleSource(source, moduleData, include, exclude, path);
	}

	public static function buildModules(project:HXProject, tempDirectory:String, outputDirectory:String):Void
	{
		tempDirectory = Path.combine(tempDirectory, "lib");
		outputDirectory = Path.combine(outputDirectory, "lib");

		System.mkdir(tempDirectory);
		System.mkdir(outputDirectory);

		var importName, hxmlPath, importPath, outputPath, moduleImport, hxml;

		for (module in project.modules)
		{
			if (module.classNames.length > 0)
			{
				importName = "Module" + module.name.charAt(0).toUpperCase() + module.name.substr(1);

				hxmlPath = Path.combine(tempDirectory, module.name + ".hxml");
				importPath = Path.combine(tempDirectory, importName + ".hx");

				if (project.targetFlags.exists("final"))
				{
					outputPath = Path.combine(outputDirectory, module.name + ".min.js");
				}
				else
				{
					outputPath = Path.combine(outputDirectory, module.name + ".js");
				}

				moduleImport = "package;\n\nimport " + module.classNames.join(";\nimport ") + ";";

				hxml = "-cp " + tempDirectory;
				hxml += "\n" + module.haxeflags.join("\n");

				for (haxelib in project.haxelibs)
				{
					hxml += "\n-cp " + Haxelib.getPath(haxelib);
				}

				for (key in project.haxedefs.keys())
				{
					if (key != "no-compilation")
					{
						var value = project.haxedefs.get(key);

						if (value == null || value == "")
						{
							hxml += "\n-D " + key;
						}
						else
						{
							hxml += "\n-D " + key + "=" + value;
						}
					}
				}

				hxml += "\n-D html5";
				hxml += "\n-D html";
				hxml += "\n--no-inline";
				hxml += "\n-dce no";
				hxml += "\n-js " + outputPath;

				var includeTypes = module.classNames.concat(module.includeTypes);
				var excludeTypes = module.excludeTypes;

				for (otherModule in project.modules)
				{
					if (otherModule != module)
					{
						excludeTypes = excludeTypes.concat(ArrayTools.getUnique(includeTypes, otherModule.classNames));
						excludeTypes = excludeTypes.concat(ArrayTools.getUnique(includeTypes, otherModule.includeTypes));
					}
				}

				if (excludeTypes.length > 0)
				{
					// order by short filters first, so they match earlier
					haxe.ds.ArraySort.sort(excludeTypes, shortFirst);
					hxml += "\n--macro lime.tools.ModuleHelper.exclude(['" + excludeTypes.join("','") + "'])";
				}

				// order by short filters first, so they match earlier
				haxe.ds.ArraySort.sort(includeTypes, shortFirst);
				hxml += "\n--macro lime.tools.ModuleHelper.expose(['" + includeTypes.join("','") + "'])";
				// hxml += "\n--macro lime.tools.ModuleHelper.generate()";

				hxml += "\n" + importName;

				File.saveContent(importPath, moduleImport);
				File.saveContent(hxmlPath, hxml);

				System.runCommand("", "haxe", [hxmlPath]);

				patchFile(outputPath);

				if (project.targetFlags.exists("final"))
				{
					HTML5Helper.minify(project, outputPath);
				}
			}
		}
	}

	private static function parseModuleSource(source:String, moduleData:ModuleData, include:Array<String>, exclude:Array<String>, currentPath:String):Void
	{
		var files = FileSystem.readDirectory(currentPath);
		var filePath:String, className:String, packageName:String;

		for (file in files)
		{
			filePath = Path.combine(currentPath, file);

			if (FileSystem.isDirectory(filePath))
			{
				packageName = StringTools.replace(filePath, source, "");
				packageName = StringTools.replace(packageName, "\\", "/");

				while (StringTools.startsWith(packageName, "/"))
					packageName = packageName.substr(1);

				packageName = StringTools.replace(packageName, "/", ".");

				if (StringTools.filter(packageName, include, exclude))
				{
					parseModuleSource(source, moduleData, include, exclude, filePath);
				}
			}
			else
			{
				if (Path.extension(file) != "hx") continue;

				className = StringTools.replace(filePath, source, "");
				className = StringTools.replace(className, "\\", "/");

				while (StringTools.startsWith(className, "/"))
					className = className.substr(1);

				className = StringTools.replace(className, "/", ".");
				className = StringTools.replace(className, ".hx", "");

				if (StringTools.filter(className, include, exclude))
				{
					moduleData.classNames.push(className);
				}
			}
		}
	}

	public static function patchFile(outputPath:String):Void
	{
		var replaceString = "var $hxClasses = {}";
		var replacement = "if (!$hx_exports.$hxClasses) $hx_exports.$hxClasses = {};\nvar $hxClasses = $hx_exports.$hxClasses";

		System.replaceText(outputPath, replaceString, replacement);
	}

	public static function updateProject(project:HXProject):Void
	{
		var excludeTypes = [];
		var suffix = (project.targetFlags.exists("final") ? ".min" : "") + ".js";
		var hasModules = false;

		for (module in project.modules)
		{
			project.dependencies.push(new Dependency("./lib/" + module.name + suffix, null));

			excludeTypes = ArrayTools.concatUnique(excludeTypes, module.classNames);
			excludeTypes = ArrayTools.concatUnique(excludeTypes, module.excludeTypes);
			excludeTypes = ArrayTools.concatUnique(excludeTypes, module.includeTypes);

			hasModules = true;
		}

		if (excludeTypes.length > 0)
		{
			// order by short filters first, so they match earlier
			haxe.ds.ArraySort.sort(excludeTypes, shortFirst);
			project.haxeflags.push("--macro lime.tools.ModuleHelper.exclude(['" + excludeTypes.join("','") + "'])");
		}

		// if (hasModules) {
		//
		// project.haxeflags.push ("--macro lime.tools.ModuleHelper.generate()");
		//
		// }
	}

	public static function shortFirst(a, b):Int
	{
		if (a.length < b.length) return -1;
		else if (a.length > b.length) return 1;
		return 0;
	}
}
#else
import haxe.macro.Compiler;
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.Expr;
import haxe.macro.JSGenApi;

using haxe.macro.Tools;
using Lambda;
using StringTools;

class ModuleHelper
{
	public static function exclude(types:Array<String>):Void
	{
		for (type in types)
		{
			Compiler.exclude(type);
			Compiler.addMetadata("@:native(\"$hx_exports." + type + "\")", type);
		}
	}

	public static function expose(classNames:Array<String>):Void
	{
		for (className in classNames)
		{
			Compiler.addMetadata("@:expose('" + className + "')", className);
		}
	}

	public static function generate()
	{
		// Compiler.setCustomJSGenerator(function(api) new Generator(api).generate());
	}
}

class Generator
{
	var api:JSGenApi;
	var buf:StringBuf;
	var inits:List<TypedExpr>;
	var statics:List<{c:ClassType, f:ClassField}>;
	var packages:haxe.ds.StringMap<Bool>;
	var forbidden:haxe.ds.StringMap<Bool>;
	var jsModern:Bool;
	var jsFlatten:Bool;
	var dce:Bool;
	var indentLevel = 0;
	var genExtend = false;
	var genExpose = false;
	var iRE = ~/^(.*)$/gm;

	public function new(api)
	{
		this.api = api;
		buf = new StringBuf();
		inits = new List();
		statics = new List();
		packages = new haxe.ds.StringMap();
		forbidden = new haxe.ds.StringMap();
		jsModern = !Context.defined("js-classic");
		jsFlatten = !Context.defined("js-unflatten");
		dce = Context.definedValue("dce") != "no";
		for (x in ["prototype", "__proto__", "constructor"])
			forbidden.set(x, true);
		api.setTypeAccessor(getType);

		for (t in api.types)
		{
			switch (t)
			{
				case TInst(c, _):
					if (!c.get().isExtern && c.get().superClass != null) genExtend = true;
					if (c.get().meta.has(":expose")) genExpose = true;
					if (genExtend && genExpose) break;
				case _:
			}
		}
	}

	function getType(t:Type)
	{
		return switch (t)
		{
			case TInst(c, _): getPath(c.get());
			case TEnum(e, _): getPath(e.get());
			case TAbstract(a, _): getPath(a.get());
			default: throw "assert";
		};
	}

	inline function indent(str:String, level = 0, notFirst = false):String
	{
		var first = true;
		var lines = str.split("\n");
		var nstr = "";
		for (i in 0...lines.length)
		{
			var s = lines[i];
			if (first && notFirst)
			{
				first = false;
				nstr += s;
			}
			else
			{
				for (i in 0...level)
				{
					nstr += '\t';
				}
				nstr += '$s';
			}
			if (i < lines.length - 1) nstr += "\n";
		}
		return nstr;
	}

	inline function print(str)
	{
		printi(str, indentLevel);
	}

	inline function printi(str, level = 0, notFirst = false)
	{
		buf.add(indent(str, level, notFirst));
	}

	inline function println(s:String = "")
	{
		print(s);
		newline();
	}

	inline function printn(s:String = "")
		print('$s\n');

	inline function printin(str, level = 0, notFirst = false)
		buf.add(indent(str, level, notFirst) + "\n");

	function printif(f:String, s:String)
	{
		if (api.hasFeature(f)) println(s);
	}

	inline function newline()
	{
		buf.add(";\n");
	}

	function field(p, staticField = true)
	{
		if (staticField) return api.isKeyword(p) ? '["$p"]' : '.$p';
		else
			return api.isKeyword(p) ? '\'$p\'' : p;
	}

	function genPackage(p:Array<String>)
	{
		if (p.length == 0) print("var ");
		var full = null;
		for (x in p)
		{
			var prev = full;
			if (full == null) full = x
			else
				full += "." + x;
			if (packages.exists(full)) continue;
			packages.set(full, true);
			if (prev == null) println('var $x = ' + (jsModern ? "{}" : '$x || {}'));
			else
			{
				var p = prev + field(x);
				println((jsModern ? '' : 'if(!$p) ') + '$p = {}');
			}
		}
	}

	function getPath(t:BaseType)
	{
		return packClass(t.pack, t.name);
	}

	function getDotPath(t:BaseType)
	{
		return (t.pack.length == 0) ? t.name : t.pack.join('.') + '.' + t.name;
	}

	function packClass(p:Array<String>, name:String)
	{
		if (jsFlatten)
		{
			var r = '';
			for (i in p)
			{
				r += i.replace("_", "_$") + '_';
			}
			return r + name.replace("_", "_$");
		}
		return (p.length == 0) ? name : p.join('.') + '.' + name;
	}

	function checkFieldName(c:ClassType, f:ClassField)
	{
		if (forbidden.exists(f.name)) Context.error("The field " + f.name + " is not allowed in JS", c.pos);
	}

	function genClassField(c:ClassType, p:String, f:ClassField, first:Bool)
	{
		checkFieldName(c, f);
		var field = field(f.name, false);
		var e = f.expr();
		if (e != null)
		{
			printin((first ? "" : ",") + '$field: ' + api.generateValue(e), indentLevel, false);
			return false;
		}
		else if (!dce && (f.kind.match(FVar(AccNormal, AccNormal) | FMethod(_)) || f.meta.has(":isVar")))
		{
			printin((first ? "" : ",") + '$field: null', indentLevel, false);
			return false;
		}
		return first;
	}

	function genStaticField(c:ClassType, p:String, f:ClassField)
	{
		checkFieldName(c, f);
		var field = field(f.name);
		var e = f.expr();
		if (e != null)
		{
			switch (f.kind)
			{
				case FMethod(_):
					print('$p$field = ');
					println(api.generateValue(e));
				default:
					statics.add({c: c, f: f});
			}
		}
		else
		{
			if (!dce && (f.kind.match(FVar(AccNormal, AccNormal) | FMethod(_)) || f.meta.has(":isVar"))) println('$p$field = null');
		}
	}

	function getProperties(fields:Array<ClassField>):String
	{
		var properties = [];
		for (f in fields)
		{
			switch (f.kind)
			{
				case FVar(g, s):
					{
						if (g == AccCall) properties.push('get_${f.name}:"get_${f.name}"');
						if (s == AccCall) properties.push('set_${f.name}:"set_${f.name}"');
					}
				case _:
			}
		}
		return (properties.length > 0) ? ('{' + properties.join(",") + '}') : "";
	}

	function genClass(c:ClassType)
	{
		api.setCurrentClass(c);

		var hxClasses = api.hasFeature("Type.resolveClass");
		var p = getPath(c);
		var pn = getDotPath(c);
		if (jsFlatten) print("var ");
		else
			genPackage(c.pack);

		if (hxClasses && !jsModern) print('$p = $$hxClasses["$pn"] = ');
		else
			print('$p = ' + (c.meta.has(":expose") ? '$$hx_exports.$p = ' : ''));
		if (c.constructor != null) print(api.generateValue(c.constructor.get().expr()));
		else
			print("function() { }");
		newline();
		if (hxClasses && jsModern) println('$$hxClasses["$pn"] = $p');

		var name = pn.split(".").map(api.quoteString).join(",");
		if (api.hasFeature("js.Boot.isClass"))
		{
			if (api.hasFeature("Type.getClassName")) println('$p.__name__ = [$name]');
			else
				println('$p.__name__ = true');
		}
		if (c.interfaces.length > 0)
		{
			var me = this;
			var inter = c.interfaces.map(function(i) return me.getPath(i.t.get())).join(",");
			print('$p.__interfaces__ = [$inter]');
			newline();
		}
		var has_property_reflection = api.hasFeature("Reflect.getProperty") || api.hasFeature("Reflect.setProperty");

		if (has_property_reflection)
		{
			var staticProperties = getProperties(c.statics.get());
			if (staticProperties.length > 0) printn('$p.__properties__ = $staticProperties');
		}
		for (f in c.statics.get())
			genStaticField(c, p, f);

		var has_class = api.hasFeature("js.Boot.getClass") && (c.superClass != null || c.fields.get().length > 0 || c.constructor != null);
		var has_prototype = has_class || c.superClass != null || c.fields.get().length > 0;

		if (has_prototype)
		{
			if (c.superClass != null)
			{
				var psup = getPath(c.superClass.t.get());
				println('$p.__super__ = $psup');
				printn('$p.prototype = $$extend($psup.prototype,{');
			}
			else
			{
				printn('$p.prototype = {');
			}
			indentLevel++;
			var first = true;
			for (f in c.fields.get())
			{
				switch (f.kind)
				{
					case FVar(r, _):
						if (r == AccResolve) continue;
					default:
				}
				first = genClassField(c, p, f, first);
			}
			if (has_class)
			{
				if (!first) print(",");
				printi('__class__: $p\n');
			}
			if (has_property_reflection)
			{
				var properties = getProperties(c.fields.get());
				if (properties.length > 0) if (c.superClass != null)
				{
					var psup = getPath(c.superClass.t.get());
					printn((first ? "" : ",") + '__properties__: $$extend($psup.prototype.__properties__,$properties)');
				}
				else
					printn((first ? "" : ",") + '__properties__: $properties');
			}
			indentLevel--;
			if (c.superClass != null) printin("});", 0);
			else
				printin("};", 0);
		}
	}

	function genEnum(e:EnumType)
	{
		var p = getPath(e);
		var pn = getDotPath(e);
		var names = pn.split(".").map(api.quoteString).join(",");
		var constructs = e.names.map(api.quoteString).join(",");
		var hxClasses = api.hasFeature("Type.resolveEnum");

		if (jsFlatten) print("var ");
		else
			genPackage(e.pack);

		if (hxClasses) print('$p = $$hxClasses["$pn"] = {');
		else
			print('$p = {');

		if (api.hasFeature("js.Boot.isEnum")) if (api.hasFeature("Type.getEnumName")) print(' __ename__ : [$names],');
		else
			print(' __ename__ : true,');
		println(' __constructs__ : [$constructs] }');
		for (c in e.constructs.keys())
		{
			var c = e.constructs.get(c);
			var f = field(c.name);
			print('$p$f = ');
			switch (c.type)
			{
				case TFun(args, _):
					var sargs = args.map(function(a) return a.name).join(",");
					print('function($sargs) { var $$x = ["${c.name}",${c.index},$sargs]; $$x.__enum__ = $p; $$x.toString = $$estr; return $$x; }');
				default:
					println("[" + api.quoteString(c.name) + "," + c.index + "]");
					if (api.hasFeature("may_print_enum")) println('$p$f.toString = $$estr');
					print('$p$f.__enum__ = $p');
			}
			newline();
		}
		if (api.hasFeature("Type.allEnums"))
		{
			var ec = Lambda.fold(e.constructs, function(c:EnumField, r:Array<String>)
			{
				if (!c.type.match(TFun(_, _))) r.push('$p.${c.name}');
				return r;
			}, []);
			if (ec.length > 0) println('$p.__empty_constructs__ = [' + ec.join(",") + ']');
		}
		var meta = api.buildMetaData(e);
		if (meta != null)
		{
			print('$p.__meta__ = ');
			println(api.generateValue(meta));
		}
	}

	function genType(t:Type)
	{
		switch (t)
		{
			case TInst(c, _):
				var c = c.get();
				if (c.init != null) inits.add(c.init);
				if (!c.isExtern) genClass(c);
			case TEnum(r, _):
				var e = r.get();
				if (!e.isExtern) genEnum(e);
			default:
		}
	}

	public function generate()
	{
		if (jsModern) println('(function (' + (genExpose ? "$hx_exports" : "") + ", $global) { \"use strict\"");

		if (jsModern) println("if (!$hx_exports.$hxClasses) $hx_exports.$hxClasses = {}");

		var vars = [];
		if (api.hasFeature("Type.resolveClass") || api.hasFeature("Type.resolveEnum")) // vars.push("$hxClasses = " + (jsModern? "{}" : "$hxClasses || {}"));
			vars.push("$hxClasses = " + (jsModern ? "$hx_exports.$hxClasses" : "$hxClasses || {}"));
		if (api.hasFeature("may_print_enum")) vars.push("$estr = function() { return " + packClass(["js"], "Boot") + ".__string_rec(this,''); }");
		if (vars.length > 0) println("var " + vars.join(","));

		if (genExtend) print("function $extend(from, fields) {
	function Inherit() {} Inherit.prototype = from; var proto = new Inherit();
	for (var name in fields) proto[name] = fields[name];
	if( fields.toString !== Object.prototype.toString ) proto.toString = fields.toString;
	return proto;
}\n");

		for (t in api.types)
			genType(t);

		if (api.hasFeature("use.$iterator"))
		{
			api.addFeature("use.$bind");
			printn("function $iterator(o) { if( o instanceof Array ) return function() { return HxOverrides.iter(o); }; return typeof(o.iterator) == 'function' ? $bind(o,o.iterator) : o.iterator; }");
		}
		if (api.hasFeature("use.$bind"))
		{
			println("var $_, $fid = 0");
			printn("function $bind(o,m) { if( m == null ) return null; if( m.__id__ == null ) m.__id__ = $fid++; var f; if( o.hx__closures__ == null ) o.hx__closures__ = {}; else f = o.hx__closures__[m.__id__]; if( f == null ) { f = function(){ return f.method.apply(f.scope, arguments); }; f.scope = o; f.method = m; o.hx__closures__[m.__id__] = f; } return f; }");
		}
		for (e in inits)
			genInit(e);
		for (s in statics)
			println(getPath(s.c) + field(s.f.name) + ' = ' + api.generateValue(s.f.expr()));
		if (api.main != null) println(api.generateValue(api.main));
		if (jsModern) print('})('
			+ (genExpose ? 'typeof exports != "undefined" ? exports : typeof window != "undefined" ? window : typeof self != "undefined" ? self : this, ' : '')
			+ 'typeof window != "undefined" ? window : typeof global != "undefined" ? global : typeof self != "undefined" ? self : this);\n');
		sys.io.File.saveContent(api.outputFile, buf.toString());
	}

	function genInit(e:TypedExpr)
	{
		var code = api.generateStatement(e);
		// cosmetic only
		var colon = ';';
		for (l in code.split('\n'))
		{
			if (l == "{" || l == "}")
			{
				colon = '';
				continue;
			}
			printn(l.replace("\t", "") + colon);
		}
	}
}
#end
