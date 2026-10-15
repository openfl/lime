import utest.Runner;
import utest.ui.Report;
import lime.app.Application;

class TestMain extends Application
{
	public function new()
	{
		super();

		var runner = new Runner();
		runner.addCase(new app.EventTest());
		runner.addCase(new app.FutureTest());
		runner.addCase(new media.OpenALTest());
		runner.addCase(new media.VideoDecoderTest());
		runner.addCase(new media.VideoInputTest());
		runner.addCase(new media.VideoNetworkTest());
		runner.addCase(new media.VideoFrameTest());
		runner.addCase(new media.VideoSourceTest());
		runner.addCase(new net.CURLTest());
		runner.addCase(new system.TimerTest());
		runner.addCase(new ui.MenuTest());
		runner.addCase(new ui.WindowTest());
		runner.addCase(new utils.ArrayBufferTest());
		runner.addCase(new utils.UInt8ArrayTest());
		runner.addCase(new utils.UInt16ArrayTest());
		runner.addCase(new utils.UInt32ArrayTest());
		runner.addCase(new utils.DataViewTest());
		runner.addCase(new system.ThreadPoolTest());
		runner.addCase(new text.FontTest());
		Report.create(runner);
		runner.run();
	}
}
