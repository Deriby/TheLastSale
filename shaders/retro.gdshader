shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, filter_linear;
uniform float grain = 0.025;
uniform float vhs = 0.0;
uniform float bloom_strength = .20;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898,78.233)))*43758.5453); }
void fragment() {
 vec2 uv=SCREEN_UV;
 uv.x+=sin(uv.y*180.0+TIME*2.0)*vhs*0.0015;
 vec3 color=texture(screen_texture,uv).rgb;
 float lightness=dot(color,vec3(.2126,.7152,.0722));
 color=mix(vec3(lightness),color,.90);
 color*=mix(vec3(.91,.97,1.035),vec3(1.025,1.005,.965),smoothstep(.035,.72,lightness));
 if(bloom_strength>0.){
  vec3 bloom=vec3(0.);
  for(int i=0;i<4;i++){
   vec2 axis=i==0?vec2(1.,0.):i==1?vec2(-1.,0.):i==2?vec2(0.,1.):vec2(0.,-1.);
   bloom+=max(texture(screen_texture,uv+axis*SCREEN_PIXEL_SIZE*3.).rgb-vec3(.74),vec3(0.));
   bloom+=max(texture(screen_texture,uv+axis*SCREEN_PIXEL_SIZE*7.).rgb-vec3(.74),vec3(0.))*.65;
  }
  color+=bloom*bloom_strength*.25;
 }
 float noise=hash(floor(FRAGCOORD.xy)+floor(TIME*18.0));
 color+=(noise-.5)*grain;
 float dither=mod(floor(FRAGCOORD.x)+mod(floor(FRAGCOORD.y),2.0)*2.0,4.0)/4.0;
 color=floor(color*191.0+dither)/191.0;
 color*=1.0-.25*pow(length((SCREEN_UV-.5)*1.1),1.5);
 color*=1.0-vhs*.06*sin(FRAGCOORD.y*3.14);
 COLOR=vec4(color,1.0);
}
