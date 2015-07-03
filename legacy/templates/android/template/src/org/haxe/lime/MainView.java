package org.haxe.lime;


import android.app.Activity;
import android.content.Context;
import android.graphics.PixelFormat;
import android.opengl.GLSurfaceView;
import android.os.Build;
import android.os.SystemClock;
import android.text.InputType;
import android.util.AttributeSet;
import android.util.Log;
import android.view.inputmethod.BaseInputConnection;
import android.view.inputmethod.EditorInfo;
import android.view.inputmethod.InputConnection;
::if (ANDROID_TARGET_SDK_VERSION > 11)::import android.view.InputDevice;::end::
import android.view.KeyCharacterMap;
import android.view.KeyEvent;
import android.view.MotionEvent;
import javax.microedition.khronos.egl.EGL10;
import javax.microedition.khronos.egl.EGLConfig;
import javax.microedition.khronos.egl.EGLContext;
import javax.microedition.khronos.egl.EGLDisplay;
import javax.microedition.khronos.opengles.GL10;
import java.util.Timer;
import java.util.TimerTask;


class MainView extends GLSurfaceView {
	
	
	static final int etTouchBegin = 15;
	static final int etTouchMove = 16;
	static final int etTouchEnd = 17;
	static final int etTouchTap = 18;
	static final int resTerminate = -1;
	
