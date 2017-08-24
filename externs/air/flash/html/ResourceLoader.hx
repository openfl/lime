package flash.html;

extern class ResourceLoader {
	function new(urlReq : flash.net.URLRequest, htmlControl : HTMLLoader, ?isStageWebViewRequest : Bool) : Void;
	function cancel() : Void;
}
