//http://glsl.heroku.com/e#6022.0


uniform float time;
uniform vec2 mouse;
uniform vec2 resolution;
varying vec2 surfacePosition;

float rand(vec2 co){
	return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43748.5453);
}
float cerp(float a, float b, float i)
{
	if(i<0.)
		i += 1.;
	i *= 3.14159265;
	i = (1.-cos(i))/2.;
	return a*(1.-i)+b*i;
}
float lerp(float a, float b, float i)
{
	if(i<0.)
		i+=1.;
	return a*(1.-i)+b*i;
}
vec3 lerp(vec3 a, vec3 b, float i)
{
	if(i<0.)
		i+=1.;
	return a*(1.-i)+b*i;
}
float posrand(vec2 pos, float width, float height)
{
	return rand(vec2(int(pos.x*width),int(pos.y*height)));
}
float tdposrand(vec2 pos, float width, float height)
{
	float n1, n2, n3, n4, n5, n6;
	n1 = posrand(pos,width,height);
	n2 = posrand(vec2(pos.x+1./width,pos.y),width,height);
	n3 = posrand(vec2(pos.x,pos.y+1./height),width,height);
	n4 = posrand(vec2(pos.x+1./width,pos.y+1./height),width,height);
	n5 = cerp(n1,n2,pos.x*width-float(int(pos.x*width)));
	n6 = cerp(n3,n4,pos.x*width-float(int(pos.x*width)));
	return cerp(n5,n6,pos.y*height-float(int(pos.y*height)));
}

vec3 readcolpath(vec3 one, vec3 two, vec3 thr, vec3 fou, float i)
{
	int num = int(i*3.);
	if(num==0)
		return lerp(one,two,i*3.-float(num));
	if(num==1)
		return lerp(two,thr,i*3.-float(num));
	if(num==2)
		return lerp(thr,fou,i*3.-float(num));
	return fou;
}
void main( void ) {

	vec2 position = surfacePosition+.5;
	vec2 odd = vec2(0,time/5.);
	vec3 col1 = vec3(1.,0.25,0.);
	vec3 col2 = vec3(.45,0.2,0.);
	vec3 col3 = vec3(0.2,.1,0.);
	vec3 col4 = vec3(.4,.3,.25);
	float color = 0.0;
	position = position*(1.+1./12.)+vec2(length(vec2(tdposrand(position-odd,2.,2.),tdposrand(position*4.3-odd,2.,2.))))/12.;
	if(position.y>0.)
	{
	//color += tdposrand(position-odd,1000.,1000.)/5.;
	color += tdposrand(position-odd,50.,50.)/8.;
	color += tdposrand(position-odd,20.,20.)/3.;
	color += tdposrand(position-odd,10.,10.)/2.;
	color += tdposrand(position-odd,5.,5.);
	color /= position.y*1.;
	}
	else
	{
		color = 16.0;
	}
	gl_FragColor = vec4( vec3( color/2. )*readcolpath(col1,col2,col3,col4,color/16.), 1.0 );
	
}