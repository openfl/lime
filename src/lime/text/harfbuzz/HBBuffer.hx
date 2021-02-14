package lime.text.harfbuzz;

#if (!lime_doc_gen || lime_harfbuzz)
import lime._internal.backend.native.NativeCFFI;
import lime.system.CFFIPointer;
import lime.utils.Bytes;
import lime.utils.DataPointer;

@:access(lime._internal.backend.native.NativeCFFI)
abstract HBBuffer(CFFIPointer) from CFFIPointer to CFFIPointer
{
	public var allocationSuccessful(get, never):Bool;
	public var clusterLevel(get, set):HBBufferClusterLevel;
	public var contentType(get, set):HBBufferContentType;
	public var direction(get, set):HBDirection;
	public var flags(get, set):Int;
	public var language(get, set):HBLanguage;
	public var length(get, set):Int;
	public var replacementCodepoint(get, set):Int;
	public var script(get, set):HBScript;
	public var segmentProperties(get, set):HBSegmentProperties;

	public function new()
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		this = NativeCFFI.lime_hb_buffer_create();
		#else
		this = null;
		#end
	}

	public function add(codepoint:Int, cluster:Int):Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_add(this, codepoint, cluster);
		#end
	}

	public function addCodepoints(text:DataPointer, textLength:Int, itemOffset:Int, itemLength:Int):Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_add_codepoints(this, text, textLength, itemOffset, itemLength);
		#end
	}

	public function addUTF8(text:String, itemOffset:Int, itemLength:Int):Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_add_utf8(this, text, itemOffset, itemLength);
		#end
	}

	public function addUTF16(text:DataPointer, textLength:Int, itemOffset:Int, itemLength:Int):Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_add_utf16(this, text, textLength, itemOffset, itemLength);
		#end
	}

	public function addUTF32(text:DataPointer, textLength:Int, itemOffset:Int, itemLength:Int):Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_add_utf32(this, text, textLength, itemOffset, itemLength);
		#end
	}

	public function clearContents():Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_clear_contents(this);
		#end
	}

	public function getGlyphInfo():Array<HBGlyphInfo>
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		var bytes = Bytes.alloc(0);
		bytes = NativeCFFI.lime_hb_buffer_get_glyph_infos(this, bytes);

		if (bytes == null)
		{
			return null;
		}
		else
		{
			var result = new Array<HBGlyphInfo>();

			var length = bytes.length;
			var position = 0, info;

			while (position < length)
			{
				info = new HBGlyphInfo();
				info.codepoint = bytes.getInt32(position);
				position += 4;
				info.mask = bytes.getInt32(position);
				position += 4;
				info.cluster = bytes.getInt32(position);
				position += 4;
				result.push(info);
			}

			return result;
		}
		#else
		return null;
		#end
	}

	public function getGlyphPositions():Array<HBGlyphPosition>
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		var bytes = Bytes.alloc(0);
		bytes = NativeCFFI.lime_hb_buffer_get_glyph_positions(this, bytes);

		if (bytes == null)
		{
			return null;
		}
		else
		{
			var result = new Array<HBGlyphPosition>();

			var length = bytes.length;
			var position = 0, glyphPosition;

			while (position < length)
			{
				glyphPosition = new HBGlyphPosition();
				glyphPosition.xAdvance = bytes.getInt32(position);
				position += 4;
				glyphPosition.yAdvance = bytes.getInt32(position);
				position += 4;
				glyphPosition.xOffset = bytes.getInt32(position);
				position += 4;
				glyphPosition.yOffset = bytes.getInt32(position);
				position += 4;
				result.push(glyphPosition);
			}

			return result;
		}
		#else
		return null;
		#end
	}

	public function guessSegmentProperties():Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_guess_segment_properties(this);
		#end
	}

	public function normalizeGlyphs():Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_normalize_glyphs(this);
		#end
	}

	public function preallocate(size:Int):Bool
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_buffer_preallocate(this, size);
		#else
		return false;
		#end
	}

	public function reset():Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_reset(this);
		#end
	}

	public function reverse():Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_reverse(this);
		#end
	}

	public function reverseClusters():Void
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_reverse_clusters(this);
		#end
	}

	// Get & Set Methods
	@:noCompletion private inline function get_allocationSuccessful():Bool
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_buffer_allocation_successful(this);
		#else
		return false;
		#end
	}

	@:noCompletion private inline function get_clusterLevel():HBBufferClusterLevel
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_buffer_get_cluster_level(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private inline function set_clusterLevel(value:HBBufferClusterLevel):HBBufferClusterLevel
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_set_cluster_level(this, value);
		#end
		return value;
	}

	@:noCompletion private inline function get_contentType():HBBufferContentType
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_buffer_get_content_type(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private inline function set_contentType(value:HBBufferContentType):HBBufferContentType
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_set_content_type(this, value);
		#end
		return value;
	}

	@:noCompletion private inline function get_direction():HBDirection
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_buffer_get_direction(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private inline function set_direction(value:HBDirection):HBDirection
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_set_direction(this, value);
		#end
		return value;
	}

	private static inline function get_empty():HBBuffer
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_buffer_get_empty();
		#else
		return null;
		#end
	}

	@:noCompletion private inline function get_flags():Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_buffer_get_flags(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private inline function set_flags(value:Int):Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_set_flags(this, value);
		#end
		return value;
	}

	@:noCompletion private inline function get_language():HBLanguage
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_buffer_get_language(this);
		#else
		return null;
		#end
	}

	@:noCompletion private inline function set_language(value:HBLanguage):HBLanguage
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_set_language(this, value);
		#end
		return value;
	}

	@:noCompletion private inline function get_length():Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_buffer_get_length(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private inline function set_length(value:Int):Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_set_length(this, value);
		#end
		return value;
	}

	@:noCompletion private inline function get_replacementCodepoint():Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_buffer_get_replacement_codepoint(this);
		#else
		return 0;
		#end
	}

	@:noCompletion private inline function set_replacementCodepoint(value:Int):Int
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_set_replacement_codepoint(this, value);
		#end
		return value;
	}

	@:noCompletion private inline function get_script():HBScript
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return NativeCFFI.lime_hb_buffer_get_script(this);
		#else
		return cast 0;
		#end
	}

	@:noCompletion private inline function set_script(value:HBScript):HBScript
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		#if neko
		value = -1;
		#end
		NativeCFFI.lime_hb_buffer_set_script(this, value);
		#end
		return value;
	}

	@:noCompletion private inline function get_segmentProperties():HBSegmentProperties
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		return null;
		// return NativeCFFI.lime_hb_buffer_get_segment_properties (this);
		#else
		return null;
		#end
	}

	@:noCompletion private inline function set_segmentProperties(value:HBSegmentProperties):HBSegmentProperties
	{
		#if (lime_cffi && lime_harfbuzz && !macro)
		NativeCFFI.lime_hb_buffer_set_segment_properties(this, value);
		#end
		return value;
	}
}
#end
