package lime.graphics; #if lime_console


import cpp.Float32;
import cpp.UInt8;
import cpp.UInt32;
import cpp.Pointer;
import lime.ConsoleIncludePaths;
import lime.graphics.console.Shader;
import lime.graphics.console.Primitive;
import lime.graphics.console.IndexBuffer;
import lime.graphics.console.VertexBuffer;
import lime.math.Matrix4;
import lime.utils.Float32Array;


@:headerCode("#include <ConsoleRenderAPI.h>")
class ConsoleRenderContext {


	public function new() {


	}
	
	
	public var width (get, never):Int;
	public var height (get, never):Int;

	
	public inline function clear (r:UInt8, g:UInt8, b:UInt8, a:UInt8, depth:Float32 = 1.0, stencil:UInt8 = 0):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderAPI::Clear ({0}, {1}, {2}, {3}, {4}, {5})",
			r, g, b, a, depth, stencil
		);

	}


	public inline function bindShader (shader:Shader):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderAPI::BindShader ((void *){0})",
			shader.ptr
		);

	}


	public inline function setVertexShaderConstantMatrix (startRegister:Int, matrix:Matrix4):Void {

		var array:Float32Array = matrix;
		untyped __cpp__ (
			"lime::ConsoleRenderAPI::SetVertexShaderConstantF ({0}, (float *){1}, 4)",
			startRegister,
			Pointer.arrayElem (array.buffer.getData (), 0).raw
		);

	}


	public inline function setVertexSource (vb:VertexBuffer):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderAPI::SetVertexSource ((void *){0})",
			vb.ptr
		);

	}


	public inline function setIndexSource (ib:IndexBuffer):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderAPI::SetIndexSource ((void *){0})",
			ib.ptr
		);

	}


	public inline function drawIndexed (primitive:Primitive, vertexCount:UInt32, startIndex:UInt32, primitiveCount:UInt32):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderAPI::DrawIndexed ({0}, {1}, {2}, {3})",
			primitive, vertexCount, startIndex, primitiveCount
		);

	}


	private inline function get_width ():Int {
		
		return untyped __cpp__ ("lime::ConsoleRenderAPI::GetWidth ()");

	}


	private inline function get_height ():Int {
		
		return untyped __cpp__ ("lime::ConsoleRenderAPI::GetHeight ()");

	}
	
	
}


#else


class ConsoleRenderContext {
	
	
	public function new () {
		
		
		
	}
	
	
	public function clear (a:Int, r:Int, g:Int, b:Int, depth:Float = 1.0, stencil:Int = 0):Void {}
	
	
}


#end
