using System;
using System.Runtime.InteropServices;

namespace cs.ndll
{
    class NativeMethods
    {
        public static IntPtr LoadLibraryWrap(String filename)
        {
            switch(Environment.OSVersion.Platform)
            {
                case PlatformID.Win32NT:
                case PlatformID.Win32S:
                case PlatformID.Win32Windows:
                    return LoadLibrary(filename);
                default:
                    return dlopen(filename, RTLD_NOW);
            }
        }

        public static void FreeLibraryWrap(IntPtr handle)
        {
            switch(Environment.OSVersion.Platform)
            {
                case PlatformID.Win32NT:
                case PlatformID.Win32S:
                case PlatformID.Win32Windows:
                    FreeLibrary(handle);
                    break;
                default:
                    dlclose(handle);
                    break;
            }
        }

        public static IntPtr GetProcAddressWrap(IntPtr handle, String symbol)
        {
            switch(Environment.OSVersion.Platform)
            {
                case PlatformID.Win32NT:
                case PlatformID.Win32S:
                case PlatformID.Win32Windows:
                    return GetProcAddress(handle, symbol);
                default:
                    return dlsym(handle, symbol);
            }
        }

        internal const int RTLD_NOW = 2;

        [DllImport("kernel32", CharSet = CharSet.Unicode, SetLastError = true)]
        private static extern IntPtr LoadLibrary(String lpFileName);
        [DllImport("kernel32", SetLastError = true)]
        private static extern bool FreeLibrary(IntPtr hModule);
        [DllImport("kernel32", SetLastError = true, ExactSpelling = false, BestFitMapping = false, ThrowOnUnmappableChar = true)]
        private static extern IntPtr GetProcAddress(IntPtr hModule, [MarshalAs(UnmanagedType.LPStr)]String lpProcName);
        [DllImport("dl", BestFitMapping = false, ThrowOnUnmappableChar = true)]
        private static extern IntPtr dlopen([MarshalAs(UnmanagedType.LPTStr)]String filename, int flags);
        [DllImport("dl")]
        private static extern int dlclose(IntPtr handle);
        [DllImport("dl", BestFitMapping = false, ThrowOnUnmappableChar = true)]
        private static extern IntPtr dlsym(IntPtr handle, [MarshalAs(UnmanagedType.LPTStr)] String symbol);
    }
}
