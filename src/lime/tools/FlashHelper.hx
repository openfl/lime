package lime.tools;

// import openfl.text.Font;
// import openfl.utils.ByteArray;
import haxe.io.Bytes;
import hxp.*;
import lime._internal.format.Base64;
import lime.tools.Asset;
import lime.tools.AssetEncoding;
import lime.tools.AssetType;
import lime.tools.HXProject;
#if (lime && lime_cffi && !macro)
import lime.text.Font;
#end
import sys.io.File;
import sys.FileSystem;
import sys.io.FileSeek;
#if format
import format.swf.Data;
import format.swf.Constants;
import format.swf.Reader;
import format.swf.Writer;
import format.wav.Data;
#end

class FlashHelper
{
	private static var swfAssetID = 1000;

	#if format
	private static function embedAsset(inAsset:Asset, packageName:String, outTags:Array<SWFTag>)
	{
		var embed = inAsset.embed;
		var path = inAsset.sourcePath;
		var type = inAsset.type;
		var flatName = inAsset.flatName;
		var ext = inAsset.format;
		var name = (path == null || path == "") ? inAsset.targetPath : path;

		if (embed == false)
		{
			return false;
		}

		Log.info("", " - \x1b[1mEmbedding asset:\x1b[0m \x1b[3;37m(" + type + ")\x1b[0m " + name);

		var cid = nextAssetID();

		if (type == AssetType.MUSIC || type == AssetType.SOUND)
		{
			var src = path;

			if (ext != "mp3" && ext != "wav")
			{
				for (e in ["wav", "mp3"])
				{
					src = path.substr(0, path.length - ext.length) + e;

					if (FileSystem.exists(src))
					{
						break;
					}
				}
			}

			if (!FileSystem.exists(src))
			{
				Sys.println("Warning: Could not embed unsupported audio file \"" + name + "\", embedding as binary");
				inAsset.type = BINARY;
				return embedAsset(inAsset, packageName, outTags);
			}

			var input = File.read(src, true);

			if (ext == "mp3")
			{
				var reader = new mpeg.audio.MpegAudioReader(input);

				var frameDataWriter = new haxe.io.BytesOutput();
				var totalLengthSamples = 0;
				var samplingFrequency = -1;
				var isStereo:Null<Bool> = null;
				var encoderDelay = 0;
				var endPadding = 0;
				var decoderDelay = 529; // This is a constant delay caused by the Fraunhofer MP3 Decoder used in Flash Player.

				while (true)
				{
					switch (reader.readNext())
					{
						case Frame(frame):
							if (frame.header.layer != mpeg.audio.Layer.Layer3)
							{
								Sys.println("Warning: Could not embed \""
									+ name
									+ "\" (Flash only supports Layer-III MP3 files, but file is "
									+ frame.header.layer
									+ "), embedding as binary");
								inAsset.type = BINARY;
								return embedAsset(inAsset, packageName, outTags);
							}
							var frameSamplingFrequency = frame.header.samplingFrequency;
							if (samplingFrequency == -1)
							{
								samplingFrequency = frameSamplingFrequency;
							}
							else if (frameSamplingFrequency != samplingFrequency)
							{
								Sys.println("Warning: Could not embed \""
									+ name
									+ "\" (Flash does not support MP3 audio with variable sampling frequencies), embedding as binary");
								inAsset.type = BINARY;
								return embedAsset(inAsset, packageName, outTags);
							}
							var frameIsStereo = frame.header.mode != mpeg.audio.Mode.SingleChannel;
							if (isStereo == null)
							{
								isStereo = frameIsStereo;
							}
							else if (frameIsStereo != isStereo)
							{
								Sys.println("Warning: Could not embed \""
									+ name
									+ "\" (Flash does not support MP3 audio with mixed mono and stero frames), embedding as binary");
								inAsset.type = BINARY;
								return embedAsset(inAsset, packageName, outTags);
							}
							frameDataWriter.write(frame.frameData);
							totalLengthSamples += mpeg.audio.Utils.lookupSamplesPerFrame(frame.header.version, frame.header.layer);

						case GaplessInfo(giEncoderDelay, giEndPadding):
							encoderDelay = giEncoderDelay;
							endPadding = giEndPadding;

						case Info(_): // ignore
						case Unknown(_): // ignore
						case End:
							break;
					}
				}

				if (totalLengthSamples == 0)
				{
					Sys.println("Warning: Could not embed \"" + name + "\" (Could not find any valid MP3 audio data), embedding as binary");
					inAsset.type = BINARY;
					return embedAsset(inAsset, packageName, outTags);
				}

				var flashSamplingFrequency = switch (samplingFrequency)
				{
					case 11025: SR11k;
					case 22050: SR22k;
					case 44100: SR44k;
					default: null;
				}

				if (flashSamplingFrequency == null)
				{
					Sys.println("Warning: Could not embed \""
						+ name
						+ "\" (Flash supports 11025, 22050 and 44100kHz MP3 files, but file is "
						+ samplingFrequency
						+ "kHz), embedding as binary");
					inAsset.type = BINARY;
					return embedAsset(inAsset, packageName, outTags);
				}

				var frameData = frameDataWriter.getBytes();

				var snd:format.swf.Sound =
					{
						sid: cid,
						format: SFMP3,
						rate: flashSamplingFrequency,
						is16bit: true,
						isStereo: isStereo,
						samples: totalLengthSamples - endPadding - encoderDelay,
						data: SDMp3(encoderDelay + decoderDelay, frameData)
					};

				outTags.push(TSound(snd));
			}
			else
			{
				var header = input.readString(4);

				if (ext == "ogg" || header == "OggS")
				{
					Sys.println("Warning: Skipping unsupported OGG file \"" + name + "\", embedding as binary");
					inAsset.type = BINARY;
					return embedAsset(inAsset, packageName, outTags);
				}
				else if (header != "RIFF")
				{
					Sys.println("Warning: Could not embed unrecognized WAV file \"" + name + "\", embedding as binary");
					inAsset.type = BINARY;
					return embedAsset(inAsset, packageName, outTags);
				}
				else
				{
					input.close();
					input = File.read(src, true);

					var r = new format.wav.Reader(input);
					var wav = r.read();
					var hdr = wav.header;

					if (hdr.format != WF_PCM)
					{
						Sys.println("Warning: Could not embed \""
							+ name
							+ "\" (Only PCM uncompressed WAV files are currently supported), embedding as binary");
						inAsset.type = BINARY;
						return embedAsset(inAsset, packageName, outTags);
					}

					// Check sampling rate
					var flashRate = switch (hdr.samplingRate)
					{
						case 5512: SR5k;
						case 11025: SR11k;
						case 22050: SR22k;
						case 44100: SR44k;
						default: null;
					}

					if (flashRate == null)
					{
						Sys.println("Warning: Could not embed \""
							+ name
							+ "\" (Flash supports 5512, 11025, 22050 and 44100kHz WAV files, but file is "
							+ hdr.samplingRate
							+ "kHz), embedding as binary");
						inAsset.type = BINARY;
						return embedAsset(inAsset, packageName, outTags);
					}

					var isStereo = switch (hdr.channels)
					{
						case 1: false;
						case 2: true;
						default:
							throw "Number of channels should be 1 or 2, but for '" + src + "' it is " + hdr.channels;
					}

					var is16bit = switch (hdr.bitsPerSample)
					{
						case 8: false;
						case 16: true;
						default:
							throw "Bits per sample should be 8 or 16, but for '" + src + "' it is " + hdr.bitsPerSample;
					}

					if (wav.data != null)
					{
						var sampleCount = Std.int(wav.data.length / (hdr.bitsPerSample / 8));

						var snd:format.swf.Sound =
							{
								sid: cid,
								format: SFLittleEndianUncompressed,
								rate: flashRate,
								is16bit: is16bit,
								isStereo: isStereo,
								samples: sampleCount,
								data: SDRaw(wav.data)
							}

						outTags.push(TSound(snd));
					}
					else
					{
						Sys.println("Warning: Could not embed WAV file \"" + name + "\", the file may be corrupted, embedding as binary");
						inAsset.type = BINARY;
						return embedAsset(inAsset, packageName, outTags);
					}
				}
			}

			input.close();
		}
		else if (type == AssetType.IMAGE)
		{
			if (inAsset.data != null)
			{
				if (inAsset.encoding == AssetEncoding.BASE64)
				{
					outTags.push(TBitsJPEG(cid, JDJPEG2(Base64.decode(inAsset.data))));
				}
				else
				{
					outTags.push(TBitsJPEG(cid, JDJPEG2(inAsset.data)));
				}
			}
			else
			{
				var src = path;

				if (ext == "jpg" || ext == "jpeg" || ext == "png" || ext == "gif")
				{
					if (!FileSystem.exists(src))
					{
						Sys.println("Warning: Could not find image path \"" + src + "\"");
					}
					else
					{
						var bytes = File.getBytes(src);
						outTags.push(TBitsJPEG(cid, JDJPEG2(bytes)));
					}
				}
				else
				{
					Sys.println("Warning: Could not embed image file \"" + name + "\", unknown image type, embedding as binary");
					inAsset.type = BINARY;
					return embedAsset(inAsset, packageName, outTags);
				}
			}
		}
		else if (type == AssetType.FONT)
		{
			// More code ripped off from "samhaxe"

			#if (lime && lime_cffi && !macro)
			var src = path;
			var face = Font.fromFile(src);
			var font = face.decompose();
			var font_name = font.family_name;
			// fallback for font name is case no one could be found..
			if (font_name == null || font_name.length == 0) font_name = Path.withoutExtension(name).split("/").pop().split("\\").pop();

			var glyphs = new Array<Font2GlyphData>();
			var glyph_layout = new Array<FontLayoutGlyphData>();

			for (native_glyph in font.glyphs)
			{
				if (native_glyph.char_code > 65535)
				{
					Sys.println("Warning: glyph with character code greater than 65535 encountered (" + native_glyph.char_code + "). Skipping...");
					continue;
				}

				var shapeRecords = new Array<ShapeRecord>();
				var i:Int = 0;
				var styleChanged:Bool = false;
				var dx = 0;
				var dy = 0;

				while (i < native_glyph.points.length)
				{
					var type = native_glyph.points[i++];

					switch (type)
					{
						case 1: // Move

							dx = native_glyph.points[i++];
							dy = native_glyph.points[i++];
							shapeRecords.push(SHRChange(
								{
									moveTo: {dx: dx, dy: -dy},
									// Set fill style to 1 in first style change record
									// Required by DefineFontX
									fillStyle0: if (!styleChanged) {idx: 1}
									else null,
									fillStyle1: null,
									lineStyle: null,
									newStyles: null
								}));
							styleChanged = true;

						case 2: // LineTo

							dx = native_glyph.points[i++];
							dy = native_glyph.points[i++];
							shapeRecords.push(SHREdge(dx, -dy));

						case 3: // CurveTo
							var cdx = native_glyph.points[i++];
							var cdy = native_glyph.points[i++];
							dx = native_glyph.points[i++];
							dy = native_glyph.points[i++];
							shapeRecords.push(SHRCurvedEdge(cdx, -cdy, dx, -dy));

						case 4: // CubicCurveTo
							var p1x = native_glyph.points[i++];
							var p1y = native_glyph.points[i++];
							var p2x = native_glyph.points[i++];
							var p2y = native_glyph.points[i++];
							var p3x = native_glyph.points[i++];
							var p3y = native_glyph.points[i++];

							// Get original points

							var cp1x = p1x + dx;
							var cp1y = p1y + dy;
							var cp2x = p2x + cp1x;
							var cp2y = p2y + cp1y;
							var endx = p3x + cp2x;
							var endy = p3y + cp2y;

							// Convert to quadratic

							var cpx = Std.int((-0.25 * dx) + (0.75 * cp1x) + (0.75 * cp2x) + (-0.25 * endx));
							var cpy = Std.int((-0.25 * dy) + (0.75 * cp1y) + (0.75 * cp2y) + (-0.25 * endy));

							// Offset again

							var cdx = cpx - dx;
							var cdy = cpy - dy;
							dx = endx - cpx;
							dy = endy - cpy;

							shapeRecords.push(SHRCurvedEdge(cdx, -cdy, dx, -dy));

						default:
							throw "Invalid control point type encountered! (" + type + ")";
					}
				}

				shapeRecords.push(SHREnd);

				glyphs.push(
					{
						charCode: native_glyph.char_code,
						shape:
							{
								shapeRecords: shapeRecords
							}
					});

				glyph_layout.push(
					{
						advance: native_glyph.advance,
						bounds:
							{
								left: native_glyph.min_x,
								right: native_glyph.max_x,
								top: -native_glyph.max_y,
								bottom: -native_glyph.min_y,
							}
					});
			}

			var kerning = new Array<FontKerningData>();

			if (font.kerning != null)
			{
				var length = font.kerning.length;
				if (length > 0xFFFF) length = 0xFFFF;
				var k;

				for (i in 0...length)
				{
					k = font.kerning[i];

					kerning.push(
						{
							charCode1: k.left_glyph,
							charCode2: k.right_glyph,
							adjust: k.x,
						});
				}
			}

			var swf_em = 1024 * 20;
			var ascent = Math.round(Math.abs(font.ascend * swf_em / font.em_size));
			var descent = Math.round(Math.abs((font.descend) * swf_em / font.em_size));
			var leading = Math.round((font.height - font.ascend + font.descend) * swf_em / font.em_size);
			var language = LangCode.LCNone;

			outTags.push(TFont(cid, FDFont3(
				{
					shiftJIS: false,
					isSmall: false,
					isANSI: false,
					isItalic: font.is_italic,
					isBold: font.is_bold,
					language: language,
					name: font_name,
					glyphs: glyphs,
					layout:
						{
							ascent: ascent,
							descent: descent,
							leading: leading,
							glyphs: glyph_layout,
							kerning: kerning
						}
				})));
			#end
		}
		else
		{
			var bytes:Bytes = null;

			if (inAsset.data != null)
			{
				if (inAsset.encoding == AssetEncoding.BASE64)
				{
					bytes = Base64.decode(inAsset.data);
				}
				else if ((inAsset.data is Bytes))
				{
					bytes = cast inAsset.data;
				}
				else
				{
					bytes = Bytes.ofString(Std.string(inAsset.data));
				}
			}

			if (bytes == null)
			{
				bytes = File.getBytes(path);
			}

			outTags.push(TBinaryData(cid, bytes));
		}

		outTags.push(TSymbolClass([
			{cid: cid, className: packageName + "__ASSET__" + flatName}]));

		return true;
	}
	#end

