
	//needs to be in a non-package
class AssetData {
	public var id:String;
	public var path:String;
	public var type:AssetType;
	public function new () {
	}
}

enum AssetType {
	BINARY;
	FONT;
	IMAGE;
	MOVIE_CLIP;
	MUSIC;
	SOUND;
	TEMPLATE;
	TEXT;
}