package net;

import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import utest.Assert;
import utest.Async;
import utest.Test;
#if (lime_cffi && lime_curl)
import lime.net.HTTPRequest;
import lime.net.curl.CURL;
import lime.net.curl.CURLCode;
#end
#if (lime_cffi && lime_curl && sys && target.threaded)
import sys.net.Host;
import sys.ssl.Certificate;
import sys.ssl.Key;
import sys.thread.Thread;
#end

/**
	Native HTTPS checks the server's certificate against the system's trusted
	certificates, which Lime gives every curl handle, unless the application
	asks it not to or brings its own.
**/
class HTTPSTest extends Test
{
	// Test certificates, valid until 2076, for 127.0.0.1 and localhost only
	private static inline var SELF_SIGNED_CERTIFICATE = "-----BEGIN CERTIFICATE-----
MIIBsDCCAVagAwIBAgIUGR3QRr79uih3MqXR2uAlGqfbmAQwCgYIKoZIzj0EAwIw
IDEeMBwGA1UEAwwVTGltZSBUZXN0IFNlbGYtU2lnbmVkMCAXDTI2MTAxNTE5Mzcw
OFoYDzIwNzYxMDAyMTkzNzA4WjAgMR4wHAYDVQQDDBVMaW1lIFRlc3QgU2VsZi1T
aWduZWQwWTATBgcqhkjOPQIBBggqhkjOPQMBBwNCAASqoO5mdmxG2B/4J2EHYIXS
FfvRHwCJnMAM6s3fEJVLipp5LJigXKpo9NWsyXzk3RwjlEZdCpFCH1YSyCxFZEsB
o2wwajAdBgNVHQ4EFgQUob3kACTHSTf75UBqkAwK8++L+BowHwYDVR0jBBgwFoAU
ob3kACTHSTf75UBqkAwK8++L+BowGgYDVR0RBBMwEYcEfwAAAYIJbG9jYWxob3N0
MAwGA1UdEwEB/wQCMAAwCgYIKoZIzj0EAwIDSAAwRQIhALg0rTo74ciicXQpMBWl
bj+AMAdPAdRyzLj4Yv4KHVidAiA17zLY08EiVBhHbnHpDXECSDF4SK8SUxvKO5PC
o61E2Q==
-----END CERTIFICATE-----
";

	private static inline var SELF_SIGNED_KEY = "-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgxvJYHbF2cTff9Ioc
PKqf8CCw9P3170ZtZ23TinTzj+ChRANCAASqoO5mdmxG2B/4J2EHYIXSFfvRHwCJ
nMAM6s3fEJVLipp5LJigXKpo9NWsyXzk3RwjlEZdCpFCH1YSyCxFZEsB
-----END PRIVATE KEY-----
";

	private static inline var TEST_CA_CERTIFICATE = "-----BEGIN CERTIFICATE-----
MIIBlTCCATugAwIBAgIUIs1zm1BDnRQezTjBcl7L6/EXfWQwCgYIKoZIzj0EAwIw
FzEVMBMGA1UEAwwMTGltZSBUZXN0IENBMCAXDTI2MTAxNTE5MzcwOFoYDzIwNzYx
MDAyMTkzNzA4WjAXMRUwEwYDVQQDDAxMaW1lIFRlc3QgQ0EwWTATBgcqhkjOPQIB
BggqhkjOPQMBBwNCAARiX7azJzG37jpwQxwhm1ePD8/P3d0Bvp4lOR+c0VWbkHYE
4cz8lV/9bqyfFTeHX+rQ0zJXy0L70PcxVkzGmvZwo2MwYTAdBgNVHQ4EFgQUxnWD
LZs78XTg3UHuwad6m8OnF84wHwYDVR0jBBgwFoAUxnWDLZs78XTg3UHuwad6m8On
F84wDwYDVR0TAQH/BAUwAwEB/zAOBgNVHQ8BAf8EBAMCAQYwCgYIKoZIzj0EAwID
SAAwRQIgRHiwZzO6apWgdamyBLbPsRnv4K1TS8Bqqwf0E4z6H0ECIQC2saas/rlv
WixvY47izAuoQAtSZqMXPEOkbF/MRZz7lg==
-----END CERTIFICATE-----
";

