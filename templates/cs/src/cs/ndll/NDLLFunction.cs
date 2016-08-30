using System;
using System.IO;
using System.Runtime.InteropServices;

namespace cs.ndll
{
    public class NDLLFunction : IDisposable
    {
        private IntPtr module;
        private Delegate func;
        private int numArgs;
        private static CFFICSLoader.CFFILoaderDelegate loaderDelegate;
        private static GCHandle pinnedLoaderFunc;
        public static String LibraryDir = null;
        public static String LibraryPrefix = "";
        public static String LibrarySuffix = ".ndll";

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr NDLLFunctionDelegate();
        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate void HxSetLoaderDelegate(IntPtr loader);
        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr CallMultDelegate(IntPtr args);
        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr Call0Delegate();
        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr Call1Delegate(IntPtr arg1);
        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr Call2Delegate(IntPtr arg1, IntPtr arg2);
        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr Call3Delegate(IntPtr arg1, IntPtr arg2, IntPtr arg3);
        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr Call4Delegate(IntPtr arg1, IntPtr arg2, IntPtr arg3, IntPtr arg4);
        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr Call5Delegate(IntPtr arg1, IntPtr arg2, IntPtr arg3, IntPtr arg4, IntPtr arg5);

        NDLLFunction(IntPtr module, Delegate func, int numArgs)
        {
            this.module = module;
            this.func = func;
            this.numArgs = numArgs;
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        private void Dispose(bool disposing)
        {
            if (module != IntPtr.Zero)
            {
                NativeMethods.FreeLibraryWrap(module);
                module = IntPtr.Zero;
            }
        }

        ~NDLLFunction()
        {
            Dispose(false);
        }

        public static NDLLFunction Load(String lib, String name, int numArgs)
        {
            if (numArgs < -1 || numArgs > 5)
                throw new ArgumentOutOfRangeException("Invalid numArgs: " + numArgs);

            IntPtr module = IntPtr.Zero;
            try
            {
                if (LibraryDir != null && (lib.StartsWith("./") || lib.StartsWith(".\\")))
                    lib = LibraryDir + Path.DirectorySeparatorChar + LibraryPrefix + lib.Substring(2) + LibrarySuffix;
                else
                    lib = lib + LibrarySuffix;
                module = NativeMethods.LoadLibraryWrap(lib);
                if (module == IntPtr.Zero)
                    return null;

                String funcName;
                if (numArgs != -1)
                    funcName = String.Format("{0}__{1}", name, numArgs);
                else
                    funcName = String.Format("{0}__MULT", name);

                IntPtr funcPtr = NativeMethods.GetProcAddressWrap(module, funcName);
                if (funcPtr == IntPtr.Zero)
                    return null;
                NDLLFunctionDelegate func = (NDLLFunctionDelegate)Marshal.GetDelegateForFunctionPointer(funcPtr, typeof(NDLLFunctionDelegate));
                Delegate cfunc = null;
                switch (numArgs)
                {
                    case -1:
                        cfunc = Marshal.GetDelegateForFunctionPointer(func(), typeof(CallMultDelegate));
                        break;
                    case 0:
                        cfunc = Marshal.GetDelegateForFunctionPointer(func(), typeof(Call0Delegate));
                        break;
                    case 1:
                        cfunc = Marshal.GetDelegateForFunctionPointer(func(), typeof(Call1Delegate));
                        break;
                    case 2:
                        cfunc = Marshal.GetDelegateForFunctionPointer(func(), typeof(Call2Delegate));
                        break;
                    case 3:
                        cfunc = Marshal.GetDelegateForFunctionPointer(func(), typeof(Call3Delegate));
                        break;
                    case 4:
                        cfunc = Marshal.GetDelegateForFunctionPointer(func(), typeof(Call4Delegate));
                        break;
                    case 5:
                        cfunc = Marshal.GetDelegateForFunctionPointer(func(), typeof(Call5Delegate));
                        break;
                }

                IntPtr dll_hx_set_loader_ptr = NativeMethods.GetProcAddressWrap(module, "hx_set_loader");
                if (dll_hx_set_loader_ptr == IntPtr.Zero)
                    return null;
                HxSetLoaderDelegate dll_hx_set_loader = (HxSetLoaderDelegate)Marshal.GetDelegateForFunctionPointer(dll_hx_set_loader_ptr, typeof(HxSetLoaderDelegate));
                IntPtr callbackPtr;
                if (loaderDelegate == null)
                {
                    loaderDelegate = new CFFICSLoader.CFFILoaderDelegate(CFFICSLoader.Load);
                    callbackPtr = Marshal.GetFunctionPointerForDelegate(loaderDelegate);
                    pinnedLoaderFunc = GCHandle.Alloc(callbackPtr, GCHandleType.Pinned);
                }
                else
                {
                    callbackPtr = (IntPtr)pinnedLoaderFunc.Target;
                }

                dll_hx_set_loader(callbackPtr);

                NDLLFunction ndllFunc = new NDLLFunction(module, cfunc, numArgs);
                module = IntPtr.Zero;
                return ndllFunc;
            }
            finally
            {
                if (module != IntPtr.Zero)
                    NativeMethods.FreeLibraryWrap(module);
            }
        }

        public object CallMult(Array args)
        {
            if (numArgs != -1)
                throw new InvalidOperationException();
            
            Array<object> hxArray = (Array<object>)args;
            CSHandleScope scope = CSHandleScope.Create();
            GCHandle[] handles = new GCHandle[hxArray.length];
            for (int i = 0; i < hxArray.length; ++i)
                handles[i] = GCHandle.Alloc(hxArray[i]);
            IntPtr[] pointers = new IntPtr[hxArray.length];
            for (int i = 0; i < hxArray.length; ++i)
                pointers[i] = GCHandle.ToIntPtr(handles[i]);
            GCHandle pinnedArray = GCHandle.Alloc(pointers, GCHandleType.Pinned);

            CallMultDelegate cfunc = (CallMultDelegate)func;
            object result = HandleUtils.GetObjectFromIntPtr(cfunc(pinnedArray.AddrOfPinnedObject()));
            scope.Destroy();
            for (int i = 0; i < hxArray.length; ++i)
                handles[i].Free();
            pinnedArray.Free();
            return result;
        }

        public object Call0()
        {
            if (numArgs != 0)
                throw new InvalidOperationException();

            CSHandleScope scope = CSHandleScope.Create();
            Call0Delegate cfunc = (Call0Delegate)func;
            object result = HandleUtils.GetObjectFromIntPtr(cfunc());
            scope.Destroy();
            return result;
        }

        public object Call1(object arg1)
        {
            if (numArgs != 1)
                throw new InvalidOperationException();

            CSHandleScope scope = CSHandleScope.Create();
            Call1Delegate cfunc = (Call1Delegate)func;
            GCHandle gch1 = GCHandle.Alloc(arg1);
            object result = HandleUtils.GetObjectFromIntPtr(cfunc(GCHandle.ToIntPtr(gch1)));
            scope.Destroy();
            gch1.Free();
            return result;
        }

        public object Call2(object arg1, object arg2)
        {
            if (numArgs != 2)
                throw new InvalidOperationException();

            CSHandleScope scope = CSHandleScope.Create();
            Call2Delegate cfunc = (Call2Delegate)func;
            GCHandle gch1 = GCHandle.Alloc(arg1);
            GCHandle gch2 = GCHandle.Alloc(arg2);
            object result = HandleUtils.GetObjectFromIntPtr(cfunc(GCHandle.ToIntPtr(gch1), GCHandle.ToIntPtr(gch2)));
            scope.Destroy();
            gch1.Free();
            gch2.Free();
            return result;
        }

        public object Call3(object arg1, object arg2, object arg3)
        {
            if (numArgs != 3)
                throw new InvalidOperationException();

            CSHandleScope scope = CSHandleScope.Create();
            Call3Delegate cfunc = (Call3Delegate)func;
            GCHandle gch1 = GCHandle.Alloc(arg1);
            GCHandle gch2 = GCHandle.Alloc(arg2);
            GCHandle gch3 = GCHandle.Alloc(arg3);
            object result = HandleUtils.GetObjectFromIntPtr(cfunc(GCHandle.ToIntPtr(gch1), GCHandle.ToIntPtr(gch2), GCHandle.ToIntPtr(gch3)));
            scope.Destroy();
            gch1.Free();
            gch2.Free();
            gch3.Free();
            return result;
        }

        public object Call4(Object arg1, Object arg2, Object arg3, Object arg4)
        {
            if (numArgs != 4)
                throw new InvalidOperationException();

            CSHandleScope scope = CSHandleScope.Create();
            Call4Delegate cfunc = (Call4Delegate)func;
            GCHandle gch1 = GCHandle.Alloc(arg1);
            GCHandle gch2 = GCHandle.Alloc(arg2);
            GCHandle gch3 = GCHandle.Alloc(arg3);
            GCHandle gch4 = GCHandle.Alloc(arg4);
            object result = HandleUtils.GetObjectFromIntPtr(cfunc(GCHandle.ToIntPtr(gch1), GCHandle.ToIntPtr(gch2), GCHandle.ToIntPtr(gch3), GCHandle.ToIntPtr(gch4)));
            scope.Destroy();
            gch1.Free();
            gch2.Free();
            gch3.Free();
            gch4.Free();
            return result;
        }

        public Object Call5(Object arg1, Object arg2, Object arg3, Object arg4, Object arg5)
        {
            if (numArgs != 5)
                throw new InvalidOperationException();

            CSHandleScope scope = CSHandleScope.Create();
            Call5Delegate cfunc = (Call5Delegate)func;
            GCHandle gch1 = GCHandle.Alloc(arg1);
            GCHandle gch2 = GCHandle.Alloc(arg2);
            GCHandle gch3 = GCHandle.Alloc(arg3);
            GCHandle gch4 = GCHandle.Alloc(arg4);
            GCHandle gch5 = GCHandle.Alloc(arg5);
            object result = HandleUtils.GetObjectFromIntPtr(cfunc(GCHandle.ToIntPtr(gch1),
                GCHandle.ToIntPtr(gch2), GCHandle.ToIntPtr(gch3), GCHandle.ToIntPtr(gch4), GCHandle.ToIntPtr(gch5)));
            scope.Destroy();
            gch1.Free();
            gch2.Free();
            gch3.Free();
            gch4.Free();
            gch5.Free();
            return result;
        }
    }
}
