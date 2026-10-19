package media;

import lime.media.VideoFrame;
import lime.media.VideoFrameFormat;
import utest.Assert;
import utest.Test;

class VideoFrameTest extends Test
{
	public function new()
	{
		super();
	}

	public function testDefaults():Void
	{
		var frame = new VideoFrame();

		Assert.equals(VideoFrameFormat.NV12, frame.format);
		Assert.equals(0, frame.width);
		Assert.equals(0, frame.height);
		Assert.equals(0, frame.length);
		Assert.isNull(frame.data);
		Assert.isNull(frame.texture);
		Assert.isNull(frame.src);
	}

	public function testChromaPlaneLayout():Void
	{
		var frame = new VideoFrame();
		frame.width = 640;
		frame.height = 360;

		Assert.equals(320, frame.chromaWidth);
		Assert.equals(180, frame.chromaHeight);
		Assert.equals(640 * 360, frame.chromaOffset);
	}

	public function testChromaPlaneRoundsUpOddSizes():Void
	{
		var frame = new VideoFrame();
		frame.width = 641;
		frame.height = 361;

		Assert.equals(321, frame.chromaWidth);
		Assert.equals(181, frame.chromaHeight);
		Assert.equals(641 * 361, frame.chromaOffset);
	}
}
