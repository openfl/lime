package lime._backend.native;


import haxe.io.Bytes;
import lime.graphics.cairo.Cairo;
import lime.graphics.cairo.CairoFormat;
import lime.graphics.cairo.CairoImageSurface;
import lime.graphics.cairo.CairoSurface;
import lime.graphics.CairoRenderContext;
import lime.graphics.ConsoleRenderContext;
import lime.graphics.GLRenderContext;
import lime.graphics.Image;
import lime.graphics.ImageBuffer;
import lime.graphics.Renderer;
import lime.graphics.opengl.GL;
import lime.math.Rectangle;
import lime.utils.UInt8Array;

#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end

@:access(lime._backend.native.NativeCFFI)
@:access(lime._backend.native.NativeGLRenderContext)
@:access(lime.graphics.cairo.Cairo)
@:access(lime.graphics.opengl.GL)
@:access(lime.graphics.GLRenderContext)
@:access(lime.ui.Window)


class NativeRenderer {
	
	
	public var handle:Dynamic;
	
	private var parent:Renderer;
	private var useHardware:Bool;
	
	#if lime_cairo
	private var cacheLock:Dynamic;
	private var cairo:Cairo;
	private var primarySurface:CairoSurface;
	#end
	
	
	public function new (parent:Renderer) {
		
		this.parent = parent;
		
	}
	
	
	public function create ():Void {
		
		#if (!macro && lime_cffi)
		handle = NativeCFFI.lime_renderer_create (parent.window.backend.handle);
		
		parent.window.__scale = NativeCFFI.lime_renderer_get_scale (handle);
		
		#if lime_console
		
		useHardware = true;
		parent.context = CONSOLE (ConsoleRenderContext.singleton);
		parent.type = CONSOLE;
		
		#else
		
		var type:String = NativeCFFI.lime_renderer_get_type (handle);
		
		switch (type) {
			
			case "opengl":
				
				var context = new GLRenderContext ();
				
				useHardware = true;
				parent.context = OPENGL (context);
				parent.type = OPENGL;
				
				if (GL.context == null) {
					
					GL.context = context;
					
				}
			
			default:
				
				useHardware = false;
				
				#if lime_cairo
				render ();
				parent.context = CAIRO (cairo);
				#end
				parent.type = CAIRO;
			
		}
		
		#end
		#end
		
	}
	
	
	private function dispatch ():Void {
		
		
		
	}
	
	
	public function flip ():Void {
		
		#if (!macro && lime_cffi)
		if (!useHardware) {
			
			#if lime_cairo
			if (cairo != null) {
				
				primarySurface.flush ();
				
			}
			#end
			NativeCFFI.lime_renderer_unlock (handle);
			
		}
		
		NativeCFFI.lime_renderer_flip (handle);
		#end
		
	}
	
	
	public function readPixels (rect:Rectangle):Image {
		
		var imageBuffer:ImageBuffer = null;
		
		switch (parent.context) {
			
			case OPENGL (gl):
				
				var windowWidth = parent.window.__width * parent.window.__scale;
				var windowHeight = parent.window.__height * parent.window.__scale;
				
				var x = Std.int (rect.x);
				var y = Std.int ((windowHeight - rect.y) - rect.height);
				var width = Std.int (rect.width);
				var height = Std.int (rect.height);
				
				var buffer = Bytes.alloc (width * height * 4);
				
				gl.readPixels (x, y, width, height, gl.RGBA, gl.UNSIGNED_BYTE, buffer);
				
				var rowLength = width * 4;
				var srcPosition = (height - 1) * rowLength;
				var destPosition = 0;
				
				var temp = Bytes.alloc (rowLength);
				var rows = Std.int (height / 2);
				
				while (rows-- > 0) {
					
					temp.blit (0, buffer, destPosition, rowLength);
					buffer.blit (destPosition, buffer, srcPosition, rowLength);
					buffer.blit (srcPosition, temp, 0, rowLength);
					
					destPosition += rowLength;
					srcPosition -= rowLength;
					
				}
				
				imageBuffer = new ImageBuffer (new UInt8Array (buffer), width, height, 32, RGBA32);
			
			default:
				
				#if (!macro && lime_cffi)
				#if !cs
				imageBuffer = NativeCFFI.lime_renderer_read_pixels (handle, rect, new ImageBuffer (new UInt8Array (Bytes.alloc (0))));
				#else
				var data:Dynamic = NativeCFFI.lime_renderer_read_pixels (handle, rect, null);
				if (data != null) {
					imageBuffer = new ImageBuffer (new UInt8Array (@:privateAccess new Bytes (data.data.length, data.data.b)), data.width, data.height, data.bitsPerPixel);
				}
				#end
				#end
				
				if (imageBuffer != null) {
					
					imageBuffer.format = RGBA32;
					
				}
			
		}
		
		if (imageBuffer != null) {
			
			return new Image (imageBuffer);
			
		}
		
		return null;
		
	}
	
	
	public function render ():Void {
		
		#if (!macro && lime_cffi)
		NativeCFFI.lime_renderer_make_current (handle);
		
		if (!useHardware) {
			
			#if lime_cairo
			var lock:Dynamic = NativeCFFI.lime_renderer_lock (handle);
			
			if (lock != null && (cacheLock == null || cacheLock.pixels != lock.pixels || cacheLock.width != lock.width || cacheLock.height != lock.height)) {
				
				primarySurface = CairoImageSurface.create (lock.pixels, CairoFormat.ARGB32, lock.width, lock.height, lock.pitch);
				
				if (cairo != null) {
					
					cairo.recreate (primarySurface);
					
				} else {
					
					cairo = new Cairo (primarySurface);
					
				}
				
			}
			
			cacheLock = lock;
			#else
			parent.context = NONE;
			#end
			
		}
		#end
		
	}
	
	
}