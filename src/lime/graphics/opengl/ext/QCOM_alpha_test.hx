package lime.graphics.opengl.ext;

@:keep
@:noCompletion class QCOM_alpha_test
{
	public var ALPHA_TEST_QCOM = 0x0BC0;
	public var ALPHA_TEST_FUNC_QCOM = 0x0BC1;
	public var ALPHA_TEST_REF_QCOM = 0x0BC2;

	@:noCompletion private function new() {}

	// GL_APICALL void GL_APIENTRY glAlphaFuncQCOM (GLenum func, GLclampf ref);
}
