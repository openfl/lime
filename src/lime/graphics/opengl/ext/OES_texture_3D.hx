package lime.graphics.opengl.ext;

@:keep
@:noCompletion class OES_texture_3D
{
	public var TEXTURE_WRAP_R_OES = 0x8072;
	public var TEXTURE_3D_OES = 0x806F;
	public var TEXTURE_BINDING_3D_OES = 0x806A;
	public var MAX_3D_TEXTURE_SIZE_OES = 0x8073;
	public var SAMPLER_3D_OES = 0x8B5F;
	public var FRAMEBUFFER_ATTACHMENT_TEXTURE_3D_ZOFFSET_OES = 0x8CD4;

	@:noCompletion private function new() {}

	// public function texImage3DOES (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, format:Int, type:Int, pixels:BytesPointer):Void {}
	// public function texSubImage3DOES (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, type:Int, pixels:BytesPointer):Void {}
	// public function copyTexSubImage3DOES (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, x:Int, y:Int, width:Int, height:Int):Void {}
	// public function compressedTexImage3DOES (target:Int, level:Int, internalformat:Int, width:Int, height:Int, depth:Int, border:Int, imageSize:Int, data:BytesPointer):Void {}
	// public function compressedTexSubImage3DOES (target:Int, level:Int, xoffset:Int, yoffset:Int, zoffset:Int, width:Int, height:Int, depth:Int, format:Int, imageSize:Int, data:BytesPointer):Void {}
	// public function framebufferTexture3DOES (target:Int, attachment:Int, textarget:Int, texture:Int, level:Int, zoffset:Int):Void {}
}
