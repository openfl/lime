package lime.graphics.opengl.ext;

@:keep
@:noCompletion class EXT_multiview_draw_buffers
{
	public var COLOR_ATTACHMENT_EXT = 0x90F0;
	public var MULTIVIEW_EXT = 0x90F1;
	public var DRAW_BUFFER_EXT = 0x0C01;
	public var READ_BUFFER_EXT = 0x0C02;
	public var MAX_MULTIVIEW_BUFFERS_EXT = 0x90F2;

	@:noCompletion private function new() {}

	// GL_APICALL void GL_APIENTRY glReadBufferIndexedEXT (GLenum src, GLint index);
	// GL_APICALL void GL_APIENTRY glDrawBuffersIndexedEXT (GLint n, const GLenum *location, const GLint *indices);
	// GL_APICALL void GL_APIENTRY glGetIntegeri_vEXT (GLenum target, GLuint index, GLint *data);
}
