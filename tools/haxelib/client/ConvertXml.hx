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
package haxelib.client;

import haxe.Json;

class ConvertXml {
	public static function convert(inXml:String) {
		// Set up the default JSON structure
		var json = {
			"name": "",
			"url" : "",
			"license": "",
			"tags": [],
			"description": "",
			"version": "0.0.1",
			"releasenote": "",
			"contributors": [],
			"dependencies": {}
		};

		// Parse the XML and set the JSON
		var xml = Xml.parse(inXml);
		var project = xml.firstChild();
		json.name = project.get("name");
		json.license = project.get("license");
		json.url = project.get("url");
		for (node in project) {
			switch (node.nodeType) {
				case #if (haxe_ver >= 3.2) Element #else Xml.Element #end:
					switch (node.nodeName) {
						case "tag":
							json.tags.push(node.get("v"));
						case "user":
							json.contributors.push(node.get("name"));
						case "version":
							json.version = node.get("name");
							json.releasenote = node.firstChild().toString();
						case "description":
							json.description = node.firstChild().toString();
						case "depends":
							var name = node.get("name");
							var version = node.get("version");
							if (version == null) version = "";
							Reflect.setField(json.dependencies, name, version);
						default:
					}
				default:
			}
		}

		return json;
	}

	public static function prettyPrint(json:Dynamic, indent="") {
		var sb = new StringBuf();
		sb.add("{\n");

		var firstRun = true;
		for (f in Reflect.fields(json)) {
			if (!firstRun) sb.add(",\n");
			firstRun = false;

			var value = switch (f) {
				case "dependencies":
					var d = Reflect.field(json, f);
					prettyPrint(d, indent + "  ");
				default:
					Json.stringify(Reflect.field(json, f));
			}
			sb.add(indent+'  "$f": $value');
		}

		sb.add('\n$indent}');
		return sb.toString();
	}
}
