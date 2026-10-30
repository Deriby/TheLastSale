shader_type canvas_item;
void fragment() {
 vec4 source = texture(TEXTURE, UV);
 float luma = dot(source.rgb, vec3(0.299, 0.587, 0.114));
 float line = 0.96 + 0.04 * sin(UV.y * 216.0 * 3.14159);
 float noise = fract(sin(dot(floor(UV * vec2(384.0,216.0)) + floor(TIME * 10.0),vec2(12.9898,78.233))) * 43758.5453);
 vec3 image = mix(source.rgb, vec3(luma), 0.65) * vec3(0.88, 1.03, 0.92);
 COLOR = vec4(clamp(image * line + (noise - 0.5) * 0.018, 0.0, 1.0), source.a);
}
