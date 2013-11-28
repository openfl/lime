package org.haxe.lime;


import android.app.Activity;
import android.content.res.AssetFileDescriptor;
import android.content.res.AssetManager;
import android.content.res.Configuration;
import android.content.Context;
import android.content.Intent;
import android.content.SharedPreferences;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.net.Uri;
import android.os.Build;
import android.os.Bundle;
import android.os.Environment;
import android.os.Handler;
import android.os.Vibrator;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.inputmethod.InputMethodManager;
import android.view.View;
import android.view.ViewGroup;
import android.view.Window;
import android.view.WindowManager;
import dalvik.system.DexClassLoader;
import java.io.File;
import java.io.FileOutputStream;
import java.io.InputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.lang.reflect.Constructor;
import java.lang.Math;
import java.lang.Runnable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.Locale;
import java.util.List;
import org.haxe.extension.Extension;
import org.haxe.HXCPP;


public class GameActivity extends Activity implements SensorEventListener {
	
	
	private static final int DEVICE_ORIENTATION_UNKNOWN = 0;
	private static final int DEVICE_ORIENTATION_PORTRAIT = 1;
	private static final int DEVICE_ORIENTATION_PORTRAIT_UPSIDE_DOWN = 2;
	private static final int DEVICE_ORIENTATION_LANDSCAPE_RIGHT = 3;
	private static final int DEVICE_ORIENTATION_LANDSCAPE_LEFT = 4;
	private static final int DEVICE_ORIENTATION_FACE_UP = 5;
	private static final int DEVICE_ORIENTATION_FACE_DOWN = 6;
	private static final int DEVICE_ROTATION_0 = 0;
	private static final int DEVICE_ROTATION_90 = 1;
	private static final int DEVICE_ROTATION_180 = 2;
	private static final int DEVICE_ROTATION_270 = 3;
	private static final String GLOBAL_PREF_FILE = "nmeAppPrefs";
	
	private static float[] accelData = new float[3];
	private static GameActivity activity;
	private static AssetManager mAssets;
	private static int bufferedDisplayOrientation = -1;
	private static int bufferedNormalOrientation = -1;
	private static Context mContext;
	private static List<Extension> extensions;
	private static float[] inclinationMatrix = new float[16];
	private static HashMap<String, Class> mLoadedClasses = new HashMap<String, Class>();
	private static float[] magnetData = new float[3];
	private static DisplayMetrics metrics;
	private static float[] orientData = new float[3];
	private static float[] rotationMatrix = new float[16];
	private static SensorManager sensorManager;
	
	public Handler mHandler;
	
