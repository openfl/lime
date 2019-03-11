package lime.graphics.opengl.ext;

@:keep
@:noCompletion class EXT_map_buffer_range
{
	public var MAP_READ_BIT_EXT = 0x0001;
	public var MAP_WRITE_BIT_EXT = 0x0002;
	public var MAP_INVALIDATE_RANGE_BIT_EXT = 0x0004;
	public var MAP_INVALIDATE_BUFFER_BIT_EXT = 0x0008;
	public var MAP_FLUSH_EXPLICIT_BIT_EXT = 0x0010;
	public var MAP_UNSYNCHRONIZED_BIT_EXT = 0x0020;

	@:noCompletion private function new() {}

	// GL_APICALL void* GL_APIENTRY glMapBufferRangeEXT (GLenum target, GLintptr offset, GLsizeiptr length, GLbitfield access);
	// GL_APICALL void GL_APIENTRY glFlushMappedBufferRangeEXT (GLenum target, GLintptr offset, GLsizeiptr length);
}
