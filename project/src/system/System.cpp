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
	
	
	#ifdef HX_WINDOWS
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
	
	
	std::wstring* System::GetManufacturer () {
		
		#ifdef HX_WINDOWS
		return GetWMIValue (bstr_t ("SELECT * FROM Win32_ComputerSystemProduct"), L"Vendor");
		#endif
		
		return NULL;
		
	}
	
	
	std::wstring* System::GetModel () {
		
		#ifdef HX_WINDOWS
		return GetWMIValue (bstr_t ("SELECT * FROM Win32_ComputerSystemProduct"), L"Version");
		#endif
		
		return NULL;
		
	}
	
	
	std::wstring* System::GetVersion () {
		
		#ifdef HX_WINDOWS
		return GetWMIValue (bstr_t ("SELECT * FROM Win32_OperatingSystem"), L"Caption");
		#endif
		
		return NULL;
		
	}
	
	
	#ifdef HX_WINDOWS
	int System::GetWindowsConsoleMode (int handleType) {
		
		HANDLE handle = GetStdHandle ((DWORD)handleType);
		DWORD mode = 0;
		
		if (handle) {
			
			bool result = GetConsoleMode (handle, &mode);
			
		}
		
		return mode;
		
	}
	#endif
	
	
	#ifdef HX_WINDOWS
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