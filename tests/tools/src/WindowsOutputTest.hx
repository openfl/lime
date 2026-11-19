import utest.Assert;
import utest.Test;

/**
	What `lime update windows` writes for the C++ target that other targets don't: the
	resource file that gives the executable its version information.
**/
class WindowsOutputTest extends Test
{
	private var fixture:Fixture;
	private var output:PlatformFixture;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		fixture = new Fixture();
		fixture.target = WINDOWS;
		// C++ on every host, as on any other host than Windows the tools make the
		// Windows target Neko unless -cpp is given, and Neko has no resource file
		fixture.targetFlags.set("cpp", "");
		fixture.write("Main.hx", "class Main {}");

		output = new PlatformFixture(fixture);
	}

	public function teardown():Void
	{
		fixture.dispose();
	}

	// A string in a resource file doubles its quotes, and a backslash in it starts an escape
	public function testMetaValuesWithQuotesAreValidResourceStrings():Void
	{
		output.update('<project>
			<meta title="My Application" company="Back\\Slash &quot;Co&quot;" package="com.example.app" />
			<app main="Main" file="MyApplication" />
		</project>');

		var resource = output.read("obj/ApplicationMain.rc");

		Assert.equals('Back\\Slash "Co"', value(resource, "CompanyName"));
		Assert.equals('Copyright (C) ' + Date.now().getFullYear() + ' Back\\Slash "Co"', value(resource, "LegalCopyright"));
		Assert.equals("MyApplication", value(resource, "InternalName"));
		Assert.equals("com.example.app", value(resource, "ProductName"));
	}

	/**
		The string a resource file's VALUE line gives a name, read as the resource compiler
		reads it, or null where what follows the name isn't one string.
	**/
	private static function value(resource:String, name:String):String
	{
		var start = resource.indexOf('VALUE "' + name + '", "');
		if (start < 0) return null;

		var i = start + name.length + 11;
		var result = new StringBuf();

		while (i < resource.length)
		{
			var c = resource.charAt(i);

			if (c == '"')
			{
				if (resource.charAt(i + 1) != '"')
				{
					var rest = StringTools.trim(resource.substring(i + 1, resource.indexOf("\n", i)));
					return rest == "" ? result.toString() : null;
				}

				result.add('"');
				i += 2;
			}
			else if (c == "\\")
			{
				result.add(resource.charAt(i + 1));
				i += 2;
			}
			else
			{
				result.add(c);
				i++;
			}
		}

		return null;
	}
}
