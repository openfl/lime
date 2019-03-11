package lime.graphics.opengl.ext;

@:keep
@:noCompletion class OES_EGL_image_external
{
	public var TEXTURE_EXTERNAL_OES = 0x8D65;
	public var SAMPLER_EXTERNAL_OES = 0x8D66;
	public var TEXTURE_BINDING_EXTERNAL_OES = 0x8D67;
	public var REQUIRED_TEXTURE_IMAGE_UNITS_OES = 0x8D68;

	@:noCompletion private function new() {}

	// public function eglImageTargetTexture2DOES (target:Int, image:BytesPointer):Void {}
}
