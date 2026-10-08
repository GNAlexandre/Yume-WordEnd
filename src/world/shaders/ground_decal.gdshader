// (H9) Décalque au sol à alpha découpé (feuilles, racines, cailloux, flaques…) : voir
// ground_decal.gdshaderinc. Dessiné avec le décor opaque, sous les panneaux et les personnages qui
// s'y tiennent. Compatible Compatibility / WebGL 2.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_disabled;

#include "res://src/world/shaders/hd2d_light.gdshaderinc"
#include "res://src/world/shaders/pixel_art.gdshaderinc"
#include "res://src/world/shaders/ground_decal.gdshaderinc"

void vertex() {
	POSITION = decal_position(VERTEX, UV2, MODELVIEW_MATRIX, PROJECTION_MATRIX);
}

void fragment() {
	vec4 c = pixel_art(albedo_texture, UV);
	ALBEDO = c.rgb * tint.rgb;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.5;
	ROUGHNESS = 1.0;
}
