// Panneau HD-2D à alpha doux (DecorPanel.soft_alpha) : fumée, vapeur, cascade, nuages, brume,
// rais de lumière (docs/ASSETS_HD2D_MONDE.md, images « alpha doux »). Même image, même bande
// animée et même décalage que panel.gdshader (panel_core.gdshaderinc), mais la transparence est
// mélangée au lieu d'être découpée à alpha_cut : le dégradé de l'image est gardé. Les panneaux
// mélangés n'écrivent pas la profondeur (ils ne cachent rien derrière eux) et sont triés par
// objet, pas entre panneaux fondus d'une même image : à réserver aux images qui flottent ou se
// superposent peu. Compatible Compatibility / WebGL 2.
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, specular_disabled;

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
	ALPHA = alpha * tint.a;
	ROUGHNESS = 1.0;
	EMISSION = emission;
}
