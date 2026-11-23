package lime._internal.format;

import haxe.ds.Vector;
import haxe.io.Bytes;

/**
	Decodes an .lzma stream (LZMA alone: a 13-byte header, then the LZMA
	data), whether or not its header holds the size it decodes to.

	A port of LzmaSpec.cpp, the reference decoder Igor Pavlov placed in the
	public domain. Flash's own decoder only reads streams that hold their exact
	size, so this reads the rest there. The range coder works on unsigned 32-bit
	values, which are kept in Int and compared unsigned.
**/
#if !lime_debug
@:fileXml('tags="haxe,release"')
@:noDebug
#end
class LZMADecoder
{
	private static inline var NUM_STATES = 12;
	private static inline var NUM_POS_BITS_MAX = 4;
	private static inline var NUM_LEN_TO_POS_STATES = 4;
	private static inline var NUM_ALIGN_BITS = 4;
	private static inline var START_POS_MODEL_INDEX = 4;
	private static inline var END_POS_MODEL_INDEX = 14;
	private static inline var NUM_FULL_DISTANCES = 128;
	private static inline var MATCH_MIN_LEN = 2;
	private static inline var PROB_INIT = 1024;

	private var input:Bytes;
	private var inputPosition:Int;
	private var range:Int;
	private var code:Int;
	private var corrupted:Bool;

	private var output:Bytes;
	private var outputLength:Int;

	private var lc:Int;
	private var lp:Int;
	private var pb:Int;
	private var dictionarySize:Int;

	private var literalProbs:Vector<Int>;
	private var posSlotProbs:Vector<Int>;
	private var posProbs:Vector<Int>;
	private var alignProbs:Vector<Int>;
	private var isMatch:Vector<Int>;
	private var isRep:Vector<Int>;
	private var isRepG0:Vector<Int>;
	private var isRepG1:Vector<Int>;
	private var isRepG2:Vector<Int>;
	private var isRep0Long:Vector<Int>;
	private var lenProbs:Vector<Int>;
	private var repLenProbs:Vector<Int>;

	/**
		The decoded data, or null when the stream is not a whole, valid .lzma
		stream.
	**/
	public static function decode(bytes:Bytes):Bytes
	{
		if (bytes == null || bytes.length < 13) return null;

		try
		{
			return new LZMADecoder(bytes).run();
		}
		catch (e:Dynamic)
		{
			return null;
		}
	}

	private function new(bytes:Bytes)
	{
		input = bytes;
	}

