package system;

#if (lime_cffi && !macro)
import lime._internal.backend.native.NativeCFFI;
import lime.media.vorbis.VorbisFile;
import lime.text.harfbuzz.HBBlob;
import lime.text.harfbuzz.HBBuffer;
import lime.text.harfbuzz.HBFace;
import lime.text.harfbuzz.HBFont;
import lime.text.harfbuzz.HBMemoryMode;
import lime.text.harfbuzz.HBSet;
import lime.utils.Bytes;
import lime.utils.DataPointer;
import sys.io.File;
#end
import utest.Assert;
import utest.Test;

/**
	Handles that release a native object when they are collected, or sooner when
	they are cleared. assets/tone.ogg is assets/tone.wav, encoded with libvorbis.
**/
@:access(lime._internal.backend.native.NativeCFFI)
class FinalizerTest extends Test
{
	#if (lime_cffi && !macro)
	private static inline var FONT_PATH = "assets/mono.ttf";
	private static inline var SOUND_PATH = "assets/tone.wav";
	private static inline var VORBIS_PATH = "assets/tone.ogg";

	// Together, more files than most systems let a process keep open
	private static inline var HANDLES = 100;
	private static inline var ROUNDS = 12;
	#end

	public function new()
	{
		super();
	}

	#if (lime_cffi && !macro)
	#if lime_harfbuzz
	public function testDroppedHarfBuzzObjectsLeaveWhatTheySharedInUse():Void
	{
		var bytes = File.getBytes(FONT_PATH);
		var blob = new HBBlob(DataPointer.fromBytes(bytes), bytes.length, HBMemoryMode.READONLY);
		var face = new HBFace(blob, 0);
		var font = new HBFont(face);
		var upem = face.upem;

		for (round in 0...ROUNDS)
		{
			dropHarfBuzzObjects(blob, font);
			collect();
		}

		Assert.isTrue(upem > 0);
		Assert.equals(upem, face.upem);
		Assert.equals(bytes.length, blob.length);
	}

	private static function dropHarfBuzzObjects(blob:HBBlob, font:HBFont):Void
	{
		for (i in 0...HANDLES)
		{
			blob.createSubBlob(0, 16);
			font.createSubFont();
			new HBFont(new HBFace(blob, 0));
			new HBBuffer();
			new HBSet();
		}
	}
	#end

	#if lime_sdl_sound
	public function testDroppedSoundStreamsCloseTheirFiles():Void
	{
		for (round in 0...ROUNDS)
		{
			Assert.equals(HANDLES, openSoundStreams(false));
			collect();
		}

		assertASoundStreamReads();
	}

	public function testClearedSoundStreamsAreNotClosedAgain():Void
	{
		for (round in 0...ROUNDS)
		{
			Assert.equals(HANDLES, openSoundStreams(true));
			collect();
		}

		assertASoundStreamReads();
	}

	private static function openSoundStreams(clear:Bool):Int
	{
		var opened = 0;

		for (i in 0...HANDLES)
		{
			var stream = NativeCFFI.lime_sdl_sound_stream_from_file(SOUND_PATH);
			if (stream == null) continue;

			opened++;
			if (clear) NativeCFFI.lime_sdl_sound_stream_clear(stream);
		}

		return opened;
	}

	// A stream closed twice takes others with it from SDL_sound's list of samples
	private static function assertASoundStreamReads():Void
	{
		var stream = NativeCFFI.lime_sdl_sound_stream_from_file(SOUND_PATH);
		Assert.notNull(stream);
		if (stream == null) return;

		var buffer = Bytes.alloc(1024);
		Assert.isTrue(NativeCFFI.lime_sdl_sound_stream_read(stream, buffer, buffer.length) > 0);
		NativeCFFI.lime_sdl_sound_stream_clear(stream);
	}
	#end

	#if lime_vorbis
	public function testDroppedVorbisFilesCloseTheirFiles():Void
	{
		for (round in 0...ROUNDS)
		{
			Assert.equals(HANDLES, openVorbisFiles(fromFile, false));
			collect();
		}

		assertAVorbisFileOpens();
	}

	public function testDroppedVorbisFilesOfBytesAreCollected():Void
	{
		var bytes = File.getBytes(VORBIS_PATH);

		for (round in 0...ROUNDS)
		{
			Assert.equals(HANDLES, openVorbisFiles(VorbisFile.fromBytes.bind(bytes), false));
			collect();
		}

		assertAVorbisFileOpens();
	}

	public function testClearedVorbisFilesAreNotClosedAgain():Void
	{
		for (round in 0...ROUNDS)
		{
			Assert.equals(HANDLES, openVorbisFiles(fromFile, true));
			collect();
		}

		assertAVorbisFileOpens();
	}

	public function testAClearedVorbisFileStaysSafeToCall():Void
	{
		var file = fromFile();
		Assert.notNull(file);
		if (file == null) return;

		file.clear();
		file.clear();

		Assert.isNull(file.info());
		Assert.isFalse(file.seekable());
		Assert.equals(0, file.streams());
		Assert.isTrue(file.timeSeek(0) < 0);

		file = null;
		collect();
	}

	private static function fromFile():VorbisFile
	{
		return VorbisFile.fromFile(VORBIS_PATH);
	}

	private static function openVorbisFiles(open:Void->VorbisFile, clear:Bool):Int
	{
		var opened = 0;

		for (i in 0...HANDLES)
		{
			var file = open();
			if (file == null) continue;

			opened++;
			if (clear) file.clear();
		}

		return opened;
	}

	private static function assertAVorbisFileOpens():Void
	{
		var file = fromFile();
		Assert.notNull(file);
		if (file == null) return;

		Assert.equals(22050, file.info().rate);
		file.clear();
	}
	#end

	private static function collect():Void
	{
		#if cpp
		cpp.vm.Gc.run(true);
		#elseif neko
		neko.vm.Gc.run(true);
		#elseif hl
		hl.Gc.major();
		#end
	}
	#end
}
