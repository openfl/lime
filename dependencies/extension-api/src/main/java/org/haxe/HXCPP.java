package org.haxe;


// Wrapper for native library


public class HXCPP {
	
	
	private static boolean mInit = false;
	
	
	public static native void main ();
	
	
	public static void run (String inClassName) {
		
		System.loadLibrary (inClassName);
		
		if (!mInit) {
			
			mInit = true;
			main ();
			
		}
		
	}
	
	
}