	// Issued by the test CA
	private static inline var SERVER_CERTIFICATE = "-----BEGIN CERTIFICATE-----
MIIBwjCCAWigAwIBAgIUKWfW88Jo9ypZU9s741KGw/3Vy/8wCgYIKoZIzj0EAwIw
FzEVMBMGA1UEAwwMTGltZSBUZXN0IENBMCAXDTI2MTAxNTE5MzcwOFoYDzIwNzYx
MDAyMTkzNzA4WjAUMRIwEAYDVQQDDAlsb2NhbGhvc3QwWTATBgcqhkjOPQIBBggq
hkjOPQMBBwNCAATaB2ofyS5hQZ/SWctBboFjC84aQ7hjPPnvNTXCeHD8QlJQRVNG
CX/HJfwNItkkveY54/M8pOreIDAxcydX7TC3o4GSMIGPMBoGA1UdEQQTMBGHBH8A
AAGCCWxvY2FsaG9zdDAMBgNVHRMBAf8EAjAAMA4GA1UdDwEB/wQEAwIHgDATBgNV
HSUEDDAKBggrBgEFBQcDATAdBgNVHQ4EFgQU8W0d7B5UU3wBN40balONjpqFYiMw
HwYDVR0jBBgwFoAUxnWDLZs78XTg3UHuwad6m8OnF84wCgYIKoZIzj0EAwIDSAAw
RQIhAKBUB9UTlKSqXtlC2ri+nGAckkQYP9pc9abJt6foEgboAiBK7N46DEiDxdYx
Ezyxk1Tlb/VXB6gY7gUBcLccLAqfXQ==
-----END CERTIFICATE-----
";

	private static inline var SERVER_KEY = "-----BEGIN PRIVATE KEY-----
MIGHAgEAMBMGByqGSM49AgEGCCqGSM49AwEHBG0wawIBAQQgeHPpnUhgHu+PaaiK
sxFsycHEsIzG+GZ/D8sBCBXVmg+hRANCAATaB2ofyS5hQZ/SWctBboFjC84aQ7hj
PPnvNTXCeHD8QlJQRVNGCX/HJfwNItkkveY54/M8pOreIDAxcydX7TC3
-----END PRIVATE KEY-----
";

	private static inline var BODY = "ok";

	public function new()
	{
		super();
	}

	#if (lime_cffi && lime_curl && sys && target.threaded)
	#if neko
	public function teardown():Void
	{
		ProcessTLSServer.closeAll();
	}

	public function testTLSFixtureStartupFailureCleansUp():Void
	{
		function temporaryDirectories():Array<String>
		{
			var directories = sys.FileSystem.readDirectory(Sys.getCwd()).filter(function(name) return StringTools.startsWith(name, "lime-test-tls-"));
			directories.sort(Reflect.compare);
			return directories;
		}
		var before = temporaryDirectories();
		Assert.raises(function() new TLSServer("invalid certificate", "invalid key"));
		Assert.same(before, temporaryDirectories(), "failed startup must remove its temporary files");
	}
	#end

	public function testRejectedConnectionsDoNotStopTheServer():Void
	{
		var server = new TLSServer(SELF_SIGNED_CERTIFICATE, SELF_SIGNED_KEY);
		for (_ in 0...8)
		{
			var rejected = fetch(server.url);
			Assert.equals(SSL_CACERT, rejected.code, CURL.strerror(rejected.code));
		}
		var accepted = fetch(server.url, function(curl)
		{
			curl.setOption(SSL_VERIFYPEER, false);
			curl.setOption(SSL_VERIFYHOST, 0);
		});
		server.stop();
		Assert.equals(OK, accepted.code, CURL.strerror(accepted.code));
		Assert.equals(BODY, accepted.body);
	}

	public function testASelfSignedCertificateIsRejected():Void
	{
		var server = new TLSServer(SELF_SIGNED_CERTIFICATE, SELF_SIGNED_KEY);
		var result = fetch(server.url);
		server.stop();

		Assert.equals(SSL_CACERT, result.code, "a self-signed certificate was accepted: " + CURL.strerror(result.code));
	}

	public function testASelfSignedCertificateIsAcceptedWithoutVerification():Void
	{
		var server = new TLSServer(SELF_SIGNED_CERTIFICATE, SELF_SIGNED_KEY);
		var result = fetch(server.url, function(curl)
		{
			curl.setOption(SSL_VERIFYPEER, false);
			curl.setOption(SSL_VERIFYHOST, 0);
		});
		server.stop();

		Assert.equals(OK, result.code, CURL.strerror(result.code));
		Assert.equals(BODY, result.body);
	}

	public function testTheApplicationsOwnCertificatesAreTrusted():Void
	{
		var server = new TLSServer(SERVER_CERTIFICATE, SERVER_KEY);

		// The system doesn't trust the test CA
		var result = fetch(server.url);
		Assert.equals(SSL_CACERT, result.code, "a certificate from an unknown CA was accepted: " + CURL.strerror(result.code));

		var path = haxe.io.Path.join([Sys.getCwd(), "lime-test-ca-" + Std.random(1000000) + ".pem"]);
		sys.io.File.saveContent(path, TEST_CA_CERTIFICATE);
		result = fetch(server.url, function(curl) curl.setOption(CAINFO, path));
		sys.FileSystem.deleteFile(path);
		server.stop();

		Assert.equals(OK, result.code, "a certificate from the CA given with CAINFO was rejected: " + CURL.strerror(result.code));
		Assert.equals(BODY, result.body);
	}

