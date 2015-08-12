package lime.system;


class JNI {
	
	
	private static var alreadyCreated = new Map<String, Bool> ();
	private static var initialized = false;
	
	
	public static function callMember (method:Dynamic, jobject:Dynamic, a:Array<Dynamic>):Dynamic {
		
		switch (a.length) {
			
			case 0: return method (jobject);
			case 1: return method (jobject, a[0]);
			case 2: return method (jobject, a[0], a[1]);
			case 3: return method (jobject, a[0], a[1], a[2]);
			case 4: return method (jobject, a[0], a[1], a[2], a[3]);
			case 5: return method (jobject, a[0], a[1], a[2], a[3], a[4]);
			case 6: return method (jobject, a[0], a[1], a[2], a[3], a[4], a[5]);
			case 7: return method (jobject, a[0], a[1], a[2], a[3], a[4], a[5], a[6]);
			default: return null;
			
		}
		
	}
	
	
	public static function callStatic (method:Dynamic, a:Array<Dynamic>):Dynamic {
		
		switch (a.length) {
			
			case 0: return method ();
			case 1: return method (a[0]);
			case 2: return method (a[0], a[1]);
			case 3: return method (a[0], a[1], a[2]);
			case 4: return method (a[0], a[1], a[2], a[3]);
			case 5: return method (a[0], a[1], a[2], a[3], a[4]);
			case 6: return method (a[0], a[1], a[2], a[3], a[4], a[5]);
			case 7: return method (a[0], a[1], a[2], a[3], a[4], a[5], a[6]);
			default: return null;
			
		}
		
	}
	
	
	public static function createMemberField (className:String, memberName:String, signature:String):JNIMemberField {
		
		init ();
		
		#if android
		return new JNIMemberField (lime_jni_create_field (className, memberName, signature, false));
		#else
		return null;
		#end
		
	}
	
	
	public static function createMemberMethod (className:String, memberName:String, signature:String, useArray:Bool = false, quietFail:Bool = false):Dynamic {
		
		init ();
		
		#if android
		className = className.split (".").join ("/");
		var handle = lime_jni_create_method (className, memberName, signature, false, quietFail);
		
		if (handle == null) {
			
			if (quietFail) {
				
				return null;
				
			}
			
			throw "Could not find member function \"" + memberName + "\"";
			
		}
		
		var method = new JNIMethod (handle);
		return method.getMemberMethod (useArray);
		#else
		return null;
		#end
		
	}
	
	
	public static function createStaticField (className:String, memberName:String, signature:String):JNIStaticField {
		
		init ();
		
		#if android
		return new JNIStaticField (lime_jni_create_field (className, memberName, signature, true));
		#else
		return null;
		#end
		
	}
	
	
	public static function createStaticMethod (className:String, memberName:String, signature:String, useArray:Bool = false, quietFail:Bool = false):Dynamic {
		
		init ();
		
		#if android
		className = className.split (".").join ("/");
		var handle = lime_jni_create_method (className, memberName, signature, true, quietFail);
		
		if (handle == null) {
			
			if (quietFail) {
				
				return null;
				
			}
			
			throw "Could not find static function \"" + memberName + "\"";
			
		}
		
		var method = new JNIMethod (handle);
		return method.getStaticMethod (useArray);
		#else
		return null;
		#end
		
	}
	
	
	public static function getEnv ():Dynamic {
		
		init ();
		
		#if android
		return lime_jni_get_env ();
		#else
		return null;
		#end
		
	}
	
	
	private static function init ():Void {
		
		if (!initialized) {
			
			initialized = true;
			
			#if android
			var method = System.load ("lime", "lime_jni_init_callback", 1);
			method (onCallback);
			#end
			
		}
		
	}
	
	
	private static function onCallback (object:Dynamic, method:Dynamic, args:Dynamic):Dynamic {
		
		var field = Reflect.field (object, method);
		
		if (field != null) {
			
			return Reflect.callMethod (object, field, args);
			
		}
		
		trace ("onCallback - unknown field " + method);
		return null;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_jni_create_field = System.load ("lime", "lime_jni_create_field", 4);
	private static var lime_jni_create_method = System.load ("lime", "lime_jni_create_method", 5);
	private static var lime_jni_get_env = System.load ("lime", "lime_jni_get_env", 0);
	private static var lime_jni_call_member = System.load ("lime", "lime_jni_call_member", 3);
	private static var lime_jni_call_static = System.load ("lime", "lime_jni_call_static", 2);
	#end
	
	
}


class JNIMemberField {
	
	
	private var field:Dynamic;
	
	
	public function new (field:Dynamic) {
		
		this.field = field;
		
	}
	
	
	public function get (jobject:Dynamic):Dynamic {
		
		#if android
		return lime_jni_get_member (field, jobject);
		#else
		return null;
		#end
		
	}
	
	
	public function set (jobject:Dynamic, value:Dynamic):Dynamic {
		
		#if android
		lime_jni_set_member (field, jobject, value);
		#end
		return value;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_jni_get_member = System.load ("lime", "lime_jni_get_member", 2);
	private static var lime_jni_set_member = System.load ("lime", "lime_jni_set_member", 3);
	#end
	
	
}


class JNIStaticField {
	
	
	private var field:Dynamic;
	
	
	public function new (field:Dynamic) {
		
		this.field = field;
		
	}
	
	
	public function get ():Dynamic {
		
		#if android
		return lime_jni_get_static (field);
		#else
		return null;
		#end
		
	}
	
	
	public function set (value:Dynamic):Dynamic {
		
		#if android
		lime_jni_set_static (field, value);
		#end
		return value;
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_jni_get_static = System.load ("lime", "lime_jni_get_static", 1);
	private static var lime_jni_set_static = System.load ("lime", "lime_jni_set_static", 2);
	#end
	
	
}


class JNIMethod {
	
	
	private var method:Dynamic;
	
	
	public function new (method:Dynamic) {
		
		this.method = method;
		
	}

	public function callMember (args:Array<Dynamic>):Dynamic {
		
		#if android
		var jobject = args.shift ();
		return lime_jni_call_member (method, jobject, args);
		#else
		return null;
		#end
		
	}
	
	
	public function callStatic (args:Array<Dynamic>):Dynamic {
		
		#if android
		return lime_jni_call_static (method, args);
		#else
		return null;
		#end
		
	}
	
	
	public function getMemberMethod (useArray:Bool):Dynamic {
		
		if (useArray) {
			
			return callMember;
			
		} else {
			
			return Reflect.makeVarArgs (callMember);
			
		}
		
	}
	
	
	public function getStaticMethod (useArray:Bool):Dynamic {
		
		if (useArray) {
			
			return callStatic;
			
		} else {
			
			return Reflect.makeVarArgs (callStatic);
			
		}
		
	}
	
	
	
	
	// Native Methods
	
	
	
	
	#if (cpp || neko || nodejs)
	private static var lime_jni_call_member = System.load ("lime", "lime_jni_call_member", 3);
	private static var lime_jni_call_static = System.load ("lime", "lime_jni_call_static", 2);
	#end
	
	
}