shader_type spatial;
render_mode cull_disabled, depth_draw_never, specular_disabled;
uniform sampler2D haze_noise : filter_linear_mipmap, repeat_enable;
uniform float drift=0.0;
varying vec3 world_at;
void vertex(){world_at=(MODEL_MATRIX*vec4(VERTEX,1.)).xyz;}
void fragment(){
 float shape=smoothstep(0.,.25,UV.x)*smoothstep(0.,.25,1.-UV.x)*sin(UV.y*3.14159);
 float density=texture(haze_noise,UV*vec2(2.4,1.)+vec2(drift*.008,0.)).r;
 float near_fade=smoothstep(.7,2.5,length(VERTEX));
 float street_only=smoothstep(.2,1.6,world_at.z)*(1.-smoothstep(10.9,12.4,world_at.z));
 ALBEDO=vec3(.38,.42,.48);ROUGHNESS=1.;ALPHA=shape*density*.032*near_fade*street_only;
}
