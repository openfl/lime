package lime.net.curl;

#if (!lime_doc_gen || lime_curl)
class CURLMultiMessage
{
	public var curl:CURL;
	public var result:CURLCode;

	@:noCompletion private function new(curl:CURL, result:CURLCode)
	{
		this.curl = curl;
		this.result = result;
	}
}
#end
