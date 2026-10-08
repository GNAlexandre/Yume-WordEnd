// (H9) Panneau de premier plan (DecorPanel.foreground ; docs/ASSETS_HD2D_MONDE.md, section 3.7) :
// le panneau ordinaire (panel.gdshader, même cœur panel_core.gdshaderinc) qui s'efface en trame
// autour du joueur quand il passe entre la caméra et lui (foreground_fade.gdshaderinc). Shader à
// part : la découpe du village (src/world/zones/village/see_through.gd) ne convertit que les
// matériaux de panel.gdshader. Compatible Compatibility / WebGL 2.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_disabled;

#include "res://src/world/shaders/hd2d_light.gdshaderinc"
#include "res://src/world/shaders/pixel_art.gdshaderinc"
#include "res://src/world/shaders/panel_core.gdshaderinc"
#include "res://src/world/shaders/foreground_fade.gdshaderinc"

void vertex() {
	UV = panel_strip_uv(UV, UV2, TIME);
	POSITION = panel_position(VERTEX, UV2.y, MODELVIEW_MATRIX, PROJECTION_MATRIX);
}

void fragment() {
	vec3 albedo;
	float alpha;
	vec3 emission;
	panel_shade(UV, albedo, alpha, emission);
	ALBEDO = albedo;
	ALPHA = alpha;
	if (foreground_amount(VERTEX, VIEW_MATRIX) > foreground_dither(FRAGCOORD.xy)) {
		ALPHA = 0.0;
	}
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	ROUGHNESS = 1.0;
	EMISSION = emission;
}
