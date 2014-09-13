package org.haxe.lime;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileDescriptor;
import java.io.FileNotFoundException;
import java.io.IOException; 
import java.lang.System;
import java.security.MessageDigest;
// import java.util.Hashtable;
import java.util.HashMap;
import java.util.Map;
import java.util.zip.CRC32;

import android.content.Context;
import android.util.Log;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.SoundPool;
import android.net.Uri;

class ManagedMediaPlayer
{
	public MediaPlayer mp;
	public float leftVol;
	public float rightVol;
	public boolean isComplete = true;
	public int loopsLeft = 0;
	public boolean wasPlaying = false;

	public ManagedMediaPlayer(MediaPlayer mp, float leftVol, float rightVol, int loop) {
		this.mp = mp;
		setVolume(leftVol, rightVol);
		isComplete = false;
		final ManagedMediaPlayer mmp = this;

		if (loop < 0) {
			mp.setLooping(true);
		} else if (loop >= 0) {
			this.loopsLeft = loop;
			mp.setOnCompletionListener(new MediaPlayer.OnCompletionListener() {
				@Override public void onCompletion(MediaPlayer mp) {
					if (--mmp.loopsLeft > 0) {
						mp.seekTo(0);
						mp.start();
					} else {
						mmp.setComplete();
					}
				}
			});
		}
	}

	public ManagedMediaPlayer setMediaPlayer(MediaPlayer mp) {
		this.mp = mp;
		return this;
	}

	public void setVolume(float leftVol, float rightVol) {
		if (mp != null)
			mp.setVolume((float)leftVol, (float)rightVol);
		this.leftVol = leftVol;
		this.rightVol = rightVol;
	}

	public int getDuration() {
		if (mp != null)
			return mp.getDuration();
		return -1;
	}

	public int getCurrentPosition() {
		if (mp != null)
			return mp.getCurrentPosition();
		return -1;
	}
	
	public boolean isPlaying() {
		if (mp != null)
			return mp.isPlaying();
		return false;
	}
	
	public void pause() {
		if (mp != null)
			mp.pause();
	}
	
	public void start() {
		if (mp != null)
			mp.start();
	}

	public void stop() {
		if (mp != null)
			mp.stop();
		release();
	}

	public void setComplete() {
		this.isComplete = true;
		stop();
	}

	public void release() {
		if (mp != null) {
			mp.release();
			mp = null;
		}
	}
}

public class Sound
{
	private static Context mContext;
	private static Sound instance;

	private static ManagedMediaPlayer mediaPlayer;
	private static boolean mediaPlayerWasPlaying;
	private static String mediaPlayerPath;
	private static SoundPool mSoundPool;
	// private static int mSoundPoolID = 0;
	private static long mTimeStamp = 0;
	private static HashMap<Integer, Integer> mSoundId;
	private static HashMap<Integer, Long> mSoundProgress;
	private static HashMap<Integer, Long> mSoundDuration;

    public Sound(Context context)
    {
    	if (instance == null) {
    		mSoundId = new HashMap<Integer, Integer>();
    		mSoundProgress = new HashMap<Integer, Long>();
    		mSoundDuration = new HashMap<Integer, Long>();
    		mTimeStamp = System.currentTimeMillis();
			mSoundPool = new SoundPool(8, AudioManager.STREAM_MUSIC, 0);
		}

    	instance = this;
    	mContext = context;
    }
	
	public void doPause()
	{
		if (mSoundPool != null) {
			mSoundPool.autoPause();
		}
		
		if (mediaPlayer != null) {
			mediaPlayerWasPlaying = mediaPlayer.isPlaying ();
			mediaPlayer.pause();
		}
	}

	public void doResume()
	{
		mTimeStamp = System.currentTimeMillis();
		mSoundPool.autoResume();

		if (mediaPlayer != null && mediaPlayerWasPlaying) {
			mediaPlayer.start ();
		}	
	}
	
	/*
	 * Sound effects using SoundPool
	 *
	 * This allows for low latency and CPU load but sounds must be 100kB or smaller
	 */

