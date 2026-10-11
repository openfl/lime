package;

import haxe.Timer;
import lime.app.Application;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLUniformLocation;
import lime.graphics.RenderContext;
import lime.graphics.WebGLRenderContext;
import lime.media.VideoDecoder;
import lime.media.VideoFrame;
import lime.system.System;
import lime.utils.Float32Array;
import lime.utils.UInt8Array;

/**
	Plays assets/video.mp4 as texture frames and checks every frame on the
	GPU, which unit tests cannot do without a GL context.

	The video is 640x360 at 30 fps. A block at the top left has a luma of
	16 + (frame * 37) % 200, so reading it back shows which frame a texture
	really holds, and a block at the top right is pure red. This catches
	textures that stop updating, frames shown out of order or before they are
	written, black frames, wrong colors and flipped pictures. Garbage is
	collected between frames, so textures freed while the decoder still uses
	them show up too. After the last frame, the test seeks several times in a
	row and checks the frames from the final position. Platforms without a
	decoder for the clip skip the test.
**/
class Main extends Application
{
	private static inline var FRAME_RATE = 30;
	private static inline var SEEK_TIME = 1.0;
	private static inline var TIMEOUT = 20.0;

	private var blackFrames:Int;
	private var decoder:VideoDecoder;
	private var finished:Bool;
	private var firstTime:Float;
	private var frame:VideoFrame;
	private var frames:Int;
	private var glBuffer:GLBuffer;
	private var glPositionAttribute:Int;
	private var glProgram:GLProgram;
	private var glRegionUniform:GLUniformLocation;
	private var mismatches:Array<String>;
	private var pixel:UInt8Array;
	private var redChecked:Bool;
	private var seekFrames:Int;
	private var seekStartTime:Float;
	private var seeked:Bool;
	private var start:Float;
	private var values:Map<Int, Bool>;

	public function new()
	{
		super();

		blackFrames = 0;
		firstTime = -1;
		frame = new VideoFrame();
		frames = 0;
		mismatches = [];
		pixel = new UInt8Array(4);
		seekFrames = 0;
		seekStartTime = -1;
		values = new Map();
	}

	override public function onPreloadComplete():Void
	{
		super.onPreloadComplete();

		if (!VideoDecoder.isSupported)
		{
			skip("video decoding is not supported on this platform");
			return;
		}

		decoder = VideoDecoder.fromFile("assets/video.mp4", TEXTURE);

		if (decoder == null)
		{
			skip("there is no H.264 and AAC decoder for the test video");
			return;
		}

		start = Timer.stamp();
	}

	override public function render(context:RenderContext):Void
	{
		if (finished || decoder == null) return;

		switch (context.type)
		{
			case OPENGL, OPENGLES, WEBGL:
			default:
				fail("no OpenGL context");
				return;
		}

		var gl = context.webgl;
		if (glProgram == null) initGL(gl);

		if (Timer.stamp() - start > TIMEOUT)
		{
			fail("timed out after " + frames + " frames");
			return;
		}

		// Read every frame in order, checking each one as it arrives
		while (decoder.readFrame(frame))
		{
			checkFrame(gl);
			if (finished) return;
			collectGarbage(gl);
		}

		if (!decoder.videoComplete) return;

		if (!seeked)
		{
			// Seeks that follow each other before a frame is read, as a seek bar
			// does while it is dragged
			seeked = true;
			decoder.seek(0.5);
			decoder.seek(1.5);
			decoder.seek(SEEK_TIME);
			return;
		}

		finish();
	}

	private function collectGarbage(gl:WebGLRenderContext):Void
	{
		#if cpp
		cpp.vm.Gc.run(true);
		#elseif hl
		hl.Gc.major();
		#end

		// Lime deletes the GL objects of the wrappers it collected when clearing
		gl.clear(gl.COLOR_BUFFER_BIT);
	}

