shader_type spatial;
render_mode world_vertex_coords, cull_disabled, diffuse_burley, specular_disabled;
uniform vec4 leaf_color : source_color = vec4(.3,.4,.25,1.);
uniform sampler2D leaf_texture : source_color, filter_linear_mipmap;
uniform float wind_time=0.0;
void vertex(){
 float sway=sin(wind_time*.74+VERTEX.x*.57+VERTEX.z*.43);
 VERTEX.x+=sway*.035;
 VERTEX.z+=sin(wind_time*.91+VERTEX.z*.6)*.019;
}
void fragment(){
 vec4 leaf=texture(leaf_texture,UV);
 ALBEDO=leaf.rgb*leaf_color.rgb*1.5;ALPHA=leaf.a;ALPHA_SCISSOR_THRESHOLD=.4;ROUGHNESS=1.0;
 if(!FRONT_FACING){NORMAL=-NORMAL;}
}