	public static int getSoundHandle(String inFilename)
	{
		int id = GameActivity.getResourceID(inFilename);
		Log.v("Sound","Get sound handle ------" + inFilename + " = " + id);

		int index;		
		
		if (id > 0) {
			index = mSoundPool.load(mContext, id, 1);
			Log.v("Sound", "Loaded index: " + index);
		} else {
			Log.v("Sound", "Resource not found: " + (-id));
			index = mSoundPool.load(inFilename, 1);
			Log.v("Sound", "Loaded index from path: " + index);
		}

		int duration = getDuration(inFilename);
		mSoundDuration.put(index, (long)duration);

		return index;
    }
	
	public static String getSoundPathByByteArray(byte[] data) throws java.lang.Exception
	{
		// HACK! It seems that the API doesn't allow to use non file streams. At least with MediaPlayer/SoundPool. 
		// The alternative is to use an AudioTrack, but the data should be decoded by hand and not sure if android
		// provides an API for decoding this kind of stuff.
		// So the partial solution at this point is to create a temporary file that will be loaded.
		
		MessageDigest messageDigest = MessageDigest.getInstance("md5");
		messageDigest.update(data);
		String md5 = new java.math.BigInteger(1, messageDigest.digest()).toString(16);
		File file = new File(mContext.getCacheDir() + "/" + md5 + ".wav");

		//File file = File.createTempFile("temp", ".sound", mContext.getFilesDir());
		if (!file.exists()) {
			Log.v("Sound", "Created temp sound file :" + file.getAbsolutePath());
			java.io.FileOutputStream fileOutputStream = new java.io.FileOutputStream(file);
			fileOutputStream.write(data);
			fileOutputStream.flush();
			fileOutputStream.close();
		} else {
			Log.v("Sound", "Opened temp sound file :" + file.getAbsolutePath());
		}
		
		return file.getAbsolutePath();
	}
	
	public static int playSound(int inResourceID, double inVolLeft, double inVolRight, int inLoop)
	{
		Log.v("Sound", "PlaySound -----" + inResourceID);
		
		inLoop--;
		if (inLoop < 0) {
			inLoop = 0;
		}

		if (mSoundId.get(inResourceID) != null) {
			//Log.v("VIEW", "Found existing sound " + inResourceID + ", stopping and removing it from progress and id check");	
			int a = mSoundId.get(inResourceID);
			mSoundPool.stop(a);
			mSoundProgress.remove(a);
			mSoundId.remove(inResourceID);
		}
		
		int streamId = mSoundPool.play(inResourceID, (float)inVolLeft, (float)inVolRight, 1, inLoop, 1.0f);
		mSoundId.put(inResourceID, streamId);
		mSoundProgress.put(streamId, (long)0);
		return streamId;
	}
	
	static public void stopSound(int inStreamID)
	{
		if (mSoundPool != null) {
			mSoundPool.stop(inStreamID);
			mSoundProgress.remove(inStreamID);
			mSoundId.values().remove(inStreamID);
		}
	}

	static public void checkSoundCompletion() 
	{
		long delta = (System.currentTimeMillis() - mTimeStamp);
		for (Map.Entry<Integer, Long> entry : mSoundProgress.entrySet()) {
			long val = entry.getValue();
			entry.setValue(val + (long)delta);
		}

		mTimeStamp = System.currentTimeMillis();
	}

	static public boolean getSoundComplete(int inSoundID, int inStreamID, int inLoop) {
		if (!mSoundProgress.containsKey(inStreamID) || !mSoundDuration.containsKey(inSoundID)) {
			return true;
		}

		return mSoundProgress.get(inStreamID) >= (mSoundDuration.get(inSoundID) * inLoop);
	}

	static public int getSoundPosition(int inSoundID, int inStreamID, int inLoop) {
		if (!mSoundProgress.containsKey(inStreamID) || !mSoundDuration.containsKey(inSoundID)) {
			return 0;
		}

		long progress = mSoundProgress.get(inStreamID);
		long total = mSoundDuration.get(inSoundID);
		return (int)(progress > (total * inLoop) ? total : (progress % total));
	}

