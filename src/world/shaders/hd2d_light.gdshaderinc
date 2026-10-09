// Éclairage HD-2D partagé par le sol, la roche, les bâtiments et les décors en panneaux de l'île
// (docs/ASSETS_HD2D.md : les images portent un éclairage plat). Demi-Lambert adouci par
// hd2d_relief (0 : à plat, la lumière ne dépend pas de l'orientation, pour les panneaux qui
// portent leur volume dans l'image ; 1 : le relief du sol et des toits se lit), sans reflet
// spéculaire. Les lumières ponctuelles (lanternes, fenêtres) éclairent tout ce qui est à leur
// portée, panneaux compris. Compatible Compatibility / WebGL 2.
// (E9) Sous la pluie, hd2d_wetness (0..1, posé par Atmosphere sur chaque matériau de la carte)
// mouille la surface : un peu plus sombre sous chaque lumière, et un reflet doux de la lumière
// (lune, soleil, lanternes) là où elle se reflète vers la caméra, plus un lustre rasant au
// lointain ; surtout sur ce qui est à plat (sol, toits : hd2d_relief), à peine sur les panneaux.

uniform float hd2d_relief : hint_range(0.0, 1.0) = 1.0;
uniform float hd2d_wetness : hint_range(0.0, 1.0) = 0.0;

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float wrapped = clamp(ndl * 0.5 + 0.5, 0.0, 1.0);
	float shape = mix(0.8, wrapped * wrapped * 1.15, hd2d_relief);
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * shape * (1.0 - 0.3 * hd2d_wetness) / PI;
	if (hd2d_wetness > 0.0) {
		float flat_part = mix(0.2, 1.0, hd2d_relief);
		float gloss = pow(clamp(dot(NORMAL, normalize(LIGHT + VIEW)), 0.0, 1.0), 28.0);
		float sheen = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 4.0);
		SPECULAR_LIGHT += LIGHT_COLOR * ATTENUATION * hd2d_wetness * flat_part * (gloss * 0.9 + sheen * 0.35);
	}
}
