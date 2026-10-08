// (H9) Ciel qui dérive (SkyDrift, src/world/sky_drift.gd) : panneaux lointains (nuages, îles,
// dirigeables en vol) qui glissent d'ouest en est le long de l'axe x du nœud et reviennent en
// boucle tous les span m. Le mouvement est tout entier dans le shader (TIME : il continue
// pendant la pause) : un mesh fixe par image, un draw call, aucun calcul par image côté moteur.
// Sommets : quad de chaque voyageur autour de x = 0 ; UV2 = (départ sur le trajet en m, vitesse
// en m/s). Fondu sur les fade derniers mètres de chaque bout du trajet (pas de saut au retour).
// Alpha mélangé (nuages en alpha doux ; les images à alpha franc restent nettes), éclairage plat
// des panneaux (hd2d_relief = 0), brume du monde comprise. Compatible Compatibility / WebGL 2.
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, specular_disabled;

#include "res://src/world/shaders/hd2d_light.gdshaderinc"
#include "res://src/world/shaders/pixel_art.gdshaderinc"

uniform sampler2D albedo_texture : source_color, filter_linear, repeat_disable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float span = 600.0;
uniform float fade = 40.0;

varying float drift_fade;

void vertex() {
	float x = mod(UV2.x + TIME * UV2.y, span) - span * 0.5;
	VERTEX.x += x;
	drift_fade = 1.0 - smoothstep(span * 0.5 - fade, span * 0.5, abs(x));
}

void fragment() {
	vec4 c = pixel_art(albedo_texture, UV);
	ALBEDO = c.rgb * tint.rgb;
	ALPHA = c.a * tint.a * drift_fade;
	ROUGHNESS = 1.0;
}
