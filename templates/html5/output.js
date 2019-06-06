(function ($hx_exports, $global) { "use strict"; var $hx_script = (function (exports, global) { ::SOURCE_FILE::
});
var $js_include = (function() { ::if embeddedLibraries::::foreach (embeddedLibraries)::
var module=undefined,exports=undefined,define=undefined;
::__current__::
::end::::end::});
$hx_exports.lime = $hx_exports.lime || {};
$hx_exports.lime.$scripts = $hx_exports.lime.$scripts || {};
$hx_exports.lime.$scripts["::APP_FILE::"] = $hx_script;
$hx_exports.lime.embed = function(projectName) { var exports = {};
	var script = $hx_exports.lime.$scripts[projectName];
	if (!script) throw Error("Cannot find project name \"" + projectName + "\"");
    script(exports, $global);
	for (var key in exports) $hx_exports[key] = $hx_exports[key] || exports[key];
    $js_include();
	var lime = exports.lime || window.lime;
	if (lime && lime.embed && this != lime.embed) lime.embed.apply(lime, arguments);
	return exports;
};
})(typeof exports != "undefined" ? exports : typeof window != "undefined" ? window : typeof self != "undefined" ? self : this, typeof window != "undefined" ? window : typeof global != "undefined" ? global : typeof self != "undefined" ? self : this);