using System;
using System.Runtime.InteropServices;

namespace cs.ndll
{
	class DelegateConverter<T> : IDisposable
    {
        private T func;
        private IntPtr funcPtr;
        private GCHandle handle;

        internal DelegateConverter(T func)
        {
            this.func = func;
        }

        ~DelegateConverter()
        {
            Dispose(false);
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        private void Dispose(bool disposing)
        {
            if (!handle.IsAllocated)
                return;

            handle.Free();
        }

        internal IntPtr ToPointer()
        {
            if (!handle.IsAllocated)
            {
                funcPtr = Marshal.GetFunctionPointerForDelegate(func as Delegate);
                handle = GCHandle.Alloc(funcPtr, GCHandleType.Pinned);
            }
            return (IntPtr)handle.Target;
        }
    }
}