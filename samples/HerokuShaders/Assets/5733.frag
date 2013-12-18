//http://glsl.heroku.com/e#5733.0


uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
varying vec2 surfacePosition;


void main( void ) {
	vec2 p = surfacePosition;
	float speed = 0.25;
	vec3 color = vec3(0.5,0.2,0.1);
	vec2 loc =  vec2(cos(time/4.0*speed)/1.9-cos(time/2.0*speed)/3.8,
			sin(time/4.0*speed)/1.9-sin(time/2.0*speed)/3.8
			);
	float depth;
	for(int i = 0; i < 100; i+=1){
		p = vec2(p.x*p.x-p.y*p.y,2.0*p.y*p.x)+loc;
		depth = float(i);
		if((p.x*p.x-p.y*p.y) >= 25.0) break;
	}
	gl_FragColor = vec4(clamp(color*depth*0.9, 0.0, 2.0)*mod(gl_FragCoord.y, 2.0), 2.0 );
}