	/*public static function embedAssets (targetPath:String, assets:Array<Asset>, packageName:String = ""):Void {

		try {

			var input = File.read (targetPath, true);

			if (input != null) {

				var reader = new Reader (input);
				var swf = reader.read ();
				input.close();

				var new_tags = new Array<SWFTag> ();
				var inserted = false;

				for (tag in swf.tags) {

					var name = Type.enumConstructor (tag);

					if (name == "TShowFrame" && !inserted && assets.length > 0) {

						new_tags.push (TShowFrame);

						for (asset in assets) {

							try {

								if (asset.type != AssetType.TEMPLATE && embedAsset (asset, packageName, new_tags)) {

									inserted = true;

								}

							} catch (e:Dynamic) {

								Sys.println ("Error embedding \"" + asset.sourcePath + "\": " + e);

							}

						}

					}

					new_tags.push (tag);

				}

				if (inserted) {

					swf.tags = new_tags;
					var output = File.write (targetPath, true);
					var writer = new Writer (output);
					writer.write (swf);
					output.close ();

				}

			} else {

				trace ("Embedding assets failed! We encountered an error. Does '" + targetPath + "' exist?");

			}

		} catch (e:Dynamic) {

			trace ("Embedding assets failed! We encountered an error accessing '" + targetPath + "': " + e);

		}

	}*/
	public static function enableLogging():Void
	{
		try
		{
			var path = switch (System.hostPlatform)
			{
				case WINDOWS: Sys.getEnv("HOMEDRIVE") + "/" + Sys.getEnv("HOMEPATH") + "/mm.cfg";
				// case MAC: "/Library/Application Support/Macromedia/mm.cfg";
				default: Sys.getEnv("HOME") + "/mm.cfg";
			}

			if (!FileSystem.exists(path))
			{
				File.saveContent(path, "ErrorReportingEnable=1\nTraceOutputFileEnable=1\nMaxWarnings=50");
			}
		}
		catch (e:Dynamic) {}
	}

