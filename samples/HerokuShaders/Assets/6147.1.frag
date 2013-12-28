//http://glsl.heroku.com/e#6147.1


#define PI 3.14159265
uniform float time;
uniform vec2 mouse, resolution;

vec3 sim(vec3 p,float s); //.h
vec2 rot(vec2 p,float r);
vec2 rotsim(vec2 p,float s);

vec2 makeSymmetry(vec2 p){ //nice stuff :)
   vec2 ret=p;
   ret=rotsim(p, 6.0);
   ret.x=abs(ret.x);
   return ret;
}

float makePoint(float x,float y,float fx,float fy,float sx,float sy,float t){
   
   float xx=x+tan(t * fx)*sy;
   float yy=y-tan(t * fx)*sy;
   return 0.8/sqrt(abs(x*xx+yy*yy));
}

vec2 sim(vec2 p,float s){
   vec2 ret=p;
   ret=p+s/2.0;
   ret=fract(ret/s)*s-s/2.0;
   return ret;
}

vec2 rot(vec2 p,float r){
   vec2 ret;
   ret.x=p.x*cos(r)-p.y*sin(r);
   ret.y=p.x*sin(r)+p.y*cos(r);
   return ret;
}

vec2 rotsim(vec2 p,float s){
   float k = atan(p.x, p.y);
   vec2 ret=rot(p,floor((k + PI/(s*2.0)) / PI*s)*(PI/s));
   return ret;
}

void main( void ) {
   vec2 p=(gl_FragCoord.xy/resolution.x)*2.0-vec2(1.0,resolution.y/resolution.x);
   p=makeSymmetry(p); 
   float x=p.x;
   float y=p.y;
   float t=time*0.2;
   float a= makePoint(x,y,3.3,2.9,0.3,0.3,t);
//        a=a+makePoint(x,y,1.8,1.7,0.5,0.4,t);      
   float b=makePoint(x,y,1.2,1.9,0.3,0.3,t);
//       b=b+makePoint(x,y,0.7,2.7,0.4,0.4,t);
   float c=makePoint(x,y,3.7,0.3,0.3,0.3,t);
//       c=c+makePoint(x,y,0.8,0.9,0.4,0.5,t);   
  gl_FragColor = vec4(a/5.,b/5.,c/5.,1.0);
}