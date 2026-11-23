package media;

#if (lime_cffi && !macro)
import haxe.Timer;
import lime.app.Application;
import lime.graphics.opengl.GLTexture;
import lime.media.VideoDecoder;
import lime.media.VideoFrame;
import lime.media.VideoFrameFormat;
import lime.ui.Window;
#end
import utest.Assert;
import utest.Test;

/**
	Texture frames of assets/video.mp4, read with one window's context current
	and then another's. Lime's windows share their textures with the main
	window's, so a decoder can keep its textures whichever window reads it.

	The name matches the OpenGLTest pattern, which CI runs with an OpenGL
	context.
**/
class VideoTextureOpenGLTest extends Test
{
	private static inline var PATH = "assets/video.mp4";
	private static inline var FRAMES = 24;
	private static inline var TIMEOUT = 15;

	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro && (lime_opengl || lime_opengles))
	public function testReadingUnderAnotherWindowKeepsTheDecodersTextures():Void
	{
		var main = getMainWindow();
		if (main == null) return;

		var other = createWindow();
		if (other == null || other.context == null || other.context.gl == null) return;

		// The textures a decoder uses when one context reads every frame
		makeCurrent(main);
		var alone = readTextures([main]);
		if (alone == null) return;

		// Every frame read under the other window's context than the last
		var alternating = readTextures([main, other]);
		if (alternating == null) return;

		makeCurrent(main);
		Assert.isTrue(alternating.length <= alone.length,
			"read under two windows, the decoder used " + alternating.length + " textures, against " + alone.length + " under one");

		// The textures it gave are deleted when it closes, wherever they were read
		var gl = main.context.gl;
		for (texture in alternating) Assert.isFalse(gl.isTexture(texture), "texture " + @:privateAccess texture.id + " is still alive");
	}

	// Reads FRAMES texture frames, making each window's context current in turn,
	// and returns the textures that the frames used
	private static function readTextures(windows:Array<Window>):Array<GLTexture>
	{
		makeCurrent(windows[0]);
		var decoder = VideoDecoder.isSupported ? VideoDecoder.fromFile(PATH, VideoFrameFormat.TEXTURE) : null;

		if (decoder == null)
		{
			trace("Cannot decode H.264 here, so texture frames were not tested");
			Assert.pass();
			return null;
		}

		var frame = new VideoFrame();
		var textures:Array<GLTexture> = [];

		for (i in 0...FRAMES)
		{
			makeCurrent(windows[i % windows.length]);
			if (!nextFrame(decoder, frame)) break;

			if (frame.texture == null)
			{
				makeCurrent(windows[0]);
				decoder.close();

				if (i > 0)
				{
					Assert.fail("frame " + i + " has no texture");
					return null;
				}

				trace("The decoder gives no texture frames here, so they were not tested");
				Assert.pass();
				return null;
			}

			if (textures.indexOf(frame.texture) < 0) textures.push(frame.texture);
		}

		makeCurrent(windows[0]);
		decoder.close();
		return textures;
	}

	private static function nextFrame(decoder:VideoDecoder, frame:VideoFrame):Bool
	{
		var start = Timer.stamp();

		while (!decoder.readFrame(frame))
		{
			if (decoder.videoComplete || Timer.stamp() - start > TIMEOUT) return false;
			Sys.sleep(0.001);
		}

		return true;
	}

	private static function getMainWindow():Window
	{
		// The first window created becomes the application's own
		if (Application.current.window == null) createWindow();

		var window = Application.current.window;

		if (window == null || window.context == null || window.context.gl == null)
		{
			trace("There is no OpenGL context here, so texture frames were not tested");
			Assert.pass();
			return null;
		}

		return window;
	}

	private static function createWindow():Window
	{
		// Left open, hidden, as closing the last window of the application ends it
		return Application.current.createWindow({width: 64, height: 64, hidden: true, title: "VideoTextureOpenGLTest", context: {type: OPENGL}});
	}

	private static function makeCurrent(window:Window):Void
	{
		@:privateAccess lime._internal.backend.native.NativeCFFI.lime_window_context_make_current(window.__backend.handle);
	}
	#end
}
