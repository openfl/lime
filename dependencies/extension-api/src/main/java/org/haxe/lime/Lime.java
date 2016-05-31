package org.haxe.lime;


public class Lime {
	
	static {
		
		System.loadLibrary("lime");
		
	}
	
	public static native void onCallback (long inHandle);
	public static native Object callObjectFunction (long inHandle, String function, Object[] args);
	public static native double callNumericFunction (long inHandle, String function, Object[] args);
	public static native void releaseReference (long inHandle);
	
}