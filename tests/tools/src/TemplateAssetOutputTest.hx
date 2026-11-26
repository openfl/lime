import hxp.ObjectTools;
import hxp.Path;
import lime.tools.HXProject;
import lime.tools.PlatformTarget;
import sys.FileSystem;
import sys.io.File;
import utest.Assert;
import utest.Test;

/**
	Template assets, `<assets type="template" />`, as `lime update` writes them: filled in with the
	context the platform fills in its own templates with, and written to the platform's output
	folder, where other assets go to its asset folder.
**/
class TemplateAssetOutputTest extends Test
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
		fixture.write("Main.hx", "class Main {}");

		output = new PlatformFixture(fixture);
	}

	public function teardown():Void
	{
		fixture.dispose();
	}

	// Building a project's template context reads the name of each of its font assets, which
	// -verbose shows as "Detecting font name", and each template asset built it again, so a
	// project went through its fonts once for each one (#2107). These tools have no native
	// library to read fonts with, so the builds themselves are counted.
	public function testTheProjectsContextIsBuiltOnceWhateverTheTemplateAssets():Void
	{
		addFont();
		writeTemplates("config", 3, "title=::APP_TITLE::");

		var project:CountedProject = null;

		output.update('<project>
			<meta title="Template Assets" />
			<app main="Main" file="MyApplication" path="Export" />
			<assets path="fonts" />
			<assets path="config" type="template" />
		</project>', null, function(platform) project = CountedProject.replace(platform));

		Assert.equals(1, project.contextBuilds, "the update built the project's template context " + project.contextBuilds + " times");

		for (i in 0...3)
		{
			Assert.equals("title=Template Assets", output.read("bin/config/template" + i + ".txt"), "template" + i);
		}
	}

	// A caller that gives no context gets the project's, built when the first template asset needs it
	public function testWithoutAContextTheProjectsIsBuiltOnceForEveryTemplateAsset():Void
	{
		writeTemplates("config", 3, "title=::APP_TITLE:: output=::OUTPUT_DIR::");

		var project:CountedProject = null;

		output.update('<project>
			<meta title="Template Assets" />
			<app main="Main" file="MyApplication" path="Export" />
			<assets path="config" type="template" />
		</project>', null, function(platform) project = CountedProject.replace(platform));

		project.contextBuilds = 0;

		var cwd = Sys.getCwd();
		Sys.setCwd(fixture.directory);

		try
		{
			@:privateAccess output.platform.copyProjectAssets("Export/other");
		}
		catch (e:Dynamic)
		{
			Sys.setCwd(cwd);
			throw e;
		}

		Sys.setCwd(cwd);

		Assert.equals(1, project.contextBuilds, "the project's template context was built " + project.contextBuilds + " times");

		for (i in 0...3)
		{
			// The project's context has no OUTPUT_DIR, which is the platform's
			Assert.equals("title=Template Assets output=null", File.getContent(Path.combine(fixture.directory, "Export/other/config/template" + i + ".txt")));
		}
	}

	// They get the platform's values, such as OUTPUT_DIR on Windows, and the project's
	public function testTemplateAssetsAreFilledInWithTheWindowsContext():Void
	{
		writeTemplates("config", 3, "title=::APP_TITLE:: output=::OUTPUT_DIR::");

		output.update('<project>
			<meta title="Template Assets" />
			<app main="Main" file="MyApplication" path="Export" />
			<assets path="config" type="template" />
		</project>');

		Assert.notNull(output.platform.targetDirectory);

		for (i in 0...3)
		{
			// The Windows platform's own output directory, which depends on the host it is built from
			Assert.equals("title=Template Assets output=" + output.platform.targetDirectory, output.read("bin/config/template" + i + ".txt"), "template" + i);
		}
	}

	// MAC_CAMERA_USAGE_DESCRIPTION, from <config:mac camera-usage-description="..." />, is in the Mac
	// target's context alone
	public function testTemplateAssetsAreFilledInWithTheMacContext():Void
	{
		fixture.target = MAC;
		fixture.write("config/usage.txt", "title=::APP_TITLE:: camera=::MAC_CAMERA_USAGE_DESCRIPTION:: output=::OUTPUT_DIR::");

		output.update('<project>
			<meta title="Template Assets" />
			<app main="Main" file="MyApplication" path="Export" />
			<config:mac camera-usage-description="Reads QR codes" />
			<assets path="config" type="template" />
		</project>');

		Assert.equals("title=Template Assets camera=Reads QR codes output=" + output.platform.targetDirectory, output.read("config/usage.txt"));
	}

	// Windows writes both to the folder the application is in
	public function testOnWindowsTemplateAssetsAndOtherAssetsGoNextToTheApplication():Void
	{
		fixture.write("config/settings.txt", "title=::APP_TITLE::");
		fixture.write("data/notes.txt", "notes ::APP_TITLE::");

		output.update('<project>
			<meta title="Template Assets" />
			<app main="Main" file="MyApplication" path="Export" />
			<assets path="config" type="template" />
			<assets path="data" />
		</project>');

		Assert.equals("title=Template Assets", output.read("bin/config/settings.txt"));
		// Other assets are copied as they are
		Assert.equals("notes ::APP_TITLE::", output.read("bin/data/notes.txt"));
	}

	// A Mac application's template assets go to the target's folder, and its other assets to the
	// application bundle's resources
	public function testOnMacTemplateAssetsGoToTheOutputFolderAndOtherAssetsToTheResources():Void
	{
		fixture.target = MAC;
		fixture.write("config/settings.txt", "title=::APP_TITLE::");
		fixture.write("data/notes.txt", "notes ::APP_TITLE::");

		output.update('<project>
			<meta title="Template Assets" />
			<app main="Main" file="MyApplication" path="Export" />
			<assets path="config" type="template" />
			<assets path="data" />
		</project>');

		var resources = "bin/MyApplication.app/Contents/Resources/";

		Assert.equals("title=Template Assets", output.read("config/settings.txt"));
		Assert.isFalse(output.exists(resources + "config/settings.txt"), "the template asset is among the resources");

		Assert.equals("notes ::APP_TITLE::", output.read(resources + "data/notes.txt"));
		Assert.isFalse(output.exists("data/notes.txt"), "the asset is with the template assets");
	}

	// A small font of Lime's own
	private function addFont():Void
	{
		var font = Path.combine(fixture.directory, "fonts/Symbols.ttf");
		FileSystem.createDirectory(Path.directory(font));
		File.copy(Path.combine(PlatformFixture.templates(), "winjs/template/source/lib/winjs-4.0.1/fonts/Symbols.ttf"), font);
	}

	private function writeTemplates(folder:String, count:Int, text:String):Void
	{
		for (i in 0...count)
		{
			fixture.write(folder + "/template" + i + ".txt", text);
		}
	}
}

/**
	A copy of a platform's project that counts how often its template context is built.
**/
private class CountedProject extends HXProject
{
	public var contextBuilds = 0;

	/**
		Puts a counted copy in place of the project that `platform` works on.
	**/
	public static function replace(platform:PlatformTarget):CountedProject
	{
		var project = new CountedProject();
		ObjectTools.copyFields(platform.project, project);
		project.contextBuilds = 0;
		platform.project = project;
		return project;
	}

	private override function get_templateContext():Dynamic
	{
		contextBuilds++;
		return super.get_templateContext();
	}
}
