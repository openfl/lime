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

	public function testTextureFramesShowWhatColorFramesDo():Void
	{
		// The GPU converts texture frames, so they are compared with the frames Lime converts, near enough,
		// rather than byte for byte, and the test video's red and blue blocks are checked where they are
		var main = getMainWindow();
		if (main == null) return;

		makeCurrent(main);
		var gl = main.context.gl;
		var decoder = VideoDecoder.isSupported ? VideoDecoder.fromFile(PATH, VideoFrameFormat.TEXTURE) : null;
		var color = VideoDecoder.isSupported ? VideoDecoder.fromFile(PATH, VideoFrameFormat.RGBA) : null;

		if (decoder == null || color == null)
		{
			trace("Cannot decode H.264 here, so texture frames were not tested");
			Assert.pass();
			return;
		}

		decoder.dropLateFrames = false;
		color.dropLateFrames = false;

		var frame = new VideoFrame();
		var reference = new VideoFrame();
		var compared = 0;

		for (i in 0...6)
		{
			if (!nextFrame(decoder, frame) || !nextFrame(color, reference)) break;

			if (frame.texture == null)
			{
				trace("The decoder gives no texture frames here, so their pixels were not tested");
				Assert.pass();
				break;
			}

			Assert.equals(reference.time, frame.time, "the texture and color frames are not the same frame");

			var pixels = new lime.utils.UInt8Array(frame.width * frame.height * 4);
			var framebuffer = gl.createFramebuffer();
			gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
			gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, frame.texture, 0);
			var status = gl.checkFramebufferStatus(gl.FRAMEBUFFER);
			if (status == gl.FRAMEBUFFER_COMPLETE) gl.readPixels(0, 0, frame.width, frame.height, gl.RGBA, gl.UNSIGNED_BYTE, pixels);
			gl.bindFramebuffer(gl.FRAMEBUFFER, null);
			gl.deleteFramebuffer(framebuffer);

			Assert.equals(gl.FRAMEBUFFER_COMPLETE, status, "the texture can't be read through a framebuffer");
			if (status != gl.FRAMEBUFFER_COMPLETE) break;

			// Row 0 of a texture read back is whichever row the texture holds first
			var flipped = difference(pixels, reference, true) < difference(pixels, reference, false);
			var mean = difference(pixels, reference, flipped);
			Assert.isTrue(mean < 3, "frame " + i + " differs from the color frame by " + mean + " a channel on average" + (flipped ? ", upside down" : ""));
			compared++;
		}

		makeCurrent(main);
		decoder.close();
		color.close();

		if (compared == 0) Assert.pass();
	}

	/** The mean difference a channel between the texture's pixels and the color frame's, over every fourth pixel **/
	private static function difference(pixels:lime.utils.UInt8Array, frame:VideoFrame, flipped:Bool):Float
	{
		var total = 0.0;
		var count = 0;

		for (y in 0...frame.height)
		{
			if (y % 2 == 1) continue;
			var row = flipped ? frame.height - 1 - y : y;

			for (x in 0...frame.width)
			{
				if (x % 2 == 1) continue;
				for (channel in 0...3)
				{
					var a:Int = pixels[(row * frame.width + x) * 4 + channel];
					var b:Int = frame.data[(y * frame.width + x) * 4 + channel];
					total += a > b ? a - b : b - a;
					count++;
				}
			}
		}

		return Math.round(total / count * 100) / 100;
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
