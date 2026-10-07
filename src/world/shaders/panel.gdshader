// Panneau HD-2D (DecorPanel, façades et murs des bâtiments) : image en pixel art filtrée au plus
// proche voisin, transparence découpée (alpha 0 ou 255 : ni tri ni mélange), éclairage plat
// (hd2d_light.gdshaderinc avec hd2d_relief = 0 pour un panneau, plus pour un mur ou un toit).
// Les UV des murs et des toits répètent la matière (uv_repeat). Compatible Compatibility / WebGL 2.
shader_type spatial;
render_mode cull_disabled, depth_draw_opaque, specular_disabled;

#include "res://src/world/shaders/hd2d_light.gdshaderinc"

uniform sampler2D albedo_texture : source_color, filter_nearest, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float alpha_cut = 0.5;
// Lueur propre (fenêtres, cristaux) : les pixels proches de glow_color s'allument sans lumière.
uniform vec4 glow_color : source_color = vec4(1.0, 0.9, 0.65, 1.0);
uniform float glow_strength = 0.0;

void fragment() {
	vec4 c = texture(albedo_texture, UV);
	ALBEDO = c.rgb * tint.rgb;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
	ROUGHNESS = 1.0;
	if (glow_strength > 0.0) {
		float near_glow = 1.0 - smoothstep(0.05, 0.12, distance(c.rgb, glow_color.rgb));
		EMISSION = c.rgb * near_glow * glow_strength;
	}
}
