package lime.media;

#if (!lime_doc_gen || (js && html5))
#if (!lime_doc_gen && (!js || !html5 || display))
class WebAudioContext
{
	public var activeSourceCount(default, null):Int;
	public var currentTime(default, null):Float;
	public var destination(default, null):Dynamic /*AudioDestinationNode*/;
	public var listener(default, null):Dynamic /*AudioListener*/;
	public var oncomplete:Dynamic /*js.html.EventListener*/;
	public var sampleRate(default, null):Float;

	public function new() {}

	public function createAnalyser():Dynamic /*AnalyserNode*/
	{
		return null;
	}

	public function createBiquadFilter():Dynamic /*BiquadFilterNode*/
	{
		return null;
	}

	@:overload(function(numberOfChannels:Int, numberOfFrames:Int, sampleRate:Float):Dynamic /*AudioBuffer*/ {})
	public function createBuffer(buffer:Dynamic /*js.html.ArrayBuffer*/, mixToMono:Bool):Dynamic /*AudioBuffer*/
	{
		return null;
	}

	public function createBufferSource():Dynamic /*AudioBufferSourceNode*/
	{
		return null;
	}

	public function createChannelMerger(?numberOfInputs:Int):Dynamic /*ChannelMergerNode*/
	{
		return null;
	}

	public function createChannelSplitter(?numberOfOutputs:Int):Dynamic /*ChannelSplitterNode*/
	{
		return null;
	}

	public function createConvolver():Dynamic /*ConvolverNode*/
	{
		return null;
	}

	public function createDelay(?maxDelayTime:Float):Dynamic /*DelayNode*/
	{
		return null;
	}

	public function createDynamicsCompressor():Dynamic /*DynamicsCompressorNode*/
	{
		return null;
	}

	public function createGain():Dynamic /*GainNode*/
	{
		return null;
	}

	public function createMediaElementSource(mediaElement:Dynamic /*js.html.MediaElement*/):Dynamic /*MediaElementAudioSourceNode*/
	{
		return null;
	}

	public function createMediaStreamSource(mediaStream:Dynamic /*js.html.rtc.MediaStream*/):Dynamic /*MediaStreamAudioSourceNode*/
	{
		return null;
	}

	public function createOscillator():Dynamic /*OscillatorNode*/
	{
		return null;
	}

	public function createPanner():Dynamic /*PannerNode*/
	{
		return null;
	}

	public function createScriptProcessor(bufferSize:Int, ?numberOfInputChannels:Int, ?numberOfOutputChannels:Int):Dynamic /*ScriptProcessorNode*/
	{
		return null;
	}

	public function createWaveShaper():Dynamic /*WaveShaperNode*/
	{
		return null;
	}

	public function createWaveTable(real:Dynamic /*js.html.Float32Array*/, imag:Dynamic /*js.html.Float32Array*/):Dynamic /*WaveTable*/
	{
		return null;
	}

	public function decodeAudioData(audioData:Dynamic /*js.html.ArrayBuffer*/, successCallback:Dynamic /*AudioBufferCallback*/,
		?errorCallback:Dynamic /*AudioBufferCallback*/):Void {}

	public function startRendering():Void {}
}
#else
typedef WebAudioContext = js.html.audio.AudioContext;
#end
#end
