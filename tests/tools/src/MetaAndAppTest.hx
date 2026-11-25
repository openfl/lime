import utest.Assert;
import utest.Test;

/**
	`<meta />` and `<app />`, from Lime's XML format documentation.
**/
class MetaAndAppTest extends Test
{
	private var fixture:Fixture;

	public function new()
	{
		super();
	}

	public function setup():Void
	{
		fixture = new Fixture();
	}

	public function teardown():Void
	{
		fixture.dispose();
	}

	// <meta title="My Application" package="com.example.myapplication" version="1.0.0" company="My Company" />
	public function testMetaDescribesTheApplication():Void
	{
		var project = fixture.parse('<project>
			<meta title="My Application" package="com.example.myapplication" version="1.0.0" company="My Company" />
		</project>');

		Assert.equals("My Application", project.meta.title);
		Assert.equals("com.example.myapplication", project.meta.packageName);
		Assert.equals("1.0.0", project.meta.version);
		Assert.equals("My Company", project.meta.company);
	}

	// <echo value="Metadata: ${meta.title} ${meta.version}" />
	public function testMetaValuesCanBeSubstituted():Void
	{
		var project = fixture.parse('<project>
			<meta title="My Application" version="1.0.0" />
			<set name="info" value="Metadata: $${meta.title} $${meta.version}" />
		</project>');

		Assert.equals("Metadata: My Application 1.0.0", project.defines.get("info"));
	}

	// "If you define the same value more than once, the last definition will be used."
	public function testLaterMetaValuesOverrideEarlierOnes():Void
	{
		var project = fixture.parse('<project>
			<meta title="First" company="My Company" />
			<meta title="Second" />
		</project>');

		Assert.equals("Second", project.meta.title);
		Assert.equals("My Company", project.meta.company);
	}

	// <app main="com.example.MyApplication" file="MyApplication" path="Export" preloader="CustomPreloader" />
	public function testAppSetsTheEntryPointAndOutput():Void
	{
		var project = fixture.parse('<project>
			<app main="com.example.MyApplication" file="MyApplication" path="Export" preloader="CustomPreloader" />
		</project>');

		Assert.equals("com.example.MyApplication", project.app.main);
		Assert.equals("MyApplication", project.app.file);
		Assert.equals("Export", project.app.path);
		Assert.equals("CustomPreloader", project.app.preloader);
	}

	public function testAppSwfVersionIsANumber():Void
	{
		var project = fixture.parse('<project>
			<app swf-version="11.8" />
		</project>');

		Assert.floatEquals(11.8, project.app.swfVersion);
	}

	// "Values can be retrieved with ${}"
	public function testAppValuesCanBeSubstituted():Void
	{
		var project = fixture.parse('<project>
			<app main="Main" file="MyApplication" />
			<set name="info" value="$${app.main} $${app.file}" />
		</project>');

		Assert.equals("Main MyApplication", project.defines.get("info"));
	}

	public function testAppValuesCanUseSubstitution():Void
	{
		var project = fixture.parse('<project>
			<set name="name" value="MyApplication" />
			<app file="$${name}" path="bin/$${name}" />
		</project>');

		Assert.equals("MyApplication", project.app.file);
		Assert.equals("bin/MyApplication", project.app.path);
	}
}
