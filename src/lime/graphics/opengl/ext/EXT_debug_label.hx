package lime.graphics.opengl.ext;

@:keep
@:noCompletion class EXT_debug_label
{
	public var PROGRAM_PIPELINE_OBJECT_EXT = 0x8A4F;
	public var PROGRAM_OBJECT_EXT = 0x8B40;
	public var SHADER_OBJECT_EXT = 0x8B48;
	public var BUFFER_OBJECT_EXT = 0x9151;
	public var QUERY_OBJECT_EXT = 0x9153;
	public var VERTEX_ARRAY_OBJECT_EXT = 0x9154;

	@:noCompletion private function new() {}

	// GL_APICALL void GL_APIENTRY glLabelObjectEXT (GLenum type, GLuint object, GLsizei length, const GLchar *label);
	// GL_APICALL void GL_APIENTRY glGetObjectLabelEXT (GLenum type, GLuint object, GLsizei bufSize, GLsizei *length, GLchar *label);
}
