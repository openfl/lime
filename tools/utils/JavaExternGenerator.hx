package utils;

import haxe.crypto.BaseCode;
import haxe.io.Bytes;
import haxe.io.Input;
import haxe.io.Output;
import haxe.zip.Compress;
import haxe.zip.Reader;
import hxp.*;
import lime.tools.HXProject;
import sys.io.File;
import sys.io.Process;
import sys.FileSystem;

class JavaExternGenerator
{
	private static inline var ACC_PUBLIC = 0x0001;
	private static inline var ACC_PRIVATE = 0x0002;
	private static inline var ACC_PROTECTED = 0x0004;
	private static inline var ACC_STATIC = 0x0008;
	private static inline var ACC_FINAL = 0x0010;
	private static inline var ACC_SUPER = 0x0020;
	private static inline var ACC_INTERFACE = 0x0200;
	private static inline var ACC_ABSTRACT = 0x0400;
	private static inline var dollars = "___";
	private static var base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";
	private static var fmatch = ~/^\((.*)\)(.*)/;

	private var config:HXProject;
	private var externPath:String;
	private var extractedAndroidClasses:Bool;
	private var extractedAndroidPaths:Array<String>;
	private var javaPath:String;
	private var mConstants:Array<Dynamic>;
	private var mProcessed:Map<String, Bool>;
	private var mStack:Array<String>;
	private var mOutput:Output;
	private var mCurrentType:String;
	private var mExactTypes:Map<String, Bool>;
	private var parsedTypes:Array<JNIType>;
	private var parsedIsObj:Array<Bool>;
	private var retType:JNIType;

	public function new(config:HXProject, javaPath:String, externPath:String)
	{
		this.config = config;
		this.javaPath = javaPath;
		this.externPath = externPath;

		mProcessed = new Map<String, Bool>();
		mExactTypes = new Map<String, Bool>();
		mProcessed.set("java/lang/Object", true);

		var paths = new Array<String>();

		if (FileSystem.isDirectory(javaPath))
		{
			this.javaPath += "/";
			getPaths(javaPath, "", paths);
		}
		else
		{
			var path = Path.withoutExtension(javaPath);

			if (Path.extension(javaPath) == "jar")
			{
				this.javaPath = path + "/";
				System.mkdir(path);
				System.runCommand(path, "jar", ["-xvf", FileSystem.fullPath(javaPath)], false);
				getPaths(path, "", paths);
			}
			else
			{
				this.javaPath = "";
				paths = [path];
			}
		}

		for (path in paths)
		{
			var type = Path.withoutExtension(path);
			mProcessed.set(type, true);
			mExactTypes.set(type, true);
		}

		mStack = paths;

		while (mStack.length > 0)
		{
			var clazz = mStack.pop();
			var members = new Map<String, String>();
			generate(clazz, members);
		}

		for (path in extractedAndroidPaths)
		{
			if (FileSystem.exists(path))
			{
				removeRecursive(path);
			}
		}
	}

	private function addType(inName:String, inJavaType:String, inArrayCount:Int)
	{
		parsedTypes.push({name: inName, java: inJavaType, arrayCount: inArrayCount});
	}

	private static function debug(s:String) {}

	private function extractAndroidClasses()
	{
		if (!extractedAndroidClasses)
		{
			extractedAndroidPaths = [];
			var platformsDirectory = config.environment.get("ANDROID_SDK") + "/platforms";

			if (FileSystem.exists(platformsDirectory))
			{
				for (path in FileSystem.readDirectory(platformsDirectory))
				{
					var directory = platformsDirectory + "/" + path;

					if (path.indexOf("android-") > -1 && FileSystem.isDirectory(directory))
					{
						var androidJAR = directory + "/android.jar";

						if (FileSystem.exists(androidJAR))
						{
							System.mkdir(path);
							extractedAndroidPaths.push(path);
							System.runCommand(path, "jar", ["-xvf", androidJAR], false);
						}
					}
				}
			}
			else
			{
				throw "Could not find Android SDK directory. Check that ANDROID_SDK is defined in ~/.lime/config.xml";
			}
		}
		extractedAndroidClasses = true;
	}

