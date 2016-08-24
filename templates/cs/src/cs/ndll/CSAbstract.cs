using System;
using System.Runtime.InteropServices;

namespace cs.ndll
{
    class CSAbstract : IDisposable
    {
        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        internal delegate IntPtr FinalizerDelegate(IntPtr arg1);

        internal IntPtr Pointer { get; private set; }
        internal int Kind { get; private set; }
        private FinalizerDelegate finalizer;
        internal FinalizerDelegate Finalizer
        {
            get
            {
                return finalizer;
            }
            set
            {
                if (disposed && value != null)
                    throw new InvalidOperationException("Tried to set finalizer to disposed CSAbstract");
                if (finalizer != null && value != null)
                    throw new InvalidOperationException("Finalizer is already set");

                finalizer = value;
                if (finalizer == null)
                {
                    GC.SuppressFinalize(this);
                    disposed = true;
                }
            }
        }
        private bool disposed;

        internal CSAbstract(int kind, IntPtr ptr)
        {
            Pointer = ptr;
            Kind = kind;
            disposed = false;
        }

        public void Dispose()
        {
            Dispose(true);
            GC.SuppressFinalize(this);
        }

        private void Dispose(bool disposing)
        {
            if (disposed)
                return;
            disposed = true;
            if (finalizer == null)
                return;

            GCHandle handle = GCHandle.Alloc(this, GCHandleType.Normal);
            finalizer(GCHandle.ToIntPtr(handle));
            handle.Free();
        }

        public void Free()
        {
            Pointer = IntPtr.Zero;
            finalizer = null;
            disposed = true;
            GC.SuppressFinalize(this);
        }

        ~CSAbstract()
        {
            Dispose(false);
        }
    }
}