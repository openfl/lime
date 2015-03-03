package lime.graphics; #if lime_console


import cpp.Float32;
import cpp.UInt8;
import cpp.UInt16;
import cpp.UInt32;
import cpp.Pointer;
import lime.ConsoleIncludePaths;
import lime.graphics.console.Shader;
import lime.graphics.console.Primitive;
import lime.graphics.console.IndexBuffer;
import lime.graphics.console.VertexBuffer;
import lime.math.Matrix4;
import lime.utils.Float32Array;


// TODO(james4k): we'll use this extern class when they support default args.
// https://github.com/HaxeFoundation/haxe/issues/3955

#if 0


@:include("ConsoleHaxeAPI.h")
@:native("lime::hxapi::ConsoleRenderContext")
extern class ConsoleRenderContext {

	public var width (get, never):Int;
	public var height (get, never):Int;

	public function createIndexBuffer (indices:Pointer<UInt16>, count:Int):IndexBuffer;
	public function createVertexBuffer (decl:VertexDecl, count:Int):VertexBuffer;
	public function lookupShader (name:String):Shader;

	public function clear (r:UInt8, g:UInt8, b:UInt8, a:UInt8, depth:Float32 = 1.0, stencil:UInt8 = 0):Void;

	public function bindShader (shader:Shader):Void;

	//public function setViewport (x:UInt16, y:UInt16, width:UInt16, height:UInt16, nearPlane:Float32 = 0.0, farPlane:Float32 = 1.0):Void;

	public function setVertexShaderConstantF (startRegister:Int, vec4:Pointer<Float32>, vec4count:Int):Void;

	public function setVertexSource (vb:VertexBuffer):Void;
	public function setIndexSource (ib:IndexBuffer):Void;

	public function draw (primitive:Primitive, startVertex:UInt32, primitiveCount:UInt32):Void;
	public function drawIndexed (primitive:Primitive, vertexCount:UInt32, startIndex:UInt32, primitiveCount:UInt32):Void;

	private function get_width ():Int;
	private function get_height ():Int;

}


#else


class ConsoleRenderContext {


	public function new() {


	}
	
	
	public var width (get, never):Int;
	public var height (get, never):Int;


	public function createIndexBuffer (indices:Pointer<UInt16>, count:Int):IndexBuffer {

		return untyped __cpp__ (
			"lime::hxapi::ConsoleRenderContext()->createIndexBuffer ({0}, {1})",
			indices, count
		);

	}


	public function createVertexBuffer (decl:VertexDecl, count:Int):VertexBuffer {

		return untyped __cpp__ (
			"lime::hxapi::ConsoleRenderContext()->createVertexBuffer ({0}, {1})",
			decl, count
		);

	}


	public function lookupShader (name:String):Shader {

		return untyped __cpp__ (
			"lime::hxapi::ConsoleRenderContext()->lookupShader ({0})",
			name
		);

	}

	
	public inline function clear (r:UInt8, g:UInt8, b:UInt8, a:UInt8, depth:Float32 = 1.0, stencil:UInt8 = 0):Void {

		untyped __cpp__ (
			"lime::hxapi::ConsoleRenderContext()->clear ({0}, {1}, {2}, {3}, {4}, {5})",
			r, g, b, a, depth, stencil
		);

	}


	public inline function bindShader (shader:Shader):Void {

		untyped __cpp__ (
			"lime::hxapi::ConsoleRenderContext()->bindShader ({0})",
			shader
		);

	}


	public inline function setVertexShaderConstantF (startRegister:Int, vec4:cpp.Pointer<Float32>, vec4count:Int):Void {

		untyped __cpp__ (
			"lime::hxapi::ConsoleRenderContext()->setVertexShaderConstantF ({0}, (float *){1}, {2})",
			startRegister,
			vec4,
			vec4count
		);

	}


	public inline function setVertexShaderConstantMatrix (startRegister:Int, matrix:Matrix4):Void {

		var array:Float32Array = matrix;
		untyped __cpp__ (
			"lime::hxapi::ConsoleRenderContext()->setVertexShaderConstantF ({0}, (float *){1}, 4)",
			startRegister,
			Pointer.arrayElem (array.buffer.getData (), 0).raw
		);

	}


	public inline function setVertexSource (vb:VertexBuffer):Void {

		untyped __cpp__ (
			"lime::hxapi::ConsoleRenderContext()->setVertexSource ({0})",
			vb
		);

	}


	public inline function setIndexSource (ib:IndexBuffer):Void {

		untyped __cpp__ (
			"lime::hxapi::ConsoleRenderContext()->setIndexSource ({0})",
			ib
		);

	}


	public inline function drawIndexed (primitive:Primitive, vertexCount:UInt32, startIndex:UInt32, primitiveCount:UInt32):Void {

		untyped __cpp__ (
			"lime::hxapi::ConsoleRenderContext()->drawIndexed ({0}, {1}, {2}, {3})",
			primitive, vertexCount, startIndex, primitiveCount
		);

	}


	private inline function get_width ():Int {
		
		return untyped __cpp__ ("lime::hxapi::ConsoleRenderContext()->get_width ()");

	}


	private inline function get_height ():Int {
		
		return untyped __cpp__ ("lime::hxapi::ConsoleRenderContext()->get_height ()");

	}
	
	
}


#end


#else


class ConsoleRenderContext {
	
	
	public function new () {
		
		
		
	}
	
	
	public function clear (a:Int, r:Int, g:Int, b:Int, depth:Float = 1.0, stencil:Int = 0):Void {}
	
	
}


#end
