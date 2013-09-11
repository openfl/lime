package org.haxe;

// Wrapper for native library

public class HXCPP {
     static boolean mInit = false;

     static public void run(String inClassName) {
         System.loadLibrary(inClassName);

         if (!mInit)
         {
            mInit = true;
            main();
         }
     }
    
     public static native void main(); 
}

