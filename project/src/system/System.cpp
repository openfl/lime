#ifdef HX_WINDOWS
#include <Windows.h>
#endif

#include <system/System.h>


namespace lime {
	
	
	std::wstring* System::GetManufacturer () {
		
		return NULL;
		
	}
	
	
	std::wstring* System::GetModel () {
		
		return NULL;
		
	}
	
	
	std::wstring* System::GetVersion () {
		
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