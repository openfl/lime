package lime.graphics.opengl.ext;

@:keep
@:noCompletion class APPLE_framebuffer_multisample
{
	public var RENDERBUFFER_SAMPLES_APPLE = 0x8CAB;
	public var FRAMEBUFFER_INCOMPLETE_MULTISAMPLE_APPLE = 0x8D56;
	public var MAX_SAMPLES_APPLE = 0x8D57;
	public var READ_FRAMEBUFFER_APPLE = 0x8CA8;
	public var DRAW_FRAMEBUFFER_APPLE = 0x8CA9;
	public var DRAW_FRAMEBUFFER_BINDING_APPLE = 0x8CA6;
	public var READ_FRAMEBUFFER_BINDING_APPLE = 0x8CAA;

	@:noCompletion private function new() {}

	// GL_APICALL void GL_APIENTRY glRenderbufferStorageMultisampleAPPLE (GLenum, GLsizei, GLenum, GLsizei, GLsizei);
	// GL_APICALL void GL_APIENTRY glResolveMultisampleFramebufferAPPLE (void);
}
