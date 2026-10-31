package lime.system;

#if flash
import flash.system.Capabilities;
#end
import lime.system.CFFI;
import lime.system.JNI;

abstract Locale(String) from String to String
{
	@:isVar public static var currentLocale(get, set):Locale;

	/**
		The languages the user prefers, most preferred first, such as `en-US` or
		`fr`. It is read each time, as the user can change it while the
		application runs, and is empty where the platform doesn't say.
	**/
	public static var preferredLocales(get, never):Array<Locale>;

	public static var systemLocale(get, never):Locale;
	private static var __systemLocale:Locale;

	public var language(get, never):String;
	public var region(get, never):String;

	public function new(value:String)
	{
		this = value;
	}

	@:noCompletion @:op(A == B) private static function equals(a:Locale, b:Locale):Bool
	{
		var language = a.language;
		var region = a.region;

		var language2 = b.language;
		var region2 = b.region;

		var languageMatch = (language == language2);
		var regionMatch = (region == region2);

		if (!languageMatch && language != null && language2 != null)
		{
			languageMatch = (language.toLowerCase() == language2.toLowerCase());
		}

		if (!regionMatch && region != null && region2 != null)
		{
			regionMatch = (region.toLowerCase() == region2.toLowerCase());
		}

		return (languageMatch && regionMatch);
	}

	#if hl
	@:hlNative("lime", "hl_locale_get_preferred_locales") private static function lime_locale_get_preferred_locales():hl.Bytes
	{
		return null;
	}

	@:hlNative("lime", "hl_locale_get_system_locale") private static function lime_locale_get_system_locale():hl.Bytes
	{
		return null;
	}
	#end

	private static function __init():Void
	{
		if (__systemLocale == null)
		{
			var locale = null;

			#if flash
			locale = Capabilities.language;
			#elseif (js && html5)
			locale = untyped navigator.language;
			#elseif (android)
			var getDefault:Void->Dynamic = JNI.createStaticMethod("java/util/Locale", "getDefault", "()Ljava/util/Locale;");
			var toString:Dynamic->String = JNI.createMemberMethod("java/util/Locale", "toString", "()Ljava/lang/String;");

			locale = toString(getDefault());
			#elseif (lime_cffi && !macro)
			#if hl
			locale = CFFI.stringValue(lime_locale_get_system_locale());
			#else
			locale = CFFI.load("lime", "lime_locale_get_system_locale", 0)();
			#end
			#end

			if (locale != null)
			{
				__systemLocale = locale;
			}
			else
			{
				__systemLocale = "en-US";
			}

			currentLocale = __systemLocale;
		}
	}

	// Get & Set Methods
	@:noCompletion private function get_language():String
	{
		if (this != null)
		{
			var index = this.indexOf("_");

			if (index > -1)
			{
				var dashIndex = this.indexOf("-");
				if (dashIndex > -1 && dashIndex < index) index = dashIndex;

				return this.substring(0, index);
			}

			index = this.indexOf("-");

			if (index > -1)
			{
				return this.substring(0, index);
			}
		}

		return this;
	}

	@:noCompletion private function get_region():String
	{
		if (this != null)
		{
			var underscoreIndex = this.indexOf("_");
			var dotIndex = this.indexOf(".");
			var dashIndex = this.indexOf("-");

			if (underscoreIndex > -1)
			{
				if (dotIndex > -1)
				{
					return this.substring(underscoreIndex + 1, dotIndex);
				}
				else
				{
					return this.substring(underscoreIndex + 1);
				}
			}
			else if (dashIndex > -1)
			{
				if (dotIndex > -1)
				{
					return this.substring(dashIndex + 1, dotIndex);
				}
				else
				{
					return this.substring(dashIndex + 1);
				}
			}
		}

		return null;
	}

	// Get & Set Methods
	private static function get_currentLocale():Locale
	{
		__init();

		return currentLocale;
	}

	private static function set_currentLocale(value:Locale):Locale
	{
		__init();

		return currentLocale = value;
	}

	private static function get_preferredLocales():Array<Locale>
	{
		var locales:Array<Locale> = [];

		#if flash
		#if air
		for (language in Capabilities.languages)
		{
			locales.push(language);
		}
		#else
		locales.push(Capabilities.language);
		#end
		#elseif (js && html5)
		var languages:Array<String> = untyped navigator.languages;
		if (languages == null) languages = [untyped navigator.language];

		for (language in languages)
		{
			if (language != null) locales.push(language);
		}
		#elseif (lime_cffi && !macro)
		#if hl
		var list = CFFI.stringValue(lime_locale_get_preferred_locales());
		#else
		var list:String = CFFI.load("lime", "lime_locale_get_preferred_locales", 0)();
		#end

		if (list != null && list != "")
		{
			for (language in list.split(","))
			{
				locales.push(language);
			}
		}
		#end

		return locales;
	}

	private static function get_systemLocale():Locale
	{
		__init();

		return __systemLocale;
	}
}
