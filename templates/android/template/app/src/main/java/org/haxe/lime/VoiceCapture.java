package org.haxe.lime;


import android.media.AudioFormat;
import android.media.AudioRecord;
import android.media.MediaRecorder;
import android.media.audiofx.AcousticEchoCanceler;
import android.media.audiofx.AudioEffect;
import android.media.audiofx.AutomaticGainControl;
import android.media.audiofx.NoiseSuppressor;
import android.os.Build;
import android.util.Log;


// Microphone capture with Android's voice processing, for lime.media.AudioInput
// when it asks for echo cancellation, noise suppression or automatic gain control.
// Lime's native code calls it through JNI and polls it, as it polls OpenAL.
public class VoiceCapture {


	private static final int ECHO_CANCELLATION = 1;
	private static final int NOISE_SUPPRESSION = 2;
	private static final int AUTO_GAIN = 4;

	private AcousticEchoCanceler echoCanceler;
	private AutomaticGainControl gainControl;
	private NoiseSuppressor noiseSuppressor;
	private int processing;
	private AudioRecord record;


	private VoiceCapture (AudioRecord record) {

		this.record = record;

	}


	// Mono 16-bit samples, or null where the voice processing capture cannot be
	// opened, as before Android 6.0, which has no non-blocking reads
	public static VoiceCapture open (int sampleRate, int bufferFrames, int requested) {

		if (Build.VERSION.SDK_INT < 23) {

			return null;

		}

		// The voice communication source turns on the device's own echo cancellation
		int source = (requested & ECHO_CANCELLATION) != 0 ? MediaRecorder.AudioSource.VOICE_COMMUNICATION : MediaRecorder.AudioSource.MIC;
		int minimum = AudioRecord.getMinBufferSize (sampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT);

		if (minimum <= 0) {

			return null;

		}

		AudioRecord record;

		try {

			record = new AudioRecord (source, sampleRate, AudioFormat.CHANNEL_IN_MONO, AudioFormat.ENCODING_PCM_16BIT, Math.max (minimum, bufferFrames * 2 * 2));

		} catch (Exception e) {

			Log.e ("VoiceCapture", e.toString ());
			return null;

		}

		if (record.getState () != AudioRecord.STATE_INITIALIZED) {

			record.release ();
			return null;

		}

		VoiceCapture capture = new VoiceCapture (record);
		capture.applyEffects (requested);
		return capture;

	}


	public int getProcessing () {

		return processing;

	}


	// Shorts read, or a negative AudioRecord error such as ERROR_DEAD_OBJECT once
	// the microphone is gone
	public int read (short[] data) {

		if (record == null) {

			return AudioRecord.ERROR_INVALID_OPERATION;

		}

		return record.read (data, 0, data.length, AudioRecord.READ_NON_BLOCKING);

	}


	public void release () {

		stop ();

		if (echoCanceler != null) echoCanceler.release ();
		if (gainControl != null) gainControl.release ();
		if (noiseSuppressor != null) noiseSuppressor.release ();
		if (record != null) record.release ();

		echoCanceler = null;
		gainControl = null;
		noiseSuppressor = null;
		record = null;

	}


	public boolean start () {

		if (record == null) {

			return false;

		}

		try {

			record.startRecording ();

		} catch (Exception e) {

			Log.e ("VoiceCapture", e.toString ());
			return false;

		}

		return record.getRecordingState () == AudioRecord.RECORDSTATE_RECORDING;

	}


	public void stop () {

		if (record != null && record.getRecordingState () == AudioRecord.RECORDSTATE_RECORDING) {

			record.stop ();

		}

	}


	// Each effect the device has is turned on or off as asked, and the ones left
	// on are the ones reported
	private void applyEffects (int requested) {

		int session = record.getAudioSessionId ();
		processing = 0;

		if (AcousticEchoCanceler.isAvailable ()) {

			echoCanceler = AcousticEchoCanceler.create (session);
			if (setEnabled (echoCanceler, (requested & ECHO_CANCELLATION) != 0)) processing |= ECHO_CANCELLATION;

		}

		if (NoiseSuppressor.isAvailable ()) {

			noiseSuppressor = NoiseSuppressor.create (session);
			if (setEnabled (noiseSuppressor, (requested & NOISE_SUPPRESSION) != 0)) processing |= NOISE_SUPPRESSION;

		}

		if (AutomaticGainControl.isAvailable ()) {

			gainControl = AutomaticGainControl.create (session);
			if (setEnabled (gainControl, (requested & AUTO_GAIN) != 0)) processing |= AUTO_GAIN;

		}

	}


	private static boolean setEnabled (AudioEffect effect, boolean enabled) {

		if (effect == null) {

			return false;

		}

		try {

			effect.setEnabled (enabled);
			return effect.getEnabled ();

		} catch (Exception e) {

			return false;

		}

	}


}
