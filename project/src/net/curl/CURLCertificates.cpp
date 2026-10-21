#include <curl/curl.h>
#include <string>
#include <stdio.h>
#include <string.h>

#if defined (_WIN32)
#ifndef WIN32_LEAN_AND_MEAN
#define WIN32_LEAN_AND_MEAN
#endif
#include <windows.h>
#include <wincrypt.h>
#elif defined (__APPLE__)
#include <TargetConditionals.h>
#if TARGET_OS_OSX
#include <Security/Security.h>
#endif
#elif defined (__ANDROID__)
#include <dirent.h>
#endif

#include "ca_certificates.h"


namespace lime {


	#if !defined (_WIN32) && !defined (__APPLE__)
	static bool AppendFile (std::string& pem, const char* path) {

		FILE* file = fopen (path, "rb");
		if (!file) return false;

		size_t start = pem.size ();
		char buffer[16384];
		size_t read;

		while ((read = fread (buffer, 1, sizeof (buffer), file)) > 0) {

			pem.append (buffer, read);

		}

		fclose (file);
		pem.append ("\n");
		return pem.size () > start + 1;

	}
	#endif


	static void AppendBundled (std::string& pem) {

		for (size_t i = 0; i < sizeof (lime_ca_certificates) / sizeof (lime_ca_certificates[0]); i++) {

			pem.append (lime_ca_certificates[i]);

		}

	}


	#if defined (__APPLE__) && TARGET_OS_OSX
	static void AppendDER (std::string& pem, const unsigned char* der, size_t length) {

		static const char* base64 = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

		pem.append ("-----BEGIN CERTIFICATE-----\n");
		size_t column = 0;

		for (size_t i = 0; i < length; i += 3) {

			unsigned int chunk = der[i] << 16;
			if (i + 1 < length) chunk |= der[i + 1] << 8;
			if (i + 2 < length) chunk |= der[i + 2];

			pem.push_back (base64[(chunk >> 18) & 63]);
			pem.push_back (base64[(chunk >> 12) & 63]);
			pem.push_back (i + 1 < length ? base64[(chunk >> 6) & 63] : '=');
			pem.push_back (i + 2 < length ? base64[chunk & 63] : '=');

			column += 4;
			if (column == 64) {

				pem.push_back ('\n');
				column = 0;

			}

		}

		if (column > 0) pem.push_back ('\n');
		pem.append ("-----END CERTIFICATE-----\n");

	}


	static void AppendCertificates (std::string& pem, CFArrayRef certificates) {

		for (CFIndex i = 0; i < CFArrayGetCount (certificates); i++) {

			SecCertificateRef certificate = (SecCertificateRef)CFArrayGetValueAtIndex (certificates, i);
			CFDataRef data = SecCertificateCopyData (certificate);

			if (data) {

				AppendDER (pem, CFDataGetBytePtr (data), CFDataGetLength (data));
				CFRelease (data);

			}

		}

	}
	#endif


	static std::string LoadCertificates () {

		std::string pem;

		#if defined (_WIN32)

		// Windows adds some roots to its store only when it first needs them
		HCERTSTORE store = CertOpenSystemStoreA (0, "ROOT");

		if (store) {

			PCCERT_CONTEXT context = NULL;

			while ((context = CertEnumCertificatesInStore (store, context)) != NULL) {

				DWORD length = 0;

				if (CryptBinaryToStringA (context->pbCertEncoded, context->cbCertEncoded, CRYPT_STRING_BASE64HEADER, NULL, &length)) {

					std::string block (length, '\0');

					if (CryptBinaryToStringA (context->pbCertEncoded, context->cbCertEncoded, CRYPT_STRING_BASE64HEADER, &block[0], &length)) {

						pem.append (block.c_str ());

					}

				}

			}

			CertCloseStore (store, 0);

		}

		AppendBundled (pem);

		#elif defined (__APPLE__) && TARGET_OS_OSX

		CFArrayRef anchors = NULL;

		if (SecTrustCopyAnchorCertificates (&anchors) == errSecSuccess && anchors) {

			AppendCertificates (pem, anchors);
			CFRelease (anchors);

		}

		SecTrustSettingsDomain domains[] = { kSecTrustSettingsDomainAdmin, kSecTrustSettingsDomainUser };

		for (size_t i = 0; i < 2; i++) {

			CFArrayRef certificates = NULL;

			if (SecTrustSettingsCopyCertificates (domains[i], &certificates) == errSecSuccess && certificates) {

				AppendCertificates (pem, certificates);
				CFRelease (certificates);

			}

		}

		if (pem.empty ()) AppendBundled (pem);

		#elif defined (__APPLE__)

		AppendBundled (pem);

		#elif defined (__ANDROID__)

		// Android 14 updates its roots through the Conscrypt module
		const char* directories[] = { "/apex/com.android.conscrypt/cacerts", "/system/etc/security/cacerts" };

		for (size_t i = 0; i < 2 && pem.empty (); i++) {

			DIR* directory = opendir (directories[i]);
			if (!directory) continue;

			struct dirent* entry;

			while ((entry = readdir (directory)) != NULL) {

				if (entry->d_name[0] == '.') continue;
				std::string path = std::string (directories[i]) + "/" + entry->d_name;
				AppendFile (pem, path.c_str ());

			}

			closedir (directory);

		}

		if (pem.empty ()) AppendBundled (pem);

		#else

		const char* bundles[] = {

			"/etc/ssl/certs/ca-certificates.crt",
			"/etc/pki/tls/certs/ca-bundle.crt",
			"/etc/pki/ca-trust/extracted/pem/tls-ca-bundle.pem",
			"/etc/ssl/ca-bundle.pem",
			"/etc/ssl/cert.pem",
			"/usr/local/share/certs/ca-root-nss.crt",
			"/usr/share/ssl/certs/ca-bundle.crt"

		};

		for (size_t i = 0; i < sizeof (bundles) / sizeof (bundles[0]); i++) {

			if (AppendFile (pem, bundles[i])) break;

		}

		if (pem.empty ()) AppendBundled (pem);

		#endif

		return pem;

	}


	void CURL_SetCertificates (CURL* curl) {

		static std::string pem = LoadCertificates ();

		if (pem.empty ()) return;

		struct curl_blob blob;
		blob.data = (void*)pem.c_str ();
		blob.len = pem.size () + 1;
		blob.flags = CURL_BLOB_NOCOPY;

		curl_easy_setopt (curl, CURLOPT_CAINFO_BLOB, &blob);
		curl_easy_setopt (curl, CURLOPT_PROXY_CAINFO_BLOB, &blob);

	}


	void CURL_UseOwnCertificates (CURL* curl, int option) {

		if (option == CURLOPT_PROXY_CAINFO || option == CURLOPT_PROXY_CAPATH) {

			curl_easy_setopt (curl, CURLOPT_PROXY_CAINFO_BLOB, NULL);

		} else {

			curl_easy_setopt (curl, CURLOPT_CAINFO_BLOB, NULL);

		}

	}


}
