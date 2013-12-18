
attribute vec3 position;
attribute vec2 surfacePosAttrib;
varying vec2 surfacePosition;

void main() {
	
	surfacePosition = surfacePosAttrib;
	gl_Position = vec4( position, 1.0 );
	
}