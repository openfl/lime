package graphics;

import lime.app.Application;
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
		// The window is left open, hidden, as closing the last window of the application ends it
		var window = Application.current.createWindow({width: 64, height: 64, hidden: true, title: "OpenGLTest"});
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
	#end
}
