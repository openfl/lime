::if embeddedLibraries::::foreach (embeddedLibraries)::
::__current__::::end::::end::
// lime.embed namespace wrapper
(function ($hx_exports, $global) { "use strict";
$hx_exports.lime = $hx_exports.lime || {};
$hx_exports.lime.$scripts = $hx_exports.lime.$scripts || {};
$hx_exports.lime.$scripts["::APP_FILE::"] = (function(exports, global) {
::SOURCE_FILE::
});
// End namespace wrapper
$hx_exports.lime.embed = function(projectName) { var exports = {};
	$hx_exports.lime.$scripts[projectName](exports, $global);
	for (var key in exports) $hx_exports[key] = $hx_exports[key] || exports[key];
	exports.lime.embed.apply(exports.lime, arguments);
	return exports;
};
})(typeof exports != "undefined" ? exports : typeof window != "undefined" ? window : typeof self != "undefined" ? self : this, typeof window != "undefined" ? window : typeof global != "undefined" ? global : typeof self != "undefined" ? self : this);
