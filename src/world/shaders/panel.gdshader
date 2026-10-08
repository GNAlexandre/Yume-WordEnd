// Panneau HD-2D (DecorPanel, façades et murs des bâtiments) : image en pixel art « net mais
// lissé » (pixel_art.gdshaderinc : pixels nets de près, sur-échantillonnés de loin, sans moiré),
// transparence découpée (alpha 0 ou 255 : ni tri ni mélange), éclairage plat
// (hd2d_light.gdshaderinc avec hd2d_relief = 0 pour un panneau, plus pour un mur ou un toit).
// Les UV des murs et des toits répètent la matière (uv_repeat). (H9) Bandes animées et décalage
// vers la caméra : panel_core.gdshaderinc (données de l'exemplaire dans UV2). La variante de
// premier plan, qui s'efface devant le joueur, est panel_foreground.gdshader. Compatible
// Compatibility / WebGL 2.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_disabled;

#include "res://src/world/shaders/hd2d_light.gdshaderinc"
#include "res://src/world/shaders/pixel_art.gdshaderinc"
#include "res://src/world/shaders/panel_core.gdshaderinc"

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
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	ROUGHNESS = 1.0;
	EMISSION = emission;
}
