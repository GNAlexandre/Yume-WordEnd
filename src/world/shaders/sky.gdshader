// (E9) Ciel peint des cartes : panorama équirectangulaire en pixel art (assets/hd2d/sky/,
// docs/ASSETS_HD2D_SUKASUKA.md, section 8 : l'ouest dans le quart gauche), lu au plus proche
// voisin comme l'ancien PanoramaSkyMaterial. Deux panoramas se fondent pendant une transition
// de lumière (panorama_from → panorama, blend de 0 à 1 : du couchant à la nuit étoilée), teinte
// et énergie du préréglage (src/world/materials/hd2d_lighting.gd). Posé par Atmosphere
// (src/autoload/atmosphere.gd, HD2DLightTargets). Compatible Compatibility / WebGL 2.
shader_type sky;

uniform sampler2D panorama : source_color, filter_nearest, repeat_enable;
uniform sampler2D panorama_from : source_color, filter_nearest, repeat_enable;
uniform float blend : hint_range(0.0, 1.0) = 1.0;
uniform vec4 tint : source_color = vec4(1.0);
uniform float energy = 1.0;

void sky() {
	vec3 c = texture(panorama, SKY_COORDS).rgb;
	if (blend < 0.999) {
		c = mix(texture(panorama_from, SKY_COORDS).rgb, c, blend);
	}
	COLOR = c * tint.rgb * energy;
}
