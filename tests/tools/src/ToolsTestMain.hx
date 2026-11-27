import utest.Runner;
import utest.ui.Report;

class ToolsTestMain
{
	public static function main():Void
	{
		// LaunchArgumentsTest starts this program as the command-line tools, which read their own
		// command line, so what reaches the application from it can be tested
		if (Sys.getEnv(LaunchArgumentsTest.RUN_TOOLS) == "1")
		{
			CommandLineTools.main();
			return;
		}

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
		runner.addCase(new ConfigDataTest());
		runner.addCase(new TemplateContextTest());
		runner.addCase(new HTML5OutputTest());
		runner.addCase(new AndroidOutputTest());
		runner.addCase(new LimeNineWarningTest());
		runner.addCase(new AndroidIconTest());
		runner.addCase(new IOSOutputTest());
		runner.addCase(new XCodeHelperTest());
		runner.addCase(new WindowsOutputTest());
		runner.addCase(new TemplateAssetOutputTest());
		runner.addCase(new HashlinkHelperTest());
		runner.addCase(new AppleOutputTest());
		runner.addCase(new OpenURLTest());
		runner.addCase(new NativeSourcesTest());
		runner.addCase(new BuildEnvironmentTest());
		runner.addCase(new CPPHelperTest());
		runner.addCase(new LaunchArgumentsTest());

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
