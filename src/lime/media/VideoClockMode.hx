package lime.media;

/**
	How a `VideoSource` times its frames against its sound.

	The audio-based modes follow the sound being heard: the position the audio
	output has mixed to, less the output's latency where OpenAL Soft reports it.
	That position only moves when the output mixes, which is every 20 ms on most
	outputs and 60 ms or more on some.
**/
#if (haxe_ver >= 4.0) enum #else @:enum #end abstract VideoClockMode(Int) from Int to Int
{
	/**
		The clock runs on a monotonic timer, and each time the audio position
		moves, it runs up to 10% faster or slower to stay with the sound. Frames
		are evenly spaced and in step with the sound, without jumps. This is the
		default.
	**/
	var SMOOTH = 0;

	/**
		The clock is the position of the sound being heard, as the audio output
		reports it. It is exact, but stands still between mixes and then jumps,
		so frames can arrive in uneven bursts.
	**/
	var AUDIO = 1;

	/**
		The clock runs on a monotonic timer between mixes, and each time the
		audio position moves, it is set back to the sound being heard. Frames are
		evenly spaced, with a small correction each time.
	**/
	var INTERPOLATED = 2;

	/**
		The clock runs on a monotonic timer alone, as for a video without sound,
		and the sound is moved to match the clock when they drift more than a
		tenth of a second apart. Frames are evenly spaced whatever the audio
		output does, but the sound skips when it is moved.
	**/
	var MONOTONIC = 3;
}
