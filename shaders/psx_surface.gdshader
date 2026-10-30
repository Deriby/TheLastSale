shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

uniform float snap_pixels = 0.5;
uniform float affine_strength = 0.35;
uniform vec4 base_color : source_color = vec4(1.0);
uniform sampler2D base_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform bool has_base = false;
uniform bool vertex_color = false;
uniform vec3 uv_scale = vec3(1.0);
uniform vec3 uv_offset = vec3(0.0);
uniform bool triplanar = false;
uniform bool world_triplanar = false;
uniform float triplanar_sharpness = 1.0;
uniform float surface_roughness = 1.0;
uniform float surface_metallic = 0.0;
uniform float surface_specular = 0.5;
uniform sampler2D roughness_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D metallic_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D occlusion_texture : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 roughness_channel = vec4(1.0,0.0,0.0,0.0);
uniform vec4 metallic_channel = vec4(1.0,0.0,0.0,0.0);
uniform vec4 occlusion_channel = vec4(1.0,0.0,0.0,0.0);
uniform bool has_roughness = false;
uniform bool has_metallic = false;
uniform bool has_occlusion = false;
uniform float occlusion_light_affect = 0.0;
uniform sampler2D normal_texture : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool has_normal = false;
uniform float normal_depth = 1.0;
uniform vec4 glow_color : source_color = vec4(0.0);
uniform sampler2D glow_texture : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform bool has_glow_texture = false;
uniform float glow_energy = 0.0;
uniform bool alpha_scissor = false;
uniform float alpha_threshold = 0.5;
uniform float coat = 0.0;
uniform float coat_roughness = 0.5;

varying vec2 affine_uv;
varying vec3 tri_position;
varying vec3 affine_tri_position;
varying vec3 tri_weights;
varying float affine_w;

void vertex() {
 UV = UV * uv_scale.xy + uv_offset.xy;
 tri_position = (world_triplanar ? (MODEL_MATRIX * vec4(VERTEX,1.0)).xyz : VERTEX) * uv_scale + uv_offset;
 vec3 tri_normal = world_triplanar ? MODEL_NORMAL_MATRIX * NORMAL : NORMAL;
 tri_weights = pow(abs(tri_normal),vec3(triplanar_sharpness));
 tri_weights /= max(dot(tri_weights,vec3(1.0)),0.0001);
 vec4 clip = PROJECTION_MATRIX * MODELVIEW_MATRIX * vec4(VERTEX,1.0);
 affine_w = max(clip.w,0.0001);
 affine_uv = UV * affine_w;
 affine_tri_position = tri_position * affine_w;
 if (snap_pixels > 0.0 && clip.w > 0.01) {
  vec2 grid = VIEWPORT_SIZE / (2.0 * snap_pixels);
  clip.xy = floor(clip.xy / clip.w * grid + 0.5) / grid * clip.w;
 }
 POSITION = clip;
}

vec4 surface_sample(sampler2D image, vec2 at, vec3 tri) {
 if (!triplanar) { return texture(image,at); }
 return texture(image,tri.xy) * tri_weights.z
      + texture(image,tri.xz) * tri_weights.y
      + texture(image,tri.zy * vec2(-1.0,1.0)) * tri_weights.x;
}

void fragment() {
 vec2 at = mix(UV,affine_uv / max(affine_w,0.0001),affine_strength);
 vec3 tri = mix(tri_position,affine_tri_position / max(affine_w,0.0001),affine_strength);
 vec4 color = base_color;
 if (has_base) { color *= surface_sample(base_texture,at,tri); }
 if (vertex_color) { color *= COLOR; }
 ALBEDO = color.rgb;
 ROUGHNESS = surface_roughness * (has_roughness ? dot(surface_sample(roughness_texture,at,tri),roughness_channel) : 1.0);
 METALLIC = surface_metallic * (has_metallic ? dot(surface_sample(metallic_texture,at,tri),metallic_channel) : 1.0);
 SPECULAR = surface_specular;
 if (has_occlusion) {
  AO = dot(surface_sample(occlusion_texture,at,tri),occlusion_channel);
  AO_LIGHT_AFFECT = occlusion_light_affect;
 }
 if (has_normal && !triplanar) {
  NORMAL_MAP = surface_sample(normal_texture,at,tri).rgb;
  NORMAL_MAP_DEPTH = normal_depth;
 }
 EMISSION = glow_color.rgb * glow_energy * (has_glow_texture ? surface_sample(glow_texture,at,tri).rgb : vec3(1.0));
 CLEARCOAT = coat;
 CLEARCOAT_ROUGHNESS = coat_roughness;
 if (alpha_scissor) { ALPHA = color.a; ALPHA_SCISSOR_THRESHOLD = alpha_threshold; }
}
