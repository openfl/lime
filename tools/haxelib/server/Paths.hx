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
package haxelib.server;

import neko.Web;
import haxe.io.*;

/**
	Absolute path.
*/
typedef AbsPath = String;

/**
	Relative path.
*/
typedef RelPath = String;

class Paths {
	static public var CWD(default, null):AbsPath =
		#if haxelib_api
			Path.normalize(Path.join([Web.getCwd(), "..", ".."]));
		#elseif haxelib_legacy
			Path.normalize(Path.join([Web.getCwd(), ".."]));
		#else
			Web.getCwd();
		#end
	static public var DB_CONFIG_NAME(default, null):RelPath = "dbconfig.json";
	static public var DB_CONFIG(default, null):AbsPath = Path.join([CWD, DB_CONFIG_NAME]);
	static public var DB_FILE_NAME(default, null):RelPath = "haxelib.db";
	static public var DB_FILE(default, null):AbsPath = Path.join([CWD, DB_FILE_NAME]);

	static public var TMP_DIR_NAME(default, null):RelPath = "tmp";
	static public var TMP_DIR(default, null):AbsPath = Path.join([CWD, TMP_DIR_NAME]);
	static public var REP_DIR_NAME(default, null):RelPath = Data.REPOSITORY;
}