//http://glsl.heroku.com/e#4278.1


uniform float time;
uniform vec2 resolution;
uniform vec2 mouse;

mat3 genRotMat(float a0,float x,float y,float z){
float a=a0*3.1415926535897932384626433832795/180.0;
  return mat3(
	1.0+(1.0-cos(a))*(x*x-1.0),
	-z*sin(a)+(1.0-cos(a))*x*y,
	y*sin(a)+(1.0-cos(a))*x*z,
	z*sin(a)+(1.0-cos(a))*x*y,
	1.0+(1.0-cos(a))*(y*y-1.0),
	-x*sin(a)+(1.0-cos(a))*y*z,
	-y*sin(a)+(1.0-cos(a))*x*z,
	x*sin(a)+(1.0-cos(a))*y*z,
	1.0+(1.0-cos(a))*(z*z-1.0)
  );
}

float cubeDist(vec3 p){
  return max(abs(p.x),max(abs(p.y),abs(p.z)));
}

void main(){
  float spread=1.0;
  float total=0.0;
  float delta=0.01;
  float cameraZ=-1.75;
  float nearZ=-1.0;
  float farZ=1.0;
  float gs=0.0;
  int iter=0;
  vec3 col=vec3(0.0,0.0,0.0);
  vec3 ray=vec3(0.0,0.0,0.0);
  mat3 rot=genRotMat(sin(time/4.13)*360.0,1.0,0.0,0.0);
  rot=rot*genRotMat(sin(time/4.64)*360.0,0.0,1.0,0.0);
  rot=rot*genRotMat(sin(time/4.24)*360.0,0.0,0.0,1.0);
  vec2 p=vec2(0.0,0.0);
  p.x=gl_FragCoord.x/resolution.y-0.5*resolution.x/resolution.y;
  p.y=gl_FragCoord.y/resolution.y-0.5;
  ray.xy+=p.xy*spread*(nearZ-cameraZ);
  vec3 rayDir=vec3(spread*p.xy*delta,delta);
  vec3 tempDir=rayDir*rot;
  vec3 norm;
  ray.z=nearZ;
	bool refracted=false;
  for(int i=0;i<250;i++){
	vec3 temp;
	vec3 tempc;
	float val;
	temp=ray.xyz*rot;
	tempc=temp;
	float thres=0.5;
	if(tempc.x<0.0)tempc.x=abs(tempc.x);
	if(tempc.x<thres)tempc.x=0.0;
	else tempc.x=1.0/tempc.x*sin(time);
	if(tempc.y<0.0)tempc.y=abs(tempc.y);
	if(tempc.y<thres)tempc.y=0.0;
	else tempc.y=1.0/tempc.y*sin(time*0.842);
	if(tempc.z<0.0)tempc.z=abs(tempc.z);
	if(tempc.z<thres)tempc.z=0.0;
	else tempc.z=1.0/tempc.z*sin(time*1.132);
	val=cubeDist(temp);
	  if(val<thres && !refracted){
		  rayDir=vec3(0.5*spread*p.xy*delta,delta);
		  refracted=true;
		}
	if(val<0.0)val=abs(val);
	if(val<thres)val=0.0;
	else val=1.0/val;
	col.x+=(val+tempc.x)/2.0;
	col.y+=(val+tempc.y)/2.0;
	col.z+=(val+tempc.z)/2.0;
	ray+=rayDir;
	iter++;
	if(ray.z>=farZ)break;
  }
  col.x=col.x/float(iter);
  col.y=col.y/float(iter);
  col.z=col.z/float(iter);
  gl_FragColor=vec4(col,1.0);
}