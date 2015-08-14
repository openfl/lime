package lime.graphics; #if lime_console


import cpp.Float32;
import cpp.UInt8;
import cpp.UInt16;
import cpp.UInt32;
import cpp.Pointer;
import lime.ConsoleIncludePaths;
import lime.graphics.console.IndexBuffer;
import lime.graphics.console.Shader;
import lime.graphics.console.Primitive;
import lime.graphics.console.RenderState;
import lime.graphics.console.Texture;
import lime.graphics.console.TextureAddressMode;
import lime.graphics.console.TextureFilter;
import lime.graphics.console.TextureFormat;
import lime.graphics.console.VertexBuffer;
import lime.graphics.console.VertexDecl;
import lime.math.Matrix4;
import lime.utils.Float32Array;


// TODO(james4k): we'll use this extern class when they support default args.
// https://github.com/HaxeFoundation/haxe/issues/3955

#if 0


@:include("ConsoleRenderContext.h")
@:native("cpp::Struct<lime::ConsoleRenderContext>")
extern class ConsoleRenderContext {

	public var width (get, never):Int;
	public var height (get, never):Int;

	public function createIndexBuffer (indices:Pointer<UInt16>, count:Int):IndexBuffer;
	public function createVertexBuffer (decl:VertexDecl, count:Int):VertexBuffer;
	public function createTexture (format:TextureFormat, width:Int, height:Int, data:Pointer<UInt8>):Texture;

	public function destroyIndexBuffer (ib:IndexBuffer):Void;
	public function destroyVertexBuffer (vb:VertexBuffer):Void;
	public function destroyTexture (tex:Texture):Void;

	public function lookupShader (name:String):Shader;

	public function clear (r:UInt8, g:UInt8, b:UInt8, a:UInt8, depth:Float32 = 1.0, stencil:UInt8 = 0):Void;

	public function bindShader (shader:Shader):Void;

	public function setViewport (x:UInt16, y:UInt16, width:UInt16, height:UInt16, nearPlane:Float32 = 0.0, farPlane:Float32 = 1.0):Void;

	public function setVertexShaderConstantF (startRegister:Int, vec4:Pointer<Float32>, vec4count:Int):Void;

	public function setVertexSource (vb:VertexBuffer):Void;
	public function setIndexSource (ib:IndexBuffer):Void;

	public function setTexture (sampler:Int, texture:Texture):Void;
	public function setTextureFilter (sampler:Int, min:TextureFilter, mag:TextureFilter):Void;
	public function setTextureAddressMode (sampler:Int, u:TextureAddressMode, v:TextureAddressMode):Void;

	public function draw (primitive:Primitive, startVertex:UInt32, primitiveCount:UInt32):Void;
	public function drawIndexed (primitive:Primitive, vertexCount:UInt32, startIndex:UInt32, primitiveCount:UInt32):Void;

	private function get_width ():Int;
	private function get_height ():Int;

}


#else


@:headerCode("#include <ConsoleRenderContext.h>")
class ConsoleRenderContext {


	public function new() {


	}
	
	
	public var width (get, never):Int;
	public var height (get, never):Int;


	public function createIndexBuffer (indices:Pointer<UInt16>, count:Int):IndexBuffer {

		return untyped __cpp__ (
			"lime::ConsoleRenderContext().createIndexBuffer ({0}, {1})",
			indices, count
		);

	}


	public function createVertexBuffer (decl:VertexDecl, count:Int):VertexBuffer {

		return untyped __cpp__ (
			"lime::ConsoleRenderContext().createVertexBuffer ({0}, {1})",
			decl, count
		);

	}


	public function createTexture (format:TextureFormat, width:Int, height:Int, data:Pointer<UInt8>):Texture {

		return untyped __cpp__ (
			"lime::ConsoleRenderContext().createTexture ({0}, {1}, {2}, {3})",
			format, width, height, data
		);

	}


