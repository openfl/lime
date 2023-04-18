using System;
using System.Runtime.InteropServices;

namespace cs.ndll
{
    class HandleUtils
    {
        internal static bool IsEmpty(GCHandle handle)
        {
            if (handle == null)
                return true;
            else if (handle.Target == null)
                return true;
            
            return false;
        }

        internal static object GetObjectFromIntPtr(IntPtr ptr)
        {
            if (ptr == IntPtr.Zero)
                return null;

            return GCHandle.FromIntPtr(ptr).Target;
        }
    }
}