	private static function compileSWC(project:HXProject, assets:Array<Asset>, id:Int, destination:String):Void
	{
		#if format
		destination = destination + "/obj";
		System.mkdir(destination);

		var label = (id > 0 ? Std.string(id + 1) : "");

		var swfVersions = [
			9, 10, /*10.1,*/ 10.2, 10.3, 11, 11.1, 11.2, 11.3, 11.4, 11.5, 11.6, 11.7, 11.8, 12, 13, 14
		];

		var flashVersion = 9;

		if (project.app.swfVersion > 14)
		{
			flashVersion += Std.int((swfVersions.length - 1) + (project.app.swfVersion - 14));
		}
		else
		{
			for (swfVersion in swfVersions)
			{
				if (project.app.swfVersion > swfVersion)
				{
					flashVersion++;
				}
			}
		}

		var header:SWFHeader =
			{
				version: flashVersion,
				compressed: true,
				width: (project.window.width == 0 ? 800 : project.window.width),
				height: (project.window.height == 0 ? 500 : project.window.height),
				fps: project.window.fps * 256,
				nframes: project.target == AIR ? 1 : 2
			};

		var tags = new Array<SWFTag>();
		var packageName = "";
		var inserted = false;

		tags.push(TBackgroundColor(project.window.background & 0xFFFFFF));

		if (project.target != AIR)
		{
			tags.push(TShowFrame);
		}

		// Might generate ABC later, so we don't need the @:bind calls in DefaultAssetLibrary?

		/*var abc = new haxe.io.BytesOutput ();
			var abcWriter = new format.abc.Writer (abc);

			for (asset in assets) {

				var classDef:ClassDef = {
					var name : packageName + "__ASSET__" + asset.flatName;
					var superclass : asset.flashClass;
					var interfaces : []];
					var constructor : null;
					var fields : [];
					var namespace : null;
					var isSealed : false;
					var isFinal : false;
					var isInterface : false;
					var statics : [];
					var staticFields : [];
				}
				abcWriter.writeClass (classDef);

		}*/

		for (asset in assets)
		{
			#if format
			try
			{
				if (asset.type != AssetType.TEMPLATE && embedAsset(asset, packageName, tags))
				{
					inserted = true;
				}
			}
			catch (e:Dynamic)
			{
				Sys.println("Error embedding \"" + asset.sourcePath + "\": " + e);
			}
			#end
		}

		tags.push(TShowFrame);

		if (inserted)
		{
			var swf:SWF = {header: header, tags: tags};
			var output = File.write(destination + "/assets.swf", true);
			var writer = new Writer(output);
			writer.write(swf);
			output.close();
		}
		#end
	}

