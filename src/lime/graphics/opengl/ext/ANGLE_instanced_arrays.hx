package lime.graphics.opengl.ext;

@:keep
#if (!js || !html5 || display)
@:noCompletion class ANGLE_instanced_arrays
{
	public var VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE = 0x88FE;

	@:noCompletion private function new() {}

	// GL_APICALL void GL_APIENTRY glDrawArraysInstancedANGLE (GLenum mode, GLint first, GLsizei count, GLsizei primcount);
	// GL_APICALL void GL_APIENTRY glDrawElementsInstancedANGLE (GLenum mode, GLsizei count, GLenum type, const void *indices, GLsizei primcount);
	// GL_APICALL void GL_APIENTRY glVertexAttribDivisorANGLE (GLuint index, GLuint divisor);
	public function drawArraysInstancedANGLE(mode:Int, first:Int, count:Int, primcount:Int):Void {}

	public function drawElementsInstancedANGLE(mode:Int, count:Int, type:Int, offset:Int, primcount:Int):Void {}

	public function vertexAttribDivisorANGLE(index:Int, divisor:Int):Void {}
}
#else
@:native("ANGLE_instanced_arrays")
@:noCompletion extern class ANGLE_instanced_arrays
{
	public var VERTEX_ATTRIB_ARRAY_DIVISOR_ANGLE:Int;
	public function drawArraysInstancedANGLE(mode:Int, first:Int, count:Int, primcount:Int):Void;
	public function drawElementsInstancedANGLE(mode:Int, count:Int, type:Int, offset:Int, primcount:Int):Void;
	public function vertexAttribDivisorANGLE(index:Int, divisor:Int):Void;
}
#end
