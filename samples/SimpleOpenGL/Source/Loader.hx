package;

import haxe.io.Bytes;
#if lime_html5
import js.html.ArrayBuffer;
import js.html.XMLHttpRequest;
import lime.utils.UInt8Array;
#else 
import lime.utils.Assets;
#end

class Loader {

	public static function loadBytes(url:String, onLoaded:Bytes->Void) : Void {
		#if lime_html5

		var request = new XMLHttpRequest();
		request.open("GET", url);
		request.responseType = "arraybuffer";
		request.onload = function (v:Dynamic):Void {
			var buffer:ArrayBuffer = request.response;
			var byteArray = new UInt8Array(buffer);
			var array:Array<Int> = new Array<Int>();
			for (i in 0...byteArray.length) {
				array.push(byteArray[i]);
			}
			var bytes = Bytes.ofData(array);
			if(onLoaded != null) {
				onLoaded(bytes);
			}
		};
		request.send(null);

		#else 

		var bytes = Assets.getBytes(url);
		if(onLoaded!=null) {
			onLoaded(bytes);
		}

		#end
	}
}