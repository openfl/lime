import utest.Assert;
import utest.Test;

/**
	`<source />`, `<classpath />`, `<haxedef />`, `<haxeflag />` and `<compilerflag />`,
	from Lime's XML format documentation.
**/
class HaxeArgumentsTest extends Test
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

	// "Use <source /> tags to add Haxe class paths"
	public function testSourceAddsAClassPath():Void
	{
		var project = fixture.parse('<project>
			<source path="Source" />
		</project>');

		Fixture.assertSame(["Source"], project.sources);
	}

	// "Same as <source/>."
	public function testClasspathIsTheSameAsSource():Void
	{
		var project = fixture.parse('<project>
			<classpath path="Other" />
		</project>');

		Fixture.assertSame(["Other"], project.sources);
	}

	public function testSourceIsSkippedWhenItsConditionFails():Void
	{
		var project = fixture.parse('<project>
			<source path="Source" />
			<source path="Extra" if="never-set" />
		</project>');

		Fixture.assertSame(["Source"], project.sources);
	}

	// <haxedef name="define" />
	public function testHaxedefAddsADefine():Void
	{
		var project = fixture.parse('<project>
			<haxedef name="define" />
			<haxedef name="level" value="2" />
		</project>');

		Assert.isTrue(project.haxedefs.exists("define"));
		Assert.equals("2", project.haxedefs.get("level"));
	}

	// <haxeflag name="-dce" value="std" />
	public function testHaxeflagAddsCompilerArguments():Void
	{
		var project = fixture.parse('<project>
			<haxeflag name="-dce" value="std" />
			<haxeflag name="--no-traces" />
		</project>');

		Fixture.assertSame(["-dce std", "--no-traces"], project.haxeflags);
	}

	public function testCompilerflagIsTheSameAsHaxeflag():Void
	{
		var project = fixture.parse('<project>
			<compilerflag name="-dce" value="full" />
		</project>');

		Fixture.assertSame(["-dce full"], project.haxeflags);
	}

	public function testHaxeflagIsSkippedWhenItsConditionFails():Void
	{
		var project = fixture.parse('<project>
			<haxeflag name="--no-traces" unless="never-set" />
			<haxeflag name="--times" if="never-set" />
		</project>');

		Fixture.assertSame(["--no-traces"], project.haxeflags);
	}

	// Sources, defines and flags are what the build passes to Haxe
	public function testSourcesDefinesAndFlagsAreGivenToHaxe():Void
	{
		var project = fixture.parse('<project>
			<source path="Source" />
			<haxedef name="define" />
			<haxedef name="level" value="2" />
			<haxeflag name="-dce" value="std" />
		</project>');

		var flags = (project.templateContext.HAXE_FLAGS : String).split("\n");

		Assert.contains("-cp Source", flags);
		Assert.contains("-D define", flags);
		Assert.contains("-D level=2", flags);
		Assert.contains("-dce std", flags);
	}
}
