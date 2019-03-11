package lime.graphics.opengl.ext;

@:keep
@:noCompletion class APPLE_sync
{
	public var SYNC_OBJECT_APPLE = 0x8A53;
	public var MAX_SERVER_WAIT_TIMEOUT_APPLE = 0x9111;
	public var OBJECT_TYPE_APPLE = 0x9112;
	public var SYNC_CONDITION_APPLE = 0x9113;
	public var SYNC_STATUS_APPLE = 0x9114;
	public var SYNC_FLAGS_APPLE = 0x9115;
	public var SYNC_FENCE_APPLE = 0x9116;
	public var SYNC_GPU_COMMANDS_COMPLETE_APPLE = 0x9117;
	public var UNSIGNALED_APPLE = 0x9118;
	public var SIGNALED_APPLE = 0x9119;
	public var ALREADY_SIGNALED_APPLE = 0x911A;
	public var TIMEOUT_EXPIRED_APPLE = 0x911B;
	public var CONDITION_SATISFIED_APPLE = 0x911C;
	public var WAIT_FAILED_APPLE = 0x911D;
	public var SYNC_FLUSH_COMMANDS_BIT_APPLE = 0x00000001;
	public var TIMEOUT_IGNORED_APPLE = 0xFFFFFFFF;

	// public var TIMEOUT_IGNORED_APPLE = 0xFFFFFFFFFFFFFFFFull;
	@:noCompletion private function new() {}

	// GL_APICALL GLsync GL_APIENTRY glFenceSyncAPPLE (GLenum condition, GLbitfield flags);
	// GL_APICALL GLboolean GL_APIENTRY glIsSyncAPPLE (GLsync sync);
	// GL_APICALL void GL_APIENTRY glDeleteSyncAPPLE (GLsync sync);
	// GL_APICALL GLenum GL_APIENTRY glClientWaitSyncAPPLE (GLsync sync, GLbitfield flags, GLuint64 timeout);
	// GL_APICALL void GL_APIENTRY glWaitSyncAPPLE (GLsync sync, GLbitfield flags, GLuint64 timeout);
	// GL_APICALL void GL_APIENTRY glGetInteger64vAPPLE (GLenum pname, GLint64 *params);
	// GL_APICALL void GL_APIENTRY glGetSyncivAPPLE (GLsync sync, GLenum pname, GLsizei bufSize, GLsizei *length, GLint *values);
}
