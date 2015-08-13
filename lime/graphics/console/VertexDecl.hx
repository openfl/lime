package lime.graphics.console;


@:enum abstract VertexDecl(Int) {

	var Position = 0;				// xyz [3]f32
	var PositionTexcoord = 5;		// xyz [3]f32, uv [2]f32
	var PositionColor = 13;			// xyz [3]f32, rgba [4]u8
	var PositionTexcoordColor = 4;	// xyz [3]f32, uv [2]f32, rgba [4]u8

}

