package org.haxe.lime;


import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.content.res.AssetManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.os.VibrationEffect;
import android.os.Vibrator;
import android.view.DisplayCutout;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.KeyCharacterMap;
import android.view.KeyEvent;
import android.view.OrientationEventListener;
import android.view.View;
import android.view.WindowInsets;
import android.view.WindowManager;
import android.webkit.MimeTypeMap;
import android.Manifest;
import org.haxe.extension.Extension;
import org.libsdl.app.SDLActivity;

import java.io.File;
import java.util.ArrayList;
import java.util.List;


public class GameActivity extends SDLActivity {


	private static AssetManager assetManager;
	private static List<Extension> extensions;
	private static DisplayMetrics metrics;
	private static DisplayCutout displayCutout;
	private static Vibrator vibrator;
	private static OrientationEventListener orientationListener;
	private static HaxeObject deviceOrientationListener;
	private static int deviceOrientation = SDL_ORIENTATION_UNKNOWN;

	public Handler handler;

	public static void setDeviceOrientationListener (HaxeObject object) {

		deviceOrientationListener = object;
		if (deviceOrientationListener != null)
		{
			deviceOrientationListener.call1("onOrientationChanged", deviceOrientation);
		}

	}

	public static double getDisplayXDPI () {

		if (metrics == null) {

			metrics = Extension.mainContext.getResources ().getDisplayMetrics ();

		}

		return metrics.xdpi;

	}

	public static int[] getDisplaySafeAreaInsets () {

		if (displayCutout == null) {

			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {

				WindowInsets windowInsets = ((GameActivity)Extension.mainContext).getWindow().getDecorView().getRootWindowInsets();

				if (windowInsets != null) {

					displayCutout = windowInsets.getDisplayCutout();

				}
			}
		}

		int[] result = {0, 0, 0, 0};

		if (displayCutout != null) {

			result[0] = displayCutout.getSafeInsetLeft();
			result[1] = displayCutout.getSafeInsetTop();
			result[2] = displayCutout.getSafeInsetRight();
			result[3] = displayCutout.getSafeInsetBottom();

		}

		return result;

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

		orientationListener = new OrientationEventListener(this) {

			public void onOrientationChanged(int degrees) {

				int orientation = SDL_ORIENTATION_UNKNOWN;
				if (degrees >= 315 || (degrees >= 0 && degrees < 45))
				{
					orientation = SDL_ORIENTATION_PORTRAIT;
				}
				else if	(degrees >= 45 && degrees < 135)
				{
					orientation = SDL_ORIENTATION_LANDSCAPE_FLIPPED;
				}
				else if	(degrees >= 135 && degrees < 225)
				{
					orientation = SDL_ORIENTATION_PORTRAIT_FLIPPED;
				}
				else if	(degrees >= 225 && degrees < 315)
				{
					orientation = SDL_ORIENTATION_LANDSCAPE;
				}

				if (deviceOrientation != orientation) {
					deviceOrientation = orientation;
					if (deviceOrientationListener != null)
					{
						deviceOrientationListener.call1("onOrientationChanged", deviceOrientation);
					}
				}

			}

		};

		assetManager = getAssets ();

		if (checkSelfPermission(Manifest.permission.VIBRATE) == PackageManager.PERMISSION_GRANTED) {

			vibrator = (Vibrator)mSingleton.getSystemService (Context.VIBRATOR_SERVICE);

		}

		handler = new Handler (Looper.getMainLooper ());

		Extension.assetManager = assetManager;
		Extension.callbackHandler = handler;
		Extension.mainActivity = this;
		Extension.mainContext = this;
		Extension.mainView = mLayout;
		Extension.packageName = getApplicationContext ().getPackageName ();

		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {

			switch ("::ANDROID_DISPLAY_CUTOUT::") {

				case "always":
					getWindow().getAttributes().layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_ALWAYS;
					break;

				case "never":
					getWindow().getAttributes().layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_NEVER;
					break;

				case "shortEdges":
					getWindow().getAttributes().layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_SHORT_EDGES;
					break;

				case "default":
					getWindow().getAttributes().layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_DEFAULT;
					break;

				default:
					getWindow().getAttributes().layoutInDisplayCutoutMode = WindowManager.LayoutParams.LAYOUT_IN_DISPLAY_CUTOUT_MODE_DEFAULT;
					break;

			}

		}

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

		if (vibrator != null) {

			vibrator.cancel ();

		}

		orientationListener.disable();

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

		orientationListener.enable();

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

		if (vibrator == null || !vibrator.hasVibrator () || period < 0 || duration <= 0) {

			return;

		}

		if (period == 0) {

			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

				vibrator.vibrate (VibrationEffect.createOneShot (duration, VibrationEffect.DEFAULT_AMPLITUDE));

			} else {

				vibrator.vibrate (duration);

			}

		} else {

			// each period has two halves (vibrator off/vibrator on), and each half requires a separate entry in the array
			int periodMS = (int)Math.ceil (period / 2.0);
			int count = (int)Math.ceil (duration / (double) periodMS);
			long[] pattern = new long[count];

			// the first entry is the delay before vibration starts, so leave it as 0
			for (int i = 1; i < count; i++) {

				pattern[i] = periodMS;

			}

			if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {

				vibrator.vibrate (VibrationEffect.createWaveform (pattern, -1));

			} else {

				vibrator.vibrate (pattern, -1);

			}

		}

	}


}