	boolean isPollImminent;
	Activity mActivity;
	static MainView mRefreshView;
	Timer mTimer = new Timer ();
	int mTimerID = 0;
	TimerTask pendingTimer;
	Runnable pollMe;
	boolean renderPending = false;
	
	
	public MainView (Context context, Activity inActivity) {
		
		super (context);
		
		isPollImminent = false;
		final MainView me = this;
		
		pollMe = new Runnable () {
			
			@Override public void run () { me.onPoll (); }
			
		};
		
		int eglVersion = 1;
		
		if (::WIN_ALLOW_SHADERS:: || ::WIN_REQUIRE_SHADERS::) {
			
			EGL10 egl = (EGL10)EGLContext.getEGL ();
			EGLDisplay display = egl.eglGetDisplay (EGL10.EGL_DEFAULT_DISPLAY);
			int[] version = new int[2];
			
			egl.eglInitialize (display, version);
			
			EGLConfig[] v2_configs = new EGLConfig[1];
			int[] num_config = new int[1];
			int[] attrs = { EGL10.EGL_RENDERABLE_TYPE, ::if DEFINE_LIME_FORCE_GLES1::1::else::4::end:: /*EGL_OPENGL_ES2_BIT*/, EGL10.EGL_NONE };
			egl.eglChooseConfig (display, attrs, v2_configs, 1, num_config);
			
			if (num_config[0]==1) {
				
				eglVersion = ::if DEFINE_LIME_FORCE_GLES1::1::else::2::end::;
				setEGLContextClientVersion (::if DEFINE_LIME_FORCE_GLES1::1::else::2::end::);
				
			}
			
		}
		
		final int renderType = (eglVersion == 1 ? 0x01 : 0x04);
		
		setEGLConfigChooser (new EGLConfigChooser () {
			
			public EGLConfig chooseConfig (EGL10 egl, EGLDisplay display) {
				
				int depth = ::if WIN_DEPTH_BUFFER::16::else::0::end::;
				int stencil = ::if WIN_STENCIL_BUFFER::8::else::0::end::;
				EGLConfig[] configs = new EGLConfig[1];
				int[] num_config = new int[1];
				
				if (::WIN_ANTIALIASING:: > 1) {
					
					int[] attrs = {
						
						EGL10.EGL_DEPTH_SIZE, depth,
						EGL10.EGL_STENCIL_SIZE, stencil,
						EGL10.EGL_SAMPLE_BUFFERS, 1 /* true */,
						EGL10.EGL_SAMPLES, ::WIN_ANTIALIASING::,
						EGL10.EGL_RENDERABLE_TYPE, renderType,
						EGL10.EGL_NONE
						
					};
					
					egl.eglChooseConfig (display, attrs, configs, 1, num_config);
					
					if (num_config[0] == 1) {
						
						return configs[0];
						
					}
					
					if (::WIN_ANTIALIASING:: > 2) {
						
						int[] attrs_aa2 = {
							
							EGL10.EGL_DEPTH_SIZE, depth,
							EGL10.EGL_STENCIL_SIZE, stencil,
							EGL10.EGL_SAMPLE_BUFFERS, 1 /* true */,
							EGL10.EGL_SAMPLES, 2,
							EGL10.EGL_RENDERABLE_TYPE, renderType,
							EGL10.EGL_NONE
							
						};
						
						egl.eglChooseConfig (display, attrs_aa2, configs, 1, num_config);
						
						if (num_config[0] == 1) {
							
							return configs[0];
							
						}
						
					}
					
					final int EGL_COVERAGE_BUFFERS_NV = 0x30E0;
					final int EGL_COVERAGE_SAMPLES_NV = 0x30E1;
					
					int[] attrs_aanv = {
						
						EGL10.EGL_DEPTH_SIZE, depth,
						EGL10.EGL_STENCIL_SIZE, stencil,
						EGL_COVERAGE_BUFFERS_NV, 1 /* true */,
						EGL_COVERAGE_SAMPLES_NV, 2,  // always 5 in practice on tegra 2
						EGL10.EGL_RENDERABLE_TYPE, renderType,
						EGL10.EGL_NONE
						
					};
					
					egl.eglChooseConfig (display, attrs_aanv, configs, 1, num_config);
					
					if (num_config[0] == 1) {
						
						return configs[0];
						
					}
					
				}
				
				int[] attrs1 = {
					
					EGL10.EGL_DEPTH_SIZE, depth,
					EGL10.EGL_STENCIL_SIZE, stencil,
					EGL10.EGL_RENDERABLE_TYPE, renderType,
					EGL10.EGL_NONE
					
				};
				
				egl.eglChooseConfig (display, attrs1, configs, 1, num_config);
				
				if (num_config[0] == 1) {
					
					return configs[0];
					
				}
				
				int[] attrs2 = {
					
					EGL10.EGL_NONE
					
				};
				
				egl.eglChooseConfig (display, attrs2, configs, 1, num_config);
				
				if (num_config[0] == 1) {
					
					return configs[0];
					
				}
				
				return null;
				
			}
			
		});
		
		mActivity = inActivity;
		mRefreshView = this;
		setFocusable (true);
		setFocusableInTouchMode (true);
		setRenderer (new Renderer (this));
		setRenderMode (GLSurfaceView.RENDERMODE_WHEN_DIRTY);
		
		::if (ANDROID_TARGET_SDK_VERSION > 11)::
		if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB) {
			
			setPreserveEGLContextOnPause (true);
			
		}
		::end::
	}
	
	
	// Haxe Thread
	public void HandleResult (int inCode) {
		
		if (inCode == resTerminate) {
			
			mActivity.finish ();
			return;
			
		}
		
		double wake = Lime.getNextWake ();
		int delayMS = (int)(wake * 1000);
		
		if (renderPending && delayMS < 5) {
			
			delayMS = 5;
			
		}
		
		if (delayMS <= 1) {
			
			queuePoll ();
			
		} else {
			
			if (pendingTimer != null) {
				
				pendingTimer.cancel ();
				
			}
			
			final MainView me = this;
			pendingTimer = new TimerTask () {
				
				@Override public void run () { 
					
					me.queuePoll ();
					
				}
				
			};
			
			mTimer.schedule (pendingTimer, delayMS);
			
		}
		
	}
	
	
	@Override public InputConnection onCreateInputConnection (EditorInfo outAttrs) {
		
		BaseInputConnection inputConnection = new BaseInputConnection (this, false) {
			
			@Override public boolean deleteSurroundingText (int beforeLength, int afterLength) {
				
				::if (ANDROID_TARGET_SDK_VERSION > 15)::
				if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.JELLY_BEAN) {
					
					if (beforeLength == 1 && afterLength == 0) {
						
						final long time = SystemClock.uptimeMillis ();
						
						super.sendKeyEvent (new KeyEvent (time, time, KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_DEL, 0, 0, KeyCharacterMap.VIRTUAL_KEYBOARD, 0, KeyEvent.FLAG_SOFT_KEYBOARD | KeyEvent.FLAG_KEEP_TOUCH_MODE));
						super.sendKeyEvent (new KeyEvent (SystemClock.uptimeMillis(), time, KeyEvent.ACTION_UP, KeyEvent.KEYCODE_DEL, 0, 0, KeyCharacterMap.VIRTUAL_KEYBOARD, 0, KeyEvent.FLAG_SOFT_KEYBOARD | KeyEvent.FLAG_KEEP_TOUCH_MODE));
						
						return true;
						
					}
					
				}
				::end::
				
				return super.deleteSurroundingText (beforeLength, afterLength);
				
			}
			
		};
		
		outAttrs.imeOptions = EditorInfo.IME_FLAG_NO_EXTRACT_UI | 33554432 /* API 11: EditorInfo.IME_FLAG_NO_FULLSCREEN */;
		
		return inputConnection;
		
	}
	
	
	::if (ANDROID_TARGET_SDK_VERSION > 11)::@Override public boolean onGenericMotionEvent (MotionEvent event) {
		
		if ((event.getSource () & InputDevice.SOURCE_CLASS_JOYSTICK) != 0 && event.getAction () == MotionEvent.ACTION_MOVE) {
			
			final MainView me = this;
			final InputDevice device = event.getDevice ();
			final int deviceId = event.getDeviceId ();
			
			int[] axisList = {
				
				android.view.MotionEvent.AXIS_X, android.view.MotionEvent.AXIS_Y, android.view.MotionEvent.AXIS_Z,
				android.view.MotionEvent.AXIS_RX, android.view.MotionEvent.AXIS_RY, android.view.MotionEvent.AXIS_RZ,
				android.view.MotionEvent.AXIS_HAT_X, android.view.MotionEvent.AXIS_HAT_Y,
				android.view.MotionEvent.AXIS_LTRIGGER, android.view.MotionEvent.AXIS_RTRIGGER
				
			};
			
			for (int i = 0; i < axisList.length; i++) {
				
				final int axis = axisList[i];
				final InputDevice.MotionRange range = device.getMotionRange (axis, event.getSource ());
				
				if (range != null) {
					
					final float value = event.getAxisValue (axis);
					
					queueEvent (new Runnable () {
						
						public void run () {
							
							me.HandleResult (Lime.onJoyMotion (deviceId, axis, ((value - range.getMin ()) / (range.getRange ())) * 65535 - 32768));
							
						}
						
					});
						
				}
				
			}
			
			return true;
			
		}
		
		return super.onGenericMotionEvent (event);
		
	}::end::
	
	
	@Override public boolean onKeyDown (final int inKeyCode, KeyEvent event) {
		
		final MainView me = this;
		
		::if (ANDROID_TARGET_SDK_VERSION > 11)::if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB_MR1 && (event.isGamepadButton (inKeyCode) || (inKeyCode >= 19 && inKeyCode <=22))) {
			
			if (event.getRepeatCount () == 0) {
				
				final int deviceId = event.getDeviceId ();
				
				queueEvent (new Runnable () {
					
					public void run () {
						
						me.HandleResult (Lime.onJoyChange (deviceId, inKeyCode, true));
						
					}
					
				});
				
			}
			
			if (inKeyCode < 19 || inKeyCode > 22) {
				
				return true;
				
			}
			
		}::end::
		
		final int keyCode = translateKeyCode (inKeyCode, event);
		final int charCode = translateCharCode (inKeyCode, event);
		
		if (keyCode != 0) {
			
			queueEvent (new Runnable () {
				
				public void run () {
					
					me.HandleResult (Lime.onKeyChange (keyCode, charCode, true));
					
				}
				
			});
			
			return true;
			
		}
		
		return super.onKeyDown (inKeyCode, event);
		
	}
	
	
	@Override public boolean onKeyUp (final int inKeyCode, KeyEvent event) {
		
		final MainView me = this;
		
		::if (ANDROID_TARGET_SDK_VERSION > 11)::if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.HONEYCOMB_MR1 && (event.isGamepadButton (inKeyCode) || (inKeyCode >= 19 && inKeyCode <=22))) {
			
			if (event.getRepeatCount () == 0) {
				
				final int deviceId = event.getDeviceId ();
				
				queueEvent (new Runnable () {
					
					public void run () {
						
						me.HandleResult (Lime.onJoyChange (deviceId, inKeyCode, false));
						
					}
					
				});
				
			}
			
			if (inKeyCode < 19 || inKeyCode > 22) {
				
				return true;
				
			}
			
		}::end::
		
		final int keyCode = translateKeyCode (inKeyCode, event);
		final int charCode = translateCharCode (inKeyCode, event);
		
		if (keyCode != 0) {
			
			queueEvent (new Runnable () {
				
				public void run () {
					
					me.HandleResult (Lime.onKeyChange (keyCode, charCode, false));
					
				}
				
			});
			
			return true;
			
		}
		
		return super.onKeyUp (inKeyCode, event);
		
	}
	
	
	// Haxe Thread
	void onPoll () {
		
		isPollImminent = false;
		HandleResult (Lime.onPoll ());
		
	}
	
	
	@Override public boolean onTouchEvent (final MotionEvent ev) {
		
		final MainView me = this;
		final int action = ev.getAction ();
		int type = -1;
		
		switch (action & MotionEvent.ACTION_MASK) {
			
			case MotionEvent.ACTION_DOWN: type = etTouchBegin; break;
			case MotionEvent.ACTION_POINTER_DOWN: type = etTouchBegin; break;
			case MotionEvent.ACTION_MOVE: type = etTouchMove; break;
			case MotionEvent.ACTION_UP: type = etTouchEnd; break;
			case MotionEvent.ACTION_POINTER_UP: type = etTouchEnd; break;
			case MotionEvent.ACTION_CANCEL: type = etTouchEnd; break;
			
		}
		
		int idx = (action & MotionEvent.ACTION_POINTER_ID_MASK) >> (MotionEvent.ACTION_POINTER_ID_SHIFT);
		final int t = type;
		
		for (int i = 0; i < ev.getPointerCount (); i++) {
			
			final int id = ev.getPointerId (i);
			final float x = ev.getX (i);
			final float y = ev.getY (i);
			final float sizeX = ev.getSize (i);
			final float sizeY = ev.getSize (i);
			
			if (type == etTouchMove || i == idx) {
				
				queueEvent (new Runnable () {
					
					public void run () {
						
						me.HandleResult (Lime.onTouch (t, x, y, id, sizeX, sizeY));
						
					}
					
				});
				
			}
			
		}
		
		try {
			
			Thread.sleep((Build.VERSION.SDK_INT < Build.VERSION_CODES.FROYO) ? 16 : 1);
			
		} catch (InterruptedException e) {
		}
		
		return true;
		
	}
	
	
	@Override public boolean onTrackballEvent (final MotionEvent ev) {
		
		final MainView me = this;
		
		queueEvent (new Runnable () {
			
			public void run() {
				
				float x = ev.getX ();
				float y = ev.getY ();
				
				me.HandleResult (Lime.onTrackball (x, y));
				
			}
			
		});
		
		return false;
		
	}
	
	
	// GUI/Timer Thread
	void queuePoll () {
		
		if (!isPollImminent) {
			
			isPollImminent = true;
			queueEvent (pollMe);
			
		}
		
	}
	
	
	
	static public void renderNow () { //Called directly from C++
		
		mRefreshView.renderPending = true;
		mRefreshView.requestRender ();
		
	}
	
	
	void sendActivity (final int inActivity) {
		
		queueEvent (new Runnable () {
			
			public void run () {
				
				Lime.onActivity (inActivity);
				
			}
			
		});
		
	}
	
	
	public int translateCharCode (int inCode, KeyEvent event) {
		
		int result = event.getUnicodeChar (event.getMetaState ());
		
		if (result == KeyCharacterMap.COMBINING_ACCENT) {
			
			//TODO
			return 0;
			
		}
		
		switch (inCode) {
			
			case 66:
			case 160: return 13; // enter
			case 111: return 27; // escape
			case 67: return 8; // backspace
			case 61: return 9; // tab
			case 62: return 32; // space
			case 112: return 127; // delete
			
		}
	
		return result;
		
	}
	
	
	public int translateKeyCode (int inCode, KeyEvent event) {
		
		switch (inCode) {
			
			case KeyEvent.KEYCODE_DPAD_CENTER: return 13; // Enter
			case KeyEvent.KEYCODE_BACK: return 27; /* Fake Escape */
			case KeyEvent.KEYCODE_MENU: return 0x01000012; /* Fake MENU */
			case KeyEvent.KEYCODE_DEL: return 8;

			// These will be ignored by the app and passed to the default handler
			case KeyEvent.KEYCODE_VOLUME_UP:
			case KeyEvent.KEYCODE_VOLUME_DOWN:
			::if (ANDROID_TARGET_SDK_VERSION > 10)::case KeyEvent.KEYCODE_VOLUME_MUTE:::end:: 
				return 0;
			
		}


		if (inCode >= 7 && inCode <= 16) {
			
			return inCode + 41; // 1-9
		
		} else if (inCode >= 29 && inCode <= 54) {
			
			return inCode + 36; // a-z
			
		} else if (inCode >= 131 && inCode <= 142) {
			
			return inCode - 19; // F1-F12
			
		} else if (inCode >= 144 && inCode <= 153) {
			
			return inCode - 96; // 1-9
			
		}
		
		switch (inCode) {
			
			case 66:
			case 160: return 13; // enter
			case 111: return 27; // escape
			case 67: return 8; // backspace
			case 61: return 9; // tab
			case 62: return 32; // space
			case 69:
			case 156: return 189; // -_
			case 70:
			case 161: return 187; // +=
			case 71: return 219; // [{
			case 72: return 221; // ]}
			case 73: return 220; // \|
			case 74: return 186; // ;:
			case 75: return 222; // '"
			case 68: return 192; // `~
			case 55:
			case 159: return 188; // ,<
			case 56:
			case 158: return 190; // .>
			case 76: return 191; // /?
			case 115: return 20; // caps lock
			case 116: return 145; // scroll lock
			case 121: return 19; // pause/break
			case 124: return 45; // insert
			case 122: return 36; // home
			case 92: return 34; // page down
			case 93: return 33; // page up
			case 112: return 46; // delete
			case 123: return 35; // end
			case 22: return 39; // right arrow
			case 21: return 37; // left arrow
			case 20: return 40; // down arrow
			case 19: return 38; // up arrow
			case 143: return 144; // num lock
			case 113:
			case 114: return 17; // ctrl
			case 59:
			case 60: return 16; // shift
			case 57:
			case 58: return 18; // alt
			
		}
		
		return inCode;
		
	}
	
	
	
	
	private static class Renderer implements GLSurfaceView.Renderer {
		
		
		MainView mMainView;
		
		
		public Renderer (MainView inView) {
			
			mMainView = inView;
			
		}
		
		
		public void onDrawFrame (GL10 gl) {
			
			mMainView.renderPending = false;
			mMainView.HandleResult (Lime.onRender ());
			//Sound.checkSoundCompletion ();
			
		}
		
		
		public void onSurfaceChanged (GL10 gl, int width, int height) {
			
			::if (DEBUG)::
			Log.v("VIEW","onSurfaceChanged " + width +"," + height);
			Log.v("VIEW", "Thread = " + java.lang.Thread.currentThread ().getId ());
			::end::
			
			mMainView.HandleResult (Lime.onResize (width, height));
			
			/*if (GameActivity.activity != null) {
				
				GameActivity.activity.onResizeAsync(width,height);
				
			}*/
			
		}
		
		
		public void onSurfaceCreated (GL10 gl, EGLConfig config) {
			
			mMainView.isPollImminent = false;
			mMainView.renderPending = false;
			::if (DEBUG)::
			Log.v("VIEW","onSurfaceCreated");
			Log.v("VIEW", "Thread = " + java.lang.Thread.currentThread ().getId ());
			::end::
			mMainView.HandleResult (Lime.onContextLost ());
			
		}
		
	}
	
	
}
