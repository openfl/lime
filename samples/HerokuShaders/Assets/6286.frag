//http://glsl.heroku.com/e#6286.0


uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
varying vec2 surfacePosition;

void main( void ) {
	vec2 p = surfacePosition;
	float speed = 0.45;
	vec3 color = vec3(.4,.1,.8);
	vec2 loc =  vec2(cos(time/1.6*speed)/1.9-cos(time/.8*speed)/3.8,
			sin(time/1.6*speed)/1.9-sin(time/.8*speed)/3.8
			);
	float depth;
	for(int i = 0; i < 100; i+=1){
		p = vec2(p.x*p.x-p.y*p.y,2.0*p.x*p.y)+loc;
		depth = float(i);
		if((p.x*p.x+p.y*p.y) >= 4.0) break;
	}
	gl_FragColor = vec4(clamp(color*depth*0.05, 0.0, 10.0)*mod(gl_FragCoord.y, 2.0), 1.0 );
}