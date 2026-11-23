package org.haxe.lime;


import android.content.Context;
import android.graphics.ImageFormat;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.media.Image;
import android.media.ImageReader;
import android.os.Handler;
import android.os.HandlerThread;
import android.util.Log;
import android.util.Range;
import android.util.Size;
import org.haxe.extension.Extension;

import java.nio.ByteBuffer;
import java.util.Arrays;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;


// Camera capture through Camera2, for lime.media.CameraInput. Lime's native code
// calls it through JNI and polls it for the newest frame, kept as NV12.
public class CameraCapture {


	private static final String TAG = "CameraCapture";

	private CameraDevice camera;
	private volatile boolean disconnected;
	private byte[] frame;
	private boolean frameReady;
	private long frameTimestamp;
	private int frameRate;
	private Range<Integer> frameRateRange;
	private Handler handler;
	private int height;
	private ImageReader reader;
	private CaptureRequest request;
	private CameraCaptureSession session;
	private HandlerThread thread;
	private int width;


	private CameraCapture () {}


	// One record per camera, its id, name and position (0 unknown, 1 front, 2 back)
	// split by 0x1F, and the records by 0x1E, the first back camera first
	public static String getDevices () {

		CameraManager manager = getManager ();
		if (manager == null) return null;

		StringBuilder back = new StringBuilder ();
		StringBuilder others = new StringBuilder ();

		try {

			for (String id : manager.getCameraIdList ()) {

				Integer facing = manager.getCameraCharacteristics (id).get (CameraCharacteristics.LENS_FACING);
				int position = 0;
				String name = "Camera " + id;

				if (facing != null && facing == CameraCharacteristics.LENS_FACING_FRONT) {

					position = 1;
					name += " (front)";

				} else if (facing != null && facing == CameraCharacteristics.LENS_FACING_BACK) {

					position = 2;
					name += " (back)";

				}

				StringBuilder target = (position == 2 && back.length () == 0) ? back : others;
				if (target.length () > 0) target.append ('\u001E');
				target.append (id).append ('\u001F').append (name).append ('\u001F').append (position);

			}

		} catch (Exception e) {

			Log.e (TAG, e.toString ());
			return null;

		}

		if (back.length () > 0 && others.length () > 0) back.append ('\u001E');
		return back.append (others).toString ();

	}


	// Opens the camera, or the first back camera when id is empty, and waits for it
	// to be ready. Returns null when it cannot, as without the CAMERA permission.
	public static CameraCapture open (String id, int width, int height, int frameRate) {

		CameraManager manager = getManager ();
		if (manager == null) return null;

		CameraCapture capture = new CameraCapture ();

		try {

			if (id == null || id.length () == 0) {

				String devices = getDevices ();
				if (devices == null || devices.length () == 0) return null;
				id = devices.split ("\u001E")[0].split ("\u001F")[0];

			}

			if (!capture.openCamera (manager, id, width, height, frameRate)) {

				capture.close ();
				return null;

			}

		} catch (Exception e) {

			Log.e (TAG, e.toString ());
			capture.close ();
			return null;

		}

		return capture;

	}


	public void close () {

		try {

			if (session != null) session.close ();
			if (camera != null) camera.close ();
			if (reader != null) reader.close ();

		} catch (Exception e) {}

		session = null;
		camera = null;
		reader = null;

		if (thread != null) {

			thread.quitSafely ();
			thread = null;

		}

		disconnected = true;

	}


	public int getFrameRate () {

		return frameRate;

	}


	public int getHeight () {

		return height;

	}


	public double getFrameTime () {

		synchronized (this) {

			return frameTimestamp / 1000000000.0;

		}

	}


	public int getWidth () {

		return width;

	}


	// Copies the newest frame into data as NV12 and returns its length, 0 when no
	// frame came since the last read, or -1 once the camera is gone
	public int read (byte[] data) {

		if (disconnected) return -1;

		synchronized (this) {

			if (!frameReady || frame == null || data.length < frame.length) return 0;

			System.arraycopy (frame, 0, data, 0, frame.length);
			frameReady = false;
			return frame.length;

		}

	}


	public boolean start () {

		if (session == null || request == null) return false;

		try {

			session.setRepeatingRequest (request, null, handler);
			return true;

		} catch (Exception e) {

			Log.e (TAG, e.toString ());
			return false;

		}

	}


	public void stop () {

		if (session == null) return;

		try {

			session.stopRepeating ();

		} catch (Exception e) {}

	}


	private static CameraManager getManager () {

		Context context = Extension.mainContext;
		return context != null ? (CameraManager)context.getSystemService (Context.CAMERA_SERVICE) : null;

	}