	/*private static function compileSWC (project:HXProject, embed:String, id:Int):Void {

		var destination = project.app.path + "/flash/obj";
		System.mkdir (destination);

		var label = (id > 0 ? Std.string (id + 1) : "");

		File.saveContent (destination + "/EmbeddedAssets.hx", embed);
		var args = [ "EmbeddedAssets", "-cp", destination, "-D", "swf-preloader-frame", "-swf", destination + "/assets.swf" ];

		if (id == 0) {

			var header = args.push ("-swf-header");
			args.push ((project.window.width == 0 ? 800 : project.window.width) + ":" + (project.window.height == 0 ? 500 : project.window.height) + ":" + project.window.fps + ":" + StringTools.hex (project.window.background, 6));

		} else {

			if (FileSystem.exists (destination + "/assets.swf")) {

				System.copyFile (destination + "/assets.swf", destination + "/.assets.swf");

			}

			// Have to daisy-chain it to fix Haxe compiler issue

			args.push ("-swf-lib");
			args.push (destination + "/.assets.swf");
			args.push ("-D");
			args.push ("flash-use-stage");

		}

		System.runCommand ("", "haxe", args);

		if (FileSystem.exists (destination + "/.assets.swf")) {

			try {

				FileSystem.deleteFile (destination + "/.assets.swf");

			} catch (e:Dynamic) {}

		}

	}*/
	public static function embedAssets(project:HXProject, targetDirectory:String):Bool
	{
		var embed = "";
		var assets = [];
		var maxSize = 1024 * 1024 * 16;
		var currentSize = 0;
		var id = 0;
		var tempFiles = [];

		for (asset in project.assets)
		{
			if (asset.embed == null || asset.embed == true)
			{
				// Log.info ("", " - \x1b[1mEmbedding asset:\x1b[0m \x1b[3;37m(" + asset.type + ")\x1b[0m " + asset.sourcePath);

				var flashClass = switch (asset.type)
				{
					case MUSIC: "flash.media.Sound";
					case SOUND: "flash.media.Sound";
					case IMAGE: "flash.display.BitmapData";
					case FONT: "flash.text.Font";
					default: "flash.utils.ByteArray";
				}

				var tagName = switch (asset.type)
				{
					case MUSIC: "@:sound";
					case SOUND: "@:sound";
					case IMAGE: "@:bitmap";
					case FONT: "@:font";
					default: "@:file";
				}

				var ignoreAsset = false;
				var sourcePath = null;

				if (asset.data != null)
				{
					sourcePath = System.getTemporaryFile();
					tempFiles.push(sourcePath);

					if (asset.encoding == AssetEncoding.BASE64)
					{
						File.saveBytes(sourcePath, Base64.decode(asset.data));
					}
					else if ((asset.data is Bytes))
					{
						File.saveBytes(sourcePath, asset.data);
					}
					else
					{
						File.saveContent(sourcePath, Std.string(asset.data));
					}
				}
				else
				{
					sourcePath = asset.sourcePath;
				}

				try
				{
					var stat = FileSystem.stat(sourcePath);

					if (stat.size >= maxSize)
					{
						Sys.println("Warning: Cannot embed large file \"" + sourcePath + "\" (>16MB)");
						ignoreAsset = true;
					}
					else
					{
						/*if (currentSize + stat.size >= maxSize) {

							//compileSWC (project, embed, id);
							compileSWC (project, assets, id);

							id++;
							currentSize = 0;
							embed = "";
							assets = [];

						}*/

						currentSize += stat.size;
					}
				}
				catch (e:Dynamic)
				{
					Sys.println("Warning: Could not access \"" + sourcePath + "\", does the file exist?");
					ignoreAsset = true;
				}

				if (ignoreAsset)
				{
					embed += "@:keep class __ASSET__" + asset.flatName + " extends " + flashClass + " { }\n";
				}
				else
				{
					assets.push(asset);

					if (asset.type == IMAGE)
					{
						embed += "@:keep " + tagName + "('" + sourcePath + "') class __ASSET__" + asset.flatName + " extends " + flashClass
							+ " { public function new () { super (0, 0, true, 0); } }\n";
					}
					else
					{
						embed += "@:keep " + tagName + "('" + sourcePath + "') class __ASSET__" + asset.flatName + " extends " + flashClass + " { }\n";
					}
				}
			}
		}

		if (embed != "")
		{
			// compileSWC (project, embed, id);
			compileSWC(project, assets, id, targetDirectory);
		}

		for (tempFile in tempFiles)
		{
			try
			{
				FileSystem.deleteFile(tempFile);
			}
			catch (e:Dynamic) {}
		}

		if (assets.length > 0)
		{
			project.haxeflags.push("-cp " + targetDirectory);
			project.haxeflags.push("-swf-lib obj/assets.swf");
			project.haxedefs.set("flash-use-stage", "");

			return true;
		}

		return false;
	}