	private function generate(inClass:String, inMembers:Map<String, String>)
	{
		Sys.println(inClass);

		var parts = Path.withoutExtension(inClass).split("/");
		var old_type = mCurrentType;
		mCurrentType = parts.join(".");
		mExactTypes.set(mCurrentType, true);
		var dir_parts = parts.slice(0, parts.length - 1);
		var outputBase = externPath;
		var dir = outputBase;
		System.mkdir(dir);

		for (d in dir_parts)
		{
			dir += "/" + d;
			System.mkdir(dir);
		}

		var filename = javaPath + inClass + ".class";

		if (!FileSystem.exists(filename))
		{
			extractAndroidClasses();
			var foundFile = false;

			for (path in extractedAndroidPaths)
			{
				if (!foundFile)
				{
					filename = path + "/" + inClass + ".class";

					if (FileSystem.exists(filename))
					{
						foundFile = true;
					}
				}
			}

			if (!foundFile)
			{
				throw "Could not find class file: \"" + inClass + "\"";
			}
		}

		var source = File.read(filename, true);
		var class_name = parts[parts.length - 1].split("$").join(dollars);
		var old_output = mOutput;
		mOutput = File.write(dir + "/" + class_name + ".hx", true);
		var old_constants = mConstants;
		mConstants = new Array<Dynamic>();

		parse(source, inMembers);

		source.close();
		mOutput.close();
		mOutput = old_output;
		mCurrentType = old_type;
		mConstants = old_constants;
	}

	public static function getHaxelib(library:String):String
	{
		var proc = new Process("haxelib", ["path", library]);
		var result = "";

		try
		{
			while (true)
			{
				var line = proc.stdout.readLine();
				if (line.substr(0, 1) != "-") result = line;
			}
		}
		catch (e:Dynamic) {};
		proc.close();
		if (result == "") throw("Could not find haxelib path  " + library + " - perhaps you need to install it?");

		return result;
	}

	private function getPaths(basePath:String, source:String, paths:Array<String>)
	{
		var files = FileSystem.readDirectory(basePath + "/" + source);

		for (file in files)
		{
			if (file.substr(0, 1) != ".")
			{
				var itemSource:String = source + "/" + file;

				if (source == "")
				{
					itemSource = file;
				}

				if (FileSystem.isDirectory(basePath + "/" + itemSource))
				{
					getPaths(basePath, itemSource, paths);
				}
				else
				{
					if (Path.extension(itemSource) == "class")
					{
						paths.push(Path.withoutExtension(itemSource));
					}
				}
			}
		}
	}

	private function isJavaObject(inType)
	{
		if (inType.arrayCount > 0) return false;
		return switch (inType.name)
		{
			case "Int", "Void", "Bool", "Float": false;
			default: true;
		}
	}

	private function isPOD(inName:String)
	{
		switch (inName)
		{
			case "Int", "Void", "Bool", "Float", "String":
				return true;
		}
		return false;
	}

	private function javaType(inType)
	{
		var result = inType.java;
		result = StringTools.replace(result, "/", ".");
		for (i in 0...inType.arrayCount)
			result += "[]";
		return result;
	}

	private function mkdir(inName:String)
	{
		if (!FileSystem.exists(inName)) FileSystem.createDirectory(inName);
	}

	private function nmeCallType(inType)
	{
		if (isJavaObject(inType)) return "callObjectFunction";
		return "callNumericFunction";
	}

	private function output(str:String)
	{
		mOutput.writeString(str);
	}

	private function outputClass(cid:Int, lastOnly:Bool)
	{
		var name:String = mConstants[mConstants[cid]];
		// pushClass(name);
		name = name.split("$").join(dollars);
		var parts = name.split("/");
		if (lastOnly) output(parts.pop());
		else
			output(parts.join("."));
	}

