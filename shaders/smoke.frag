#include <flutter/runtime_effect.glsl>

uniform float uTime;
uniform vec2 uResolution;
uniform float uColorR;
uniform float uColorG;
uniform float uColorB;
uniform float uDark;

out vec4 fragColor;

#define FC FlutterFragCoord().xy
#define R uResolution
#define T (uTime+660.)

float rnd(vec2 p){p=fract(p*vec2(12.9898,78.233));p+=dot(p,p+34.56);return fract(p.x*p.y);}
float noise(vec2 p){vec2 i=floor(p),f=fract(p),u=f*f*(3.-2.*f);return mix(mix(rnd(i),rnd(i+vec2(1,0)),u.x),mix(rnd(i+vec2(0,1)),rnd(i+1.),u.x),u.y);}
float fbm(vec2 p){float t=.0,a=1.;for(int i=0;i<5;i++){t+=a*noise(p);p*=mat2(1,-1.2,.2,1.2)*2.;a*=.5;}return t;}

void main(){
  vec2 uv=(FC-.5*R)/R.y;
  vec3 col=vec3(1);
  uv.x+=.25;
  uv*=vec2(2,1);

  float n=fbm(uv*.28-vec2(T*.01,0));
  n=noise(uv*3.+n*2.);

  col.r-=fbm(uv+vec2(0,T*.015)+n);
  col.g-=fbm(uv*1.003+vec2(0,T*.015)+n+.003);
  col.b-=fbm(uv*1.006+vec2(0,T*.015)+n+.006);

  vec3 u_color=vec3(uColorR,uColorG,uColorB);
  col=mix(col,u_color,dot(col,vec3(.21,.71,.07)));

  // Dark mode: clamp to dark base. Light mode: invert so base is white.
  float lo=mix(.92,0.08,uDark);
  float hi=1.;
  if(uDark<.5){
    col=1.-col;
  }
  col=clamp(col,lo,hi);
  fragColor=vec4(col,1);
}
