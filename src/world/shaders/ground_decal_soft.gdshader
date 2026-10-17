// (H9) Décalque au sol à alpha doux (ombres de feuillage, taches de soleil, brume, congères) :
// voir ground_decal.gdshaderinc. Mélangé, sans écrire la profondeur ; sa priorité de rendu
// (GroundDecal : sous les ombres des panneaux, une par couche) le dessine avant les personnages
// et dans l'ordre des couches. tint.a règle son opacité. Compatible Compatibility / WebGL 2.
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, specular_disabled;

#include "res://src/world/shaders/hd2d_light.gdshaderinc"
#include "res://src/world/shaders/pixel_art.gdshaderinc"
#include "res://src/world/shaders/ground_decal.gdshaderinc"
#include "res://src/world/shaders/depth_focus.gdshaderinc"

void vertex() {
	POSITION = decal_position(VERTEX, UV2, MODELVIEW_MATRIX, PROJECTION_MATRIX);
}

void fragment() {
	vec2 uv_dx = dFdx(UV);
	vec2 uv_dy = dFdy(UV);
	vec4 c = pixel_art_grad(albedo_texture, UV, uv_dx, uv_dy);
	// (RD) Dessiné après le flou de profondeur de l'écran : il se floute lui-même.
	float blur = focus_radius(-VERTEX.z) * VIEWPORT_SIZE.y / 720.0;
	if (blur >= 0.5) {
		c = focus_sample(albedo_texture, UV, uv_dx, uv_dy, blur);
	}
	ALBEDO = c.rgb * tint.rgb;
	ALPHA = c.a * tint.a;
	ROUGHNESS = 1.0;
}
