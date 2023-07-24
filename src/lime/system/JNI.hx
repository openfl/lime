package lime.system;

#if (!lime_doc_gen || android)
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
#else
import lime._internal.backend.native.NativeCFFI;
#end
#if !lime_doc_gen
#if target.threaded
import sys.thread.Thread;
#elseif cpp
import cpp.vm.Thread;
#elseif neko
import neko.vm.Thread;
#end
#end

/**
	The Java Native Interface (JNI) allows C++ code to call Java functions, and
	vice versa. On Android, Haxe code compiles to C++, but only Java code can
	access the Android system API, so it's often necessary to use both.

	For a working example, run `lime create extension MyExtension`, then look at
	MyExtension.hx and MyExtension.java.

	You can pass Haxe objects to Java, much like any other data. In Java,
	they'll have type `org.haxe.lime.HaxeObject`, meaning the method that
	receives them might have signature `(Lorg/haxe/lime/HaxeObject;)V`. Once
	sent, the Java class can store the object and call its functions.

	Note that most Java code runs on a different thread than Haxe, meaning that
	you can get thread-related errors in both directions. Java functions can
	use `Extension.callbackHandler.post()` to switch to the UI thread, while
	Haxe code can avoid the problem using `lime.system.JNI.JNISafety`.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
class JNI
{
	private static var alreadyCreated = new Map<String, Bool>();
	private static var initialized = false;

	public static function callMember(method:Dynamic, jobject:Dynamic, a:Array<Dynamic>):Dynamic
	{
		return Reflect.callMethod(null, method, [jobject].concat(a));
	}

	public static function callStatic(method:Dynamic, a:Array<Dynamic>):Dynamic
	{
		return Reflect.callMethod(null, method, a);
	}

	public static function createMemberField(className:String, memberName:String, signature:String):JNIMemberField
	{
		init();

		#if (android && lime_cffi && !macro)
		return new JNIMemberField(NativeCFFI.lime_jni_create_field(className, memberName, signature, false));
		#else
		return new JNIMemberField(null);
		#end
	}

	public static function createMemberMethod(className:String, memberName:String, signature:String, useArray:Bool = false, quietFail:Bool = false):Dynamic
	{
		init();

		#if (android && lime_cffi && !macro)
		className = className.split(".").join("/");
		var handle = NativeCFFI.lime_jni_create_method(className, memberName, signature, false, quietFail);

		if (handle == null)
		{
			if (quietFail)
			{
				return null;
			}

			throw "Could not find member function \"" + memberName + "\"";
		}

		var method = new JNIMethod(handle);
		return method.getMemberMethod(useArray);
		#else
		return null;
		#end
	}

	public static function createStaticField(className:String, memberName:String, signature:String):JNIStaticField
	{
		init();

		#if (android && lime_cffi && !macro)
		return new JNIStaticField(NativeCFFI.lime_jni_create_field(className, memberName, signature, true));
		#else
		return new JNIStaticField(null);
		#end
	}

	public static function createStaticMethod(className:String, memberName:String, signature:String, useArray:Bool = false, quietFail:Bool = false):Dynamic
	{
		init();

		#if (android && lime_cffi && !macro)
		className = className.split(".").join("/");
		var handle = NativeCFFI.lime_jni_create_method(className, memberName, signature, true, quietFail);

		if (handle == null)
		{
			if (quietFail)
			{
				return null;
			}

			throw "Could not find static function \"" + memberName + "\"";
		}

		var method = new JNIMethod(handle);
		return method.getStaticMethod(useArray);
		#else
		return null;
		#end
	}

	public static function getEnv():Dynamic
	{
		init();

		#if (android && lime_cffi && !macro)
		return NativeCFFI.lime_jni_get_env();
		#else
		return null;
		#end
	}

	private static function init():Void
	{
		if (!initialized)
		{
			initialized = true;

			#if (android && !macro)
			var method = System.load("lime", "lime_jni_init_callback", 1);
			method(onCallback);
			#end
		}
	}

	private static function onCallback(object:Dynamic, method:String, args:Array<Dynamic>):Dynamic
	{
		var field = Reflect.field(object, method);

		if (field != null)
		{
			if (args == null) args = [];

			return Reflect.callMethod(object, field, args);
		}

		trace("onCallback - unknown field " + method);
		return null;
	}

	public static function postUICallback(callback:Void->Void):Void
	{
		// TODO: Rename this?

		#if (android && lime_cffi && !macro)
		NativeCFFI.lime_jni_post_ui_callback(callback);
		#else
		callback();
		#end
	}
}

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
class JNIMemberField
{
	@:noCompletion private var field:Dynamic;

	public function new(field:Dynamic)
	{
		this.field = field;
	}

	public function get(jobject:Dynamic):Dynamic
	{
		#if (android && lime_cffi && !macro)
		return NativeCFFI.lime_jni_get_member(field, jobject);
		#else
		return null;
		#end
	}

	public function set(jobject:Dynamic, value:Dynamic):Dynamic
	{
		#if (android && lime_cffi && !macro)
		NativeCFFI.lime_jni_set_member(field, jobject, value);
		#end
		return value;
	}
}

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
class JNIStaticField
{
	@:noCompletion private var field:Dynamic;

	public function new(field:Dynamic)
	{
		this.field = field;
	}

	public function get():Dynamic
	{
		#if (android && lime_cffi && !macro)
		return NativeCFFI.lime_jni_get_static(field);
		#else
		return null;
		#end
	}

	public function set(value:Dynamic):Dynamic
	{
		#if (android && lime_cffi && !macro)
		NativeCFFI.lime_jni_set_static(field, value);
		#end
		return value;
	}
}

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
@:access(lime._internal.backend.native.NativeCFFI)
class JNIMethod
{
	@:noCompletion private var method:Dynamic;

	public function new(method:Dynamic)
	{
		this.method = method;
	}

	public function callMember(args:Array<Dynamic>):Dynamic
	{
		#if (android && lime_cffi && !macro)
		var jobject = args.shift();
		return NativeCFFI.lime_jni_call_member(method, jobject, args);
		#else
		return null;
		#end
	}

	public function callStatic(args:Array<Dynamic>):Dynamic
	{
		#if (android && lime_cffi && !macro)
		return NativeCFFI.lime_jni_call_static(method, args);
		#else
		return null;
		#end
	}

	public function getMemberMethod(useArray:Bool):Dynamic
	{
		if (useArray)
		{
			return callMember;
		}
		else
		{
			return Reflect.makeVarArgs(callMember);
		}
	}

	public function getStaticMethod(useArray:Bool):Dynamic
	{
		if (useArray)
		{
			return callStatic;
		}
		else
		{
			return Reflect.makeVarArgs(callStatic);
		}
	}
}

/**
	Most times a Java class calls a Haxe function, it does so on the UI thread,
	which can lead to thread-related errors. These errors can be avoided by
	switching back to the main thread before executing any code.

	Usage:

	```haxe
	class MyClass implements JNISafety
	{
		@:runOnMainThread
		public function callbackFunction(data:Dynamic):Void
		{
			// Code here is guaranteed to run on Haxe's main thread. It's safe
			// to call `callbackFunction` via JNI.
		}

		public function notACallbackFunction():Void
		{
			// Code here will run on whichever thread calls the function. It may
			// not be safe to call `notACallbackFunction` via JNI.
		}
	}
	```
**/
// Haxe 3 can't parse "target.threaded" inside parentheses.
#if !doc_gen
#if target.threaded
@:autoBuild(lime.system.JNI.JNISafetyTools.build())
#elseif (cpp || neko)
@:autoBuild(lime.system.JNI.JNISafetyTools.build())
#end
#end
interface JNISafety {}

