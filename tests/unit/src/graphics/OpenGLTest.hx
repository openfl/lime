package graphics;

import lime.app.Application;
import lime.graphics.OpenGLRenderContext;
import lime.graphics.WebGL2RenderContext;
import lime.graphics.opengl.GLBuffer;
import lime.graphics.opengl.GLFramebuffer;
import lime.graphics.opengl.GLProgram;
import lime.graphics.opengl.GLTexture;
import lime.ui.Window;
import lime.utils.ArrayBuffer;
import lime.utils.DataPointer;
import lime.utils.Float32Array;
import lime.utils.UInt8Array;
import utest.Assert;
import utest.Test;
#if (sys && target.threaded)
import sys.thread.Deque;
import sys.thread.Thread;
#end

class OpenGLTest extends Test
{
	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro && lime_opengl && (windows || mac || linux) && !rpi)
	private static inline var BUFFER_MAP_POINTER = 0x88BD;
	private static inline var MAP_WRITE_BIT = 0x0002;

	public function testAMappedBufferGivesItsPointer():Void
	{
		var window = createWindow();
		var gl = window != null && window.context != null ? window.context.gl : null;

		if (gl == null)
		{
			// utest takes a warning as a failure, so the test passes, saying why
			trace("There is no OpenGL context here, so OpenGL was not tested");
			Assert.pass();
			return;
		}

		var buffer = gl.createBuffer();
		gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
		gl.bufferData(gl.ARRAY_BUFFER, 16, 0, gl.STATIC_DRAW);
		var mapped = gl.mapBufferRange(gl.ARRAY_BUFFER, 0, 16, MAP_WRITE_BIT);

		if (mapped == 0)
		{
			trace("This OpenGL cannot map buffers, so their pointers were not tested");
			Assert.pass();
		}
		else
		{
			Assert.equals(mapped, gl.getBufferPointerv(gl.ARRAY_BUFFER, BUFFER_MAP_POINTER));
			gl.unmapBuffer(gl.ARRAY_BUFFER);
		}

		gl.deleteBuffer(buffer);
	}

	public function testImageDataIsCopiedBetweenTextures():Void
	{
		var main = getMainWindow();
		if (main == null) return;

		var gl = main.context.gl;
		makeCurrent(main);

		if (gl.version < 4.3 && gl.getSupportedExtensions().indexOf("ARB_copy_image") == -1)
		{
			trace("This OpenGL has neither OpenGL 4.3 nor ARB_copy_image, so copying images was not tested");
			Assert.pass();
			return;
		}

		var texels = new UInt8Array(16);
		for (i in 0...16)
			texels[i] = i * 16 + 8;

		var source = createTexture(gl, texels);
		var destination = createTexture(gl, 0);

		// Clears an error left by an earlier test
		gl.getError();
		gl.copyImageSubData(source, gl.TEXTURE_2D, 0, 0, 0, 0, destination, gl.TEXTURE_2D, 0, 0, 0, 0, 2, 2, 1);
		Assert.equals(gl.NO_ERROR, gl.getError());

		var framebuffer = gl.createFramebuffer();
		gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
		gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, destination, 0);

		var copied = new UInt8Array(16);
		gl.readPixels(0, 0, 2, 2, gl.RGBA, gl.UNSIGNED_BYTE, copied);
		gl.bindFramebuffer(gl.FRAMEBUFFER, null);
		gl.deleteFramebuffer(framebuffer);

		Assert.same([for (i in 0...16) texels[i]], [for (i in 0...16) copied[i]]);

		gl.deleteTexture(source);
		gl.deleteTexture(destination);
	}

	public function testWindowsShareTextures():Void
	{
		var main = getMainWindow();
		if (main == null) return;

		var gl = main.context.gl;
		makeCurrent(main);
		var texture = gl.createTexture();
		gl.bindTexture(gl.TEXTURE_2D, texture);
		gl.bindTexture(gl.TEXTURE_2D, null);

		var other = createWindow();
		makeCurrent(other);
		var shared = gl.isTexture(texture);

		makeCurrent(main);
		gl.deleteTexture(texture);
		Assert.isTrue(shared, "a texture made for one window could not be drawn in another");
	}

	public function testTheMainWindowsContextStaysCurrent():Void
	{
		var main = getMainWindow();
		if (main == null) return;

		// Each context has its own active texture unit, so it tells which one is current
		var gl = main.context.gl;
		makeCurrent(main);
		gl.activeTexture(gl.TEXTURE5);

		var other = createWindow();
		Assert.equals(gl.TEXTURE5, gl.getParameter(gl.ACTIVE_TEXTURE), "making a window left its context current");

		makeCurrent(other);
		Assert.equals(gl.TEXTURE0, gl.getParameter(gl.ACTIVE_TEXTURE), "another window had the main window's context");

		// Each window makes its own context current to render
		var backend = @:privateAccess Application.current.__backend;
		@:privateAccess backend.renderEventInfo.type = RENDER;
		@:privateAccess backend.handleRenderEvent();
		Assert.equals(gl.TEXTURE5, gl.getParameter(gl.ACTIVE_TEXTURE), "rendering left the last window's context current");

		makeCurrent(other);
		other.close();
		Assert.equals(gl.TEXTURE5, gl.getParameter(gl.ACTIVE_TEXTURE), "closing the window whose context was current left none current");

		makeCurrent(main);
		gl.activeTexture(gl.TEXTURE0);
	}

	public function testARenderKeepsItsContextWhenAnotherWindowOpensAndCloses():Void
	{
		var main = getMainWindow();
		if (main == null) return;

		var gl = main.context.gl;
		makeCurrent(main);
		gl.activeTexture(gl.TEXTURE5);

		var other = createWindow();
		makeCurrent(other);
		gl.activeTexture(gl.TEXTURE3);
		makeCurrent(main);

		var units:Array<Int> = [];
		var listener = function(_)
		{
			var popup = createWindow();
			units.push(gl.getParameter(gl.ACTIVE_TEXTURE));
			popup.close();
			units.push(gl.getParameter(gl.ACTIVE_TEXTURE));
		};

		other.onRender.add(listener);
		var backend = @:privateAccess Application.current.__backend;
		@:privateAccess backend.renderEventInfo.type = RENDER;
		@:privateAccess backend.handleRenderEvent();
		other.onRender.remove(listener);

		Assert.equals(2, units.length);
		Assert.equals(gl.TEXTURE3, units[0], "making a window moved the rest of the render to another context");
		Assert.equals(gl.TEXTURE3, units[1], "closing a window moved the rest of the render to another context");
		Assert.equals(gl.TEXTURE5, gl.getParameter(gl.ACTIVE_TEXTURE), "rendering left the last window's context current");

		makeCurrent(other);
		gl.activeTexture(gl.TEXTURE0);
		other.close();
		makeCurrent(main);
		gl.activeTexture(gl.TEXTURE0);
	}

	// WebGL2RenderContext's srcOffset, srcLength and length count elements of the view, as in WebGL 2.
	// The views here start partway into their buffers, so a read that runs past a view stays in its buffer.

	public function testWebGL2BufferDataUploadsTheWholeView():Void
	{
		var gl2 = getWebGL2();
		if (gl2 == null) return;

		var gl = Application.current.window.context.gl;
		var view = floatsAt(new ArrayBuffer(48), 8, [1, 2, 3, 4, 5, 6]);
		var buffer = gl.createBuffer();
		gl.bindBuffer(gl.ARRAY_BUFFER, buffer);

		gl2.bufferData(gl.ARRAY_BUFFER, view, gl.STATIC_DRAW);

		Assert.same([1.0, 2, 3, 4, 5, 6], readArrayBuffer(gl));
		finishBufferTest(gl, buffer);
	}

	@Ignored("Waiting on #2135")
	public function testWebGL2BufferDataTakesSrcOffsetAndLengthInElements():Void
	{
		// Native targets take both as bytes today, and upload the whole view's byteLength (see #2135)
		var gl2 = getWebGL2();
		if (gl2 == null) return;

		var gl = Application.current.window.context.gl;
		var view = floatsAt(new ArrayBuffer(48), 8, [1, 2, 3, 4, 5, 6]);
		var buffer = gl.createBuffer();
		gl.bindBuffer(gl.ARRAY_BUFFER, buffer);

		gl2.bufferData(gl.ARRAY_BUFFER, view, gl.STATIC_DRAW, 2, 3);
		var uploaded = readArrayBuffer(gl);
		Assert.same([3.0, 4, 5], uploaded, "srcOffset 2, length 3 uploaded " + uploaded.join(", "));

		// A length of 0 takes the rest of the view
		gl2.bufferData(gl.ARRAY_BUFFER, view, gl.STATIC_DRAW, 4);
		uploaded = readArrayBuffer(gl);
		Assert.same([5.0, 6], uploaded, "srcOffset 4 uploaded " + uploaded.join(", "));

		finishBufferTest(gl, buffer);
	}

	public function testWebGL2BufferSubDataWritesTheWholeView():Void
	{
		var gl2 = getWebGL2();
		if (gl2 == null) return;

		var gl = Application.current.window.context.gl;
		var buffer = gl.createBuffer();
		gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
		gl.bufferData(gl.ARRAY_BUFFER, 32, new Float32Array(8), gl.STATIC_DRAW);

		gl2.bufferSubData(gl.ARRAY_BUFFER, 8, floatsAt(new ArrayBuffer(32), 4, [7, 8, 9]));

		Assert.same([0.0, 0, 7, 8, 9, 0, 0, 0], readArrayBuffer(gl));
		finishBufferTest(gl, buffer);
	}

	@Ignored("Waiting on #2135")
	public function testWebGL2BufferSubDataTakesSrcOffsetAndLengthInElements():Void
	{
		// Native targets take both as bytes today (see #2135)
		var gl2 = getWebGL2();
		if (gl2 == null) return;

		var gl = Application.current.window.context.gl;
		var buffer = gl.createBuffer();
		gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
		gl.bufferData(gl.ARRAY_BUFFER, 32, new Float32Array(8), gl.STATIC_DRAW);

		gl2.bufferSubData(gl.ARRAY_BUFFER, 4, floatsAt(new ArrayBuffer(32), 4, [10, 20, 30, 40]), 1, 2);

		Assert.same([0.0, 20, 30, 0, 0, 0, 0, 0], readArrayBuffer(gl));
		finishBufferTest(gl, buffer);
	}

	public function testWebGL2UniformVectorsTakeTheWholeArray():Void
	{
		var gl2 = getWebGL2();
		if (gl2 == null) return;

		var gl = Application.current.window.context.gl;
		var program = createUniformProgram(gl);
		var location = gl.getUniformLocation(program, "values");

		gl2.uniform4fv(location, new Float32Array([for (i in 1...13) i]));

		Assert.same([1.0, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12], readVectorUniforms(gl, program));
		finishProgramTest(gl, program);
	}

	@Ignored("Waiting on #2135")
	public function testWebGL2UniformVectorsTakeSrcOffsetAndSrcLength():Void
	{
		// Native targets ignore both today, and send the whole array (see #2135)
		var gl2 = getWebGL2();
		if (gl2 == null) return;

		var gl = Application.current.window.context.gl;
		var program = createUniformProgram(gl);
		var location = gl.getUniformLocation(program, "values");
		gl.uniform4fv(location, 3, new Float32Array(12));

		// Two vectors, from the fifth float on
		gl2.uniform4fv(location, new Float32Array([for (i in 1...17) i]), 4, 8);

		Assert.same([5.0, 6, 7, 8, 9, 10, 11, 12, 0, 0, 0, 0], readVectorUniforms(gl, program));
		finishProgramTest(gl, program);
	}

	public function testWebGL2UniformMatrixTakesTheWholeArray():Void
	{
		var gl2 = getWebGL2();
		if (gl2 == null) return;

		var gl = Application.current.window.context.gl;
		var program = createUniformProgram(gl);
		var location = gl.getUniformLocation(program, "transform");

		gl2.uniformMatrix4fv(location, false, new Float32Array([for (i in 1...17) i]));

		Assert.same([for (i in 1...17) (i : Float)], readMatrixUniform(gl, program));
		finishProgramTest(gl, program);
	}

	@Ignored("Waiting on #2135")
	public function testWebGL2UniformMatrixTakesSrcOffsetAndSrcLengthInFloats():Void
	{
		// Native targets take srcOffset as bytes today, and srcLength as a number of matrices (see #2135)
		var gl2 = getWebGL2();
		if (gl2 == null) return;

		var gl = Application.current.window.context.gl;
		var program = createUniformProgram(gl);
		var location = gl.getUniformLocation(program, "transform");
		gl.uniformMatrix4fv(location, 1, false, new Float32Array(16));

		gl2.uniformMatrix4fv(location, false, new Float32Array([for (i in 1...33) i]), 16, 16);

		Assert.same([for (i in 17...33) (i : Float)], readMatrixUniform(gl, program));
		finishProgramTest(gl, program);
	}

	public function testWebGL2ReadPixelsFillsTheViewFromItsStart():Void
	{
		var gl2 = getWebGL2();
		if (gl2 == null) return;

		var gl = Application.current.window.context.gl;
		var target = createTargetTexture(gl);
		var buffer = new ArrayBuffer(24);
		var view = new UInt8Array(buffer, 4, 16);

		gl2.readPixels(0, 0, 2, 2, gl.RGBA, gl.UNSIGNED_BYTE, view);

		Assert.same(TEXELS, [for (i in 0...16) view[i]]);
		Assert.same([0, 0, 0, 0, 0, 0, 0, 0], [for (i in 0...4) buffer.get(i)].concat([for (i in 20...24) buffer.get(i)]), "outside the view");
		finishTargetTest(gl, target);
	}

	public function testWebGL2ReadPixelsTakesDstOffsetInBytesForBytes():Void
	{
		// An element of a UInt8Array is a byte, so this offset is right whichever way it is counted
		var gl2 = getWebGL2();
		if (gl2 == null) return;

		var gl = Application.current.window.context.gl;
		var target = createTargetTexture(gl);
		var view = new UInt8Array(new ArrayBuffer(32), 2, 24);

		gl2.readPixels(0, 0, 2, 2, gl.RGBA, gl.UNSIGNED_BYTE, view, 4);

		Assert.same([0, 0, 0, 0].concat(TEXELS).concat([0, 0, 0, 0]), [for (i in 0...24) view[i]]);
		finishTargetTest(gl, target);
	}

	@Ignored("Waiting on #2135")
	public function testWebGL2ReadPixelsTakesDstOffsetInElements():Void
	{
		// Native targets take dstOffset as bytes today (see #2135)
		var gl2 = getWebGL2();
		if (gl2 == null) return;

		// Floats read from a float texture, so no driver converts them
		var gl = Application.current.window.context.gl;
		var texture = gl.createTexture();
		gl.bindTexture(gl.TEXTURE_2D, texture);
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
		gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA32F, 1, 1, 0, gl.RGBA, gl.FLOAT, new Float32Array([0.25, 0.5, 0.75, 1]));
		gl.bindTexture(gl.TEXTURE_2D, null);
		var framebuffer = gl.createFramebuffer();
		gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
		gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);

		if (gl.checkFramebufferStatus(gl.FRAMEBUFFER) != gl.FRAMEBUFFER_COMPLETE)
		{
			trace("This OpenGL cannot draw to a float texture, so readPixels with a dstOffset was not tested");
			Assert.pass();
		}
		else
		{
			var view = new Float32Array(new ArrayBuffer(48), 0, 12);
			gl2.readPixels(0, 0, 1, 1, gl.RGBA, gl.FLOAT, view, 4);
			Assert.same([0.0, 0, 0, 0, 0.25, 0.5, 0.75, 1, 0, 0, 0, 0], [for (i in 0...12) view[i]]);
		}

		finishTargetTest(gl, {texture: texture, framebuffer: framebuffer});
	}

	public function testWebGL2ClearBufferTakesTheWholeView():Void
	{
		var gl2 = getWebGL2();
		if (gl2 == null) return;

		var gl = Application.current.window.context.gl;
		var target = createTargetTexture(gl);

		gl2.clearBufferfv(gl.COLOR, 0, new Float32Array([0.2, 0.4, 0.6, 0.8]));

		assertTargetIs(gl, [51, 102, 153, 204]);
		finishTargetTest(gl, target);
	}

	@Ignored("Waiting on #2135")
	public function testWebGL2ClearBufferTakesSrcOffsetInElements():Void
	{
		// Native targets take srcOffset as bytes today (see #2135)
		var gl2 = getWebGL2();
		if (gl2 == null) return;

		var gl = Application.current.window.context.gl;
		var target = createTargetTexture(gl);

		gl2.clearBufferfv(gl.COLOR, 0, new Float32Array([9, 9, 9, 9, 0.2, 0.4, 0.6, 0.8]), 4);

		assertTargetIs(gl, [51, 102, 153, 204]);
		finishTargetTest(gl, target);
	}

	#if (sys && target.threaded)
	#if neko
	@Ignored("Waiting on #2136")
	#end
	public function testGLObjectsStayRegisteredWhileOtherThreadsCollect():Void
	{
		// Objects are made and deleted here while other threads collect, which runs the finalizers of
		// the objects dropped without being deleted. While the finalizers change the registered objects
		// without the lock that register and deregister skip, this can hang or crash (see #2136).
		var main = getMainWindow();
		if (main == null) return;

		var gl = main.context.gl;
		makeCurrent(main);

		var running = [true];
		var finished = new Deque<Int>();

		for (i in 0...3)
		{
			Thread.create(function()
			{
				var collections = 0;

				while (running[0])
				{
					var garbage = [for (j in 0...500) [j, j + 1, j + 2]];
					garbage = null;
					collect();
					collections++;
				}

				finished.add(collections);
			});
		}

		var live:Array<{texture:GLTexture, buffer:GLBuffer, framebuffer:GLFramebuffer}> = [];
		var made = 0;
		var end = haxe.Timer.stamp() + 1;

		while (haxe.Timer.stamp() < end)
		{
			for (i in 0...16)
			{
				// A name is only an object once it has been bound
				var texture = gl.createTexture();
				gl.bindTexture(gl.TEXTURE_2D, texture);
				var buffer = gl.createBuffer();
				gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
				var framebuffer = gl.createFramebuffer();
				gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
				made++;

				// One in four is kept, and the rest dropped for the collector to finalize
				if (i % 4 == 0) live.push({texture: texture, buffer: buffer, framebuffer: framebuffer});
			}

			while (live.length > 96)
			{
				var objects = live.shift();
				gl.deleteTexture(objects.texture);
				gl.deleteBuffer(objects.buffer);
				gl.deleteFramebuffer(objects.framebuffer);
			}

			gl.bindTexture(gl.TEXTURE_2D, null);
			gl.bindBuffer(gl.ARRAY_BUFFER, null);
			gl.bindFramebuffer(gl.FRAMEBUFFER, null);
		}

		running[0] = false;
		var collections = 0;
		var stopped = 0;
		var deadline = haxe.Timer.stamp() + 5;

		while (stopped < 3 && haxe.Timer.stamp() < deadline)
		{
			var count:Null<Int> = finished.pop(false);

			if (count != null)
			{
				collections += count;
				stopped++;
			}
			else
			{
				Sys.sleep(0.01);
			}
		}

		var problems = [];
		for (objects in live)
		{
			if (!gl.isTexture(objects.texture)) problems.push("a live texture is not a texture");
			if (!gl.isBuffer(objects.buffer)) problems.push("a live buffer is not a buffer");
			if (!gl.isFramebuffer(objects.framebuffer)) problems.push("a live framebuffer is not a framebuffer");

			// Bindings are read back through the registered objects
			gl.bindTexture(gl.TEXTURE_2D, objects.texture);
			if (gl.getParameter(gl.TEXTURE_BINDING_2D) != objects.texture) problems.push("a bound texture is not found by its name");
			gl.bindBuffer(gl.ARRAY_BUFFER, objects.buffer);
			if (gl.getParameter(gl.ARRAY_BUFFER_BINDING) != objects.buffer) problems.push("a bound buffer is not found by its name");
			gl.bindFramebuffer(gl.FRAMEBUFFER, objects.framebuffer);
			if (gl.getParameter(gl.FRAMEBUFFER_BINDING) != objects.framebuffer) problems.push("a bound framebuffer is not found by its name");
		}

		gl.bindTexture(gl.TEXTURE_2D, null);
		gl.bindBuffer(gl.ARRAY_BUFFER, null);
		gl.bindFramebuffer(gl.FRAMEBUFFER, null);

		for (objects in live)
		{
			gl.deleteTexture(objects.texture);
			gl.deleteBuffer(objects.buffer);
			gl.deleteFramebuffer(objects.framebuffer);
		}

		Assert.equals(0, problems.length, problems.length + " problems with " + live.length + " live sets of " + made + ", first: " + problems[0]);
		Assert.equals(3, stopped, "the other threads did not all stop");
		Assert.isTrue(collections > 0, "the other threads did not collect");
	}
	#end

	#if software_gl
	public function testAForcedSoftwareContextDraws():Void
	{
		var forced = Sys.getEnv("LIME_SOFTWARE_GL");

		if (forced == null || forced == "" || forced == "0")
		{
			trace("LIME_SOFTWARE_GL is not set, so software OpenGL was not tested");
			Assert.pass();
			return;
		}

		if (Application.current.window == null) createWindow();
		var main = Application.current.window;

		if (main == null || main.context == null)
		{
			trace("There is no window here, so software OpenGL was not tested");
			Assert.pass();
			return;
		}

		var gl = main.context.gl;

		if (gl == null)
		{
			Assert.fail("The window fell back to " + main.context.type + " instead of software OpenGL");
			return;
		}

		makeCurrent(main);
		var renderer = gl.getString(gl.RENDERER);
		Assert.isFalse(main.context.attributes.hardware, renderer + " was reported as hardware");

		// A quad drawn over a red clear, so the pixels come from a shader, not only the clear
		var program = createProgram(gl, "attribute vec2 position; void main () { gl_Position = vec4 (position, 0.0, 1.0); }",
			"void main () { gl_FragColor = vec4 (0.0, 1.0, 0.0, 1.0); }");
		var texture = createTexture(gl, 0);
		var framebuffer = gl.createFramebuffer();
		gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
		gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
		gl.viewport(0, 0, 2, 2);
		gl.clearColor(1, 0, 0, 1);
		gl.clear(gl.COLOR_BUFFER_BIT);

		var buffer = gl.createBuffer();
		gl.bindBuffer(gl.ARRAY_BUFFER, buffer);
		gl.bufferData(gl.ARRAY_BUFFER, 32, new Float32Array([-1, -1, 1, -1, -1, 1, 1, 1]), gl.STATIC_DRAW);
		var position = gl.getAttribLocation(program, "position");
		gl.useProgram(program);
		gl.enableVertexAttribArray(position);
		gl.vertexAttribPointer(position, 2, gl.FLOAT, false, 0, 0);
		gl.drawArrays(gl.TRIANGLE_STRIP, 0, 4);

		var pixels = new UInt8Array(16);
		gl.readPixels(0, 0, 2, 2, gl.RGBA, gl.UNSIGNED_BYTE, pixels);

		gl.disableVertexAttribArray(position);
		gl.useProgram(null);
		gl.bindBuffer(gl.ARRAY_BUFFER, null);
		gl.bindFramebuffer(gl.FRAMEBUFFER, null);
		gl.deleteBuffer(buffer);
		gl.deleteFramebuffer(framebuffer);
		gl.deleteTexture(texture);
		gl.deleteProgram(program);

		Assert.same([for (i in 0...16) i % 2 == 1 ? 255 : 0], [for (i in 0...16) pixels[i]], renderer + " did not draw the quad");
	}
	#end

	private static function createProgram(gl:OpenGLRenderContext, vertexSource:String, fragmentSource:String):lime.graphics.opengl.GLProgram
	{
		var program = gl.createProgram();

		for (source in [{type: gl.VERTEX_SHADER, text: vertexSource}, {type: gl.FRAGMENT_SHADER, text: fragmentSource}])
		{
			var shader = gl.createShader(source.type);
			gl.shaderSource(shader, source.text);
			gl.compileShader(shader);
			Assert.isTrue(gl.getShaderParameter(shader, gl.COMPILE_STATUS) != 0, gl.getShaderInfoLog(shader));
			gl.attachShader(program, shader);
			gl.deleteShader(shader);
		}

		gl.linkProgram(program);
		Assert.isTrue(gl.getProgramParameter(program, gl.LINK_STATUS) != 0, gl.getProgramInfoLog(program));
		return program;
	}

	private static var TEXELS = [for (i in 0...16) i * 16 + 8];

	private static function getWebGL2():WebGL2RenderContext
	{
		var main = getMainWindow();
		if (main == null) return null;

		makeCurrent(main);
		if (main.context.webgl2 != null) return main.context.webgl2;

		// Desktop OpenGL 3 has every call these tests make, and a WebGL2RenderContext wraps the same context
		if (main.context.gl.version >= 3) return main.context.gl;

		trace("This OpenGL is older than 3.0, so WebGL2RenderContext was not tested");
		Assert.pass();
		return null;
	}

	private static function floatsAt(buffer:ArrayBuffer, byteOffset:Int, values:Array<Float>):Float32Array
	{
		var view = new Float32Array(buffer, byteOffset, values.length);
		for (i in 0...values.length)
			view[i] = values[i];
		return view;
	}

	/** The floats in the buffer bound to ARRAY_BUFFER, however many it holds **/
	private static function readArrayBuffer(gl:OpenGLRenderContext):Array<Float>
	{
		var size:Int = gl.getBufferParameter(gl.ARRAY_BUFFER, gl.BUFFER_SIZE);
		var floats = new Float32Array(size >> 2);
		if (size > 0) gl.getBufferSubData(gl.ARRAY_BUFFER, 0, floats.byteLength, floats);
		return [for (i in 0...floats.length) floats[i]];
	}

	private static function finishBufferTest(gl:OpenGLRenderContext, buffer:GLBuffer):Void
	{
		gl.bindBuffer(gl.ARRAY_BUFFER, null);
		gl.deleteBuffer(buffer);
		clearErrors(gl);
	}

	private static function createUniformProgram(gl:OpenGLRenderContext):GLProgram
	{
		var program = createProgram(gl,
			"uniform vec4 values[3]; uniform mat4 transform; attribute vec4 position; void main () { gl_Position = transform * position + values[0] + values[1] + values[2]; }",
			"void main () { gl_FragColor = vec4 (1.0); }");
		gl.useProgram(program);
		return program;
	}

	private static function readVectorUniforms(gl:OpenGLRenderContext, program:GLProgram):Array<Float>
	{
		var values = [];
		var vector = new Float32Array(4);

		for (i in 0...3)
		{
			gl.getUniformfv(program, gl.getUniformLocation(program, "values[" + i + "]"), vector);
			for (j in 0...4)
				values.push(vector[j]);
		}

		return values;
	}

	private static function readMatrixUniform(gl:OpenGLRenderContext, program:GLProgram):Array<Float>
	{
		var matrix = new Float32Array(16);
		gl.getUniformfv(program, gl.getUniformLocation(program, "transform"), matrix);
		return [for (i in 0...16) matrix[i]];
	}

	private static function finishProgramTest(gl:OpenGLRenderContext, program:GLProgram):Void
	{
		gl.useProgram(null);
		gl.deleteProgram(program);
		clearErrors(gl);
	}

	/** A framebuffer bound to a 2x2 texture holding TEXELS **/
	private static function createTargetTexture(gl:OpenGLRenderContext):{texture:GLTexture, framebuffer:GLFramebuffer}
	{
		var texels = new UInt8Array(16);
		for (i in 0...16)
			texels[i] = TEXELS[i];

		var texture = createTexture(gl, texels);
		var framebuffer = gl.createFramebuffer();
		gl.bindFramebuffer(gl.FRAMEBUFFER, framebuffer);
		gl.framebufferTexture2D(gl.FRAMEBUFFER, gl.COLOR_ATTACHMENT0, gl.TEXTURE_2D, texture, 0);
		return {texture: texture, framebuffer: framebuffer};
	}

	private static function assertTargetIs(gl:OpenGLRenderContext, rgba:Array<Int>, ?pos:haxe.PosInfos):Void
	{
		var pixels = new UInt8Array(16);
		gl.readPixels(0, 0, 2, 2, gl.RGBA, gl.UNSIGNED_BYTE, pixels);

		// A float becomes a byte by rounding, which may go either way at .5
		var actual:Array<Int> = [for (i in 0...16) pixels[i]];
		var close = true;
		for (i in 0...16)
		{
			if (Math.abs(actual[i] - rgba[i % 4]) > 1) close = false;
		}

		Assert.isTrue(close, "cleared to " + actual.slice(0, 4).join(", ") + ", not " + rgba.join(", "), pos);
	}

	private static function finishTargetTest(gl:OpenGLRenderContext, target:{texture:GLTexture, framebuffer:GLFramebuffer}):Void
	{
		gl.bindFramebuffer(gl.FRAMEBUFFER, null);
		gl.deleteFramebuffer(target.framebuffer);
		gl.deleteTexture(target.texture);
		clearErrors(gl);
	}

	private static function clearErrors(gl:OpenGLRenderContext):Void
	{
		var count = 0;
		while (gl.getError() != gl.NO_ERROR && count++ < 16) {}
	}

	private static function collect():Void
	{
		#if cpp
		cpp.vm.Gc.run(true);
		#elseif neko
		neko.vm.Gc.run(true);
		#elseif hl
		hl.Gc.major();
		#end
	}

	private static function getMainWindow():Window
	{
		// The first window created becomes the application's own
		if (Application.current.window == null) createWindow();

		var window = Application.current.window;

		if (window == null || window.context == null || window.context.gl == null)
		{
			// utest takes a warning as a failure, so the test passes, saying why
			trace("There is no OpenGL context here, so OpenGL was not tested");
			Assert.pass();
			return null;
		}

		return window;
	}

	private static function createTexture(gl:OpenGLRenderContext, data:DataPointer):GLTexture
	{
		var texture = gl.createTexture();
		gl.bindTexture(gl.TEXTURE_2D, texture);
		// A texture without mipmaps is complete, as copying needs, only with a filter that doesn't use them
		gl.texParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.NEAREST);
		gl.texImage2D(gl.TEXTURE_2D, 0, gl.RGBA, 2, 2, 0, gl.RGBA, gl.UNSIGNED_BYTE, data);
		gl.bindTexture(gl.TEXTURE_2D, null);
		return texture;
	}

	private static function createWindow():Window
	{
		// The window is left open, hidden, as closing the last window of the application ends it
		var window = Application.current.createWindow({width: 64, height: 64, hidden: true, title: "OpenGLTest", context: {type: OPENGL}});
		#if lime_test_require_opengl
		Assert.isTrue(window != null && window.context != null && window.context.gl != null, "The OpenGL tests require an OpenGL context");
		#end
		return window;
	}

	private static function makeCurrent(window:Window):Void
	{
		@:privateAccess lime._internal.backend.native.NativeCFFI.lime_window_context_make_current(window.__backend.handle);
	}
	#end
}
