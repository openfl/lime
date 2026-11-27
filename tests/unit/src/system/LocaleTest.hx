package system;

import lime.system.Locale;
import utest.Assert;
import utest.Test;

class LocaleTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro)
	public function testPreferredLocalesAreLanguagesAndRegions():Void
	{
		var locales = Locale.preferredLocales;

		for (locale in locales)
		{
			Assert.isTrue(~/^[a-z]{2,3}(-[A-Za-z0-9]+)?$/.match(locale), "\"" + locale + "\" is not a language and region");
		}

		#if (windows || mac)
		// Desktops always have a language set
		Assert.isTrue(locales.length > 0, "no preferred language was found");
		#else
		// Elsewhere none may be set, as with LANG=C on Linux
		if (locales.length == 0) Assert.pass();
		#end
	}

	#if linux
	public function testPreferredLocalesFollowTheLanguageSettings():Void
	{
		// Linux names the language in LANG, and those to fall back on in LANGUAGE
		var lang = Sys.getEnv("LANG");
		var language = Sys.getEnv("LANGUAGE");
		Sys.putEnv("LANG", "fr_CA.UTF-8");
		Sys.putEnv("LANGUAGE", "de:en_GB");
		var locales = Locale.preferredLocales;
		Sys.putEnv("LANG", lang != null ? lang : "");
		Sys.putEnv("LANGUAGE", language != null ? language : "");

		Assert.equals("fr-CA,de,en-GB", locales.join(","));
	}
	#end
	#end
}
