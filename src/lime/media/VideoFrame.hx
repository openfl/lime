package lime.media;

import lime.utils.UInt8Array;

/**
	A decoded video frame returned by `VideoDecoder`.
**/
class VideoFrame
{
	/**
		The decoded frame bytes.
	**/
	public var data:UInt8Array;

	/**
		The pixel format of `data`.
	**/
	public var format:VideoFrameFormat;

	/**
		The frame height in pixels.
	**/
	public var height:Int;

	/**
		Monotonically increasing value that changes when new frame data is decoded.
	**/
	public var serial:Int;

	/**
		The frame timestamp in seconds on the media timeline.
	**/
	public var timestamp:Float;

	/**
		The frame width in pixels.
	**/
	public var width:Int;

	public function new(data:UInt8Array = null, width:Int = 0, height:Int = 0, format:VideoFrameFormat = null, timestamp:Float = 0.0,
			serial:Int = 0)
	{
		this.data = data;
		this.width = width;
		this.height = height;
		this.format = format == null ? VideoFrameFormat.RGBA : format;
		this.timestamp = timestamp;
		this.serial = serial;
	}
}
