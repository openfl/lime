package lime.graphics.opengl.ext;

@:keep
@:noCompletion class EXT_texture_storage
{
	public var TEXTURE_IMMUTABLE_FORMAT_EXT = 0x912F;
	public var ALPHA8_EXT = 0x803C;
	public var LUMINANCE8_EXT = 0x8040;
	public var LUMINANCE8_ALPHA8_EXT = 0x8045;
	public var RGBA32F_EXT = 0x8814;
	public var RGB32F_EXT = 0x8815;
	public var ALPHA32F_EXT = 0x8816;
	public var LUMINANCE32F_EXT = 0x8818;
	public var LUMINANCE_ALPHA32F_EXT = 0x8819;
	public var RGBA16F_EXT = 0x881A;
	public var RGB16F_EXT = 0x881B;
	public var ALPHA16F_EXT = 0x881C;
	public var LUMINANCE16F_EXT = 0x881E;
	public var LUMINANCE_ALPHA16F_EXT = 0x881F;
	public var RGB10_A2_EXT = 0x8059;
	public var RGB10_EXT = 0x8052;
	public var BGRA8_EXT = 0x93A1;
	public var R8_EXT = 0x8229;
	public var RG8_EXT = 0x822B;
	public var R32F_EXT = 0x822E;
	public var RG32F_EXT = 0x8230;
	public var R16F_EXT = 0x822D;
	public var RG16F_EXT = 0x822F;

	@:noCompletion private function new() {}

	// GL_APICALL void GL_APIENTRY glTexStorage1DEXT (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width);
	// GL_APICALL void GL_APIENTRY glTexStorage2DEXT (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height);
	// GL_APICALL void GL_APIENTRY glTexStorage3DEXT (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth);
	// GL_APICALL void GL_APIENTRY glTextureStorage1DEXT (GLuint texture, GLenum target, GLsizei levels, GLenum internalformat, GLsizei width);
	// GL_APICALL void GL_APIENTRY glTextureStorage2DEXT (GLuint texture, GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height);
	// GL_APICALL void GL_APIENTRY glTextureStorage3DEXT (GLuint texture, GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth);
}