	private static MainView mMainView;
	private MainView mView;
	private Sound _sound;
	
	
	protected void onCreate (Bundle state) {
		
		super.onCreate (state);
		
		activity = this;
		mContext = this;
		mHandler = new Handler ();
		mAssets = getAssets ();
		
		Extension.assetManager = mAssets;
		Extension.callbackHandler = mHandler;
		Extension.mainActivity = this;
		Extension.mainContext = this;
		
		_sound = new Sound (getApplication ());
		//getResources().getAssets();
		
		requestWindowFeature (Window.FEATURE_NO_TITLE);
		::if WIN_FULLSCREEN::
		getWindow ().addFlags (WindowManager.LayoutParams.FLAG_FULLSCREEN | WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON);
		::end::
		
		metrics = new DisplayMetrics ();
		getWindowManager ().getDefaultDisplay ().getMetrics (metrics);
		
		// Pre-load these, so the C++ knows where to find them
		
		//if (mMainView == null) {
			
			Log.d ("lime", "mMainView is NULL");
			
			::foreach ndlls::
			System.loadLibrary ("::name::");::end::
			HXCPP.run ("ApplicationMain");
			
			//mMainView = new MainView (getApplication (), this);
			
		/*} else {
			
			ViewGroup parent = (ViewGroup)mMainView.getParent ();
			
			if (parent != null) {
				
				parent.removeView (mMainView);
				
			}
			
			mMainView.onResume ();
			
		}
		
		mView = mMainView;*/
		mView = new MainView (getApplication (), this);
		setContentView (mView);
		
		sensorManager = (SensorManager)activity.getSystemService (Context.SENSOR_SERVICE);
		
		if (sensorManager != null) {
			
			sensorManager.registerListener (this, sensorManager.getDefaultSensor (Sensor.TYPE_ACCELEROMETER), SensorManager.SENSOR_DELAY_GAME);
			sensorManager.registerListener (this, sensorManager.getDefaultSensor (Sensor.TYPE_MAGNETIC_FIELD), SensorManager.SENSOR_DELAY_GAME);
			
		}
		
		if (extensions == null) {
			
			extensions = new ArrayList<Extension>();
			::if (ANDROID_EXTENSIONS != null)::::foreach ANDROID_EXTENSIONS::
			extensions.add (new ::__current__:: ());::end::::end::
			
		}
		
		for (Extension extension : extensions) {
			
			extension.onCreate (state);
			
		}
		
	}
	
	
	public static double CapabilitiesGetPixelAspectRatio () {
		
		return metrics.xdpi / metrics.ydpi;
		
	}
	
	
	public static double CapabilitiesGetScreenDPI () {
		
		return metrics.xdpi;
		
	}
	
	
	public static double CapabilitiesGetScreenResolutionX () {
		
		return metrics.widthPixels;
		
	}
	
	
	public static double CapabilitiesGetScreenResolutionY () {
		
		return metrics.heightPixels;
		
	}
	
	
	public static String CapabilitiesGetLanguage () {
		
		return Locale.getDefault ().getLanguage ();
		
	}
	
	
	public static void clearUserPreference (String inId) {
		
		SharedPreferences prefs = activity.getSharedPreferences (GLOBAL_PREF_FILE, MODE_PRIVATE);
		SharedPreferences.Editor prefEditor = prefs.edit ();
		prefEditor.putString (inId, "");
		prefEditor.commit ();
		
	}
	
	
	public void doPause () {
		
		_sound.doPause ();
		
		mView.sendActivity (Lime.DEACTIVATE);
		mView.onPause ();
		
		if (sensorManager != null) {
			
			sensorManager.unregisterListener (this);
			
		}
		
	}
	
	
	public void doResume () {
			
		mView.onResume ();
		
		_sound.doResume ();
		
		mView.sendActivity (Lime.ACTIVATE);
		
		if (sensorManager != null) {
			
			sensorManager.registerListener (this, sensorManager.getDefaultSensor (Sensor.TYPE_ACCELEROMETER), SensorManager.SENSOR_DELAY_GAME);
			sensorManager.registerListener (this, sensorManager.getDefaultSensor (Sensor.TYPE_MAGNETIC_FIELD), SensorManager.SENSOR_DELAY_GAME);
			
		}
		
	}
	
	
	public static AssetManager getAssetManager () {
		
		return mAssets;
		
	}
	
	
	public static Context getContext () {
		
		return mContext;
		
	}
	
	
	public static GameActivity getInstance () {
		
		return activity;
		
	}
	
	
	public static MainView getMainView () {
		
		return activity.mView;
		
	}
	
	
	public static byte[] getResource (String inResource) {
		
		try {
			
			InputStream inputStream = mAssets.open (inResource, AssetManager.ACCESS_BUFFER);
			long length = inputStream.available ();
			byte[] result = new byte[(int)length];
			inputStream.read (result);
			inputStream.close ();
			return result;
			
		} catch (IOException e) {
			
			Log.e ("GameActivity",  "getResource" + ":" + e.toString ());
			
		}
		
		return null;
		
	}
	
	
	public static int getResourceID (String inFilename) {
		
		//::foreach assets::::if (type == "music")::if (inFilename.equals("::id::")) return ::APP_PACKAGE::.R.raw.::flatName::;
		//::end::::end::
		//::foreach assets::::if (type == "sound")::if (inFilename.equals("::id::")) return ::APP_PACKAGE::.R.raw.::flatName::;
		//::end::::end::
		return -1;
		
	}
	
	
	static public String getSpecialDir (int inWhich) {
		
		Log.v ("GameActivity", "Get special Dir " + inWhich);
		File path = null;
		
		switch (inWhich) {
			
			case 0: // App
				return mContext.getPackageCodePath ();
			
			case 1: // Storage
				path = mContext.getFilesDir ();
				break;
			
			case 2: // Desktop
				path = Environment.getDataDirectory ();
				break;
			
			case 3: // Docs
				path = Environment.getExternalStorageDirectory ();
				break;
			
			case 4: // User
				path = mContext.getExternalFilesDir (Environment.DIRECTORY_DOWNLOADS);
				break;
			
		}
		
		return path == null ? "" : path.getAbsolutePath ();
		
	}
	
	
	public static String getUserPreference (String inId) {
		
		SharedPreferences prefs = activity.getSharedPreferences (GLOBAL_PREF_FILE, MODE_PRIVATE);
		return prefs.getString (inId, "");
		
	}
	
	
	public static void launchBrowser (String inURL) {
		
		Intent browserIntent = new Intent (Intent.ACTION_VIEW).setData (Uri.parse (inURL));
		
		try {
			
			activity.startActivity (browserIntent);
			
		} catch (Exception e) {
			
			Log.e ("GameActivity", e.toString ());
			return;
			
		}
		
	}
	
	
	private void loadNewSensorData (SensorEvent event) {
		
		final int type = event.sensor.getType ();
		
		if (type == Sensor.TYPE_ACCELEROMETER) {
			
			accelData = event.values.clone ();
			Lime.onAccelerate (-accelData[0], -accelData[1], accelData[2]);
			
		}
		
		if (type == Sensor.TYPE_MAGNETIC_FIELD) {
			
			magnetData = event.values.clone ();
			//Log.d("GameActivity","new mag: " + magnetData[0] + ", " + magnetData[1] + ", " + magnetData[2]);
			
		}
		
	}
	
	
	@Override public void onAccuracyChanged (Sensor sensor, int accuracy) {
		
		
		
	}
	
	
	@Override protected void onActivityResult (int requestCode, int resultCode, Intent data) {
		
		for (Extension extension : extensions) {
			
			if (!extension.onActivityResult (requestCode, resultCode, data)) {
				
				return;
				
			}
			
		}
		
		super.onActivityResult (requestCode, resultCode, data);
		
	}
	
	
	@Override protected void onDestroy () {
		
		for (Extension extension : extensions) {
			
			extension.onDestroy ();
			
		}
		
		// TODO: Wait for result?
		mView.sendActivity (Lime.DESTROY);
		activity = null;
		super.onDestroy ();
		
	}
	
	
	@Override protected void onPause () {
		
		doPause ();
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
		doResume();
		
		for (Extension extension : extensions) {
			
			extension.onResume ();
			
		}
		
	}
	
	
	@Override public void onSensorChanged (SensorEvent event) {
		
		loadNewSensorData (event);
		
		if (accelData != null && magnetData != null) {
			
			boolean foundRotationMatrix = SensorManager.getRotationMatrix (rotationMatrix, inclinationMatrix, accelData, magnetData);
			
			if (foundRotationMatrix) {
				
				SensorManager.getOrientation (rotationMatrix, orientData);
				Lime.onOrientationUpdate (orientData[0], orientData[1], orientData[2]);
				
			}
			
		}
		
		Lime.onDeviceOrientationUpdate (prepareDeviceOrientation ());
		Lime.onNormalOrientationFound (bufferedNormalOrientation);
		
	}
	
	
	@Override protected void onStart () {
		
		super.onStart();
		
		::if WIN_FULLSCREEN::::if (ANDROID_TARGET_SDK_VERSION >= 16)::
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
			
			getWindow().getDecorView().setSystemUiVisibility (View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN | View.SYSTEM_UI_FLAG_LAYOUT_STABLE | View.SYSTEM_UI_FLAG_LOW_PROFILE | View.SYSTEM_UI_FLAG_FULLSCREEN);
			
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
	
	
	public static void popView () {
		
		activity.setContentView (activity.mView);
		activity.doResume ();
		
	}
	
	
	public static void postUICallback (final long inHandle) {
		
		activity.mHandler.post (new Runnable () {
			
			@Override public void run () {
				
				Lime.onCallback (inHandle);
				
			}
			
		});
		
	}
	
	
	private int prepareDeviceOrientation () {
		
		int rawOrientation = getWindow ().getWindowManager ().getDefaultDisplay ().getOrientation ();
		
		if (rawOrientation != bufferedDisplayOrientation) {
			
			bufferedDisplayOrientation = rawOrientation;
			
		}
		
		int screenOrientation = getResources ().getConfiguration ().orientation;
		int deviceOrientation = DEVICE_ORIENTATION_UNKNOWN;
		
		if (bufferedNormalOrientation < 0) {
			
			switch (screenOrientation) {
				
				case Configuration.ORIENTATION_LANDSCAPE:
					
					switch (bufferedDisplayOrientation) {
						
						case DEVICE_ROTATION_0:
						case DEVICE_ROTATION_180:
							bufferedNormalOrientation = DEVICE_ORIENTATION_LANDSCAPE_LEFT;
							break;
						
						case DEVICE_ROTATION_90:
						case DEVICE_ROTATION_270:
							bufferedNormalOrientation = DEVICE_ORIENTATION_PORTRAIT;
							break;
						
						default:
							bufferedNormalOrientation = DEVICE_ORIENTATION_UNKNOWN;
						
					}
					
					break;
				
				case Configuration.ORIENTATION_PORTRAIT:
					
					switch (bufferedDisplayOrientation) {
						
						case DEVICE_ROTATION_0:
						case DEVICE_ROTATION_180:
							bufferedNormalOrientation = DEVICE_ORIENTATION_PORTRAIT;
							break;
						
						case DEVICE_ROTATION_90:
						case DEVICE_ROTATION_270:
							bufferedNormalOrientation = DEVICE_ORIENTATION_LANDSCAPE_LEFT;
							break;
						
						default:
							bufferedNormalOrientation = DEVICE_ORIENTATION_UNKNOWN;
						
					}
					
					break;
				
				default: // ORIENTATION_SQUARE OR ORIENTATION_UNDEFINED
					bufferedNormalOrientation = DEVICE_ORIENTATION_UNKNOWN;
				
			}
			
		}
		
		switch (screenOrientation) {
			
			case Configuration.ORIENTATION_LANDSCAPE:
				
				switch (bufferedDisplayOrientation) {
					
					case DEVICE_ROTATION_0:
					case DEVICE_ROTATION_270:
						deviceOrientation = DEVICE_ORIENTATION_LANDSCAPE_LEFT;
						break;
					
					case DEVICE_ROTATION_90:
					case DEVICE_ROTATION_180:
						deviceOrientation = DEVICE_ORIENTATION_LANDSCAPE_RIGHT;
						break;
					
					default: // impossible!
						deviceOrientation = DEVICE_ORIENTATION_UNKNOWN;
					
				}
				
				break;
			
			case Configuration.ORIENTATION_PORTRAIT:
				
				switch (bufferedDisplayOrientation) {
					
					case DEVICE_ROTATION_0:
					case DEVICE_ROTATION_90:
						deviceOrientation = DEVICE_ORIENTATION_PORTRAIT;
						break;
					
					case DEVICE_ROTATION_180:
					case DEVICE_ROTATION_270:
						deviceOrientation = DEVICE_ORIENTATION_PORTRAIT_UPSIDE_DOWN;
						break;
					
					default: // impossible!
						deviceOrientation = DEVICE_ORIENTATION_UNKNOWN;
				}
				
				break;
			
			default: // ORIENTATION_SQUARE OR ORIENTATION_UNDEFINED
				deviceOrientation = DEVICE_ORIENTATION_UNKNOWN;
			
		}
		
		return deviceOrientation;
		
	}
	
	
	public static void pushView (View inView) {
		
		activity.doPause ();
		activity.setContentView (inView);
		
	}
	
	
	public void queueRunnable (Runnable runnable) {
		
		Log.e ("GameActivity", "queueing...");
		
	}
	
	
	public static void registerExtension (Extension extension) {
		
		if (extensions.indexOf (extension) == -1) {
			
			extensions.add (extension);
			
		}
		
	}
	
	
	public static void showKeyboard (boolean show) {
		
		InputMethodManager mgr = (InputMethodManager)activity.getSystemService (Context.INPUT_METHOD_SERVICE);
		mgr.hideSoftInputFromWindow (activity.mView.getWindowToken (), 0);
		
		if (show) {
			
			mgr.toggleSoftInput (InputMethodManager.SHOW_FORCED, 0);
			// On the Nexus One, SHOW_FORCED makes it impossible
			// to manually dismiss the keyboard.
			// On the Droid SHOW_IMPLICIT doesn't bring up the keyboard.
			
		}
		
	}
	
	
	public static void setUserPreference (String inId, String inPreference) {
		
		SharedPreferences prefs = activity.getSharedPreferences (GLOBAL_PREF_FILE, MODE_PRIVATE);
		SharedPreferences.Editor prefEditor = prefs.edit ();
		prefEditor.putString (inId, inPreference);
		prefEditor.commit ();
		
	}
	
	
	public static void vibrate (int period, int duration) {
		
		Vibrator v = (Vibrator)activity.getSystemService (Context.VIBRATOR_SERVICE);
		
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