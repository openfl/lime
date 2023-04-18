package lime.graphics.opengl.ext;

@:keep
@:noCompletion class EXT_separate_shader_objects
{
	public var VERTEX_SHADER_BIT_EXT = 0x00000001;
	public var FRAGMENT_SHADER_BIT_EXT = 0x00000002;
	public var ALL_SHADER_BITS_EXT = 0xFFFFFFFF;
	public var PROGRAM_SEPARABLE_EXT = 0x8258;
	public var ACTIVE_PROGRAM_EXT = 0x8259;
	public var PROGRAM_PIPELINE_BINDING_EXT = 0x825A;

	@:noCompletion private function new() {}

	// GL_APICALL void GL_APIENTRY glUseProgramStagesEXT (GLuint pipeline, GLbitfield stages, GLuint program);
	// GL_APICALL void GL_APIENTRY glActiveShaderProgramEXT (GLuint pipeline, GLuint program);
	// GL_APICALL GLuint GL_APIENTRY glCreateShaderProgramvEXT (GLenum type, GLsizei count, const GLchar **strings);
	// GL_APICALL void GL_APIENTRY glBindProgramPipelineEXT (GLuint pipeline);
	// GL_APICALL void GL_APIENTRY glDeleteProgramPipelinesEXT (GLsizei n, const GLuint *pipelines);
	// GL_APICALL void GL_APIENTRY glGenProgramPipelinesEXT (GLsizei n, GLuint *pipelines);
	// GL_APICALL GLboolean GL_APIENTRY glIsProgramPipelineEXT (GLuint pipeline);
	// GL_APICALL void GL_APIENTRY glProgramParameteriEXT (GLuint program, GLenum pname, GLint value);
	// GL_APICALL void GL_APIENTRY glGetProgramPipelineivEXT (GLuint pipeline, GLenum pname, GLint *params);
	// GL_APICALL void GL_APIENTRY glProgramUniform1iEXT (GLuint program, GLint location, GLint x);
	// GL_APICALL void GL_APIENTRY glProgramUniform2iEXT (GLuint program, GLint location, GLint x, GLint y);
	// GL_APICALL void GL_APIENTRY glProgramUniform3iEXT (GLuint program, GLint location, GLint x, GLint y, GLint z);
	// GL_APICALL void GL_APIENTRY glProgramUniform4iEXT (GLuint program, GLint location, GLint x, GLint y, GLint z, GLint w);
	// GL_APICALL void GL_APIENTRY glProgramUniform1fEXT (GLuint program, GLint location, GLfloat x);
	// GL_APICALL void GL_APIENTRY glProgramUniform2fEXT (GLuint program, GLint location, GLfloat x, GLfloat y);
	// GL_APICALL void GL_APIENTRY glProgramUniform3fEXT (GLuint program, GLint location, GLfloat x, GLfloat y, GLfloat z);
	// GL_APICALL void GL_APIENTRY glProgramUniform4fEXT (GLuint program, GLint location, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
	// GL_APICALL void GL_APIENTRY glProgramUniform1ivEXT (GLuint program, GLint location, GLsizei count, const GLint *value);
	// GL_APICALL void GL_APIENTRY glProgramUniform2ivEXT (GLuint program, GLint location, GLsizei count, const GLint *value);
	// GL_APICALL void GL_APIENTRY glProgramUniform3ivEXT (GLuint program, GLint location, GLsizei count, const GLint *value);
	// GL_APICALL void GL_APIENTRY glProgramUniform4ivEXT (GLuint program, GLint location, GLsizei count, const GLint *value);
	// GL_APICALL void GL_APIENTRY glProgramUniform1fvEXT (GLuint program, GLint location, GLsizei count, const GLfloat *value);
	// GL_APICALL void GL_APIENTRY glProgramUniform2fvEXT (GLuint program, GLint location, GLsizei count, const GLfloat *value);
	// GL_APICALL void GL_APIENTRY glProgramUniform3fvEXT (GLuint program, GLint location, GLsizei count, const GLfloat *value);
	// GL_APICALL void GL_APIENTRY glProgramUniform4fvEXT (GLuint program, GLint location, GLsizei count, const GLfloat *value);
	// GL_APICALL void GL_APIENTRY glProgramUniformMatrix2fvEXT (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
	// GL_APICALL void GL_APIENTRY glProgramUniformMatrix3fvEXT (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
	// GL_APICALL void GL_APIENTRY glProgramUniformMatrix4fvEXT (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
	// GL_APICALL void GL_APIENTRY glValidateProgramPipelineEXT (GLuint pipeline);
	// GL_APICALL void GL_APIENTRY glGetProgramPipelineInfoLogEXT (GLuint pipeline, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
}
