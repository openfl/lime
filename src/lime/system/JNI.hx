package lime.system;

#if (!lime_doc_gen || android)
import lime._internal.backend.native.NativeCFFI;

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
		switch (a.length)
		{
			case 0:
				return method(jobject);
			case 1:
				return method(jobject, a[0]);
			case 2:
				return method(jobject, a[0], a[1]);
			case 3:
				return method(jobject, a[0], a[1], a[2]);
			case 4:
				return method(jobject, a[0], a[1], a[2], a[3]);
			case 5:
				return method(jobject, a[0], a[1], a[2], a[3], a[4]);
			case 6:
				return method(jobject, a[0], a[1], a[2], a[3], a[4], a[5]);
			case 7:
				return method(jobject, a[0], a[1], a[2], a[3], a[4], a[5], a[6]);
			default:
				return null;
		}
	}

	public static function callStatic(method:Dynamic, a:Array<Dynamic>):Dynamic
	{
		switch (a.length)
		{
			case 0:
				return method();
			case 1:
				return method(a[0]);
			case 2:
				return method(a[0], a[1]);
			case 3:
				return method(a[0], a[1], a[2]);
			case 4:
				return method(a[0], a[1], a[2], a[3]);
			case 5:
				return method(a[0], a[1], a[2], a[3], a[4]);
			case 6:
				return method(a[0], a[1], a[2], a[3], a[4], a[5]);
			case 7:
				return method(a[0], a[1], a[2], a[3], a[4], a[5], a[6]);
			default:
				return null;
		}
	}

	public static function createMemberField(className:String, memberName:String, signature:String):JNIMemberField
	{
		init();

		#if (android && lime_cffi && !macro)
		return new JNIMemberField(NativeCFFI.lime_jni_create_field(className, memberName, signature, false));
		#else
		return null;
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
		return null;
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

			#if android
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
#end