	private function outputFunctionArgs()
	{
		output("(");
		for (i in 0...parsedTypes.length)
		{
			if (i > 0) output(", ");
			output("arg" + i + ":");
			outputType(parsedTypes[i]);
		}
		output(")");
	}

	private function outputPackage(cid:Int)
	{
		var name = (mConstants[mConstants[cid]]);
		var parts = name.split("/");
		parts.pop();
		output("package " + parts.join(".") + ";\n\n\n");
	}

	private function outputType(inType:JNIType)
	{
		for (i in 0...inType.arrayCount)
			output("Array<");
		output(inType.name);
		for (i in 0...inType.arrayCount)
			output(">");
	}

	private function parse(src:Input, inMembers:Map<String, String>)
	{
		src.bigEndian = true;

		var m0 = src.readByte();
		var m1 = src.readByte();
		var m2 = src.readByte();
		var m3 = src.readByte();

		debug(StringTools.hex(m0, 2) + StringTools.hex(m1, 2) + StringTools.hex(m2, 2) + StringTools.hex(m3, 2));
		debug("Version (min):" + src.readUInt16());
		debug("Version (maj):" + StringTools.hex(src.readUInt16(), 4));

		var ccount = src.readUInt16();

		debug("mConstants : " + ccount);

		var cid = 1;
		while (cid < ccount)
		{
			var tag = src.readByte();
			switch (tag)
			{
				case 1:
					var len = src.readUInt16();
					var str = src.readString(len);
					// debug("Str:"+str);
					mConstants[cid] = str;

				case 3:
					var i = src.readInt32();
					// debug("Int32:"+i);
					mConstants[cid] = i;

				case 4:
					var f = src.readFloat();
					// debug("Float32:"+f);
					mConstants[cid] = f;

				case 5:
					var hi = src.readInt32();
					var lo = src.readInt32();
					// debug("Long - ignore");
					mConstants[cid] = {lo: lo, hi: hi};
					cid++;

				case 6:
					var f = src.readDouble();
					// debug("Float64:"+f);
					mConstants[cid] = f;
					cid++;

				case 7:
					var cref = src.readUInt16();
					// debug("Class ref:" + cref);
					mConstants[cid] = cref;

				case 8:
					var sref = src.readUInt16();
					// debug("String ref:" + sref);
					mConstants[cid] = sref;

				case 9, 10, 11, 12:
					var cref = src.readUInt16();
					var type = src.readUInt16();
					// debug("Member ref:" + cref + "," + type);
					mConstants[cid] = {cref: cref, type: type};

				default:
					throw("Unknown constant tag:" + tag);
			}
			cid++;
		}

		var access = src.readUInt16();

		debug("Access: " + access);

		var is_interface = (access & ACC_INTERFACE) > 0;
		var java_out:Output = null;

		var this_ref = src.readUInt16();

		debug("This : " + mConstants[mConstants[this_ref]]);

		outputPackage(this_ref);
		output("class ");
		outputClass(this_ref, true);

		var super_ref = src.readUInt16();
		if (super_ref > 0)
		{
			debug("Super : " + mConstants[mConstants[super_ref]]);

			var name = mConstants[mConstants[super_ref]];
			if (name == "java/lang/Object")
			{
				debug(" -> ignore super");
				super_ref = 0;
			}
			else
			{
				output(" extends ");
				outputClass(super_ref, false);
			}
		}
		else
			debug("Super : None.");

		if (super_ref > 0) generate(mConstants[mConstants[super_ref]], inMembers);

		var intf_count = src.readUInt16();

		debug("Interfaces:" + intf_count);

		for (i in 0...intf_count)
		{
			var i_ref = src.readUInt16();
			/*
				No need to expose these to haxe?
				if (i>0 || super_ref>0)
				output(",");
				output(" implements ");
				outputClass(i_ref,false);
				debug("Implements : " + mConstants[mConstants[i_ref]]);
			 */
		}

		output("\n{\n");

		if (super_ref == 0) output("	var __jobject:Dynamic;\n	\n");

		var java_name = "";

		if (is_interface)
		{
			var dir = "stubs";
			var parts = mCurrentType.split(".");
			var dir_parts = parts.slice(0, parts.length - 1);
			System.mkdir(dir);

			for (d in dir_parts)
			{
				dir += "/" + d;
				System.mkdir(dir);
			}

			var interface_name = parts[parts.length - 1];
			var impl_name = "Haxe" + parts[parts.length - 1].split("$").join("");
			java_name = dir_parts.join("/") + "/" + impl_name + ".java";

			java_out = File.write("stubs/" + java_name, true);
			java_out.writeString("package " + dir_parts.join(".") + ";\n");
			java_out.writeString("import org.haxe.lime.Value;\n");
			java_out.writeString("import org.haxe.lime.Lime;\n\n");
			java_out.writeString("import " + StringTools.replace(parts.join("."), "$", ".") + ";\n\n");
			java_out.writeString("class " + impl_name + " implements " + interface_name.split("$").join(".") + " {\n");
			java_out.writeString("   long __haxeHandle;\n");
			java_out.writeString("   public " + impl_name + "(long inHandle) { __haxeHandle=inHandle; }\n");

			output("   public function new() { __jobject = openfl.utils.JNI.createInterface(this,\""
				+ dir_parts.join(".")
				+ "."
				+ impl_name
				+ "\", classDef ); }\n	\n");
		}

		var field_count = src.readUInt16();

		debug("Fields:" + field_count);

		var seen = new Map<String, Bool>();

		for (i in 0...field_count)
		{
			var access = src.readUInt16();
			var name_ref = src.readUInt16();

			debug(" field : " + mConstants[name_ref]);

			var desc_ref = src.readUInt16();

			debug("  desc : " + mConstants[desc_ref]);

			var expose = access == (ACC_PUBLIC | ACC_FINAL | ACC_STATIC);
			var as_string = false;

			if (expose)
			{
				var type = toHaxeType(mConstants[desc_ref]).name;
				if (isPOD(type))
				{
					output("	static inline public var " + mConstants[name_ref] + ":" + type);
					as_string = type == "String";
				}
				else
					expose = false;
			}

			var att_count = src.readUInt16();

			for (a in 0...att_count)
			{
				readAttribute(src, expose, as_string);
			}

			if (expose) output(";\n");
		}

		var method_count = src.readUInt16();
		debug("Method:" + method_count);

		output("	\n");
		var constructed = false;

		for (i in 0...method_count)
		{
			var access = src.readUInt16();
			var expose = (access & ACC_PUBLIC) > 0;
			var is_static = (access & ACC_STATIC) > 0;
			var name_ref = src.readUInt16();
			debug(" method: " + mConstants[name_ref]);
			var desc_ref = src.readUInt16();

			var func_name = mConstants[name_ref];
			var constructor = func_name == "<init>";

			if (expose)
			{
				debug("  desc : " + mConstants[desc_ref]);
				splitFunctionType(mConstants[desc_ref]);

				var func_key = func_name + " " + mConstants[desc_ref];
				if (constructor)
				{
					func_name = "_create";
				}

				// Method overloading ...
				var uniq_name = func_name;
				var do_override = "";
				if (inMembers.exists(func_key))
				{
					uniq_name = inMembers.get(func_key);
					if (!constructor && !is_static) do_override = "override ";
					seen.set(uniq_name, true);
				}
				else
				{
					if (seen.exists(func_name))
					{
						for (i in 1...100000)
						{
							uniq_name = func_name + i;
							if (!seen.exists(uniq_name)) break;
						}
					}
					seen.set(uniq_name, true);
					inMembers.set(func_key, uniq_name);
				}

				if (constructor) is_static = true;

				var ret_full_class = constructor || ((mExactTypes.exists(retType.name) || isPOD(retType.name)) && retType.arrayCount == 0);

				if (constructor) retType = {name: mCurrentType, java: mCurrentType, arrayCount: 0};

				var ret_void = (retType.name == "Void" && retType.arrayCount == 0);

				if (is_interface)
				{
					java_out.writeString("	@Override public " + javaType(retType) + " " + func_name + "(");

					for (i in 0...parsedTypes.length)
					{
						if (i > 0) java_out.writeString(",");
						java_out.writeString(javaType(parsedTypes[i]) + " arg" + i);
					}

					java_out.writeString(") {\n");

					if (parsedTypes.length > 0) java_out.writeString("		Object [] args = new Object[" + parsedTypes.length + "];\n");
					else
						java_out.writeString("		Object [] args = null;\n");

					for (i in 0...parsedTypes.length)
					{
						if (isJavaObject(parsedTypes[i])) java_out.writeString("		args[" + i + "] = arg" + i + ";\n");
						else
							java_out.writeString("		args[" + i + "] = new Value(arg" + i + ");\n");
					}

					if (!ret_void) java_out.writeString("		return (" + javaType(retType) + ")");

					java_out.writeString("		Lime." + nmeCallType(retType) + "(__haxeHandle,\"" + uniq_name + "\",args)");

					if (!ret_void) java_out.writeString(")");
					java_out.writeString(";\n	}\n");

					output("	public function " + uniq_name);
					outputFunctionArgs();
					output(":");

					if (ret_full_class) outputType(retType);
					else
						output("Dynamic");
					output("\n	{\n		return null;\n	}\n	\n");
				}
				else
				{
					output("	private static var _" + uniq_name + "_func:Dynamic;\n\n");
					output("	public ");

					if (is_static || constructor) output("static ");

					output(do_override + "function " + uniq_name);
					outputFunctionArgs();
					output(":");

					if (ret_full_class) outputType(retType);
					else
						output("Dynamic");

					output("\n");
					output("	{\n");
					func_name = "_" + uniq_name + "_func";
					output("		if (" + func_name + " == null)\n");
					output("			" + func_name + " = openfl.utils.JNI." + (is_static ? "createStaticMethod" : "createMemberMethod"));
					output("(\"" + StringTools.replace(mCurrentType, ".", "/") + "\", \"" + mConstants[name_ref] + "\", \"" + mConstants[desc_ref]
						+ "\", true);\n");

					output("		var a = new Array<Dynamic>();\n");

					if (!is_static) output("		a.push (__jobject);\n");

					for (i in 0...parsedTypes.length)
						output("		a.push(arg" + i + ");\n");

					if (ret_void) output("		");
					else if (ret_full_class && !isPOD(retType.name)) output("		return new " + retType.name + "(");
					else
						output("		return ");

					output(func_name + "(a)");

					if (ret_full_class && !isPOD(retType.name)) output(");\n");
					else
						output(";\n");

					output("	}\n	\n	\n");
				}
			}

			if (constructor && !constructed)
			{
				constructed = true;
				output("	public function new(handle:Dynamic)\n	{\n");
				if (super_ref > 0) output("		super(handle);");
				else
					output("		__jobject = handle;");
				output("\n	}\n	\n	\n");
			}

			var att_count = src.readUInt16();
			for (a in 0...att_count)
				readAttribute(src, false, false);
		}

		if (java_out != null)
		{
			java_out.writeString("}\n");
			java_out.close();

			System.mkdir("compiled");
			var nme_path = getHaxelib("openfl") + "/__backends/native/templates/android/template/src";
			System.runCommand("", "javac", [
				"-classpath",
				"\"classes/android.jar\";\"" + javaPath.substr(0, javaPath.length - 1) + "\"",
				"-sourcepath",
				nme_path,
				"-d",
				"compiled",
				"stubs/" + java_name
			], true, true, true);

			// Sys.setCwd("compiled");

			var class_name = java_name.substr(0, java_name.length - 4) + "class";

			var dx = Sys.getEnv("ANDROID_SDK") + "/platforms/" + extractedAndroidPaths[0] + "/tools/dx";
			System.runCommand("compiled", dx, ["--dex", "--output=classes.jar", class_name], true, true, true);

			if (FileSystem.exists("classes.jar"))
			{
				var class_def = File.getBytes("classes.jar");
				class_def = Compress.run(class_def, 9);
				var class_str = BaseCode.encode(class_def.toString(), base64);

				output("\n   static var classDef = \"" + class_str + "\";\n");
			}
		}

		output("}");
	}

