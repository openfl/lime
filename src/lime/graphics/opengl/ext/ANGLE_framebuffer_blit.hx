package lime.graphics.opengl.ext;

@:keep
@:noCompletion class ANGLE_framebuffer_blit
{
	public var READ_FRAMEBUFFER_ANGLE = 0x8CA8;
	public var DRAW_FRAMEBUFFER_ANGLE = 0x8CA9;
	public var DRAW_FRAMEBUFFER_BINDING_ANGLE = 0x8CA6;
	public var READ_FRAMEBUFFER_BINDING_ANGLE = 0x8CAA;

	@:noCompletion private function new() {}

	// GL_APICALL void GL_APIENTRY glBlitFramebufferANGLE (GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter);
}
