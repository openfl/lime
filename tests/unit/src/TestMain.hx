import utest.Runner;
import utest.ui.Report;
import lime.app.Application;

class TestMain extends Application {
	public function new() {
		super();

		var runner = new Runner();
		runner.addCase(new utils.ArrayBufferTest());
		runner.addCase(new utils.UInt8ArrayTest());
		runner.addCase(new utils.UInt16ArrayTest());
		runner.addCase(new utils.UInt32ArrayTest());
		runner.addCase(new utils.DataViewTest());
		runner.addCase(new utils.ObjectPoolTest());
		#if target.threaded
		runner.addCase(new utils.ThreadSafeObjectPoolTest());
		#end
		Report.create(runner);
		runner.run();
	}
}