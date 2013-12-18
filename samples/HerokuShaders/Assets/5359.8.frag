//http://glsl.heroku.com/e#5359.8


uniform float time;
uniform vec2 resolution;


// NEBULA - CoffeeBreakStudios.com (CBS)
// Work in progress....
//
// 3148.26: Switched from classic to simplex noise
// 3148.27: Reduced number of stars
// 3249.0:  Switched to fast computed 3D noise. Less quality but ~ 2x faster
// 3249.5:  Removed use of random number generator to gain performance
// 3265.0:  Added rotation: glsl.heroku.com/e#3005.1
// 3265.6:  Faster random number generator
// 5359.0:  Added Barrel distortion and different starfield: http://glsl.heroku.com/e#5334.3

//Utility functions

vec3 fade(vec3 t) {
  return vec3(1.0,1.0,1.0);
}

vec2 rotate(vec2 point, float rads) {
	float cs = cos(rads);
	float sn = sin(rads);
	return point * mat2(cs, -sn, sn, cs);
}	

vec4 randomizer4(const vec4 x)
{
	vec4 z = mod(x, vec4(5612.0));
	z = mod(z, vec4(3.1415927 * 2.0));
	return(fract(cos(z) * vec4(56812.5453)));
}

float rand(vec2 co){
	return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// Fast computed noise
// http://www.gamedev.net/topic/502913-fast-computed-noise/

const float A = 1.0;
const float B = 57.0;
const float C = 113.0;
const vec3 ABC = vec3(A, B, C);
const vec4 A3 = vec4(0, B, C, C+B);
const vec4 A4 = vec4(A, A+B, C+A, C+A+B);

float cnoise4(const in vec3 xx)
{
	vec3 x = mod(xx + 32768.0, 65536.0);
	vec3 ix = floor(x);
	vec3 fx = fract(x);
	vec3 wx = fx*fx*(3.0-2.0*fx);
	float nn = dot(ix, ABC);
	
	vec4 N1 = nn + A3;
	vec4 N2 = nn + A4;
	vec4 R1 = randomizer4(N1);
	vec4 R2 = randomizer4(N2);
	vec4 R = mix(R1, R2, wx.x);
	float re = mix(mix(R.x, R.y, wx.y), mix(R.z, R.w, wx.y), wx.z);
	
	return 1.0 - 2.0 * re;
}
float surface3 ( vec3 coord, float frequency ) {
	
	float n = 0.0;	
		
	n += 1.0	* abs( cnoise4( coord * frequency ) );
	n += 0.5	* abs( cnoise4( coord * frequency * 2.0 ) );
	n += 0.25	* abs( cnoise4( coord * frequency * 4.0 ) );
	n += 0.125	* abs( cnoise4( coord * frequency * 8.0 ) );
	n += 0.0625	* abs( cnoise4( coord * frequency * 16.0 ) );
	
	return n;
}

vec2 barrelDistortion(vec2 coord) {
	vec2 cc = coord;// - 0.5;
	float dist = dot(cc, cc);
	return coord + cc * (dist * dist) * .4;
}

void main( void ) {
	float rads = radians(time*3.15);
	//vec2 position = gl_FragCoord.xy / resolution.xy;
	vec2 position=barrelDistortion(-1.0+2.0*((gl_FragCoord.xy)/resolution.xy));
	vec2 positionStars = ( gl_FragCoord.xy -  resolution.xy*.5 ) / resolution.x;
	position += rotate(position, rads);
	float n = surface3(vec3(position*sin(time*0.1), time * 0.05)*mat3(1,sin(1.0),0,0,.8,.6,0,-.6,.8),0.9);
	float n2 = surface3(vec3(position*cos(time*0.1), time * 0.04)*mat3(1,cos(1.0),0,0,.8,.6,0,-.6,.8),0.8);
		float lum = length(n);
		float lum2 = length(n2);
	
	vec3 tc = pow(vec3(1.0-lum),vec3(sin(position.x)+cos(time)+4.0,8.0+sin(time)+4.0,8.0));
	vec3 tc2 = pow(vec3(1.1-lum2),vec3(5.0,position.y+cos(time)+7.0,sin(position.x)+sin(time)+2.0));
	vec3 curr_color = (tc*0.8) + (tc2*0.5);
	
	
	// 256 angle steps
	float angle = atan(positionStars.y,positionStars.x)/(2.*3.14159265359);
	angle += rads*0.5;
	angle -= floor(angle);
	
	float rad = length(positionStars);
	
	float color = 0.0;
	for (int i = 0; i < 10; i++) {
		float angleFract = fract(angle*256.);
		float angleRnd = floor(angle*256.)+1.;
		float angleRnd1 = fract(angleRnd*fract(angleRnd*.7235)*45.1);
		float angleRnd2 = fract(angleRnd*fract(angleRnd*.82657)*13.724);
		float t = time+angleRnd1*10.;
		float radDist = sqrt(angleRnd2+float(i));
		
		float adist = radDist/rad*.1;
		float dist = (t*.1+adist);
		dist = abs(fract(dist)-.5);
		color += max(0.,.5-dist*40./adist)*(.5-abs(angleFract-.5))*5./adist/radDist;
		
		angle = fract(angle+.61);
	}
	float color1 = color*rad;
	
	//curr_color += color/(n+n2);
	
	
	gl_FragColor = vec4(curr_color, 1.0)+vec4( color1,color1,color,color1)/(n+n2);
}