	private function run():Bytes
	{
		var properties = input.get(0);
		if (properties >= 9 * 5 * 5) return null;

		lc = properties % 9;
		properties = Std.int(properties / 9);
		lp = properties % 5;
		pb = Std.int(properties / 5);

		dictionarySize = input.getInt32(1);
		// Below 4 KiB, the window is 4 KiB
		if (ltUnsigned(dictionarySize, 1 << 12)) dictionarySize = 1 << 12;

		var sizeLow = input.getInt32(5);
		var sizeHigh = input.getInt32(9);
		var sizeDefined = !(sizeLow == -1 && sizeHigh == -1);
		// Larger sizes than an Int holds are not read
		if (sizeDefined && (sizeHigh != 0 || sizeLow < 0)) return null;
		var remaining = sizeDefined ? sizeLow : 0;
		var markerIsMandatory = !sizeDefined;

		output = Bytes.alloc(sizeDefined ? remaining : 1 << 16);
		outputLength = 0;

		inputPosition = 13;
		if (!initRangeDecoder()) return null;

		literalProbs = probabilities(0x300 << (lc + lp));
		posSlotProbs = probabilities(NUM_LEN_TO_POS_STATES << 6);
		posProbs = probabilities(1 + NUM_FULL_DISTANCES - END_POS_MODEL_INDEX);
		alignProbs = probabilities(1 << NUM_ALIGN_BITS);
		isMatch = probabilities(NUM_STATES << NUM_POS_BITS_MAX);
		isRep = probabilities(NUM_STATES);
		isRepG0 = probabilities(NUM_STATES);
		isRepG1 = probabilities(NUM_STATES);
		isRepG2 = probabilities(NUM_STATES);
		isRep0Long = probabilities(NUM_STATES << NUM_POS_BITS_MAX);
		lenProbs = lengthProbabilities();
		repLenProbs = lengthProbabilities();

		var rep0 = 0, rep1 = 0, rep2 = 0, rep3 = 0;
		var state = 0;
		var finished = false;

		while (true)
		{
			if (sizeDefined && remaining == 0 && !markerIsMandatory && code == 0)
			{
				// Finished without an end marker
				finished = true;
				break;
			}

			var posState = outputLength & ((1 << pb) - 1);

			if (decodeBit(isMatch, (state << NUM_POS_BITS_MAX) + posState) == 0)
			{
				if (sizeDefined && remaining == 0) return null;

				decodeLiteral(state, rep0);
				state = state < 4 ? 0 : (state < 10 ? state - 3 : state - 6);
				remaining--;
				continue;
			}

			var length:Int;

			if (decodeBit(isRep, state) != 0)
			{
				if (sizeDefined && remaining == 0) return null;
				if (outputLength == 0) return null;

				if (decodeBit(isRepG0, state) == 0)
				{
					if (decodeBit(isRep0Long, (state << NUM_POS_BITS_MAX) + posState) == 0)
					{
						// A short rep: one byte from rep0
						state = state < 7 ? 9 : 11;
						putByte(getByte(rep0 + 1));
						remaining--;
						continue;
					}
				}
				else
				{
					var distance:Int;

					if (decodeBit(isRepG1, state) == 0)
					{
						distance = rep1;
					}
					else
					{
						if (decodeBit(isRepG2, state) == 0)
						{
							distance = rep2;
						}
						else
						{
							distance = rep3;
							rep3 = rep2;
						}

						rep2 = rep1;
					}

					rep1 = rep0;
					rep0 = distance;
				}

				length = decodeLength(repLenProbs, posState);
				state = state < 7 ? 8 : 11;
			}
			else
			{
				rep3 = rep2;
				rep2 = rep1;
				rep1 = rep0;
				length = decodeLength(lenProbs, posState);
				state = state < 7 ? 7 : 10;
				rep0 = decodeDistance(length);

				if (rep0 == -1)
				{
					// The end marker
					finished = code == 0;
					break;
				}

				if (sizeDefined && remaining == 0) return null;
				if (!ltUnsigned(rep0, dictionarySize) || !ltUnsigned(rep0, outputLength)) return null;
			}

			length += MATCH_MIN_LEN;
			var tooLong = false;

			if (sizeDefined && remaining < length)
			{
				length = remaining;
				tooLong = true;
			}

			copyMatch(rep0 + 1, length);
			remaining -= length;

			if (tooLong) return null;
		}

		if (!finished || corrupted) return null;
		if (sizeDefined && remaining != 0) return null;

		return output.sub(0, outputLength);
	}

	// Range decoding

	private function initRangeDecoder():Bool
	{
		corrupted = false;
		range = -1;
		code = 0;

		var first = readByte();

		for (i in 0...4)
		{
			code = (code << 8) | readByte();
		}

		if (first != 0 || code == range) corrupted = true;
		return !corrupted;
	}

	private inline function readByte():Int
	{
		// Running out of data is a truncated stream
		if (inputPosition >= input.length) throw "truncated";
		return input.get(inputPosition++);
	}

	private inline function normalize():Void
	{
		if (ltUnsigned(range, 1 << 24))
		{
			range = range << 8;
			code = (code << 8) | readByte();
		}
	}

	private function decodeBit(probs:Vector<Int>, index:Int):Int
	{
		var probability = probs[index];
		var bound = ((range >>> 11) * probability) | 0;
		var symbol:Int;

		if (ltUnsigned(code, bound))
		{
			probability += (2048 - probability) >>> 5;
			range = bound;
			symbol = 0;
		}
		else
		{
			probability -= probability >>> 5;
			code = (code - bound) | 0;
			range = (range - bound) | 0;
			symbol = 1;
		}

		probs[index] = probability;
		normalize();
		return symbol;
	}

	private function decodeDirectBits(count:Int):Int
	{
		var result = 0;

		while (count-- > 0)
		{
			range = range >>> 1;
			code = (code - range) | 0;
			var t = 0 - (code >>> 31);
			code = (code + (range & t)) | 0;
			if (code == range) corrupted = true;
			normalize();
			result = (result << 1) + (t + 1);
		}

		return result;
	}

	private function bitTree(probs:Vector<Int>, offset:Int, bits:Int):Int
	{
		var m = 1;

		for (i in 0...bits)
		{
			m = (m << 1) + decodeBit(probs, offset + m);
		}

		return m - (1 << bits);
	}

