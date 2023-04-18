package lime.graphics.opengl.ext;

@:keep
@:noCompletion class NV_coverage_sample
{
	public var COVERAGE_COMPONENT_NV = 0x8ED0;
	public var COVERAGE_COMPONENT4_NV = 0x8ED1;
	public var COVERAGE_ATTACHMENT_NV = 0x8ED2;
	public var COVERAGE_BUFFERS_NV = 0x8ED3;
	public var COVERAGE_SAMPLES_NV = 0x8ED4;
	public var COVERAGE_ALL_FRAGMENTS_NV = 0x8ED5;
	public var COVERAGE_EDGE_FRAGMENTS_NV = 0x8ED6;
	public var COVERAGE_AUTOMATIC_NV = 0x8ED7;
	public var COVERAGE_BUFFER_BIT_NV = 0x8000;

	@:noCompletion private function new() {}

	// GL_APICALL void GL_APIENTRY glCoverageMaskNV (GLboolean mask);
	// GL_APICALL void GL_APIENTRY glCoverageOperationNV (GLenum operation);
}
