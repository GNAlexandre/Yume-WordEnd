// Éclairage HD-2D partagé par le sol, la roche, les bâtiments et les décors en panneaux de l'île
// (docs/ASSETS_HD2D.md : les images portent un éclairage plat). Demi-Lambert adouci par
// hd2d_relief (0 : à plat, la lumière ne dépend pas de l'orientation, pour les panneaux qui
// portent leur volume dans l'image ; 1 : le relief du sol et des toits se lit), sans reflet
// spéculaire. Les lumières ponctuelles (lanternes, fenêtres) éclairent tout ce qui est à leur
// portée, panneaux compris. Compatible Compatibility / WebGL 2.

uniform float hd2d_relief : hint_range(0.0, 1.0) = 1.0;

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float wrapped = clamp(ndl * 0.5 + 0.5, 0.0, 1.0);
	float shape = mix(0.8, wrapped * wrapped * 1.15, hd2d_relief);
	DIFFUSE_LIGHT += LIGHT_COLOR * ATTENUATION * shape / PI;
}
