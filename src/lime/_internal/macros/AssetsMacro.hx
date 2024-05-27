package lime._internal.macros;

#if macro
import haxe.crypto.BaseCode;
import haxe.io.Bytes;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
#end
#if (macro && !display)
import lime._internal.format.Base64;
import sys.io.File;
import sys.FileSystem;
#end

class AssetsMacro
{
	#if (!macro || display)
	macro public static function cacheVersion()
	{
		return macro 0;
	}
	#else
	macro public static function cacheVersion()
	{
		return macro $v{Std.int(Math.random() * 1000000)};
	}

	macro public static function embedBytes():Array<Field>
	{
		var fields = embedData(":file");
		if (fields == null) return null;

		var superCall = Context.defined("html5") ? macro super(bytes.b.buffer)
			: Context.defined("hl") ? macro super(bytes.b, bytes.length)
			: macro super(bytes.length, bytes.b);

		var definition = macro class Temp
		{
			public function new(?length:Int, ?bytesData:haxe.io.BytesData)
			{
				var bytes = haxe.Resource.getBytes(resourceName);
				$superCall;
			}
		};

		fields.push(definition.fields[0]);

		return fields;
	}

	macro public static function embedByteArray():Array<Field>
	{
		var fields = embedData(":file");
		if (fields == null) return null;

		var definition = macro class Temp
		{
			public function new(?length:Int = 0)
			{
				super();

				var bytes = haxe.Resource.getBytes(resourceName);
				__fromBytes(bytes);
			}
		};

		fields.push(definition.fields[0]);

		return fields;
	}

	private static function embedData(metaName:String, encode:Bool = false):Array<Field>
	{
		if (Context.defined("display")) return null;

		var classType = Context.getLocalClass().get();
		var metaData = classType.meta;
		var position = Context.currentPos();
		var fields = Context.getBuildFields();

		for (meta in metaData.extract(metaName))
		{
			if (meta.params.length == 0) continue;

			switch (meta.params[0].expr)
			{
				case EConst(CString("" | null)):
					return null;

				case EConst(CString(filePath)):
					var path = filePath;

					if (!FileSystem.exists(filePath))
					{
						path = Context.resolvePath(filePath);
					}

					if (!FileSystem.exists(path) || FileSystem.isDirectory(path))
					{
						return null;
					}

					var bytes = File.getBytes(path);
					var resourceName = "__ASSET__"
						+ metaName
						+ "_"
						+ (classType.pack.length > 0 ? classType.pack.join("_") + "_" : "")
						+ classType.name;

					if (Context.getResources().exists(resourceName))
					{
						return null;
					}

					if (encode)
					{
						var resourceType = "image/png";

						if (bytes.get(0) == 0xFF && bytes.get(1) == 0xD8)
						{
							resourceType = "image/jpg";
						}
						else if (bytes.get(0) == 0x47 && bytes.get(1) == 0x49 && bytes.get(2) == 0x46)
						{
							resourceType = "image/gif";
						}

						var definition = macro class Temp
						{
							private static inline var resourceType:String = $v{ resourceType };
						};

						fields.push(definition.fields[0]);

						var base64 = Base64.encode(bytes);
						Context.addResource(resourceName, Bytes.ofString(base64));
					}
					else
					{
						Context.addResource(resourceName, bytes);
					}

					var definition = macro class Temp
					{
						private static inline var resourceName:String = $v{ resourceName };
					};

					fields.push(definition.fields[0]);

					return fields;

				default:
			}
		}

		return null;
	}

	macro public static function embedFont():Array<Field>
	{
		if (Context.defined("display")) return Context.getBuildFields();

		var fields = null;

		var classType = Context.getLocalClass().get();
		var metaData = classType.meta.get();
		var position = Context.currentPos();
		var fields = Context.getBuildFields();

		var path = "";
		var glyphs = "32-255";

		for (meta in metaData)
		{
			if (meta.name == ":font")
			{
				if (meta.params.length > 0)
				{
					switch (meta.params[0].expr)
					{
						case EConst(CString(filePath)):
							path = filePath;

							if (!sys.FileSystem.exists(filePath))
							{
								path = Context.resolvePath(filePath);
							}

						default:
					}
				}
			}
		}

		if (path != null && path != "")
		{
			if (Context.defined("html5"))
			{
				Sys.command("haxelib", ["run", "lime", "generate", "-font-hash", sys.FileSystem.fullPath(path)]);
				path += ".hash";
			}

			var bytes = File.getBytes(path);
			var resourceName = "LIME_font_" + (classType.pack.length > 0 ? classType.pack.join("_") + "_" : "") + classType.name;

			Context.addResource(resourceName, bytes);

			for (field in fields)
			{
				if (field.name == "new")
				{
					fields.remove(field);
					break;
				}
			}

			var definition = macro class Temp
			{
				private static var resourceName:String = $v{ resourceName };

				public function new()
				{
					super();

					__fromBytes(haxe.Resource.getBytes(resourceName));
				}
			};

			fields.push(definition.fields[0]);
			fields.push(definition.fields[1]);

			return fields;
		}

		return fields;
	}

	macro public static function embedImage():Array<Field>
	{
		var fields = embedData(":image", Context.defined("html5"));
		if (fields == null) return null;

		var definition:TypeDefinition;
		if (Context.defined("html5"))
		{
			definition = macro class Temp
			{
				public static var preload:js.html.Image;

				public function new(?buffer:lime.graphics.ImageBuffer,
					?offsetX:Int, ?offsetY:Int, ?width:Int, ?height:Int,
					?color:Null<Int>, ?type:lime.graphics.ImageType,
					?onload:Dynamic = true)
				{
					super();

					if (preload != null)
					{
						var buffer = new lime.graphics.ImageBuffer();
						buffer.__srcImage = preload;
						buffer.width = preload.width;
						buffer.width = preload.height;

						__fromImageBuffer(buffer);
					}
					else
					{
						__fromBase64(haxe.Resource.getString(resourceName), resourceType, function(image)
						{
							if (preload == null)
							{
								preload = image.buffer.__srcImage;
							}

							if (onload != null)
							{
								onload(image);
							}
						});
					}
				}
			};
		}
		else
		{
			definition = macro class Temp
			{
				public function new(?buffer:lime.graphics.ImageBuffer,
					?offsetX:Int, ?offsetY:Int, ?width:Int, ?height:Int,
					?color:Null<Int>, ?type:lime.graphics.ImageType)
				{
					super();

					__fromBytes(haxe.Resource.getBytes(resourceName), null);
				}
			};
		}

		for (field in definition.fields)
		{
			fields.push(field);
		}

		return fields;
	}

	macro public static function embedSound():Array<Field>
	{
		var fields = embedData(":sound");
		// CFFILoader.h(248) : NOT Implemented:api_buffer_data
		if (fields == null || Context.defined("html5") || !Context.defined("openfl"))
			return null;

		var definition = macro class Temp
		{
			public function new(?stream:openfl.net.URLRequest,
				?context:openfl.media.SoundLoaderContext,
				?forcePlayAsMusic:Bool = false)
			{
				super();

				var byteArray = openfl.utils.ByteArray.fromBytes(haxe.Resource.getBytes(resourceName));
				loadCompressedDataFromByteArray(byteArray, byteArray.length, forcePlayAsMusic);
			}
		};

		fields.push(definition.fields[0]);

		return fields;
	}
	#end
}
