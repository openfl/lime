//http://glsl.heroku.com/e#6175.0


uniform float time;
uniform vec2 resolution;
uniform vec4 mouse;
uniform sampler2D tex0;
uniform sampler2D tex1;

const float M_PI = 3.14159265358979323846;

struct SphereIntersection
{
	// IN:
	vec4 sphere;
	vec3 ro;
	vec3 rd;
	// OUT:
	float t;
	vec3 pos;
	vec3 normal;
	float depth;
};

float saturate(float f)
{
	return clamp(f,0.0,1.0);
}

vec3 saturate(vec3 v)
{
	return clamp(v,vec3(0,0,0),vec3(1,1,1));
}

// ... I went on the internet and I found THIS
float rand(vec2 co)
{
	return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

// Theta, Phi (r == 1)
vec2 normalToSpherical(vec3 normal)
{
	vec2 spherical;
	// Flip ZY. 
	normal.yz = normal.zy;
	spherical.x = atan(normal.y,normal.x); // Theta
	spherical.y = acos(normal.z); // Phi
	return spherical;
}

// Input: Theta, Phi
vec3 sphericalToCartesian(vec2 s)
{
	vec3 cart;
	cart.x = cos(s.x) * sin(s.y);
	cart.y = sin(s.x) * sin(s.y);
	cart.z = cos(s.y);
	// Flip ZY
	cart.yz = cart.zy;
	return cart;
}

// Ray origin, Ray direction, (Sphere center, Sphere radius)
void raySphere(inout SphereIntersection i)
{
	vec4 sphere = i.sphere;
	vec3 ro = i.ro;
	vec3 rd = i.rd;
	vec3 sc = sphere.xyz;
	float sr = sphere.w;
	vec3 sd = ro-sc;
	// a == 1
	float b = 2.0*dot(rd,sd);
	float c = dot(sd,sd)-(sr*sr);
	float disc = b*b - 4.0*c;
	if(disc<0.0)
	{
		i.t = -1.0;
		return;
	}
	float t = (-b-sqrt(disc))/2.0;
	i.t = t;
	i.pos = ro+rd*t;
	i.normal = normalize(i.pos-sphere.xyz);
	i.depth = 2.0*sr*dot(normalize(sd),i.normal);
}

vec3 sphereNormal(vec4 sphere, vec3 point)
{
	return normalize(point-sphere.xyz);
}

float sphereFunction(vec2 coord)
{
	coord.x -= time/4.0;
	coord.y += sin(time/4.0);
	float thetaCoeff = 24.0;
	float phiCoeff = 16.0;
	float height = 0.8;
	height += (sin(3.0*coord.y)*sin(4.0*coord.x))/10.0;
	height += (sin(16.0*coord.y)*sin(24.0*coord.x))/10.0;
	return height;
}

vec3 sphereFunctionNormal(vec2 coord, vec4 sphere)
{
	// Approximates the local slope of the heightfield function
	float d = 0.01;
	vec2 s0coord = coord; // Center
	vec2 s1coord = coord+vec2(d,0); // +X = +Theta
	vec2 s2coord = coord+vec2(0,-d); // +Y = -Phi
	// Sample heightfield
	float s0 = sphereFunction(s0coord) * sphere.w;
	float s1 = sphereFunction(s1coord) * sphere.w;
	float s2 = sphereFunction(s2coord) * sphere.w;
	// Convert samples to cartesian
	vec3 s0c = sphericalToCartesian(s0coord)*s0;
	vec3 s1c = sphericalToCartesian(s1coord)*s1;
	vec3 s2c = sphericalToCartesian(s2coord)*s2;
	// Tangent space
	vec3 x = s1c-s0c;
	vec3 y = s2c-s0c;
	vec3 normal = normalize(cross(y,x));
	return normal;
}

void rayMarchSphere(inout SphereIntersection i)
{
	const float NUM_SAMPLES = 50.0;
	vec3 pos = i.pos;
	vec3 dir = i.rd;
	float stepSize = i.depth/NUM_SAMPLES;
	
	// No hit
	i.t = -1.0;
	
	for(float s = 0.0; s < NUM_SAMPLES; s++)
	{
		if(s == 0.0)
		{
			pos += dir*stepSize*rand(gl_FragCoord.xy);
		}
		vec3 v = pos-i.sphere.xyz;
		float height = length(v);
		vec3 n = v/height;
		vec2 sCoord = normalToSpherical(n);
		float testHeight = sphereFunction(sCoord)*i.sphere.w;
		testHeight += 0.000001; // Prevent floating point error
		if(height<=testHeight)
		{
			i.t = length(pos-i.ro);
			i.pos = pos;
			i.normal = n;
			i.normal = sphereFunctionNormal(sCoord,i.sphere);
			return;
		}
		pos += dir*stepSize;
	}
	return;
}

vec3 lighting(vec3 point, vec3 N, vec3 light, vec3 color)
{
	vec3 toLight = light-point;
	vec3 L = normalize(toLight);
	return color*saturate(dot(N,L));
}

void rayMarchedSphereIntersection(inout SphereIntersection i)
{
	// First intersect the sphere
	raySphere(i);
	// Then raymarch the heightfield
	if(i.t > 0.0)
	{
		rayMarchSphere(i);
	}
}

void main(void)
{
	vec2 screenPos = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
	vec2 screenPosAR = vec2(screenPos.x*(resolution.x/resolution.y),screenPos.y);
	
	vec3 rayDir = normalize(vec3(screenPosAR.x,screenPosAR.y,1.0));
	vec3 light = vec3(sin(time/4.0)*3.0,cos(time/5.0)*3.0,-2.0);
	vec4 sphere = vec4(0.0,0.0,3.0,2.2);
	
	SphereIntersection inter;
	inter.ro = vec3(0,0,0);
	inter.rd = rayDir;
	inter.sphere = sphere;
	rayMarchedSphereIntersection(inter);
	//raySphere(inter);
	
	vec3 color;
	if(inter.t > 0.0)
	{
		float shadowFactor = 1.0;
		SphereIntersection shadowInter;
		vec3 lightDir = normalize(light-inter.pos);
		shadowInter.ro = inter.pos;
		shadowInter.rd = lightDir;
		shadowInter.pos = inter.pos+lightDir*0.1;
		shadowInter.sphere = sphere;
		shadowInter.depth = sphere.w;
		rayMarchSphere(shadowInter);
		if(shadowInter.t > 0.0)
		{
			//shadowFactor = 0.0;
		}
		// Some crazy colors
		vec3 diffuse = normalize(normalize(inter.pos-sphere.xyz)+vec3(abs(sin(time/4.0)),abs(cos(time/5.0)),abs(sin(time/5.0)*2.0)));
		color.xyz = lighting(inter.pos, inter.normal, light, diffuse) * shadowFactor;
		color.xyz += saturate(inter.normal.zzz+0.50)*diffuse; // Some fake backlighting
	}
	else
	{
		color.xyz = vec3(0,0,0);
	}
	
	gl_FragColor.xyz = color;
	gl_FragColor.w = 1.0;
}