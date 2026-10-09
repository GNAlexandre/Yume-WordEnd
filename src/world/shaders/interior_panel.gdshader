// (E3) Panneaux d'un intérieur : portes, fenêtres et éléments de mur posés par InteriorRoom,
// meubles InteriorPanel. Même image « nette mais lissée », transparence découpée, teinte et lueur
// que panel.gdshader (panel_core.gdshaderinc), plus la lumière de la pièce et la coupe
// (interior_core.gdshaderinc). Données de chaque sommet (gardées par le PropBatcher, qui fond
// tous les meubles d'une même image en un draw call) :
// - UV2.x : coordonnée de coupe (z du monde : ligne du mur, bord sud du meuble) ;
// - UV2.y : hauteur gardée quand la coupe passe (m au-dessus du sol).
// Compatible Compatibility / WebGL 2.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_disabled;

#include "res://src/world/shaders/hd2d_light.gdshaderinc"
#include "res://src/world/shaders/pixel_art.gdshaderinc"
#include "res://src/world/shaders/panel_core.gdshaderinc"
#include "res://src/world/shaders/interior_core.gdshaderinc"

varying vec3 world_pos;
varying vec2 light_xz;
varying float cut_coord;
varying float keep_height;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec3 n = (MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz;
	light_xz = world_pos.xz + normalize(n + vec3(0.0, 0.0001, 0.0)).xz * 0.3;
	cut_coord = UV2.x;
	keep_height = UV2.y;
}

void fragment() {
	vec3 albedo;
	float alpha;
	vec3 emission;
	panel_shade(UV, albedo, alpha, emission);
	float height = world_pos.y - floor_y;
	if (interior_is_cut(cut_coord) && height > keep_height + 0.002) {
		discard;
	}
	ALBEDO = albedo;
	ALPHA = alpha;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	ROUGHNESS = 1.0;
	EMISSION = emission + albedo * interior_light(light_xz, height);
}
