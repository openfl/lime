package lime.graphics.opengl.ext;

@:keep
@:noCompletion class NV_fence
{
	public var ALL_COMPLETED_NV = 0x84F2;
	public var FENCE_STATUS_NV = 0x84F3;
	public var FENCE_CONDITION_NV = 0x84F4;

	@:noCompletion private function new() {}

	// GL_APICALL void GL_APIENTRY glDeleteFencesNV (GLsizei, const GLuint *);
	// GL_APICALL void GL_APIENTRY glGenFencesNV (GLsizei, GLuint *);
	// GL_APICALL GLboolean GL_APIENTRY glIsFenceNV (GLuint);
	// GL_APICALL GLboolean GL_APIENTRY glTestFenceNV (GLuint);
	// GL_APICALL void GL_APIENTRY glGetFenceivNV (GLuint, GLenum, GLint *);
	// GL_APICALL void GL_APIENTRY glFinishFenceNV (GLuint);
	// GL_APICALL void GL_APIENTRY glSetFenceNV (GLuint, GLenum);
}