	private function checkFrame(gl:WebGLRenderContext):Void
	{
		if (frame.texture == null)
		{
			fail("frame " + frames + " has no texture");
			return;
		}

		if (frame.width != 640 || frame.height != 360)
		{
			fail("frame size " + frame.width + "x" + frame.height);
			return;
		}

		if (firstTime < 0) firstTime = frame.time;

		var index = Math.round((frame.time - firstTime) * FRAME_RATE);
		var expectedLuma = 16 + (index * 37) % 200;

		// The block's chroma is neutral, so its RGB is the luma expanded from video range
		var expected = Math.round(Math.max(0, Math.min(255, (expectedLuma - 16) * 255 / 219)));
		var color = sample(gl, 32, 32, 96, 96);
		var gray = Math.round((color[0] + color[1] + color[2]) / 3);

		if (color[0] + color[1] + color[2] == 0 && expected > 8) blackFrames++;

		if (Math.abs(gray - expected) > 10 && mismatches.length < 10)
		{
			mismatches.push("frame " + index + " at " + Math.round(frame.time * 1000) + " ms reads " + gray + ", expected " + expected);
		}

		values.set(gray, true);

		if (seeked)
		{
			if (seekStartTime < 0) seekStartTime = frame.time;
			seekFrames++;
		}
		else
		{
			frames++;
		}

		if (!redChecked)
		{
			// Sampled from the top right, so a flipped picture fails too
			var red = sample(gl, 640 - 96, 32, 640 - 32, 96);
			redChecked = true;

			if (red[0] < 200 || red[1] > 40 || red[2] > 40)
			{
				fail("the red block reads " + red.join(","));
			}
		}
	}

	private function fail(message:String):Void
	{
		trace("Video smoke failed: " + message);
		finished = true;
		if (decoder != null) decoder.close();
		System.exit(1);
	}

	private function finish():Void
	{
		var distinct = Lambda.count(values);

		if (frames < 58) fail("only " + frames + " of 60 frames arrived");
		else if (blackFrames > 0) fail(blackFrames + " frames were black");
		else if (distinct < 30) fail("only " + distinct + " different frames were shown, so textures are not updating");
		else if (mismatches.length > 1) fail("frames do not match their times: " + mismatches.join("; "));
		else if (seekFrames < 28) fail("only " + seekFrames + " frames arrived after seeking");
		else if (seekStartTime > SEEK_TIME + 0.001 || seekStartTime + 1 / FRAME_RATE <= SEEK_TIME) fail("after seeking to " + SEEK_TIME + " s, the first frame was at " + seekStartTime + " s");

		if (finished) return;

		trace("Video smoke passed: " + frames + " frames, " + distinct + " distinct, " + seekFrames + " after seeking");
		finished = true;
		decoder.close();
		System.exit(0);
	}

	private function initGL(gl:WebGLRenderContext):Void
	{
		var precision = #if !desktop "precision mediump float;" #else "" #end;

		// Draws one region of the video texture over the whole window
		glProgram = GLProgram.fromSources(gl, "attribute vec2 aPosition;
			uniform vec4 uRegion;
			varying vec2 vTexCoord;

			void main(void) {
				vTexCoord = uRegion.xy + (aPosition * 0.5 + 0.5) * uRegion.zw;
				gl_Position = vec4(aPosition, 0.0, 1.0);
			}", precision + "uniform sampler2D uImage0;
			varying vec2 vTexCoord;

			void main(void) {
				gl_FragColor = vec4(texture2D(uImage0, vTexCoord).rgb, 1.0);
			}");

		glPositionAttribute = gl.getAttribLocation(glProgram, "aPosition");
		glRegionUniform = gl.getUniformLocation(glProgram, "uRegion");
		gl.useProgram(glProgram);
		gl.uniform1i(gl.getUniformLocation(glProgram, "uImage0"), 0);

		glBuffer = gl.createBuffer();
		gl.bindBuffer(gl.ARRAY_BUFFER, glBuffer);
		gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), gl.STATIC_DRAW);
	}

	private function sample(gl:WebGLRenderContext, left:Float, top:Float, right:Float, bottom:Float):Array<Int>
	{
		// Texture frames start with the top row of the picture, so the region is
		// given from the top left in picture pixels
		gl.viewport(0, 0, Std.int(window.width * window.scale), Std.int(window.height * window.scale));
		gl.useProgram(glProgram);
		gl.uniform4f(glRegionUniform, left / 640, bottom / 360, (right - left) / 640, (top - bottom) / 360);

		gl.activeTexture(gl.TEXTURE0);
		gl.bindTexture(gl.TEXTURE_2D, frame.texture);
		gl.bindBuffer(gl.ARRAY_BUFFER, glBuffer);
		gl.enableVertexAttribArray(glPositionAttribute);
		gl.vertexAttribPointer(glPositionAttribute, 2, gl.FLOAT, false, 0, 0);
		gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);
		gl.disableVertexAttribArray(glPositionAttribute);

		gl.readPixels(Std.int(window.width * window.scale / 2), Std.int(window.height * window.scale / 2), 1, 1, gl.RGBA, gl.UNSIGNED_BYTE, pixel);
		return [pixel[0], pixel[1], pixel[2]];
	}

	private function skip(message:String):Void
	{
		trace("Video smoke skipped: " + message);
		finished = true;
		System.exit(0);
	}
}
