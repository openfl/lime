import utest.Runner;
import utest.ui.Report;

class ToolsTestMain
{
	public static function main():Void
	{
		var runner = new Runner();
		runner.addCase(new ConditionalsTest());
		runner.addCase(new MetaAndAppTest());
		runner.addCase(new WindowTest());
		runner.addCase(new IncludeTest());
		runner.addCase(new HaxelibTest());
		runner.addCase(new HaxeArgumentsTest());
		runner.addCase(new AssetsTest());
		runner.addCase(new AssetEmbeddingTest());
		runner.addCase(new ConfigTest());
		runner.addCase(new ProjectElementsTest());

		// Each test is named as it starts, so a run that stops (the tools exit on errors) shows where
		runner.onTestStart.add(function(handler)
		{
			Sys.println("Running " + Type.getClassName(Type.getClass(handler.fixture.target)) + "." + handler.fixture.method);
			Sys.stdout().flush();
		});

		Report.create(runner);
		runner.run();
	}
}
