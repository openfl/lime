import utest.Runner;
import utest.ui.Report;
import lime.app.Application;

class TestMain extends Application
{
	public function new()
	{
		super();

		var runner = new Runner();
		runner.addCase(new app.ApplicationTest());
		runner.addCase(new app.EventTest());
		runner.addCase(new app.FutureTest());
		runner.addCase(new app.PromiseTest());
		runner.addCase(new graphics.ImageCodecTest());
		runner.addCase(new graphics.ImageCopyTest());
		runner.addCase(new graphics.ImageDecodeOutputTest());
		runner.addCase(new graphics.ImageFillTest());
		runner.addCase(new graphics.ImageOperationOutputTest());
		runner.addCase(new graphics.ImagePixelTest());
		runner.addCase(new graphics.ImageRegionTest());
		runner.addCase(new graphics.OpenGLTest());
		runner.addCase(new math.ARGBTest());
		runner.addCase(new math.BGRATest());
		runner.addCase(new math.ColorMatrixTest());
		runner.addCase(new math.Matrix3Test());
		runner.addCase(new math.Matrix4Test());
		runner.addCase(new math.RectangleTest());
		runner.addCase(new math.RGBATest());
		runner.addCase(new math.Vector2Test());
		runner.addCase(new math.Vector4Test());
		runner.addCase(new media.AudioBufferTest());
		runner.addCase(new media.AudioInputTest());
		runner.addCase(new media.AudioSourceTest());
		runner.addCase(new media.OpenALTest());
		runner.addCase(new media.VideoDecoderTest());
		runner.addCase(new media.VideoInputTest());
		runner.addCase(new media.VideoNetworkTest());
		runner.addCase(new media.VideoFrameTest());
		runner.addCase(new media.VideoSourceTest());
		runner.addCase(new net.CURLEasyTest());
		runner.addCase(new net.CURLMultiTest());
		runner.addCase(new net.CURLTest());
		runner.addCase(new net.HTTPRequestMethodsTest());
		runner.addCase(new net.HTTPRequestRedirectTest());
		runner.addCase(new net.HTTPRequestResponseTest());
		runner.addCase(new net.HTTPRequestTest());
		runner.addCase(new net.HTTPRequestTransferTest());
		runner.addCase(new net.HTTPSTest());
		runner.addCase(new net.LocalSocketTest());
		runner.addCase(new net.URIParserTest());
		runner.addCase(new net.WebSocketTest());
		runner.addCase(new system.DisplayTest());
		runner.addCase(new system.FinalizerTest());
		runner.addCase(new system.LocaleTest());
		runner.addCase(new system.TimerTest());
		runner.addCase(new ui.GamepadTest());
		runner.addCase(new ui.HighDPITest());
		runner.addCase(new ui.MenuTest());
		runner.addCase(new ui.WebViewTest());
		runner.addCase(new ui.WindowTest());
		runner.addCase(new utils.ArrayBufferTest());
		runner.addCase(new utils.AssetBundleTest());
		runner.addCase(new utils.AssetLibraryTest());
		runner.addCase(new utils.AssetManifestTest());
		runner.addCase(new utils.AssetsTest());
		runner.addCase(new utils.Base64Test());
		runner.addCase(new utils.CompressionTest());
		runner.addCase(new utils.Float32ArrayTest());
		runner.addCase(new utils.Float64ArrayTest());
		runner.addCase(new utils.Int8ArrayTest());
		runner.addCase(new utils.Int16ArrayTest());
		runner.addCase(new utils.Int32ArrayTest());
		runner.addCase(new utils.ObjectPoolTest());
		runner.addCase(new utils.PackedAssetLibraryTest());
		runner.addCase(new utils.UInt8ArrayTest());
		runner.addCase(new utils.UInt8ClampedArrayTest());
		runner.addCase(new utils.UInt16ArrayTest());
		runner.addCase(new utils.UInt32ArrayTest());
		runner.addCase(new utils.DataViewTest());
		runner.addCase(new system.ThreadPoolTest());
		runner.addCase(new text.FontTest());
		runner.addCase(new text.UTF8StringTest());
		runner.addCase(new tools.ImageHelperTest());
		#if sys
		// Each test is named as it starts, so a run that hangs shows where
		runner.onTestStart.add(function(handler)
		{
			Sys.println("Running " + Type.getClassName(Type.getClass(handler.fixture.target)) + "." + handler.fixture.method);
			Sys.stdout().flush();
		});
		#end

		Report.create(runner);
		runner.run();
	}
}
