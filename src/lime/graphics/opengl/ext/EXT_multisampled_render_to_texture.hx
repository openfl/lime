package lime.graphics.opengl.ext;

@:keep
@:noCompletion class EXT_multisampled_render_to_texture
{
	public var FRAMEBUFFER_ATTACHMENT_TEXTURE_SAMPLES_EXT = 0x8D6C;
	public var RENDERBUFFER_SAMPLES_EXT = 0x8CAB;
	public var FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_EXT = 0x8D56;
	public var MAX_SAMPLES_EXT = 0x8D57;

	@:noCompletion private function new() {}

	// GL_APICALL void GL_APIENTRY glRenderbufferStorageMultisampleEXT (GLenum, GLsizei, GLenum, GLsizei, GLsizei);
	// GL_APICALL void GL_APIENTRY glFramebufferTexture2DMultisampleEXT (GLenum, GLenum, GLenum, GLuint, GLint, GLsizei);
}
