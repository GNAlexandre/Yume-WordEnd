// (H9) Décalque au sol à alpha doux (ombres de feuillage, taches de soleil, brume, congères) :
// voir ground_decal.gdshaderinc. Mélangé, sans écrire la profondeur ; sa priorité de rendu
// (GroundDecal : sous les ombres des panneaux, une par couche) le dessine avant les personnages
// et dans l'ordre des couches. tint.a règle son opacité. Compatible Compatibility / WebGL 2.
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, specular_disabled;

#include "res://src/world/shaders/hd2d_light.gdshaderinc"
#include "res://src/world/shaders/pixel_art.gdshaderinc"
#include "res://src/world/shaders/ground_decal.gdshaderinc"

void vertex() {
	POSITION = decal_position(VERTEX, UV2, MODELVIEW_MATRIX, PROJECTION_MATRIX);
}

void fragment() {
	vec4 c = pixel_art(albedo_texture, UV);
	ALBEDO = c.rgb * tint.rgb;
	ALPHA = c.a * tint.a;
	ROUGHNESS = 1.0;
}
