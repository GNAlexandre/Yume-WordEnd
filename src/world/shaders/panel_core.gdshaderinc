// (H9) Cœur des panneaux HD-2D, partagé par panel.gdshader et panel_foreground.gdshader (à
// inclure après hd2d_light.gdshaderinc et pixel_art.gdshaderinc) : uniformes de l'image, bande
// animée (docs/ASSETS_HD2D_MONDE.md, section 3.4), décalage vers la caméra et couleur d'un
// pixel. Les données propres à chaque exemplaire passent par UV2 (le PropBatcher les garde quand
// il fond les panneaux d'une même image en un mesh) :
// - UV2.x : phase de la bande animée (0..1, tirée de la position du panneau) ;
// - UV2.y : décalage vers la caméra (m) d'un panneau posé contre un mur ou sur un toit.
// Compatible Compatibility / WebGL 2.

uniform sampler2D albedo_texture : source_color, filter_linear, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float alpha_cut = 0.5;
// Lueur propre (fenêtres, cristaux) : les pixels proches de glow_color s'allument sans lumière.
uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.65, 1.0);
uniform float glow_strength = 0.0;
// Bande animée : nombre d'images côte à côte (1 : image fixe) et cadence (images par seconde ;
// 0 : chaque exemplaire garde l'image de sa phase).
uniform float frames = 1.0;
uniform float fps = 0.0;

// UV dans l'image courante de la bande : l'image change avec le temps (TIME, qui continue
// pendant la pause), décalée de la phase de l'exemplaire.
vec2 panel_strip_uv(vec2 uv, vec2 uv2, float time) {
	if (frames < 1.5) {
		return uv;
	}
	float frame = floor(mod(time * fps + uv2.x * frames, frames));
	return vec2((frame + uv.x) / frames, uv.y);
}

// Position (clip) du sommet, tirée de offset m vers la caméra le long de son rayon : le panneau
// passe devant le mur ou le toit sur lequel il est posé sans bouger à l'écran.
vec4 panel_position(vec3 vertex, float offset, mat4 modelview, mat4 projection) {
	vec4 view = modelview * vec4(vertex, 1.0);
	if (offset > 0.0) {
		view.xyz *= max(1.0 - offset / max(length(view.xyz), 0.001), 0.0);
	}
	return projection * view;
}

// Couleur du pixel du panneau : image « nette mais lissée », teinte, transparence (découpée par
// l'appelant à alpha_cut), lueur des pixels couleur cristal.
void panel_shade(vec2 uv, out vec3 albedo, out float alpha, out vec3 emission) {
	vec4 c = pixel_art(albedo_texture, uv);
	albedo = c.rgb * tint.rgb;
	alpha = c.a;
	emission = vec3(0.0);
	if (glow_strength > 0.0) {
		float near_glow = 1.0 - smoothstep(0.05, 0.12, distance(c.rgb, glow_color.rgb));
		emission = c.rgb * near_glow * glow_strength;
	}
}
