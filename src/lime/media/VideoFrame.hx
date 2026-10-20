package lime.media;

import lime.graphics.opengl.GLTexture;
import lime.utils.UInt8Array;

/**
	A decoded video frame, filled by `VideoDecoder.readFrame` or
	`VideoSource.readFrame`.

	A frame can be read into again and again. Its `data` is only reallocated
	when a larger frame arrives.

	@see lime.media.VideoFrameFormat
**/
class VideoFrame
{
	/**
		The height of the chroma plane of an `NV12` frame, in rows.
	**/
	public var chromaHeight(get, never):Int;

	/**
		The byte offset of the chroma plane in `data` for an `NV12` frame.
	**/
	public var chromaOffset(get, never):Int;

	/**
		The width of the chroma plane of an `NV12` frame, in Cb/Cr pairs.
	**/
	public var chromaWidth(get, never):Int;

	/**
		The matrix that converts this frame's YCbCr samples to RGB.
	**/
	public var colorMatrix:VideoColorMatrix;

	/**
		The frame's pixels in `format`. Only the first `length` bytes belong to
		this frame.
	**/
	public var data:UInt8Array;

	/**
		How long the frame is displayed, in seconds.
	**/
	public var duration:Float;

	/**
		The layout of `data`.
	**/
	public var format:VideoFrameFormat;

	/**
		Whether the YCbCr samples use the full 0-255 range rather than the
		16-235 (luma) and 16-240 (chroma) video range.
	**/
	public var fullRange:Bool;

	/**
		The height of the frame in pixels.
	**/
	public var height:Int;

	/**
		The number of bytes of `data` used by the frame.
	**/
	public var length:Int;

	/**
		On HTML5, the `<video>` element showing the frame, which WebGL uploads
		with `texImage2D`. `data` is `null` there. Elsewhere it is `null`.
	**/
	public var src:Dynamic;

	/**
		For a `TEXTURE` frame, the RGBA texture showing it, with the top row of
		the picture first. It belongs to the decoder, so do not delete it, and it
		is only valid until the next frame is read.
	**/
	public var texture:GLTexture;

	/**
		The time the frame is displayed on the video's timeline, in seconds.
	**/
	public var time:Float;

	/**
		The width of the frame in pixels.
	**/
	public var width:Int;

	public function new()
	{
		colorMatrix = BT709;
		duration = 0;
		format = NV12;
		fullRange = false;
		height = 0;
		length = 0;
		time = 0;
		width = 0;
	}

	// Get & Set Methods
	@:noCompletion private inline function get_chromaHeight():Int
	{
		return (height + 1) >> 1;
	}

	@:noCompletion private inline function get_chromaOffset():Int
	{
		return width * height;
	}

	@:noCompletion private inline function get_chromaWidth():Int
	{
		return (width + 1) >> 1;
	}
}
