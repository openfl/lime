//http://glsl.heroku.com/e#6238.0


uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

void main( void ) {
	
	vec3 color1 = vec3(1.7, 0.25, 0.5);
	vec3 color2 = vec3(0.5, 0.7, 0.25);
	vec3 color3 = vec3(0.25, 0.5, 0.7);
	
	vec2 point1 = resolution/2.0 + vec2(sin(time*2.0) * 10.0, cos(time*2.0) * 5.0);
	vec2 point2 = resolution/2.0 + vec2(sin(time)*75.0, cos(time)*50.0);
	vec2 point3 = resolution/2.0 + vec2(sin(time)*25.0, sin(time*2.0)*50.0)*2.0;
	
	vec2 dist1 = gl_FragCoord.xy - point1;
	float intensity1 = pow(32.0/(0.01+length(dist1)), 2.0);
	
	vec2 dist2 = gl_FragCoord.xy - point2;
	float intensity2 = pow(3.0/(0.01+length(dist2)), 2.0);
	
	vec2 dist3 = gl_FragCoord.xy - point3;
	float intensity3 = pow(62.0/(0.01+length(dist3)), 1.0);
	
	gl_FragColor = vec4((color1*intensity1 + color2*intensity2 + color3*intensity3)*mod(gl_FragCoord.y, 2.0),1.0);
}