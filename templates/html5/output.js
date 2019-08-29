(function ($hx_exports, $global) { "use strict"; var $hx_script = (function (exports, global) { ::SOURCE_FILE::
});
$hx_exports.lime = $hx_exports.lime || {};
$hx_exports.lime.$scripts = $hx_exports.lime.$scripts || {};
$hx_exports.lime.$scripts["::APP_FILE::"] = $hx_script;
$hx_exports.lime.embed = function(projectName) { var exports = {};
	var script = $hx_exports.lime.$scripts[projectName];
	if (!script) throw Error("Cannot find project name \"" + projectName + "\"");
	script(exports, $global);
	for (var key in exports) $hx_exports[key] = $hx_exports[key] || exports[key];
	var lime = exports.lime || window.lime;
	if (lime && lime.embed && this != lime.embed) lime.embed.apply(lime, arguments);
	return exports;
};
::if false::
	AMD compatibility: If define() is present we need to
	- call it, to define our module
	- disable it so that the embedded libraries register themselves in the global scope!
::end::if(typeof define == "function" && define.amd) {
	define([], function() { return $hx_exports.lime; });
	define.__amd = define.amd;
	define.amd = null;
}
})(typeof exports != "undefined" ? exports : typeof define == "function" && define.amd ? {} : typeof window != "undefined" ? window : typeof self != "undefined" ? self : this, typeof window != "undefined" ? window : typeof global != "undefined" ? global : typeof self != "undefined" ? self : this);
::if embeddedLibraries::::foreach (embeddedLibraries)::
::__current__::::end::::end::
if(typeof define == "function" && define.__amd) {
	define.amd = define.__amd;
	delete define.__amd;
}