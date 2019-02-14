package flash.events;

@:require(flash10_1) extern class DRMStatusEvent extends Event
{
	var contentData:flash.net.drm.DRMContentData;
	#if air
	var detail(default, never):String;
	var isAnonymous(default, never):Bool;
	var isAvailableOffline(default, never):Bool;
	#end
	var isLocal:Bool;
	#if air
	var offlineLeasePeriod(default, never):UInt;
	var policies(default, never):flash.utils.Object;
	#end
	var voucher:flash.net.drm.DRMVoucher;
	#if air
	var voucherEndDate(default, never):Date;
	#end
	function new(?type:String, bubbles:Bool = false, cancelable:Bool = false, ?inMetadata:flash.net.drm.DRMContentData, ?inVoucher:flash.net.drm.DRMVoucher,
		inLocal:Bool = false):Void;
	static var DRM_STATUS(default, never):String;
}
