using System;
using System.Runtime.InteropServices;

namespace cs.ndll
{
    class CSPersistent
    {
        internal object Value { get; private set; }

        internal CSPersistent(object value)
        {
            Value = value;
        }

        internal void Destroy()
        {
            Value = null;
        }
    }
}
