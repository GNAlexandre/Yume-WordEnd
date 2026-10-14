// (E3) Panneaux d'un intérieur : portes, fenêtres et éléments de mur posés par InteriorRoom,
// meubles InteriorPanel. Même image « nette mais lissée », transparence découpée, teinte et lueur
// que panel.gdshader (panel_core.gdshaderinc), plus la lumière de la pièce et la coupe
// (interior_core.gdshaderinc). Données de chaque sommet (gardées par le PropBatcher, qui fond
// tous les meubles d'une même image en un draw call) :
// - UV2.x : coordonnée de coupe (z du monde : ligne du mur, bord sud du meuble) ;
// - UV2.y : hauteur gardée quand la coupe passe (m au-dessus du sol).
// (R1) La lumière vient d'Atmosphere (InteriorRoom.apply_lighting) : une fenêtre s'assombrit et
// bleuit avec le jour du dehors (night_view), une lampe ou un cristal luit selon lamp_energy.
// Compatible Compatibility / WebGL 2.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_disabled;

#include "res://src/world/shaders/hd2d_light.gdshaderinc"
#include "res://src/world/shaders/pixel_art.gdshaderinc"
#include "res://src/world/shaders/panel_core.gdshaderinc"
#include "res://src/world/shaders/interior_core.gdshaderinc"

// Ce que suit la lueur (pixels couleur cristal) : 0 rien, 1 le jour (vitres), 2 les lampes.
uniform float glow_follows = 2.0;
// (R1) Une fenêtre (glow_follows = 1) montre le dehors : quand le jour des fenêtres baisse
// (window_energy, posée par Atmosphere), son image s'assombrit vers cette teinte bleu nuit.
// Blanc : sans effet (HD2DLightTargets le pose quand l'image <nom>_night.png du cahier n° 3
// remplace celle du jour la nuit).
uniform vec4 night_view : source_color = vec4(0.36, 0.42, 0.66, 1.0);

// Les panneaux de meubles ont une coupe propre, les murs et portes gardent cut_line.
uniform bool furniture_panel = false;
uniform float furniture_cut_line = 1000000.0;

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
	bool furniture_cut = furniture_panel && cut_coord >= furniture_cut_line - cut_margin;
	if ((interior_is_cut(cut_coord) || furniture_cut) && height > keep_height + 0.002) {
		discard;
	}
	if (glow_follows > 0.5 && glow_follows < 1.5) {
		albedo *= mix(night_view.rgb, vec3(1.0), smoothstep(0.15, 0.9, window_energy));
	}
	ALBEDO = albedo;
	ALPHA = alpha;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	ROUGHNESS = 1.0;
	float glow_scale = glow_follows > 1.5 ? lamp_energy : (glow_follows > 0.5 ? window_energy : 1.0);
	EMISSION = emission * glow_scale + albedo * interior_light(light_xz, height);
}
