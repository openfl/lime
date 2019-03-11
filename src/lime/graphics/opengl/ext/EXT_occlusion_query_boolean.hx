package lime.graphics.opengl.ext;

@:keep
@:noCompletion class EXT_occlusion_query_boolean
{
	public var ANY_SAMPLES_PASSED_EXT = 0x8C2F;
	public var ANY_SAMPLES_PASSED_CONSERVATIVE_EXT = 0x8D6A;
	public var CURRENT_QUERY_EXT = 0x8865;
	public var QUERY_RESULT_EXT = 0x8866;
	public var QUERY_RESULT_AVAILABLE_EXT = 0x8867;

	@:noCompletion private function new() {}

	// GL_APICALL void GL_APIENTRY glGenQueriesEXT (GLsizei n, GLuint *ids);
	// GL_APICALL void GL_APIENTRY glDeleteQueriesEXT (GLsizei n, const GLuint *ids);
	// GL_APICALL GLboolean GL_APIENTRY glIsQueryEXT (GLuint id);
	// GL_APICALL void GL_APIENTRY glBeginQueryEXT (GLenum target, GLuint id);
	// GL_APICALL void GL_APIENTRY glEndQueryEXT (GLenum target);
	// GL_APICALL void GL_APIENTRY glGetQueryivEXT (GLenum target, GLenum pname, GLint *params);
	// GL_APICALL void GL_APIENTRY glGetQueryObjectuivEXT (GLuint id, GLenum pname, GLuint *params);
}
