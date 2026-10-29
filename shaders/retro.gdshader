shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float grain = 0.025;
uniform float vhs = 0.0;
uniform float bloom_strength = .20;
uniform bool posterize = false;
uniform vec4 game_bounds = vec4(0.0,0.0,1.0,1.0);
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898,78.233)))*43758.5453); }
void fragment() {
 vec2 uv=SCREEN_UV;
 uv.x+=sin(uv.y*180.0+TIME*2.0)*vhs*0.0015;
 vec3 color=texture(screen_texture,uv).rgb;
 float lightness=dot(color,vec3(.2126,.7152,.0722));
 color=mix(vec3(lightness),color,.90);
 color*=mix(vec3(.94,.98,1.035),vec3(1.015,1.0,.975),smoothstep(.035,.72,lightness));
 if(bloom_strength>0.){
  vec3 bloom=vec3(0.);
  for(int i=0;i<4;i++){
   vec2 axis=i==0?vec2(1.,0.):i==1?vec2(-1.,0.):i==2?vec2(0.,1.):vec2(0.,-1.);
   bloom+=max(texture(screen_texture,uv+axis*SCREEN_PIXEL_SIZE*3.).rgb-vec3(.82),vec3(0.));
   bloom+=max(texture(screen_texture,uv+axis*SCREEN_PIXEL_SIZE*9.).rgb-vec3(.82),vec3(0.))*.65;
   bloom+=max(texture(screen_texture,uv+axis*SCREEN_PIXEL_SIZE*21.).rgb-vec3(.82),vec3(0.))*.38;
  }
  color+=bloom*bloom_strength*.25;
 }
 float noise=hash(floor(FRAGCOORD.xy)+floor(TIME*18.0));
 color+=(noise-.5)*grain;
 float dither=mod(floor(FRAGCOORD.x)+mod(floor(FRAGCOORD.y),2.0)*2.0,4.0)/4.0;
 if(posterize)color=floor(color*191.0+dither)/191.0;
 color*=1.0-.18*pow(length((SCREEN_UV-.5)*1.1),1.5);
 color*=1.0-vhs*.06*sin(FRAGCOORD.y*3.14);
 vec2 lower=step(game_bounds.xy,SCREEN_UV);
 vec2 upper=step(SCREEN_UV,game_bounds.zw);
 COLOR=vec4(color*lower.x*lower.y*upper.x*upper.y,1.0);
}
