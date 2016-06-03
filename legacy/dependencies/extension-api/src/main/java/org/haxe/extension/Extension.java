package org.haxe.extension;


import android.app.Activity;
import android.content.res.AssetManager;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;


public class Extension {
	
	
	public static AssetManager assetManager;
	public static Handler callbackHandler;
	public static Activity mainActivity;
	public static Context mainContext;
	public static View mainView;
	public static String packageName;
	
	
	/**
	 * Called when an activity you launched exits, giving you the requestCode 
	 * you started it with, the resultCode it returned, and any additional data 
	 * from it.
	 */
	public boolean onActivityResult (int requestCode, int resultCode, Intent data) {
		
		return true;
		
	}
	
	
	public boolean onBackPressed () {
		
		return true;
		
	}
	
	
	/**
	 * Called when the activity is starting.
	 */
	public void onCreate (Bundle savedInstanceState) {
		
		
		
	}
	
	
	/**
	 * Perform any final cleanup before an activity is destroyed.
	 */
	public void onDestroy () {
		
		
		
	}
	
	
	/**
	 * Called when the overall system is running low on memory, 
	 * and actively running processes should trim their memory usage.
	 * This is a backwards compatibility method as it is called at the same time as 
	 * onTrimMemory(TRIM_MEMORY_COMPLETE).
	 */
	public void onLowMemory () {
		
		
		
	}
	
	
	/**
	 * Called when the a new Intent is received
	 */
	public void onNewIntent (Intent intent) {
		
		
		
	}
	
	
	/**
	 * Called as part of the activity lifecycle when an activity is going into
	 * the background, but has not (yet) been killed.
	 */
	public void onPause () {
		
		
		
	}
	
	
	/**
	 * Called after {@link #onStop} when the current activity is being 
	 * re-displayed to the user (the user has navigated back to it).
	 */
	public void onRestart () {
		
		
		
	}
	
	
	/**
	 * Called after {@link #onRestart}, or {@link #onPause}, for your activity 
	 * to start interacting with the user.
	 */
	public void onResume () {
		
		
		
	}
	
	
	/**
	 * Called after {@link #onCreate} &mdash; or after {@link #onRestart} when  
	 * the activity had been stopped, but is now again being displayed to the 
	 * user.
	 */
	public void onStart () {
		
		
		
	}
	
	
	/**
	 * Called when the activity is no longer visible to the user, because 
	 * another activity has been resumed and is covering this one. 
	 */
	public void onStop () {
		
		
		
	}
	
	
	/**
	 * Called when the operating system has determined that it is a
	 * good time for a process to trim unneeded memory from its process.
	 * 
	 * See http://developer.android.com/reference/android/content/ComponentCallbacks2.html for the level explanation.
	 */
	public void onTrimMemory (int level) {
		
		
		
	}
	
	
}