//http://glsl.heroku.com/e#5805.18


uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float function_f (float x) {
	return 	+ mouse.y * 0.5 * 2.0 * resolution.y / 4.0 / (1.0 + exp((x+200.0)*0.1))
		- mouse.y * 0.5 * 2.0 * resolution.y / 4.0 / (1.0 + exp((x+100.0)*0.1))
		+ mouse.y * 0.5 * 2.0 * resolution.y / 4.0 / (1.0 + exp(x*0.1))
		- mouse.y * 0.5 * 2.0 * resolution.y / 4.0 / (1.0 + exp((x-100.0)*0.1))
		+ mouse.y * 0.5 * 2.0 * resolution.y / 4.0 / (1.0 + exp((x-200.0)*0.1))
		+ sin(x*0.1 - time*10.0 + mouse.x * 10.0)*50.0;
}

float function_g (float x) {
	return 	- mouse.y * 0.5 * 2.0 * resolution.y / 4.0 / (1.0 + exp((x+200.0)*0.1))
		+ mouse.y * 0.5 * 2.0 * resolution.y / 4.0 / (1.0 + exp((x+100.0)*0.1))
		- mouse.y * 0.5 * 2.0 * resolution.y / 4.0 / (1.0 + exp(x*0.1))
		+ mouse.y * 0.5 * 2.0 * resolution.y / 4.0 / (1.0 + exp((x-100.0)*0.1))
		- mouse.y * 0.5 * 2.0 * resolution.y / 4.0 / (1.0 + exp((x-200.0)*0.1))
		+ sin(x*0.1 + time*5.0 - mouse.x * 10.0)*50.0;
}


void main( void ) {
	
	vec3 color_1 = vec3(0.25, sin(time), cos(time));
	vec3 color_2 = vec3(0.5, 0.25, cos(time));
	
	vec2 pos = gl_FragCoord.xy;
	
	pos.y -= resolution.y / 2.0;
	pos.x -= resolution.x / 2.0;
	
	float intensity_f = 16.0 / abs(pos.y - function_f(pos.x));
	intensity_f = pow(intensity_f, 0.5);
	
	float intensity_g = 16.0 / abs(pos.y - function_g(pos.x));
	intensity_g += pow(intensity_g, 0.5);
	
	gl_FragColor = vec4((color_1 * intensity_f + color_2 * intensity_g)*mod(gl_FragCoord.y, 2.0), 1);
}