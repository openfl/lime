#ifdef HX_WINDOWS

#include <windows.h>
#include <Shlobj.h>
#include <time.h>

#elif defined (EPPC)

#include <time.h>
#include <stdint.h>

#else

#include <sys/time.h>
#include <stdint.h>

#ifdef HX_LINUX
#include <unistd.h>
#include <stdio.h>
#endif

#ifndef EMSCRIPTEN
typedef uint64_t __int64;
#endif

#endif

#ifdef HX_MACOS
#include <mach/mach_time.h>  
#include <mach-o/dyld.h>
#include <CoreServices/CoreServices.h>
#endif

#ifdef ANDROID
#include <android/log.h>
#include <time.h>
#endif

#ifdef TIZEN
#include <FSystem.h>
#endif

#ifdef IPHONE
#include <QuartzCore/QuartzCore.h>
#endif

#include <system/System.h>


namespace lime {
	
	
	double System::GetTimestamp () {
		
		#ifdef _WIN32
		
		static __int64 t0 = 0;
		static double period = 0;
		__int64 now;
		
		if (QueryPerformanceCounter ((LARGE_INTEGER*)&now)) {
			
			if (t0 == 0) {
				
				t0 = now;
				__int64 freq;
				QueryPerformanceFrequency ((LARGE_INTEGER*)&freq);
				
				if (freq != 0)
					period = 1.0 / freq;
				
			}
			
			if (period != 0)
				return (now - t0) * period;
			
		}
		
		return (double)clock () / ((double)CLOCKS_PER_SEC);
		
		#elif defined (HX_MACOS)
		
		static double time_scale = 0.0;
		
		if (time_scale == 0.0) {
			
			mach_timebase_info_data_t info;
			mach_timebase_info (&info);  
			time_scale = 1e-9 * (double)info.numer / info.denom;
			
		}
		
		double r = mach_absolute_time () * time_scale;  
		return mach_absolute_time () * time_scale;
		
		#else
		
		static double t0 = 0;
		
		#if defined (IPHONE)
		
		double t = CACurrentMediaTime (); 
		
		#elif defined (GPH) || defined (HX_LINUX) || defined (EMSCRIPTEN)
		
		struct timeval tv;
		if (gettimeofday (&tv, 0))
			return 0;
		double t = (tv.tv_sec + ((double)tv.tv_usec) / 1000000.0);
		
		#elif defined (EPPC)
		
		time_t tod;
		time (&tod);
		double t = (double)tod;
		
		#else
		
		struct timespec ts;
		clock_gettime (CLOCK_MONOTONIC, &ts);
		double t = (ts.tv_sec + ((double)ts.tv_nsec) * 1e-9);
		
		#endif
		
		if (t0 == 0) t0 = t;
			return t - t0;
		
		#endif
		
	}
	
	
}