	private boolean openCamera (CameraManager manager, String id, int requestedWidth, int requestedHeight, int requestedFrameRate) throws CameraAccessException {

		CameraCharacteristics characteristics = manager.getCameraCharacteristics (id);
		StreamConfigurationMap map = characteristics.get (CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
		if (map == null) return false;

		// The size nearest the one asked for
		Size best = null;
		long bestScore = 0;

		for (Size size : map.getOutputSizes (ImageFormat.YUV_420_888)) {

			long score = Math.abs (size.getWidth () - requestedWidth) + Math.abs (size.getHeight () - requestedHeight);

			if (best == null || score < bestScore) {

				best = size;
				bestScore = score;

			}

		}

		if (best == null) return false;

		width = best.getWidth ();
		height = best.getHeight ();

		// The rate range whose top is nearest the rate asked for, a fixed rate first
		Range<Integer>[] ranges = characteristics.get (CameraCharacteristics.CONTROL_AE_AVAILABLE_TARGET_FPS_RANGES);
		frameRateRange = null;

		if (ranges != null) {

			for (Range<Integer> range : ranges) {

				if (frameRateRange == null) {

					frameRateRange = range;
					continue;

				}

				int difference = Math.abs (range.getUpper () - requestedFrameRate);
				int bestDifference = Math.abs (frameRateRange.getUpper () - requestedFrameRate);

				if (difference < bestDifference || (difference == bestDifference && range.getLower () > frameRateRange.getLower ())) {

					frameRateRange = range;

				}

			}

		}

		frameRate = frameRateRange != null ? frameRateRange.getUpper () : requestedFrameRate;

		thread = new HandlerThread ("LimeCamera");
		thread.start ();
		handler = new Handler (thread.getLooper ());

		reader = ImageReader.newInstance (width, height, ImageFormat.YUV_420_888, 3);
		reader.setOnImageAvailableListener (new ImageReader.OnImageAvailableListener () {

			@Override public void onImageAvailable (ImageReader imageReader) {

				Image image = null;

				try {

					image = imageReader.acquireLatestImage ();
					if (image != null) keepFrame (image);

				} catch (Exception e) {

					Log.e (TAG, e.toString ());

				} finally {

					if (image != null) image.close ();

				}

			}

		}, handler);

		final CountDownLatch opened = new CountDownLatch (1);

		manager.openCamera (id, new CameraDevice.StateCallback () {

			@Override public void onOpened (CameraDevice device) {

				camera = device;
				opened.countDown ();

			}

			@Override public void onDisconnected (CameraDevice device) {

				disconnected = true;
				device.close ();
				opened.countDown ();

			}

			@Override public void onError (CameraDevice device, int error) {

				disconnected = true;
				device.close ();
				opened.countDown ();

			}

		}, handler);

		if (!await (opened) || camera == null || disconnected) return false;

		final CountDownLatch configured = new CountDownLatch (1);

		camera.createCaptureSession (Arrays.asList (reader.getSurface ()), new CameraCaptureSession.StateCallback () {

			@Override public void onConfigured (CameraCaptureSession captureSession) {

				session = captureSession;
				configured.countDown ();

			}

			@Override public void onConfigureFailed (CameraCaptureSession captureSession) {

				configured.countDown ();

			}

		}, handler);

		if (!await (configured) || session == null) return false;

		CaptureRequest.Builder builder = camera.createCaptureRequest (CameraDevice.TEMPLATE_PREVIEW);
		builder.addTarget (reader.getSurface ());
		if (frameRateRange != null) builder.set (CaptureRequest.CONTROL_AE_TARGET_FPS_RANGE, frameRateRange);
		request = builder.build ();

		return true;

	}


	private static boolean await (CountDownLatch latch) {

		try {

			return latch.await (5, TimeUnit.SECONDS);

		} catch (InterruptedException e) {

			return false;

		}

	}


	// YUV_420_888 rows and pixels can be spaced out, so they are packed into NV12
	private void keepFrame (Image image) {

		Image.Plane[] planes = image.getPlanes ();
		if (planes.length < 3) return;

		int imageWidth = image.getWidth ();
		int imageHeight = image.getHeight ();
		int chromaWidth = (imageWidth + 1) / 2;
		int chromaHeight = (imageHeight + 1) / 2;
		int length = imageWidth * imageHeight + chromaWidth * chromaHeight * 2;

		synchronized (this) {

			if (frame == null || frame.length != length) frame = new byte[length];

			ByteBuffer y = planes[0].getBuffer ();
			int yStride = planes[0].getRowStride ();

			for (int row = 0; row < imageHeight; row++) {

				y.position (row * yStride);
				y.get (frame, row * imageWidth, imageWidth);

			}

			ByteBuffer u = planes[1].getBuffer ();
			ByteBuffer v = planes[2].getBuffer ();
			int uvStride = planes[1].getRowStride ();
			int uvPixelStride = planes[1].getPixelStride ();
			int offset = imageWidth * imageHeight;

			for (int row = 0; row < chromaHeight; row++) {

				int source = row * uvStride;

				for (int column = 0; column < chromaWidth; column++) {

					int index = source + column * uvPixelStride;
					frame[offset++] = u.get (index);
					frame[offset++] = v.get (index);

				}

			}

			width = imageWidth;
			height = imageHeight;
			frameTimestamp = image.getTimestamp ();
			frameReady = true;

		}

	}


}