	public function destroyIndexBuffer (ib:IndexBuffer):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderContext().destroyIndexBuffer ({0})",
			ib
		);

	}



	public function destroyVertexBuffer (vb:VertexBuffer):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderContext().destroyVertexBuffer ({0})",
			vb
		);

	}


	public function destroyTexture (tex:Texture):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderContext().destroyTexture ({0})",
			tex
		);

	}


	public function lookupShader (name:String):Shader {

		return untyped __cpp__ (
			"lime::ConsoleRenderContext().lookupShader ({0})",
			name
		);

	}

	
	public inline function clear (r:UInt8, g:UInt8, b:UInt8, a:UInt8, depth:Float32 = 1.0, stencil:UInt8 = 0):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderContext().clear ({0}, {1}, {2}, {3}, {4}, {5})",
			r, g, b, a, depth, stencil
		);

	}


	public inline function bindShader (shader:Shader):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderContext().bindShader ({0})",
			shader
		);

	}


	public function setViewport (x:UInt16, y:UInt16, width:UInt16, height:UInt16, nearPlane:Float32 = 0.0, farPlane:Float32 = 1.0):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderContext().setViewport ({0}, {1}, {2}, {3}, {4}, {5})",
			x, y, width, height, nearPlane, farPlane
		);

	}


	public function setRasterizerState (state:RasterizerState):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderContext().setRasterizerState ({0})",
			state
		);

	}


	public function setDepthStencilState (state:DepthStencilState):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderContext().setDepthStencilState ({0})",
			state
		);

	}


	public function setBlendState (state:BlendState):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderContext().setBlendState ({0})",
			state
		);

	}


	public inline function setVertexShaderConstantF (startRegister:Int, vec4:cpp.Pointer<Float32>, vec4count:Int):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderContext().setVertexShaderConstantF ({0}, (float *){1}, {2})",
			startRegister,
			vec4,
			vec4count
		);

	}


	public inline function setVertexSource (vb:VertexBuffer):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderContext().setVertexSource ({0})",
			vb
		);

	}


	public inline function setIndexSource (ib:IndexBuffer):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderContext().setIndexSource ({0})",
			ib
		);

	}


	public inline function setTexture (sampler:Int, texture:Texture):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderContext().setTexture ({0}, {1})",
			sampler, texture
		);

	}


	public inline function setTextureFilter (sampler:Int, min:TextureFilter, mag:TextureFilter):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderContext().setTextureFilter ({0}, {1}, {2})",
			sampler, min, mag
		);

	}


	public inline function setTextureAddressMode (sampler:Int, u:TextureAddressMode, v:TextureAddressMode):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderContext().setTextureAddressMode ({0}, {1}, {2})",
			sampler, u, v
		);

	}


	public inline function draw (primitive:Primitive, startVertex:UInt32, primitiveCount:UInt32):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderContext().draw ({0}, {1}, {2})",
			primitive, startVertex, primitiveCount
		);

	}


	public inline function drawIndexed (primitive:Primitive, vertexCount:UInt32, startIndex:UInt32, primitiveCount:UInt32):Void {

		untyped __cpp__ (
			"lime::ConsoleRenderContext().drawIndexed ({0}, {1}, {2}, {3})",
			primitive, vertexCount, startIndex, primitiveCount
		);

	}


	private inline function get_width ():Int {
		
		return untyped __cpp__ ("lime::ConsoleRenderContext().get_width ()");

	}


	private inline function get_height ():Int {
		
		return untyped __cpp__ ("lime::ConsoleRenderContext().get_height ()");

	}
	
	
}


#end


#else


import lime.graphics.console.Shader;
import lime.graphics.console.Primitive;
import lime.graphics.console.IndexBuffer;
import lime.graphics.console.VertexBuffer;


class ConsoleRenderContext {
	
	
	public function new () {
		
		
		
	}
	
	
	public var width (get, never):Int;
	public var height (get, never):Int;

	public function createIndexBuffer (indices, count:Int):IndexBuffer { return new IndexBuffer (); }
	public function createVertexBuffer (decl, count:Int):VertexBuffer { return new VertexBuffer (); }
	public function lookupShader (name:String):Shader { return new Shader (); }

	public function clear (r:Int, g:Int, b:Int, a:Int, depth:Float = 1.0, stencil:Int = 0):Void {}

	public function bindShader (shader:Shader):Void {}

	public function setViewport (x, y, width, height, nearPlane = 0.0, farPlane = 1.0):Void {}

	public function setVertexShaderConstantF (startRegister, vec4, vec4count):Void {}

	public function setVertexSource (vb:VertexBuffer):Void {}
	public function setIndexSource (ib:IndexBuffer):Void {}

	public function draw (primitive, startVertex, primitiveCount):Void {}
	public function drawIndexed (primitive, vertexCount, startIndex, primitiveCount):Void {}

	private function get_width ():Int { return 0; }
	private function get_height ():Int { return 0; }
	
	
}


#end
