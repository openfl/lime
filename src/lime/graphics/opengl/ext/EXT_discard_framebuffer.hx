package lime.graphics.opengl.ext;

@:keep
@:noCompletion class EXT_discard_framebuffer
{
	public var COLOR_EXT = 0x1800;
	public var DEPTH_EXT = 0x1801;
	public var STENCIL_EXT = 0x1802;

	@:noCompletion private function new() {}

	// GL_APICALL void GL_APIENTRY glDiscardFramebufferEXT (GLenum target, GLsizei numAttachments, const GLenum *attachments);
}
