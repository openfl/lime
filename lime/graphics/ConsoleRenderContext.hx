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


@:include("ConsoleRenderContext.h")
@:native("cpp::Struct<lime::ConsoleRenderContext>")
extern class ConsoleRenderContext {

	@:native("ConsoleRenderContext()")
	public static var singleton:ConsoleRenderContext;

	public var width (get, never):Int;
	public var height (get, never):Int;

	public function createIndexBuffer (count:Int):IndexBuffer;
	public function createVertexBuffer (decl:VertexDecl, count:Int):VertexBuffer;
	public function createTexture (format:TextureFormat, width:Int, height:Int, data:Pointer<UInt8>):Texture;

	public function transientIndexBuffer (count:Int):IndexBuffer;
	public function transientVertexBuffer (decl:VertexDecl, count:Int):VertexBuffer;

	public function destroyIndexBuffer (ib:IndexBuffer):Void;
	public function destroyVertexBuffer (vb:VertexBuffer):Void;
	public function destroyTexture (tex:Texture):Void;

	public function lookupShader (name:String):Shader;

	@:overload(function(r:UInt8, g:UInt8, b:UInt8, a:UInt8):Void{})
	@:overload(function(r:UInt8, g:UInt8, b:UInt8, a:UInt8, depth:Float32):Void{})
	public function clear (
		r:UInt8, g:UInt8, b:UInt8, a:UInt8,
		depth:Float32 /* = 1.0 */,
		stencil:UInt8 /* = 0 */
	):Void;

	public function bindShader (shader:Shader):Void;

	@:overload(function(x:UInt16, y:UInt16, width:UInt16, height:UInt16):Void{})
	@:overload(function(x:UInt16, y:UInt16, width:UInt16, height:UInt16, nearPlane:Float32):Void{})
	public function setViewport (
		x:UInt16, y:UInt16, width:UInt16, height:UInt16,
		nearPlane:Float32 /* = 0.0 */,
		farPlane:Float32 /* = 1.0 */
	):Void;

	public function setRasterizerState (state:RasterizerState):Void;
	public function setDepthStencilState (state:DepthStencilState):Void;
	public function setBlendState (state:BlendState):Void;

	public function setPixelShaderConstantF (startRegister:Int, vec4:Pointer<Float32>, vec4count:Int):Void;
	public function setVertexShaderConstantF (startRegister:Int, vec4:Pointer<Float32>, vec4count:Int):Void;

	public function setVertexSource (vb:VertexBuffer):Void;
	public function setIndexSource (ib:IndexBuffer):Void;

	public function setTexture (sampler:Int, texture:Texture):Void;
	public function setTextureFilter (sampler:Int, min:TextureFilter, mag:TextureFilter):Void;
	public function setTextureAddressMode (sampler:Int, u:TextureAddressMode, v:TextureAddressMode):Void;

	public function draw (primitive:Primitive, startVertex:UInt32, primitiveCount:UInt32):Void;
	public function drawIndexed (primitive:Primitive, vertexCount:UInt32, startIndex:UInt32, primitiveCount:UInt32):Void;

	public function debugReadFrameBuffer (dest:Pointer<UInt8>, width:Int, height:Int):Void;

	private function get_width ():Int;
	private function get_height ():Int;

}


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
