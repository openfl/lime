package lime.graphics.opengl.ext;

@:keep
@:noCompletion class EXT_robustness
{
	public var GUILTY_CONTEXT_RESET_EXT = 0x8253;
	public var INNOCENT_CONTEXT_RESET_EXT = 0x8254;
	public var UNKNOWN_CONTEXT_RESET_EXT = 0x8255;
	public var CONTEXT_ROBUST_ACCESS_EXT = 0x90F3;
	public var RESET_NOTIFICATION_STRATEGY_EXT = 0x8256;
	public var LOSE_CONTEXT_ON_RESET_EXT = 0x8252;
	public var NO_RESET_NOTIFICATION_EXT = 0x8261;

	@:noCompletion private function new() {}

	// GL_APICALL GLenum GL_APIENTRY glGetGraphicsResetStatusEXT (void);
	// GL_APICALL void GL_APIENTRY glReadnPixelsEXT (GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GLsizei bufSize, void *data);
	// GL_APICALL void GL_APIENTRY glGetnUniformfvEXT (GLuint program, GLint location, GLsizei bufSize, float *params);
	// GL_APICALL void GL_APIENTRY glGetnUniformivEXT (GLuint program, GLint location, GLsizei bufSize, GLint *params);
}