	public static function getLogLength():Int
	{
		try
		{
			var path = switch (System.hostPlatform)
			{
				case WINDOWS: Path.escape(Sys.getEnv("APPDATA") + "/Macromedia/Flash Player/Logs/flashlog.txt");
				case MAC: Sys.getEnv("HOME") + "/Library/Preferences/Macromedia/Flash Player/Logs/flashlog.txt";
				default: Sys.getEnv("HOME") + "/.macromedia/Flash_Player/Logs/flashlog.txt";
			}

			if (FileSystem.exists(path))
			{
				return FileSystem.stat(path).size;
			}
		}
		catch (e:Dynamic) {}

		return 0;
	}

	private static function nextAssetID()
	{
		return swfAssetID++;
	}

	public static function run(project:HXProject, workingDirectory:String, targetPath:String):Void
	{
		var player:String = null;

		if (!StringTools.endsWith(targetPath, ".html"))
		{
			if (project.environment.exists("SWF_PLAYER"))
			{
				player = project.environment.get("SWF_PLAYER");
			}
			else
			{
				player = Sys.getEnv("FLASH_PLAYER_EXE");
			}
		}

		System.openFile(workingDirectory, targetPath, player);
	}

	public static function tailLog(start:Int = 0, clear:Bool = true):Void
	{
		try
		{
			var path = switch (System.hostPlatform)
			{
				case WINDOWS: Sys.getEnv("APPDATA") + "/Macromedia/Flash Player/Logs/flashlog.txt";
				case MAC: Sys.getEnv("HOME") + "/Library/Preferences/Macromedia/Flash Player/Logs/flashlog.txt";
				default: Sys.getEnv("HOME") + "/.macromedia/Flash_Player/Logs/flashlog.txt";
			}

			var position = start;

			if (FileSystem.exists(path))
			{
				if (clear)
				{
					try
					{
						File.saveContent(path, "");
						position = 0;
					}
					catch (e:Dynamic) {}
				}

				while (true)
				{
					var input = null;

					try
					{
						input = File.read(path, false);
						input.seek(position, FileSeek.SeekBegin);

						if (!input.eof())
						{
							var bytes = input.readAll();
							position = input.tell();

							if (bytes.length > 0)
							{
								Sys.print(bytes.getString(0, bytes.length));
							}
						}

						input.close();
					}
					catch (e:Dynamic)
					{
						if (input != null)
						{
							input.close();
						}
					}

					Sys.sleep(0.3);
				}
			}
		}
		catch (e:Dynamic) {}
	}
}
