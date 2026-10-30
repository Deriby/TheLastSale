shader_type canvas_item;
render_mode unshaded;
uniform float opacity = 1.0;
float grain(vec2 p) { return fract(sin(dot(p,vec2(12.9898,78.233)))*43758.5453); }
void fragment() {
 vec2 p=UV;
 float edge=smoothstep(.24,.78,length((p-.5)*vec2(1.15,1.0)));
 float left=1.0-smoothstep(.22,.79,p.x);
 float scan=step(.56,fract(FRAGCOORD.y*.5))*.035;
 float dust=grain(floor(FRAGCOORD.xy)+floor(TIME*12.0));
 float band=(1.0-smoothstep(.0,.055,abs(p.y-fract(TIME*.018))))*.035;
 float density=clamp((left*.62+edge*.43+scan+band+(dust-.5)*.045)*opacity,0.0,.94);
 vec3 tint=vec3(.007,.009,.008)+vec3(.021,.014,.01)*dust;
 COLOR=vec4(tint,density);
}
