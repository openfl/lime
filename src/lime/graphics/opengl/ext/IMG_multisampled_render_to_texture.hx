package lime.graphics.opengl.ext;

@:keep
@:noCompletion class IMG_multisampled_render_to_texture
{
	public var RENDERBUFFER_SAMPLES_IMG = 0x9133;
	public var FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_IMG = 0x9134;
	public var MAX_SAMPLES_IMG = 0x9135;
	public var TEXTURE_SAMPLES_IMG = 0x9136;

	@:noCompletion private function new() {}

	// GL_APICALL void GL_APIENTRY glRenderbufferStorageMultisampleIMG (GLenum, GLsizei, GLenum, GLsizei, GLsizei);
	// GL_APICALL void GL_APIENTRY glFramebufferTexture2DMultisampleIMG (GLenum, GLenum, GLenum, GLuint, GLint, GLsizei);
}
