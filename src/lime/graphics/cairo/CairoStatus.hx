package lime.graphics.cairo;

#if (!lime_doc_gen || lime_cairo)
@:enum abstract CairoStatus(Int) from Int to Int from UInt to UInt
{
	public var SUCCESS = 0;
	public var NO_MEMORY = 1;
	public var INVALID_RESTORE = 2;
	public var INVALID_POP_GROUP = 3;
	public var NO_CURRENT_POINT = 4;
	public var INVALID_MATRIX = 5;
	public var INVALID_STATUS = 6;
	public var NULL_POINTER = 7;
	public var INVALID_STRING = 8;
	public var INVALID_PATH_DATA = 9;
	public var READ_ERROR = 10;
	public var WRITE_ERROR = 11;
	public var SURFACE_FINISHED = 12;
	public var SURFACE_TYPE_MISMATCH = 13;
	public var PATTERN_TYPE_MISMATCH = 14;
	public var INVALID_CONTENT = 15;
	public var INVALID_FORMAT = 16;
	public var INVALID_VISUAL = 17;
	public var FILE_NOT_FOUND = 18;
	public var INVALID_DASH = 19;
	public var INVALID_DSC_COMMENT = 20;
	public var INVALID_INDEX = 21;
	public var CLIP_NOT_REPRESENTABLE = 22;
	public var TEMP_FILE_ERROR = 23;
	public var INVALID_STRIDE = 24;
	public var FONT_TYPE_MISMATCH = 25;
	public var USER_FONT_IMMUTABLE = 26;
	public var USER_FONT_ERROR = 27;
	public var NEGATIVE_COUNT = 28;
	public var INVALID_CLUSTERS = 29;
	public var INVALID_SLANT = 30;
	public var INVALID_WEIGHT = 31;
	public var INVALID_SIZE = 32;
	public var USER_FONT_NOT_IMPLEMENTED = 33;
	public var DEVICE_TYPE_MISMATCH = 34;
	public var DEVICE_ERROR = 35;
	public var INVALID_MESH_CONSTRUCTION = 36;
	public var DEVICE_FINISHED = 37;
	public var JBIG2_GLOBAL_MISSING = 38;
}
#end