	/*
	 * Music using MediaPlayer
	 *
	 * This allows for larger audio files but consumes more CPU than SoundPool
	 */
	
	private static int getMusicHandle(String inPath)
    {
		int id = GameActivity.getResourceID(inPath);
		Log.v("Sound","Get music handle ------" + inPath + " = " + id);	
		return id;		
	}

	private static MediaPlayer createMediaPlayer(String inPath) 
	{
		MediaPlayer mp = null;
		int resId = getMusicHandle(inPath);
		if (resId < 0) {
			if (inPath.charAt(0) == File.separatorChar) {
				try {
		        	FileInputStream fis = new FileInputStream(new File(inPath));
			        FileDescriptor fd = fis.getFD();
					mp = new MediaPlayer();
					mp.setDataSource(fd);
					mp.prepare();
		        } catch(FileNotFoundException e) { 
		            System.out.println(e.getMessage());
		            return null;
		        } catch(IOException e) { 
		            System.out.println(e.getMessage());
		            return null;
		        }
		    } else {
				Uri uri = Uri.parse(inPath);
				mp = MediaPlayer.create(mContext, uri);
		    }
		} else {
			mp = MediaPlayer.create(mContext, resId);
		}

		return mp;
	}

	public static int playMusic(String inPath, double inVolLeft, double inVolRight, int inLoop, double inStartTime)
    {
    	Log.i("Sound", "playMusic");
		
		if (mediaPlayer != null) {
			mediaPlayer.stop ();
		}
		
		MediaPlayer mp = createMediaPlayer(inPath);
		if (mp == null) {
			return -1;
		}

		return playMediaPlayer(mp, inPath, inVolLeft, inVolRight, inLoop, inStartTime);
	}
		
	private static int playMediaPlayer(MediaPlayer mp, final String inPath, double inVolLeft, double inVolRight, int inLoop, double inStartTime)
	{	
		mediaPlayer = new ManagedMediaPlayer(mp, (float)inVolLeft, (float)inVolRight, inLoop);
		mediaPlayerPath = inPath;
		mp.seekTo((int)inStartTime);
		mediaPlayer.start();

		return 0;
	}

	public static void stopMusic(String inPath)
	{
		Log.v("Sound", "stopMusic");
		
		if (mediaPlayer != null && inPath.equals(mediaPlayerPath)) {
			mediaPlayer.stop ();
		}
	}
	
	public static int getDuration(String inPath)
	{
		int duration = -1;
		if (mediaPlayer != null && inPath.equals(mediaPlayerPath)) {
			duration = mediaPlayer.getDuration ();
		} else {
			MediaPlayer mp = createMediaPlayer(inPath);
			if (mp != null) {
				duration = mp.getDuration();
				mp.release();
			}
		}

		return duration;
	}
	
	public static int getPosition(String inPath)
	{
		if (mediaPlayer != null && inPath.equals(mediaPlayerPath)) {
			return mediaPlayer.getCurrentPosition ();
		}
		return -1;
	}
	
	public static double getLeft(String inPath)
	{
		if (mediaPlayer != null && inPath.equals(mediaPlayerPath)) {
			return mediaPlayer.leftVol;
		}

		return 0.5;
	}
	
	public static double getRight(String inPath)
	{
		if (mediaPlayer != null && inPath.equals(mediaPlayerPath)) {
			return mediaPlayer.rightVol;
		}

		return 0.5;
	}
	
	public static boolean getComplete(String inPath)
	{
		if (mediaPlayer != null && inPath.equals(mediaPlayerPath)) {
			return mediaPlayer.isComplete;
		}

		return true;
	}

	public static void setMusicTransform(String inPath, double inVolLeft, double inVolRight)
	{
		if (mediaPlayer != null && inPath.equals(mediaPlayerPath)) {
			mediaPlayer.setVolume((float)inVolLeft, (float)inVolRight);
		}
	}
}
	