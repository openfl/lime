#ifdef HX_WINDOWS
#define _WIN32_DCOM
#include <iostream>
#include <wbemidl.h>
#include <comutil.h>
#pragma comment(lib, "wbemuuid.lib")
#include <Windows.h>
#endif

#include <system/System.h>


namespace lime {


	#ifdef LIME_HASHLINK
	bool System::_isHL = (hl_nan () != 0);
	#else
	bool System::_isHL = false;
	#endif


	void System::GCEnterBlocking () {

		if (!_isHL) {

			gc_enter_blocking ();

		}

	}


	void System::GCExitBlocking () {

		if (!_isHL) {

			gc_exit_blocking ();

		}

	}


	void System::GCTryEnterBlocking () {

		if (!_isHL) {

			// TODO: Only supported in HXCPP 4.3
			// gc_try_blocking ();

		}

	}


	void System::GCTryExitBlocking () {

		if (!_isHL) {

			// TODO: Only supported in HXCPP 4.3
			//gc_try_unblocking ();

		}

	}


	#if defined (HX_WINDOWS) && !defined (HX_WINRT)
	std::wstring* GetWMIValue (BSTR query, BSTR field) {

		HRESULT hres = 0;
		IWbemLocator *pLoc = NULL;
		IWbemServices *pSvc = NULL;
		IEnumWbemClassObject* pEnumerator = NULL;
		IWbemClassObject *pclsObj = NULL;
		ULONG uReturn = 0;
		std::wstring* result = NULL;

		// hres = CoInitializeEx (0, COINIT_MULTITHREADED);

		// if (FAILED (hres)) {

		// 	return NULL;

		// }

		// hres = CoInitializeSecurity (NULL, -1, NULL, NULL, RPC_C_AUTHN_LEVEL_DEFAULT, RPC_C_IMP_LEVEL_IMPERSONATE, NULL, EOAC_NONE, NULL);

		// if (FAILED (hres)) {

		// 	CoUninitialize ();
		// 	NULL;

		// }

		hres = CoCreateInstance (CLSID_WbemLocator, 0, CLSCTX_INPROC_SERVER, IID_IWbemLocator, (LPVOID *) &pLoc);

		if (FAILED (hres)) {

			//CoUninitialize ();
			return NULL;

		}

		hres = pLoc->ConnectServer (_bstr_t (L"ROOT\\CIMV2"), NULL, NULL, 0, NULL, 0, 0, &pSvc);

		if (FAILED (hres)) {

			pLoc->Release ();
			// CoUninitialize ();
			return NULL;

		}

		hres = CoSetProxyBlanket (pSvc, RPC_C_AUTHN_WINNT, RPC_C_AUTHZ_NONE, NULL, RPC_C_AUTHN_LEVEL_CALL, RPC_C_IMP_LEVEL_IMPERSONATE, NULL, EOAC_NONE);

		if (FAILED (hres)) {

			pSvc->Release ();
			pLoc->Release ();
			// CoUninitialize ();
			return NULL;

		}

		hres = pSvc->ExecQuery (bstr_t ("WQL"), query, WBEM_FLAG_FORWARD_ONLY | WBEM_FLAG_RETURN_IMMEDIATELY, NULL, &pEnumerator);

		if (FAILED (hres)) {

			pSvc->Release ();
			pLoc->Release ();
			// CoUninitialize ();
			return NULL;

		}

		while (pEnumerator) {

			HRESULT hr = pEnumerator->Next (WBEM_INFINITE, 1, &pclsObj, &uReturn);
			if (uReturn == 0) break;

			VARIANT vtProp;

			hr = pclsObj->Get (field, 0, &vtProp, 0, 0);
			VariantClear (&vtProp);
			result = new std::wstring (vtProp.bstrVal, SysStringLen (vtProp.bstrVal));

			pclsObj->Release ();

		}

		pSvc->Release ();
		pLoc->Release ();
		pEnumerator->Release ();
		// CoUninitialize ();

		return result;

	}
	#endif


	std::wstring* System::GetDeviceModel () {

		#if defined (HX_WINDOWS) && !defined (HX_WINRT)
		return GetWMIValue (bstr_t ("SELECT * FROM Win32_ComputerSystemProduct"), L"Version");
		#endif

		return NULL;

	}


	std::wstring* System::GetDeviceVendor () {

		#if defined (HX_WINDOWS) && !defined (HX_WINRT)
		return GetWMIValue (bstr_t ("SELECT * FROM Win32_ComputerSystemProduct"), L"Vendor");
		#endif

		return NULL;

	}


	std::wstring* System::GetPlatformLabel () {

		#if defined (HX_WINDOWS) && !defined (HX_WINRT)
		return GetWMIValue (bstr_t ("SELECT * FROM Win32_OperatingSystem"), L"Caption");
		#endif

		return NULL;

	}


	std::wstring* System::GetPlatformName () {

		return NULL;

	}


	std::wstring* System::GetPlatformVersion () {

		#if defined (HX_WINDOWS) && !defined (HX_WINRT)
		return GetWMIValue (bstr_t ("SELECT * FROM Win32_OperatingSystem"), L"Version");
		#endif

		return NULL;

	}


	#if defined (HX_WINDOWS) && !defined (HX_WINRT)
	int System::GetWindowsConsoleMode (int handleType) {

		HANDLE handle = GetStdHandle ((DWORD)handleType);
		DWORD mode = 0;

		if (handle) {

			bool result = GetConsoleMode (handle, &mode);

		}

		return mode;

	}
	#endif