#if !doc_gen
class JNISafetyTools
{
	#if target.threaded
	private static var mainThread:Thread = Thread.current();
	#elseif (cpp || neko)
	private static var mainThread:Thread = Thread.current();
	#end

	/**
		@return Whether the calling function is being run on the main thread.
	**/
	public static inline function onMainThread():Bool
	{
		#if target.threaded
		return Thread.current() == mainThread;
		#elseif (cpp || neko)
		return Thread.current() == mainThread;
		#else
		return true;
		#end
	}

	public static macro function build():Array<Field>
	{
		var fields:Array<Field> = Context.getBuildFields();

		#if macro
		for (field in fields)
		{
			// Don't modify constructors.
			if (field.name == "new")
			{
				continue;
			}

			// Don't modify functions lacking `@:runOnMainThread`.
			if (field.meta == null || !Lambda.exists(field.meta,
				function(meta) return meta.name == ":runOnMainThread"))
			{
				continue;
			}

			switch (field.kind)
			{
				case FFun(f):
					// The function needs to call itself and can't be inline.
					field.access.remove(AInline);

					// Make sure there's no return value.
					switch (f.ret)
					{
						case macro:Void:
							// Good to go.
						case null:
							f.ret = macro:Void;
						default:
							Context.error("Expected return type Void, got "
								+ new haxe.macro.Printer().printComplexType(f.ret) + ".", field.pos);
					}

					var args:Array<Expr> = [];
					for (arg in f.args)
					{
						args.push(macro $i{arg.name});

						// Account for an unlikely edge case.
						if (arg.name == field.name)
							Context.error('${field.name}() should not take an argument named ${field.name}.', field.pos);
					}

					// Check the thread before running the function.
					f.expr = macro
						if (!lime.system.JNI.JNISafetyTools.onMainThread())
							haxe.MainLoop.runInMainThread($i{field.name}.bind($a{args}))
						else
							${f.expr};
				default:
			}
		}
		#end

		return fields;
	}
}
#end
#end
