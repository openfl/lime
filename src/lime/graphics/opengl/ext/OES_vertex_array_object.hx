package lime.graphics.opengl.ext;

@:keep
#if (!js || !html5 || display)
@:noCompletion class OES_vertex_array_object
{
	public var VERTEX_ARRAY_BINDING_OES = 0x85B5;

	@:noCompletion private function new() {}

	public function createVertexArrayOES():Dynamic
	{
		return null;
	} /*WebGLVertexArrayObject*/

	public function deleteVertexArrayOES(arrayObject:Dynamic /*WebGLVertexArrayObject*/):Void {}

	public function isVertexArrayOES(arrayObject:Dynamic /*WebGLVertexArrayObject*/):Bool
	{
		return false;
	}

	public function bindVertexArrayOES(arrayObject:Dynamic /*WebGLVertexArrayObject*/):Void {}

	// public function bindVertexArrayOES (array:Int):Void {}
	// public function deleteVertexArraysOES (n:Int, arrays:Array<Int>):Void {}
	// public function genVertexArraysOES (n:Int, arrays:Array<Int>):Void {}
	// public function isVertexArrayOES (array:Int):Bool;
}
#else
@:native("OES_vertex_array_object")
@:noCompletion extern class OES_vertex_array_object
{
	public var VERTEX_ARRAY_BINDING_OES:Int;
	public function createVertexArrayOES():Dynamic; /*WebGLVertexArrayObject*/
	public function deleteVertexArrayOES(arrayObject:Dynamic /*WebGLVertexArrayObject*/):Void;
	public function isVertexArrayOES(arrayObject:Dynamic /*WebGLVertexArrayObject*/):Bool;
	public function bindVertexArrayOES(arrayObject:Dynamic /*WebGLVertexArrayObject*/):Void;
}
#end
