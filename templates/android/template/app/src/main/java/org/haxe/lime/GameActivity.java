package org.haxe.lime;


import android.content.Context;
import android.content.Intent;
import android.content.res.AssetManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Vibrator;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.KeyCharacterMap;
import android.view.KeyEvent;
import android.view.View;
import android.webkit.MimeTypeMap;
import org.haxe.extension.Extension;
import org.libsdl.app.SDLActivity;

import java.io.File;
import java.util.ArrayList;
import java.util.List;


public class GameActivity extends SDLActivity {


	private static AssetManager assetManager;
	private static List<Extension> extensions;
	private static DisplayMetrics metrics;

	public Handler handler;


	public static double getDisplayXDPI () {

		if (metrics == null) {

			metrics = new DisplayMetrics ();
			Extension.mainActivity.getWindowManager ().getDefaultDisplay ().getMetrics (metrics);

		}

		return metrics.xdpi;

	}


	protected String[] getLibraries () {

		return new String[] {
			::foreach ndlls::"::name::",
			::end::"ApplicationMain"
		};

	}


	@Override protected String getMainSharedObject () {

		return "libApplicationMain.so";

	}


	@Override protected String getMainFunction () {

		return "hxcpp_main";

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


	::if (ANDROID_TARGET_SDK_VERSION >= 23)::
	@Override public void onRequestPermissionsResult (int requestCode, String permissions[], int[] grantResults) {

		for (Extension extension : extensions) {

			if (!extension.onRequestPermissionsResult (requestCode, permissions, grantResults)) {

				return;

			}

		}

		super.onRequestPermissionsResult (requestCode, permissions, grantResults);

	}
	::end::


	@Override protected void onRestart () {

		super.onRestart ();

		for (Extension extension : extensions) {

			extension.onRestart ();

		}

	}


	@Override protected void onResume () {

		super.onResume ();

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


	public static void openFile (String path) {

		try {

			String extension = path;
			int index = path.lastIndexOf ('.');

			if (index > 0) {

				extension = path.substring (index + 1);

			}

			String mimeType = MimeTypeMap.getSingleton ().getMimeTypeFromExtension (extension);
			File file = new File (path);

			Intent intent = new Intent ();
			intent.setAction (Intent.ACTION_VIEW);
			intent.setDataAndType (Uri.fromFile (file), mimeType);

			Extension.mainActivity.startActivity (intent);

		} catch (Exception e) {

			Log.e ("GameActivity", e.toString ());
			return;

		}

	}


	public static void openURL (String url, String target) {

		Intent browserIntent = new Intent (Intent.ACTION_VIEW).setData (Uri.parse (url));

		try {

			Extension.mainActivity.startActivity (browserIntent);

		} catch (Exception e) {

			Log.e ("GameActivity", e.toString ());
			return;

		}

	}


	public static void postUICallback (final long handle) {

		Extension.callbackHandler.post (new Runnable () {

			@Override public void run () {

				Lime.onCallback (handle);

			}

		});

	}


	public static void vibrate (int period, int duration) {

		Vibrator v = (Vibrator)mSingleton.getSystemService (Context.VIBRATOR_SERVICE);

		if (period == 0) {

			v.vibrate (duration);

		} else {

			int periodMS = (int)Math.ceil (period / 2);
			int count = (int)Math.ceil ((duration / period) * 2);
			long[] pattern = new long[count];

			for (int i = 0; i < count; i++) {

				pattern[i] = periodMS;

			}

			v.vibrate (pattern, -1);

		}

	}


}
