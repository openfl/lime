package org.haxe.lime;


import android.content.res.AssetManager;
import android.content.Intent;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.view.View;
import java.util.ArrayList;
import java.util.List;

import org.haxe.extension.Extension;
import org.haxe.HXCPP;
import org.libsdl.app.SDLActivity;


public class GameActivity extends SDLActivity {
	
	
	private static AssetManager assetManager;
	private static List<Extension> extensions;
	
	public Handler handler;
	
	
	public static void postUICallback (final long handle) {
		
		Extension.callbackHandler.post (new Runnable () {
			
			@Override public void run () {
				
				Lime.onCallback (handle);
				
			}
			
		});
		
	}
	
	
	@Override protected void onActivityResult (int requestCode, int resultCode, Intent data) {
		
		for (Extension extension : extensions) {
			
			if (!extension.onActivityResult (requestCode, resultCode, data)) {
				
				return;
				
			}
			
		}
		
		super.onActivityResult (requestCode, resultCode, data);
		
	}
	
	
	@Override public void onBackPressed () {
		
		for (Extension extension : extensions) {
			
			if (!extension.onBackPressed ()) {
				
				return;
				
			}
			
		}
		
		super.onBackPressed ();
		
	}
	
	
	protected void onCreate (Bundle state) {
		
		super.onCreate (state);
		
		assetManager = getAssets ();
		handler = new Handler ();
		
		Extension.assetManager = assetManager;
		Extension.callbackHandler = handler;
		Extension.mainActivity = this;
		Extension.mainContext = this;
		Extension.mainView = mLayout;
		Extension.packageName = getApplicationContext ().getPackageName ();
		
		if (extensions == null) {
			
			extensions = new ArrayList<Extension> ();
			::if (ANDROID_EXTENSIONS != null)::::foreach ANDROID_EXTENSIONS::
			extensions.add (new ::__current__:: ());::end::::end::
			
		}
		
		for (Extension extension : extensions) {
			
			extension.onCreate (state);
			
		}
		
	}
	
	
	@Override protected void onDestroy () {
		
		for (Extension extension : extensions) {
			
			extension.onDestroy ();
			
		}
		
		super.onDestroy ();
		
	}
	
	
	@Override public void onLowMemory () {
		
		super.onLowMemory ();
		
		for (Extension extension : extensions) {
			
			extension.onLowMemory ();
			
		}
		
	}
	
	
	@Override protected void onNewIntent (final Intent intent) {
		
		for (Extension extension : extensions) {
			
			extension.onNewIntent (intent);
			
		}
		
		super.onNewIntent (intent);
		
	}
	
	
	@Override protected void onPause () {
		
		super.onPause ();
		
		for (Extension extension : extensions) {
			
			extension.onPause ();
			
		}
		
	}
	
	
	@Override protected void onRestart () {
		
		super.onRestart ();
		
		for (Extension extension : extensions) {
			
			extension.onRestart ();
			
		}
		
	}
	
	
	@Override protected void onResume () {
		
		super.onResume();
		
		for (Extension extension : extensions) {
			
			extension.onResume ();
			
		}
		
	}
	
	
	@Override protected void onRestoreInstanceState (Bundle savedState) {
		
		super.onRestoreInstanceState (savedState);
		
		for (Extension extension : extensions) {
			
			extension.onRestoreInstanceState (savedState);
			
		}
		
	}
	
	
	@Override protected void onSaveInstanceState (Bundle outState) {
		
		super.onSaveInstanceState (outState);
		
		for (Extension extension : extensions) {
			
			extension.onSaveInstanceState (outState);
			
		}
		
	}
	
	
	@Override protected void onStart () {
		
		super.onStart ();
		
		::if WIN_FULLSCREEN::::if (ANDROID_TARGET_SDK_VERSION < 19)::
		if (Build.VERSION.SDK_INT >= 19) {
			
			getWindow ().getDecorView ().setSystemUiVisibility (View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN | View.SYSTEM_UI_FLAG_LAYOUT_STABLE | View.SYSTEM_UI_FLAG_LOW_PROFILE | View.SYSTEM_UI_FLAG_FULLSCREEN);
			
		}
		::end::::end::
		
		for (Extension extension : extensions) {
			
			extension.onStart ();
			
		}
		
	}
	
	
	@Override protected void onStop () {
		
		super.onStop ();
		
		for (Extension extension : extensions) {
			
			extension.onStop ();
			
		}
		
	}
	
	
	::if (ANDROID_TARGET_SDK_VERSION >= 14)::
	@Override public void onTrimMemory (int level) {
		
		if (Build.VERSION.SDK_INT >= 14) {
			
			super.onTrimMemory (level);
			
			for (Extension extension : extensions) {
				
				extension.onTrimMemory (level);
				
			}
			
		}
		
	}
	::end::
	
	
	@Override public void onWindowFocusChanged(boolean hasFocus) {
		
		super.onWindowFocusChanged (hasFocus);
		
		::if WIN_FULLSCREEN::::if (ANDROID_TARGET_SDK_VERSION >= 19)::
		if (hasFocus) {
			
			if (Build.VERSION.SDK_INT >= 19) {
				
				getWindow ().getDecorView ().setSystemUiVisibility (View.SYSTEM_UI_FLAG_LAYOUT_STABLE | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION | View.SYSTEM_UI_FLAG_FULLSCREEN | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY);
				
			}
			
		}
		::end::::end::
		
	}
	
	
}