	private function parseTypes(type:String, inArrayCount:Int)
	{
		if (type == "") return;
		var is_obj = false;
		switch (type.substr(0, 1))
		{
			case "[":
				parseTypes(type.substr(1), inArrayCount + 1);
			case "I":
				addType("Int", "int", inArrayCount);
			case "C":
				addType("Int", "char", inArrayCount);
			case "S":
				addType("Int", "short", inArrayCount);
			case "B":
				addType("Int", "byte", inArrayCount);
			case "V":
				addType("Void", "void", inArrayCount);
			case "Z":
				addType("Bool", "boolean", inArrayCount);
			case "J":
				addType("Float", "long", inArrayCount);
			case "F":
				addType("Float", "float", inArrayCount);
			case "D":
				addType("Float", "double", inArrayCount);
			case "L":
				is_obj = true;
				var end = type.indexOf(";");
				if (end < 1) throw("Bad object string: " + type);
				var name = type.substr(1, end - 1);
				addType(processObjectArg(name.split("/").join("."), inArrayCount), name, inArrayCount);
				type = type.substr(end);
			default:
				throw("Unknown java type: " + type);
		}
		parsedIsObj.push(is_obj);
		if (type.length > 1) parseTypes(type.substr(1), 0);
	}

	private function processObjectArg(inObj:String, inArrayCount:Int)
	{
		if (inObj == "java.lang.CharSequence" || inObj == "java.lang.String") return "String";
		if (mExactTypes.exists(inObj) && inArrayCount == 0) return inObj;
		return "Dynamic /*" + inObj + "*/";
	}