	private function bitTreeReverse(probs:Vector<Int>, offset:Int, bits:Int):Int
	{
		var m = 1;
		var symbol = 0;

		for (i in 0...bits)
		{
			var bit = decodeBit(probs, offset + m);
			m = (m << 1) + bit;
			symbol |= bit << i;
		}

		return symbol;
	}

	// LZMA

	private function decodeLiteral(state:Int, rep0:Int):Void
	{
		var previous = outputLength > 0 ? getByte(1) : 0;
		var literalState = ((outputLength & ((1 << lp) - 1)) << lc) + (previous >>> (8 - lc));
		var offset = 0x300 * literalState;
		var symbol = 1;

		if (state >= 7)
		{
			var matchByte = getByte(rep0 + 1);

			do
			{
				var matchBit = (matchByte >>> 7) & 1;
				matchByte = matchByte << 1;
				var bit = decodeBit(literalProbs, offset + ((1 + matchBit) << 8) + symbol);
				symbol = (symbol << 1) | bit;
				if (matchBit != bit) break;
			}
			while (symbol < 0x100);
		}

		while (symbol < 0x100)
		{
			symbol = (symbol << 1) | decodeBit(literalProbs, offset + symbol);
		}

		putByte(symbol - 0x100);
	}

	// Choice, Choice2, a low and a mid coder of 3 bits per position state, and a high coder of 8 bits
	private static inline var LEN_CHOICE = 0;
	private static inline var LEN_CHOICE_2 = 1;
	private static inline var LEN_LOW = 2;
	private static inline var LEN_MID = LEN_LOW + (1 << NUM_POS_BITS_MAX << 3);
	private static inline var LEN_HIGH = LEN_MID + (1 << NUM_POS_BITS_MAX << 3);
	private static inline var LEN_SIZE = LEN_HIGH + 256;

	private static function lengthProbabilities():Vector<Int>
	{
		return probabilities(LEN_SIZE);
	}

	private function decodeLength(probs:Vector<Int>, posState:Int):Int
	{
		if (decodeBit(probs, LEN_CHOICE) == 0) return bitTree(probs, LEN_LOW + (posState << 3), 3);
		if (decodeBit(probs, LEN_CHOICE_2) == 0) return 8 + bitTree(probs, LEN_MID + (posState << 3), 3);
		return 16 + bitTree(probs, LEN_HIGH, 8);
	}

	private function decodeDistance(length:Int):Int
	{
		var lengthState = length > NUM_LEN_TO_POS_STATES - 1 ? NUM_LEN_TO_POS_STATES - 1 : length;
		var posSlot = bitTree(posSlotProbs, lengthState << 6, 6);
		if (posSlot < START_POS_MODEL_INDEX) return posSlot;

		var directBits = (posSlot >>> 1) - 1;
		var distance = (2 | (posSlot & 1)) << directBits;

		if (posSlot < END_POS_MODEL_INDEX)
		{
			distance += bitTreeReverse(posProbs, distance - posSlot, directBits);
		}
		else
		{
			distance += decodeDirectBits(directBits - NUM_ALIGN_BITS) << NUM_ALIGN_BITS;
			distance += bitTreeReverse(alignProbs, 0, NUM_ALIGN_BITS);
		}

		return distance;
	}

	// The output, which is its own window

	private inline function getByte(distance:Int):Int
	{
		return output.get(outputLength - distance);
	}

	private function putByte(value:Int):Void
	{
		ensureCapacity(1);
		output.set(outputLength++, value);
	}

	private function copyMatch(distance:Int, length:Int):Void
	{
		ensureCapacity(length);

		for (i in 0...length)
		{
			output.set(outputLength, output.get(outputLength - distance));
			outputLength++;
		}
	}

	private function ensureCapacity(count:Int):Void
	{
		if (outputLength + count <= output.length) return;

		var capacity = output.length < 1024 ? 1024 : output.length;
		while (capacity < outputLength + count) capacity *= 2;

		var grown = Bytes.alloc(capacity);
		grown.blit(0, output, 0, outputLength);
		output = grown;
	}

	private static function probabilities(count:Int):Vector<Int>
	{
		var probs = new Vector<Int>(count);
		for (i in 0...count) probs[i] = PROB_INIT;
		return probs;
	}

	private static inline function ltUnsigned(a:Int, b:Int):Bool
	{
		return (a ^ 0x80000000) < (b ^ 0x80000000);
	}
}
