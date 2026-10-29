shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D sign_art : source_color, filter_linear_mipmap;
void fragment(){
 vec3 art=texture(sign_art,UV).rgb;
 ALBEDO=art;EMISSION=art*.28;ROUGHNESS=.8;
}