	private function pushClass(inName:String)
	{
		if (!mProcessed.get(inName))
		{
			mProcessed.set(inName, true);
			mStack.push(inName);
		}
	}

	private function readAttribute(src:Input, inOutputConst:Bool, asString:Bool)
	{
		var name_ref = src.readUInt16();
		debug("   attr:" + mConstants[name_ref]);
		var len = src.readInt32();
		var bytes = Bytes.alloc(len);
		src.readBytes(bytes, 0, len);

		if (inOutputConst && mConstants[name_ref] == "ConstantValue")
		{
			var ref = (bytes.get(0) << 8) + bytes.get(1);
			if (asString) output(" = \"" + mConstants[mConstants[ref]] + "\"");
			else
				output(" = " + mConstants[ref]);
		}
	}

	private function removeRecursive(file)
	{
		if (!FileSystem.isDirectory(file))
		{
			FileSystem.deleteFile(file);
			return;
		}
		for (f in FileSystem.readDirectory(file))
			removeRecursive(file + "/" + f);
		FileSystem.deleteDirectory(file);
	}

	private function splitFunctionType(type:String)
	{
		if (!fmatch.match(type)) throw("Not a function : " + type);
		var args = fmatch.matched(1);
		retType = toHaxeType(fmatch.matched(2));
		parsedTypes = [];
		parsedIsObj = [];
		parseTypes(args, 0);
	}

	private function toHaxeType(inStr:String)
	{
		parsedTypes = [];
		parsedIsObj = [];
		parseTypes(inStr, 0);
		return parsedTypes[0];
	}
	/*public static function main()
		{
			var args = Sys.args();
			debug(args.toString());

			new JavaExternGenerator(args[0], "gen");
	}*/
}

typedef JNIType =
{
	name:String,
	java:String,
	arrayCount:Int
};
