package lime.media;

/**
	The pixel layout of a decoded `VideoFrame`.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract VideoFrameFormat(Int) from Int to Int
{
	/**
		Two planes: `width * height` bytes of luma (Y), then interleaved chroma
		(Cb, Cr) at half resolution, `VideoFrame.chromaWidth * 2` bytes per row
		for `VideoFrame.chromaHeight` rows.

		This is the format decoders produce, so it costs the least to read.
		Upload the planes as one-channel (R8 or LUMINANCE) and two-channel (RG8
		or LUMINANCE_ALPHA) textures, and convert to RGB in a shader using
		`VideoFrame.colorMatrix` and `VideoFrame.fullRange`.
	**/
	var NV12 = 0;

	/**
		Interleaved 8-bit red, green, blue and alpha, `width * 4` bytes per row,
		converted from YUV on the decoding thread.
	**/
	var RGBA = 1;
}
