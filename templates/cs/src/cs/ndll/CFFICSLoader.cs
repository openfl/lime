using System;
using System.Runtime.InteropServices;
using System.Text;
using haxe.lang;

namespace cs.ndll
{
    class CFFICSLoader
    {
        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        internal delegate IntPtr CFFILoaderDelegate(String inName);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate int ValTypeDelegate(IntPtr arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate int AllocKindDelegate();

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr AllocAbstractDelegate(int arg1, IntPtr arg2);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate void FreeAbstractDelegate(IntPtr arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr ValToKindDelegate(IntPtr arg1, int arg2);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr ValDataDelegate(IntPtr arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr ValArrayIntDelegate(IntPtr arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr AllocBoolDelegate([MarshalAs(UnmanagedType.I1)]bool arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr AllocNullDelegate();

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr CreateRootDelegate(IntPtr inValue);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr QueryRootDelegate(IntPtr inValue);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate void DestroyRootDelegate(IntPtr inValue);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate void ValGCDelegate(IntPtr arg1, CSAbstract.FinalizerDelegate arg2);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate double ValNumberDelegate(IntPtr arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate int ValStrLenDelegate(IntPtr arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr ValStringDelegate(IntPtr arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate int ValIntDelegate(IntPtr arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr AllocIntDelegate(int arg1);
        
        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr AllocArrayDelegate(int arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr AllocArrayTypeDelegate(int arg1, hxValueType arg2);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate int ValArraySizeDelegate(IntPtr arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr ValArrayIDelegate(IntPtr arg1, int arg2);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate void ValArraySetIDelegate(IntPtr arg1, int arg2, IntPtr arg3);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate void ValArrayPushDelegate(IntPtr arg1, IntPtr arg2);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate int ValIdDelegate(String arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate void AllocFieldDelegate(IntPtr arg1, int arg2, IntPtr arg3);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr ValCall0Delegate(IntPtr arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr AllocEmptyObjectDelegate();

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr AllocStringLenDelegate(IntPtr inStr, int inLen);

         [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr AllocWStringLenDelegate(IntPtr inStr, int inLen);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr AllocFloatDelegate(double arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr AllocBufferLenDelegate(int inLen);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr BufferDataDelegate(IntPtr inBuffer);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr BufferValDelegate(IntPtr b);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr ValToBufferDelegate(IntPtr arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate void BufferSetSizeDelegate(IntPtr inBuffer, int inLen);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate int BufferSizeDelegate(IntPtr inBuffer);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr PinBufferDelegate(IntPtr arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate void UnPinBufferDelegate(IntPtr arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr ValFieldDelegate(IntPtr arg1, int arg2);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate bool ValBoolDelegate(IntPtr arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate void ValThrowDelegate(IntPtr arg1);

        [UnmanagedFunctionPointerAttribute(CallingConvention.Cdecl)]
        private delegate IntPtr EmptyDelegate();

        private enum hxValueType
        {
            valtUnknown = -1,
            valtInt = 0xff,
            valtNull = 0,
            valtFloat = 1,
            valtBool = 2,
            valtString = 3,
            valtObject = 4,
            valtArray = 5,
            valtFunction = 6,
            valtEnum,
            valtClass,
            valtRoot = 0xff,
            valtAbstractBase = 0x100,
        };
        
        private static int sgKinds = (int)(hxValueType.valtAbstractBase + 2);

        private static DelegateConverter<ValTypeDelegate> val_type;
        private static DelegateConverter<AllocKindDelegate> alloc_kind;
        private static DelegateConverter<AllocAbstractDelegate> alloc_abstract;
        private static DelegateConverter<FreeAbstractDelegate> free_abstract;
        private static DelegateConverter<ValToKindDelegate> val_to_kind;
        private static DelegateConverter<ValDataDelegate> val_data;
        private static DelegateConverter<ValArrayIntDelegate> val_array_int;
        private static DelegateConverter<AllocBoolDelegate> alloc_bool;
        private static DelegateConverter<AllocNullDelegate> alloc_null;
        private static DelegateConverter<CreateRootDelegate> create_root;
        private static DelegateConverter<QueryRootDelegate> query_root;
        private static DelegateConverter<DestroyRootDelegate> destroy_root;
        private static DelegateConverter<ValGCDelegate> val_gc;
        private static DelegateConverter<ValNumberDelegate> val_number;
        private static DelegateConverter<ValStrLenDelegate> val_strlen;
        private static DelegateConverter<ValStringDelegate> val_string;
        private static DelegateConverter<ValIntDelegate> val_int;
        private static DelegateConverter<AllocIntDelegate> alloc_int;
        private static DelegateConverter<AllocArrayDelegate> alloc_array;
        private static DelegateConverter<AllocArrayTypeDelegate> alloc_array_type;
        private static DelegateConverter<ValArraySizeDelegate> val_array_size;
        private static DelegateConverter<ValArrayIDelegate> val_array_i;
        private static DelegateConverter<ValArraySetIDelegate> val_array_set_i;
        private static DelegateConverter<ValArrayPushDelegate> val_array_push;
        private static DelegateConverter<ValIdDelegate> val_id;
        private static DelegateConverter<AllocFieldDelegate> alloc_field;
        private static DelegateConverter<ValCall0Delegate> val_call0;
        private static DelegateConverter<AllocEmptyObjectDelegate> alloc_empty_object;
        private static DelegateConverter<AllocStringLenDelegate> alloc_string_len;
        private static DelegateConverter<AllocWStringLenDelegate> alloc_wstring_len;
        private static DelegateConverter<AllocFloatDelegate> alloc_float;
        private static DelegateConverter<AllocBufferLenDelegate> alloc_buffer_len;
        private static DelegateConverter<BufferDataDelegate> buffer_data;
        private static DelegateConverter<BufferValDelegate> buffer_val;
        private static DelegateConverter<ValToBufferDelegate> val_to_buffer;
        private static DelegateConverter<BufferSetSizeDelegate> buffer_set_size;
        private static DelegateConverter<BufferSizeDelegate> buffer_size;
        private static DelegateConverter<PinBufferDelegate> pin_buffer;
        private static DelegateConverter<UnPinBufferDelegate> unpin_buffer;
        private static DelegateConverter<ValFieldDelegate> val_field;
        private static DelegateConverter<ValBoolDelegate> val_bool;
         private static DelegateConverter<ValThrowDelegate> val_throw;
        private static DelegateConverter<EmptyDelegate> empty;

        private static int cs_val_type(IntPtr inArg1)
        {
            object arg1 = HandleUtils.GetObjectFromIntPtr(inArg1);
            if (arg1 == null)
                return (int)hxValueType.valtNull;

            if (arg1 is Boolean)
                return (int)hxValueType.valtBool;
            else if (arg1 is sbyte ||
                arg1 is byte ||
                arg1 is short ||
                arg1 is ushort ||
                arg1 is int ||
                arg1 is uint ||
                arg1 is long ||
                arg1 is ulong)
                return (int)hxValueType.valtInt;
            else if (arg1 is float ||
                arg1 is double ||
                arg1 is decimal)
                return (int)hxValueType.valtFloat;
            else if (arg1 is String)
                return (int)hxValueType.valtString;
            else if (arg1 is Array)
                return (int)hxValueType.valtArray;
            else if (arg1 is Function)
                return (int)hxValueType.valtFunction;
            else if (arg1.GetType().IsEnum)
                return (int)hxValueType.valtEnum;
            else if (arg1.GetType().IsClass)
                return (int)hxValueType.valtClass;
            else if (arg1 is DynamicObject)
                return (int)hxValueType.valtObject;
            else if (arg1 is CSAbstract)
                return ((CSAbstract)arg1).Kind;

            return (int)hxValueType.valtUnknown;
        }

        // Abstract types
        private static int cs_alloc_kind()
        {
            return ++sgKinds;
        }

        private static IntPtr cs_alloc_abstract(int arg1, IntPtr arg2)
        {
            return CSHandleContainer.GetCurrent().CreateGCHandle(new CSAbstract(arg1, arg2));
        }

        private static void cs_free_abstract(IntPtr inArg1)
        {
            CSAbstract arg1 = (CSAbstract)HandleUtils.GetObjectFromIntPtr(inArg1);
            arg1.Free();
        }

        private static IntPtr cs_val_to_kind(IntPtr inArg1, int arg2)
        {
            CSAbstract arg1 = (CSAbstract)HandleUtils.GetObjectFromIntPtr(inArg1);
            if (arg1 == null)
                return IntPtr.Zero;

            return arg1.Kind == arg2 ? arg1.Pointer : IntPtr.Zero;
        }

        private static IntPtr cs_val_data(IntPtr inArg1)
        {
            CSAbstract arg1 = (CSAbstract)HandleUtils.GetObjectFromIntPtr(inArg1);
            if (arg1 == null)
                return IntPtr.Zero;

            return arg1.Pointer;
        }

        private static IntPtr cs_val_array_int(IntPtr inArg1)
        {
            Array arg1 = (Array)HandleUtils.GetObjectFromIntPtr(inArg1);
            if (arg1 == null)
                return IntPtr.Zero;
            
            Array<int> intHxArray = arg1 as Array<int>;
            if (intHxArray != null)
                return CSHandleContainer.GetCurrent().GetAddrOfBlittableObject(intHxArray.__a);
            
            return IntPtr.Zero;
        }

        private static IntPtr cs_alloc_bool(bool arg1)
        {
            return CSHandleContainer.GetCurrent().CreateGCHandle(arg1);
        }

        private static IntPtr cs_alloc_null()
        {
            return IntPtr.Zero;
        }

        private static IntPtr cs_create_root(IntPtr inValue)
        {
            object value = HandleUtils.GetObjectFromIntPtr(inValue);
            GCHandle handle = GCHandle.Alloc(new CSPersistent(value));
            return GCHandle.ToIntPtr(handle);
        }

        private static IntPtr cs_query_root(IntPtr inValue)
        {
            CSPersistent persistent = (CSPersistent)HandleUtils.GetObjectFromIntPtr(inValue);
            return CSHandleContainer.GetCurrent().CreateGCHandle(persistent.Value);
        }

        private static void cs_destroy_root(IntPtr inValue)
        {
            GCHandle handle = GCHandle.FromIntPtr(inValue);
            CSPersistent persistent = (CSPersistent)handle.Target;
            handle.Free();
        }

        private static void cs_val_gc(IntPtr inArg1, CSAbstract.FinalizerDelegate arg2)
        {
            object value = HandleUtils.GetObjectFromIntPtr(inArg1);
            if (value == null)
                return;

            if (value is CSAbstract)
            {
                CSAbstract arg1 = (CSAbstract)value;
                arg1.Finalizer = arg2;
            }
            else
            {
                // TODO
            }
        }

        private static double cs_val_number(IntPtr inArg1)
        {
            object arg1 = HandleUtils.GetObjectFromIntPtr(inArg1);
            if (arg1 == null)
                return 0;

            if (arg1 is sbyte)
                return (sbyte)arg1;
            else if (arg1 is byte)
                return (byte)arg1;
            else if (arg1 is short)
                return (short)arg1;
            else if (arg1 is ushort)
                return (ushort)arg1;
            else if (arg1 is int)
                return (int)arg1;
            else if (arg1 is uint)
                return (uint)arg1;
            else if (arg1 is long)
                return (long)arg1;
            else if (arg1 is ulong)
                return (ulong)arg1;
            else if (arg1 is float)
                return (float)arg1;
            else if (arg1 is double)
                return (double)arg1;
            else if (arg1 is decimal)
            {
                decimal d = (decimal)(arg1);
                return decimal.ToDouble(d);
            }

            return 0;
        }

        private static int cs_val_strlen(IntPtr inArg1)
        {
            String arg1 = (String)HandleUtils.GetObjectFromIntPtr(inArg1);
            if (arg1 == null)
                return 0;

            return Encoding.UTF8.GetByteCount(arg1);
        }

        private static IntPtr cs_val_string(IntPtr inArg1)
        {
            String arg1 = (String)HandleUtils.GetObjectFromIntPtr(inArg1);
            if (arg1 == null)
                return IntPtr.Zero;

            CSHandleContainer container = CSHandleContainer.GetCurrent();
            byte[] bytes = System.Text.Encoding.UTF8.GetBytes(arg1);
            IntPtr memory = container.AllocateMemory(sizeof(byte) * (bytes.Length + 1));
            Marshal.Copy(bytes, 0, memory, bytes.Length);
            Marshal.WriteByte(memory, bytes.Length, 0);
            return memory;
        }

        private static int cs_val_int(IntPtr inArg1)
        {
            object arg1 = HandleUtils.GetObjectFromIntPtr(inArg1);
            if (arg1 == null)
                return 0;

            if (arg1 is sbyte)
                return (sbyte)arg1;
            else if (arg1 is byte)
                return (byte)arg1;
            else if (arg1 is short)
                return (short)arg1;
            else if (arg1 is ushort)
                return (ushort)arg1;
            else if (arg1 is int)
                return (int)arg1;
            else if (arg1 is uint)
                return (int)(uint)arg1;
            else if (arg1 is long)
                return (int)(long)arg1;
            else if (arg1 is ulong)
                return (int)(ulong)arg1;
            else if (arg1 is float)
                return (int)(float)arg1;
            else if (arg1 is double)
                return (int)(double)arg1;
            else if (arg1 is decimal)
            {
                decimal d = (decimal)arg1;
                return decimal.ToInt32(d);
            }

            return 0;
        }

        private static IntPtr cs_alloc_int(int arg1)
        {
            return CSHandleContainer.GetCurrent().CreateGCHandle(arg1);
        }

        private static IntPtr cs_alloc_array(int arg1)
        {
            return CSHandleContainer.GetCurrent().CreateGCHandle(new Array<object>(new object[arg1]));
        }

        private static IntPtr cs_alloc_array_type(int arg1, hxValueType arg2)
        {
            Array arr;
            switch(arg2)
            {
                case hxValueType.valtBool:
                    arr = new Array<bool>(new bool[arg1]);
                    break;
                case hxValueType.valtInt:
                    arr = new Array<int>(new int[arg1]);
                    break;
                case hxValueType.valtFloat:
                    arr = new Array<double>(new double[arg1]);
                    break;
                case hxValueType.valtString:
                    arr = new Array<String>(new String[arg1]);
                    break;
                case hxValueType.valtObject:
                    arr = new Array<object>(new object[arg1]);
                    break;
                default:
                    return IntPtr.Zero;
            }
            return CSHandleContainer.GetCurrent().CreateGCHandle(arr);
        }

        private static int cs_val_array_size(IntPtr inArg1)
        {
            object arg1 = HandleUtils.GetObjectFromIntPtr(inArg1);
            if (arg1 is Array<object>)
                return ((Array<object>)arg1).length;
            else if (arg1 is Array<bool>)
                return ((Array<bool>)arg1).length;
            else if (arg1 is Array<byte>)
                return ((Array<byte>)arg1).length;
            else if (arg1 is Array<sbyte>)
                return ((Array<sbyte>)arg1).length;
            else if (arg1 is Array<uint>)
                return ((Array<uint>)arg1).length;
            else if (arg1 is Array<int>)
                return ((Array<int>)arg1).length;
            else if (arg1 is Array<ulong>)
                return ((Array<ulong>)arg1).length;
            else if (arg1 is Array<long>)
                return ((Array<long>)arg1).length;
            else if (arg1 is Array<float>)
                return ((Array<float>)arg1).length;
            else if (arg1 is Array<double>)
                return ((Array<double>)arg1).length;

            return 0;
        }

        private static IntPtr cs_val_array_i(IntPtr inArg1, int arg2)
        {
            Array arg1 = (Array)HandleUtils.GetObjectFromIntPtr(inArg1);
            if (arg1 == null)
                return IntPtr.Zero;

            return CSHandleContainer.GetCurrent().CreateGCHandle(arg1[arg2]);
        }

        private static void cs_val_array_set_i(IntPtr inArg1, int arg2, IntPtr inArg3)
        {
            Array arg1 = (Array)HandleUtils.GetObjectFromIntPtr(inArg1);
            object arg3 = HandleUtils.GetObjectFromIntPtr(inArg3);
            if (arg1 == null)
                return;
            
            arg1[arg2] = arg3;
        }

        private static void cs_val_array_push(IntPtr inArg1, IntPtr inArg2)
        {
            Array<object> arg1 = (Array<object>)HandleUtils.GetObjectFromIntPtr(inArg1);
            object arg2 = HandleUtils.GetObjectFromIntPtr(inArg2);
            if (arg1 == null)
                return;
            
            arg1.push(arg2);
        }

        private static int cs_val_id(String arg1)
        {
            return CSHandleContainer.GetCurrent().GetId(arg1);
        }

        private static void cs_alloc_field(IntPtr inArg1, int arg2, IntPtr inArg3)
        {
            object arg1 = HandleUtils.GetObjectFromIntPtr(inArg1);
            object arg3 = HandleUtils.GetObjectFromIntPtr(inArg3);
            if (arg1 == null)
                throw new ArgumentNullException("Null object set");

            String field = CSHandleContainer.GetCurrent().GetStringFromId(arg2);
            Reflect.setField(arg1, field, arg3);
        }

        private static IntPtr cs_val_field(IntPtr inArg1, int arg2)
        {
            object arg1 = HandleUtils.GetObjectFromIntPtr(inArg1);
            if (arg1 == null)
                throw new ArgumentNullException("Null object get");

            CSHandleContainer container = CSHandleContainer.GetCurrent();
            String field = container.GetStringFromId(arg2);
            return container.CreateGCHandle(Reflect.field(arg1, field));
        }

        private static IntPtr cs_val_call0(IntPtr inArg1)
        {
            Function arg1 = (Function)HandleUtils.GetObjectFromIntPtr(inArg1);
            if (arg1 == null)
                throw new ArgumentNullException("Null function call");

            return CSHandleContainer.GetCurrent().CreateGCHandle(arg1.__hx_invoke0_o());
        }

        private static IntPtr cs_alloc_empty_object()
        {
            return CSHandleContainer.GetCurrent().CreateGCHandle(new DynamicObject());
        }

        private static IntPtr cs_alloc_string_len(IntPtr inStr, int inLen)
        {
            byte[] bytes = new byte[inLen];
            Marshal.Copy(inStr, bytes, 0, inLen);
            String str = Encoding.UTF8.GetString(bytes, 0, inLen);
            return CSHandleContainer.GetCurrent().CreateGCHandle(str);
        }

        private static IntPtr cs_alloc_wstring_len(IntPtr inStr, int inLen)
        {
            byte[] bytes;
            String str;
            int totalLen;
            switch(Environment.OSVersion.Platform)
            {
                case PlatformID.Win32NT:
                case PlatformID.Win32S:
                case PlatformID.Win32Windows:
                    totalLen = inLen * 2;
                    bytes = new byte[totalLen];
                    Marshal.Copy(inStr, bytes, 0, totalLen);
                    str = Encoding.Unicode.GetString(bytes);
                    return CSHandleContainer.GetCurrent().CreateGCHandle(str);
                default:
                    totalLen = inLen * 4;
                    bytes = new byte[totalLen];
                    Marshal.Copy(inStr, bytes, 0, totalLen);
                    str = Encoding.UTF32.GetString(bytes);
                    return CSHandleContainer.GetCurrent().CreateGCHandle(str);
            }
        }

        private static IntPtr cs_alloc_float(double arg1)
        {
            return CSHandleContainer.GetCurrent().CreateGCHandle(arg1);
        }

        private static IntPtr cs_alloc_buffer_len(int inLen)
        {
            byte[] buffer = new byte[inLen];
            return CSHandleContainer.GetCurrent().CreatePinnedGCHandle(buffer);
        }

        private static IntPtr cs_buffer_val(IntPtr b)
        {
            return b;
        }

        private static IntPtr cs_val_to_buffer(IntPtr arg1)
        {
            return arg1;
        }

        private static void cs_buffer_set_size(IntPtr inBuffer, int inLen)
        {
            byte[] buffer = (byte[])HandleUtils.GetObjectFromIntPtr(inBuffer);
            if (buffer != null) {
                System.Array.Resize<byte>(ref buffer, inLen);
            }
        }

        private static int cs_buffer_size(IntPtr inBuffer)
        {
            byte[] buffer = (byte[])HandleUtils.GetObjectFromIntPtr(inBuffer);
            if (buffer == null)
                return 0;

            return buffer.Length;
        }

        private static IntPtr cs_buffer_data(IntPtr inBuffer)
        {
            byte[] buffer = (byte[])HandleUtils.GetObjectFromIntPtr(inBuffer);
            if (buffer == null)
                return IntPtr.Zero;

            return CSHandleContainer.GetCurrent().GetAddrOfBlittableObject(buffer);
        }

        private static IntPtr cs_pin_buffer(IntPtr inBuffer)
        {
            byte[] buffer = (byte[])GCHandle.FromIntPtr(inBuffer).Target;
            return GCHandle.ToIntPtr(GCHandle.Alloc(buffer, GCHandleType.Pinned));
        }

        private static void cs_unpin_buffer(IntPtr inArg1)
        {
            GCHandle handle = GCHandle.FromIntPtr(inArg1);
            handle.Free();
        }

        private static bool cs_val_bool(IntPtr inArg1)
        {
            object arg1 = HandleUtils.GetObjectFromIntPtr(inArg1);
            if (arg1 == null)
                return false;

            return (bool)arg1;
        }

        private static void cs_val_throw(IntPtr inArg1)
        {
            object arg1 = HandleUtils.GetObjectFromIntPtr(inArg1);
            throw new Exception(arg1.ToString());
        }

        private static IntPtr cs_empty() { return IntPtr.Zero; }

        static CFFICSLoader()
        {
            val_type = new DelegateConverter<ValTypeDelegate>(new ValTypeDelegate(cs_val_type));
            alloc_kind = new DelegateConverter<AllocKindDelegate>(new AllocKindDelegate(cs_alloc_kind));
            alloc_abstract = new DelegateConverter<AllocAbstractDelegate>(new AllocAbstractDelegate(cs_alloc_abstract));
            free_abstract = new DelegateConverter<FreeAbstractDelegate>(new FreeAbstractDelegate(cs_free_abstract));
            val_to_kind = new DelegateConverter<ValToKindDelegate>(new ValToKindDelegate(cs_val_to_kind));
            val_data = new DelegateConverter<ValDataDelegate>(new ValDataDelegate(cs_val_data));
            val_array_int = new DelegateConverter<ValArrayIntDelegate>(new ValArrayIntDelegate(cs_val_array_int));
            alloc_bool = new DelegateConverter<AllocBoolDelegate>(new AllocBoolDelegate(cs_alloc_bool));
            alloc_null = new DelegateConverter<AllocNullDelegate>(new AllocNullDelegate(cs_alloc_null));
            create_root = new DelegateConverter<CreateRootDelegate>(new CreateRootDelegate(cs_create_root));
            query_root = new DelegateConverter<QueryRootDelegate>(new QueryRootDelegate(cs_query_root));
            destroy_root = new DelegateConverter<DestroyRootDelegate>(new DestroyRootDelegate(cs_destroy_root));
            val_gc = new DelegateConverter<ValGCDelegate>(new ValGCDelegate(cs_val_gc));
            val_number = new DelegateConverter<ValNumberDelegate>(new ValNumberDelegate(cs_val_number));
            val_strlen = new DelegateConverter<ValStrLenDelegate>(new ValStrLenDelegate(cs_val_strlen));
            val_string = new DelegateConverter<ValStringDelegate>(new ValStringDelegate(cs_val_string));
            val_int = new DelegateConverter<ValIntDelegate>(new ValIntDelegate(cs_val_int));
            alloc_int = new DelegateConverter<AllocIntDelegate>(new AllocIntDelegate(cs_alloc_int));
            alloc_array = new DelegateConverter<AllocArrayDelegate>(new AllocArrayDelegate(cs_alloc_array));
            alloc_array_type = new DelegateConverter<AllocArrayTypeDelegate>(new AllocArrayTypeDelegate(cs_alloc_array_type));
            val_array_size = new DelegateConverter<ValArraySizeDelegate>(new ValArraySizeDelegate(cs_val_array_size));
            val_array_i = new DelegateConverter<ValArrayIDelegate>(new ValArrayIDelegate(cs_val_array_i));
            val_array_set_i = new DelegateConverter<ValArraySetIDelegate>(new ValArraySetIDelegate(cs_val_array_set_i));
            val_array_push = new DelegateConverter<ValArrayPushDelegate>(new ValArrayPushDelegate(cs_val_array_push));
            val_id = new DelegateConverter<ValIdDelegate>(new ValIdDelegate(cs_val_id));
            alloc_field = new DelegateConverter<AllocFieldDelegate>(new AllocFieldDelegate(cs_alloc_field));
            val_call0 = new DelegateConverter<ValCall0Delegate>(new ValCall0Delegate(cs_val_call0));
            alloc_empty_object = new DelegateConverter<AllocEmptyObjectDelegate>(new AllocEmptyObjectDelegate(cs_alloc_empty_object));
            alloc_string_len = new DelegateConverter<AllocStringLenDelegate>(new AllocStringLenDelegate(cs_alloc_string_len));
            alloc_wstring_len = new DelegateConverter<AllocWStringLenDelegate>(new AllocWStringLenDelegate(cs_alloc_wstring_len));
            alloc_float = new DelegateConverter<AllocFloatDelegate>(new AllocFloatDelegate(cs_alloc_float));
            alloc_buffer_len = new DelegateConverter<AllocBufferLenDelegate>(new AllocBufferLenDelegate(cs_alloc_buffer_len));
            buffer_data = new DelegateConverter<BufferDataDelegate>(new BufferDataDelegate(cs_buffer_data));
            buffer_val = new DelegateConverter<BufferValDelegate>(new BufferValDelegate(cs_buffer_val));
            val_to_buffer = new DelegateConverter<ValToBufferDelegate>(new ValToBufferDelegate(cs_val_to_buffer));
            buffer_set_size = new DelegateConverter<BufferSetSizeDelegate>(new BufferSetSizeDelegate(cs_buffer_set_size));
            buffer_size = new DelegateConverter<BufferSizeDelegate>(new BufferSizeDelegate(cs_buffer_size));
            pin_buffer = new DelegateConverter<PinBufferDelegate>(new PinBufferDelegate(cs_pin_buffer));
            unpin_buffer = new DelegateConverter<UnPinBufferDelegate>(new UnPinBufferDelegate(cs_unpin_buffer));
            val_field = new DelegateConverter<ValFieldDelegate>(new ValFieldDelegate(cs_val_field));
            val_bool = new DelegateConverter<ValBoolDelegate>(new ValBoolDelegate(cs_val_bool));
            val_throw = new DelegateConverter<ValThrowDelegate>(new ValThrowDelegate(cs_val_throw));
            empty = new DelegateConverter<EmptyDelegate>(new EmptyDelegate(cs_empty));
        }

        internal static IntPtr Load(String inName)
        {
            switch (inName)
            {
                case "val_type":
                    return val_type.ToPointer();
                case "alloc_kind":
                    return alloc_kind.ToPointer();
                case "alloc_abstract":
                    return alloc_abstract.ToPointer();
                case "free_abstract":
                    return free_abstract.ToPointer();
                case "val_to_kind":
                    return val_to_kind.ToPointer();
                case "val_array_int":
                    return val_array_int.ToPointer();
                case "alloc_bool":
                    return alloc_bool.ToPointer();
                case "alloc_null":
                    return alloc_null.ToPointer();
                case "create_root":
                    return create_root.ToPointer();
                case "query_root":
                    return query_root.ToPointer();
                case "destroy_root":
                    return destroy_root.ToPointer();
                case "val_data":
                    return val_data.ToPointer();
                case "alloc_root":
                    return empty.ToPointer();
                case "val_gc":
                    return val_gc.ToPointer();
                case "val_number":
                    return val_number.ToPointer();
                case "val_strlen":
                    return val_strlen.ToPointer();
                case "val_string":
                    return val_string.ToPointer();
                case "val_int":
                    return val_int.ToPointer();
                case "alloc_int":
                    return alloc_int.ToPointer();
                case "alloc_array":
                    return alloc_array.ToPointer();
                case "alloc_array_type":
                    return alloc_array_type.ToPointer();
                case "val_array_size":
                    return val_array_size.ToPointer();
                case "val_array_i":
                    return val_array_i.ToPointer();
                case "val_array_set_i":
                    return val_array_set_i.ToPointer();
                case "val_array_push":
                    return val_array_push.ToPointer();
                case "val_id":
                    return val_id.ToPointer();
                case "alloc_field":
                    return alloc_field.ToPointer();
                case "val_call0":
                    return val_call0.ToPointer();
                case "alloc_empty_object":
                    return alloc_empty_object.ToPointer();
                case "alloc_string_len":
                    return alloc_string_len.ToPointer();
                case "alloc_wstring_len":
                    return alloc_wstring_len.ToPointer();
                case "alloc_float":
                    return alloc_float.ToPointer();
                case "alloc_buffer_len":
                    return alloc_buffer_len.ToPointer();
                case "buffer_data":
                    return buffer_data.ToPointer();
                case "buffer_val":
                    return buffer_val.ToPointer();
                case "val_to_buffer":
                    return val_to_buffer.ToPointer();
                case "buffer_set_size":
                    return buffer_set_size.ToPointer();
                case "buffer_size":
                    return buffer_size.ToPointer();
                case "pin_buffer":
                    return pin_buffer.ToPointer();
                case "unpin_buffer":
                    return unpin_buffer.ToPointer();
                case "val_field":
                    return val_field.ToPointer();
                case "val_bool":
                    return val_bool.ToPointer();
                case "val_throw":
                    return val_throw.ToPointer();
            }

            return IntPtr.Zero;
        }
    }
}