	#if defined (HX_WINDOWS) && !defined (HX_WINRT)
	bool System::SetWindowsConsoleMode (int handleType, int mode) {

		HANDLE handle = GetStdHandle ((DWORD)handleType);

		if (handle) {

			return SetConsoleMode (handle, (DWORD)mode);

		}

		return false;

	}
	#endif


}


#ifdef HX_LINUX

// Improve compatibility with old glibc

#define __fdelt_chk __fdelt_chk_local
#include <sys/select.h>
#undef __fdelt_chk

long int __fdelt_chk (long int d) {

	if (d >= FD_SETSIZE) {

		//printf("Select - bad fd.\n");
		return 0;

	}

	return d / __NFDBITS;

}

#endif


#if defined(ANDROID) && !defined(HXCPP_CLANG)

#include <stdint.h>
#include <wchar.h>
#include <errno.h>

/*
* This code was written by Rich Felker in 2010; no copyright is claimed.
* This code is in the public domain. Attribution is appreciated but
* unnecessary.
*/

#define OOB(c,b) (((((b)>>3)-0x10)|(((b)>>3)+((int32_t)(c)>>26))) & ~7)

#define R(a,b) ((uint32_t)((a==0x80 ? 0x40-b : -a) << 23))

#define C(x) ( x<2 ? -1 : ( R(0x80,0xc0) | x ) )
#define D(x) C((x+16))
#define E(x) ( ( x==0 ? R(0xa0,0xc0) : \
				x==0xd ? R(0x80,0xa0) : \
				R(0x80,0xc0) ) \
			| ( R(0x80,0xc0) >> 6 ) \
			| x )
#define F(x) ( ( x>=5 ? 0 : \
				x==0 ? R(0x90,0xc0) : \
				x==4 ? R(0x80,0xa0) : \
				R(0x80,0xc0) ) \
			| ( R(0x80,0xc0) >> 6 ) \
			| ( R(0x80,0xc0) >> 12 ) \
			| x )

#define SA 0xc2u
#define SB 0xf4u

const uint32_t bittab[] = {
				C(0x2),C(0x3),C(0x4),C(0x5),C(0x6),C(0x7),
	C(0x8),C(0x9),C(0xa),C(0xb),C(0xc),C(0xd),C(0xe),C(0xf),
	D(0x0),D(0x1),D(0x2),D(0x3),D(0x4),D(0x5),D(0x6),D(0x7),
	D(0x8),D(0x9),D(0xa),D(0xb),D(0xc),D(0xd),D(0xe),D(0xf),
	E(0x0),E(0x1),E(0x2),E(0x3),E(0x4),E(0x5),E(0x6),E(0x7),
	E(0x8),E(0x9),E(0xa),E(0xb),E(0xc),E(0xd),E(0xe),E(0xf),
	F(0x0),F(0x1),F(0x2),F(0x3),F(0x4)
};

// Added minor C++ compile fixes

size_t _mbsrtowcs(wchar_t * ws, const char **src, size_t wn, mbstate_t *st)
{
	const unsigned char *s = (const unsigned char *)*src;
	size_t wn0 = wn;
	unsigned c = 0;

	if (st && (c = *(unsigned *)st)) {
		if (ws) {
			*(unsigned *)st = 0;
			goto resume;
		} else {
			goto resume0;
		}
	}

	if (!ws) for (;;) {
		if (*s-1u < 0x7f && (uintptr_t)s%4 == 0) {
			while (!(( *(uint32_t*)s | *(uint32_t*)s-0x01010101) & 0x80808080)) {
				s += 4;
				wn -= 4;
			}
		}
		if (*s-1u < 0x7f) {
			s++;
			wn--;
			continue;
		}
		if (*s-SA > SB-SA) break;
		c = bittab[*s++-SA];
resume0:
		if (OOB(c,*s)) { s--; break; }
		s++;
		if (c&(1U<<25)) {
			if (*s-0x80u >= 0x40) { s-=2; break; }
			s++;
			if (c&(1U<<19)) {
				if (*s-0x80u >= 0x40) { s-=3; break; }
				s++;
			}
		}
		wn--;
		c = 0;
	} else for (;;) {
		if (!wn) {
			*src = (const char *)s;
			return wn0;
		}
		if (*s-1u < 0x7f && (uintptr_t)s%4 == 0) {
			while (wn>=5 && !(( *(uint32_t*)s | *(uint32_t*)s-0x01010101) & 0x80808080)) {
				*ws++ = *s++;
				*ws++ = *s++;
				*ws++ = *s++;
				*ws++ = *s++;
				wn -= 4;
			}
		}
		if (*s-1u < 0x7f) {
			*ws++ = *s++;
			wn--;
			continue;
		}
		if (*s-SA > SB-SA) break;
		c = bittab[*s++-SA];
resume:
		if (OOB(c,*s)) { s--; break; }
		c = (c<<6) | *s++-0x80;
		if (c&(1U<<31)) {
			if (*s-0x80u >= 0x40) { s-=2; break; }
			c = (c<<6) | *s++-0x80;
			if (c&(1U<<31)) {
				if (*s-0x80u >= 0x40) { s-=3; break; }
				c = (c<<6) | *s++-0x80;
			}
		}
		*ws++ = c;
		wn--;
		c = 0;
	}

	if (!c && !*s) {
		if (ws) {
			*ws = 0;
			*src = 0;
		}
		return wn0-wn;
	}
	errno = EILSEQ;
	if (ws) *src = (const char *)s;
	return -1;
}

#endif