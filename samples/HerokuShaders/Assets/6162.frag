//http://glsl.heroku.com/e#6162.0


#define PI 3.141592653589793

#define ZOOM (4. - sin(time/2.)*3.)

#define MAX_ITERATION 6
#define ITERATION_BAIL sqrt(PI/2.)

#define MAX_MARCH 50
#define MAX_DISTANCE 2.3

uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;

float DE(vec3 p)
{
	vec3 w = p;
	float dr = 1.;
	float r = 0.;
	for (int i=0; i<MAX_ITERATION; ++i)
	{
		r = length(w);
		if (r>ITERATION_BAIL) break;
		
		dr*=pow(r, 7.)*8.+1.;
		
		float x = w.x; float x2 = x*x; float x4 = x2*x2;
		float y = w.y; float y2 = y*y; float y4 = y2*y2;
		float z = w.z; float z2 = z*z; float z4 = z2*z2;
		
		float k3 = x2 + z2;
		float k2 = inversesqrt( pow(k3, 7.) );
		float k1 = x4 + y4 + z4 - 6.0*y2*z2 - 6.0*x2*y2 + 2.0*z2*x2;
		float k4 = x2 - y2 + z2;
		
		w =  vec3(64.0*x*y*z*(x2-z2)*k4*(x4-6.0*x2*z2+z4)*k1*k2,
			  -16.0*y2*k3*k4*k4 + k1*k1,
			  -8.0*y*k4*(x4*x4 - 28.0*x4*x2*z2 + 70.0*x4*z4 - 28.0*x2*z2*z4 + z4*z4)*k1*k2);
		w+=p;
	} 
	return  .5*log(r)*r/dr;
}

bool inCircle(vec3 p, vec3 d)
{
	float rdt = dot(p, d);
	float rdr = dot(p, p) - 1.253314137315501; // sqrt(PI/2)
	return (rdt*rdt)-rdr>0.;	
}


void main( void )
{
	vec2 pos = (gl_FragCoord.xy*2.0 - resolution.xy) / resolution.y;
	
	vec2 m = vec2(sin(time), cos(time))/ZOOM;
	//m = ((.5-mouse)*PI*2.)/ZOOM;
	m.y = clamp(m.y, -PI/2.+.01, PI/2.-.01);
	
	vec3 camOrigin = vec3(cos(m.x)*cos(m.y), sin(m.y), cos(m.y)*sin(m.x))*2.0;
	vec3 camTarget = vec3(0.0, 0.0, 0.0);
	vec3 camDir = normalize(camTarget - camOrigin);
	vec3 camUp  = normalize(vec3(0.0, 1.0, 0.0));
	vec3 camSide = normalize(cross(camDir, camUp));
	vec3 camCDS = cross(camDir, camSide);
	
	vec3 ray = normalize(camSide*pos.x + camCDS*pos.y + camDir*ZOOM);
	
	float col = 0., col2 = 0., col3 = 0.;
	if (inCircle(camOrigin, ray))
	{
		float m = 1.0, dist = 0.0, total_dist = 0.0;
		
		for(int i=0; i<MAX_MARCH; ++i)
		{
			total_dist += dist;
			dist = DE(camOrigin + ray * total_dist);
			m -= 0.02;
			if(dist<0.002/ZOOM || total_dist>MAX_DISTANCE) break;
		}
		
		col = m;
		col2 = m*2.5-total_dist;
		col3 = m*1.5-total_dist;
		if (total_dist>MAX_DISTANCE) col = 0.;
	}	
	
	gl_FragColor = vec4(col, col2/2., col3*2., 1.0);
}