	public function testAResetHandleStillChecksCertificates():Void
	{
		var server = new TLSServer(SELF_SIGNED_CERTIFICATE, SELF_SIGNED_KEY);
		var curl = new CURL();
		curl.setOption(SSL_VERIFYPEER, false);
		curl.reset();
		var result = perform(curl, server.url);
		curl.cleanup();
		server.stop();

		Assert.equals(SSL_CACERT, result.code, "a reset handle accepted a self-signed certificate: " + CURL.strerror(result.code));
	}

	public function testThePublicInternetIsTrusted():Void
	{
		// Checks that the system's certificates are found; needs a network
		var result = fetch("https://www.howsmyssl.com/a/check");

		if (result.code == COULDNT_RESOLVE_HOST || result.code == COULDNT_CONNECT || result.code == OPERATION_TIMEDOUT)
		{
			Assert.warn("No network to check the system's certificates with: " + CURL.strerror(result.code));
			return;
		}

		Assert.equals(OK, result.code, "a public server's certificate was rejected: " + CURL.strerror(result.code));
	}

	@:timeout(20000)
	public function testHTTPRequestChecksCertificates(async:Async):Void
	{
		var server = new TLSServer(SELF_SIGNED_CERTIFICATE, SELF_SIGNED_KEY);

		var checked = new HTTPRequest<String>();
		checked.load(server.url).onComplete(function(_)
		{
			Assert.fail("HTTPRequest accepted a self-signed certificate");
			server.stop();
			async.done();
		}).onError(function(_)
		{
			var unchecked = new HTTPRequest<String>();
			unchecked.verifyCertificates = false;
			unchecked.load(server.url).onComplete(function(body)
			{
				Assert.equals(BODY, body);
				server.stop();
				async.done();
			}).onError(function(error)
			{
				Assert.fail("HTTPRequest with verifyCertificates = false failed: " + error);
				server.stop();
				async.done();
			});
		});
	}

	private static function fetch(url:String, ?configure:CURL->Void):{code:CURLCode, body:String}
	{
		var curl = new CURL();
		if (configure != null) configure(curl);
		var result = perform(curl, url);
		curl.cleanup();
		return result;
	}

	private static function perform(curl:CURL, url:String):{code:CURLCode, body:String}
	{
		var buffer = new BytesBuffer();
		curl.setOption(URL, url);
		curl.setOption(NOSIGNAL, true);
		curl.setOption(TIMEOUT, 10);
		curl.setOption(WRITEFUNCTION, function(curl:CURL, output:Bytes):Int
		{
			buffer.addBytes(output, 0, output.length);
			return output.length;
		});
		var code = curl.perform();
		return {code: code, body: buffer.getBytes().toString()};
	}
	#end
}

#if (lime_cffi && lime_curl && sys && target.threaded)
#if neko
private typedef TLSServer = ProcessTLSServer;
#else
/**
	Answers HTTPS requests on a local port with a fixed body, presenting the
	given certificate.
**/
#if (cpp && !windows)
@:cppFileCode("#include <signal.h>")
#end
private class TLSServer
{
	public var url(default, null):String;

	private var listener:sys.ssl.Socket;
	private var stopped:Bool;

	public function new(certificate:String, key:String)
	{
		#if (cpp && !windows)
		// curl hangs up on a certificate it rejects, and released hxcpp sends
		// TLS without MSG_NOSIGNAL, so the server's next write would end the
		// tests with SIGPIPE
		untyped __cpp__("signal(SIGPIPE, SIG_IGN)");
		#end

		listener = new sys.ssl.Socket();
		listener.verifyCert = false;
		listener.setCertificate(Certificate.fromString(certificate), Key.readPEM(key, false));
		listener.bind(new Host("127.0.0.1"), 0);
		listener.listen(4);
		url = "https://127.0.0.1:" + listener.host().port + "/";
		Thread.create(acceptConnections);
	}

	public function stop():Void
	{
		stopped = true;
	}

	private function acceptConnections():Void
	{
		while (!stopped)
		{
			// Waits briefly, so stopping is seen
			if (sys.net.Socket.select([listener], [], [], 0.05).read.length == 0) continue;

			try
			{
				var connection = listener.accept();
				Thread.create(function() serve(connection));
			}
			catch (e:Dynamic) {}
		}

		listener.close();
	}

	private function serve(connection:sys.ssl.Socket):Void
	{
		try
		{
			connection.handshake();
			while (connection.input.readLine() != "") {}
			connection.output.writeString("HTTP/1.1 200 OK\r\nConnection: close\r\nContent-Length: 2\r\n\r\nok");
			connection.output.flush();
		}
		catch (e:Dynamic) {}

		try connection.close() catch (e:Dynamic) {}
	}
}
#end
#end
