package lime.graphics.opengl.ext;

@:keep
@:noCompletion class AMD_performance_monitor
{
	public var COUNTER_TYPE_AMD = 0x8BC0;
	public var COUNTER_RANGE_AMD = 0x8BC1;
	public var UNSIGNED_INT64_AMD = 0x8BC2;
	public var PERCENTAGE_AMD = 0x8BC3;
	public var PERFMON_RESULT_AVAILABLE_AMD = 0x8BC4;
	public var PERFMON_RESULT_SIZE_AMD = 0x8BC5;
	public var PERFMON_RESULT_AMD = 0x8BC6;

	@:noCompletion private function new() {}

	// public function getPerfMonitorGroupsAMD (GLint *numGroups, GLsizei groupsSize, GLuint *groups);
	// public function getPerfMonitorCountersAMD (GLuint group, GLint *numCounters, GLint *maxActiveCounters, GLsizei counterSize, GLuint *counters);
	// public function getPerfMonitorGroupStringAMD (GLuint group, GLsizei bufSize, GLsizei *length, GLchar *groupString);
	// public function getPerfMonitorCounterStringAMD (GLuint group, GLuint counter, GLsizei bufSize, GLsizei *length, GLchar *counterString);
	// public function getPerfMonitorCounterInfoAMD (GLuint group, GLuint counter, GLenum pname, GLvoid *data);
	// public function genPerfMonitorsAMD (GLsizei n, GLuint *monitors);
	// public function deletePerfMonitorsAMD (GLsizei n, GLuint *monitors);
	// public function selectPerfMonitorCountersAMD (GLuint monitor, GLboolean enable, GLuint group, GLint numCounters, GLuint *countersList);
	// public function beginPerfMonitorAMD (GLuint monitor);
	// public function endPerfMonitorAMD (GLuint monitor);
	// public function getPerfMonitorCounterDataAMD (GLuint monitor, GLenum pname, GLsizei dataSize, GLuint *data, GLint *bytesWritten);
}
