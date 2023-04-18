const path = require ('path');

module.exports = {
	entry: "./../haxe/::if DEBUG::debug.hxml::else::::if FINAL::final.hxml::else::release.hxml::end::::end::",
	output: {
		path: path.resolve (__dirname, "dist"),
		filename: "::OUTPUT_FILE::",
		library: "lime",
		libraryTarget: 'window',
		libraryExport: 'lime'
	},
	module: {
		rules: [
			{
				test: /\.hxml$/,
				loader: 'haxe-loader',
			}
		]
	}
};