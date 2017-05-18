/*
 * Copyright (C)2005-2016 Haxe Foundation
 *
 * Permission is hereby granted, free of charge, to any person obtaining a
 * copy of this software and associated documentation files (the "Software"),
 * to deal in the Software without restriction, including without limitation
 * the rights to use, copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons to whom the
 * Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
 * DEALINGS IN THE SOFTWARE.
 */
package haxelib;

import haxe.ds.Option;

using Std;

enum Preview {
	ALPHA;
	BETA;
	RC;
}

abstract SemVer(String) to String {

	public var major(get, never):Int;
	public var minor(get, never):Int;
	public var patch(get, never):Int;
	public var preview(get, never):Null<Preview>;
	public var previewNum(get, never):Null<Int>;
	public var data(get, never):SemVerData;
	public var valid(get, never):Bool;

	inline function new(s) this = s;

	static public function compare(a:SemVer, b:SemVer) {
		function toArray(data:SemVerData)
			return [
				data.major,
				data.minor,
				data.patch,
				if (data.preview == null) 100 else data.preview.getIndex(),
				if (data.previewNum == null) -1 else data.previewNum
			];

		var a = toArray(a.data),
			b = toArray(b.data);

		for (i in 0...a.length)
			switch Reflect.compare(a[i], b[i]) {
				case 0:
				case v: return v;
			}

		return 0;
	}
	@:to public function toValidatable():Validator.Validatable
		return {
			validate:
				function ():Option<String>
					return
						try {
							get_data();
							None;
						}
						catch (e:Dynamic)
							Some(Std.string(e))
		}

	inline function get_major()
		return data.major;

	inline function get_minor()
		return data.minor;

	inline function get_patch()
		return data.patch;

	inline function get_preview()
		return data.preview;

	inline function get_previewNum()
		return data.previewNum;

	inline function get_valid()
		return isValid(this);

	@:op(a > b) static inline function gt(a:SemVer, b:SemVer)
		return compare(a, b) == 1;

	@:op(a >= b) static inline function gteq(a:SemVer, b:SemVer)
		return compare(a, b) != -1;

	@:op(a < b) static inline function lt(a:SemVer, b:SemVer)
		return compare(a, b) == -1;

	@:op(a <= b) static inline function lteq(a:SemVer, b:SemVer)
		return compare(a, b) != 1;

	@:op(a == b) static inline function eq(a:SemVer, b:SemVer)
		return compare(a, b) == 0;

	@:op(a != b) static inline function neq(a:SemVer, b:SemVer)
		return compare(a, b) != 0;

	static var FORMAT = ~/^(\d|[1-9]\d*)\.(\d|[1-9]\d*)\.(\d|[1-9]\d*)(-(alpha|beta|rc)(\.(\d|[1-9]\d*))?)?$/;

	static var cache = new Map();

	@:to function get_data():SemVerData {
		if (!cache.exists(this))
			cache[this] = getData();
		return cache[this];
	}

	@:from static function fromData(data:SemVerData)
		return
			new SemVer(
				data.major + '.' + data.minor + '.' + data.patch +
					if (data.preview == null) ''
					else '-' + data.preview.getName().toLowerCase() +
						if (data.previewNum == null) '';
						else '.' + data.previewNum
			);

	function getData():SemVerData
		return
			if (valid) {//RAPTORS: This query will already cause the matching.
				major: FORMAT.matched(1).parseInt(),
				minor: FORMAT.matched(2).parseInt(),
				patch: FORMAT.matched(3).parseInt(),
				preview:
					switch FORMAT.matched(5) {
						case 'alpha': ALPHA;
						case 'beta': BETA;
						case 'rc': RC;
						case v if (v == null): null;
						case v: throw 'unrecognized preview tag $v';
					},
				previewNum:
					switch FORMAT.matched(7) {
						case null: null;
						case v: v.parseInt();
					}
			}
			else
				throw '$this is not a valid version string';//TODO: include some URL for reference

	static public function isValid(s:String)
		return Std.is(s, String) && FORMAT.match(s.toLowerCase());

	static public function ofString(s:String) {
		var ret = new SemVer(s);
		ret.getData();
		return ret;
	}

	static public var DEFAULT(default, null) = new SemVer('0.0.0');
}

typedef SemVerData =  {
	major:Int,
	minor:Int,
	patch:Int,
	preview:Null<Preview>,
	previewNum:Null<Int>,
}
