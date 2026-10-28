shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, filter_nearest;
uniform float grain = 0.025;
uniform float vhs = 0.0;
float hash(vec2 p) { return fract(sin(dot(p, vec2(12.9898,78.233)))*43758.5453); }
void fragment() {
 vec2 uv=SCREEN_UV;
 uv.x+=sin(uv.y*180.0+TIME*2.0)*vhs*0.0015;
 vec3 color=texture(screen_texture,uv).rgb;
 float noise=hash(floor(FRAGCOORD.xy)+floor(TIME*18.0));
 color+=(noise-.5)*grain;
 float dither=mod(floor(FRAGCOORD.x)+mod(floor(FRAGCOORD.y),2.0)*2.0,4.0)/4.0;
 color=floor(color*47.0+dither)/47.0;
 color*=1.0-.20*pow(length((SCREEN_UV-.5)*1.1),1.5);
 color*=1.0-vhs*.06*sin(FRAGCOORD.y*3.14);
 COLOR=vec4(color,1.0);
}
