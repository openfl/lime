package flash.security;

extern class CryptContext extends flash.events.EventDispatcher {
	var signerCN(default,never) : String;
	var signerDN(default,never) : String;
	var signerValidEnd(default,never) : UInt;
	var verificationTime(default,never) : UInt;
	function new() : Void;
	function HasValidVerifySession() : Bool;
	function VerifySigASync(sig : String, data : String, ignoreCertTime : Bool) : Void;
	function VerifySigSync(sig : String, data : String, ignoreCertTime : Bool) : Void;
	function addCRLRevEvidenceBase64(crl : String) : Void;
	function addCRLRevEvidenceRaw(crl : flash.utils.ByteArray) : Void;
	function addChainBuildingCertBase64(cert : String, trusted : Bool) : Void;
	function addChainBuildingCertRaw(cert : flash.utils.ByteArray, trusted : Bool) : Void;
	function addTimestampingRootRaw(cert : flash.utils.ByteArray) : Void;
	function getDataTBVStatus() : UInt;
	function getIDStatus() : UInt;
	function getIDSummaryFromSigChain(version : UInt) : String;
	function getOverallStatus() : UInt;
	function getPublicKey(cert : String) : flash.utils.ByteArray;
	function getRevCheckSetting() : String;
	function getSignerExtendedKeyUsages() : Array<Dynamic>;
	function getSignerIDSummary(version : UInt) : String;
	function getSignerTrustFlags() : UInt;
	function getSignerTrustSettings() : Array<Dynamic>;
	function getTimestampRevCheckSetting() : String;
	function getUseSystemTrustStore() : Bool;
	function setRevCheckSetting(setting : String) : Void;
	function setSignerCert(cert : String) : Dynamic;
	function setSignerCertDN(dn : String) : Dynamic;
	function setTimestampRevCheckSetting(setting : String) : Void;
	function useCodeSigningValidationRules() : Void;
	function useSystemTrustStore(trusted : Bool) : Void;
	function verifyTimestamp(tsp : String, data : String, ignoreCertTime : Bool) : Void;
}
