package flash.desktop;

extern class FilePromiseWrapper
{
	var filePromise(default, never):IFilePromise;
	function new(fp:IFilePromise):Void;
}
