package graphics;

import lime.app.Application;
import lime.ui.Window;
import utest.Assert;
import utest.Test;

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

		makeCurrent(main);
		gl.activeTexture(gl.TEXTURE0);
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

	private static function createWindow():Window
	{
		// The window is left open, hidden, as closing the last window of the application ends it
		return Application.current.createWindow({width: 64, height: 64, hidden: true, title: "OpenGLTest"});
	}

	private static function makeCurrent(window:Window):Void
	{
		@:privateAccess lime._internal.backend.native.NativeCFFI.lime_window_context_make_current(window.__backend.handle);
	}
	#end
}
