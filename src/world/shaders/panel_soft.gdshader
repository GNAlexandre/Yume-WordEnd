// Panneau HD-2D à alpha doux (DecorPanel.soft_alpha) : fumée, vapeur, cascade, nuages, brume,
// rais de lumière (docs/ASSETS_HD2D_MONDE.md, images « alpha doux »). Même image, même bande
// animée et même décalage que panel.gdshader (panel_core.gdshaderinc), mais la transparence est
// mélangée au lieu d'être découpée à alpha_cut : le dégradé de l'image est gardé. Les panneaux
// mélangés n'écrivent pas la profondeur (ils ne cachent rien derrière eux) et sont triés par
// objet, pas entre panneaux fondus d'une même image : à réserver aux images qui flottent ou se
// superposent peu. (RD) Dessiné après le flou de profondeur de l'écran, il se floute lui-même
// (depth_focus.gdshaderinc, DepthFocus). Compatible Compatibility / WebGL 2.
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, specular_disabled;

#include "res://src/world/shaders/hd2d_light.gdshaderinc"
#include "res://src/world/shaders/pixel_art.gdshaderinc"
#include "res://src/world/shaders/panel_core.gdshaderinc"
#include "res://src/world/shaders/depth_focus.gdshaderinc"

varying vec2 panel_variation;
varying vec2 panel_ground;

void vertex() {
	panel_variation = panel_tone(UV2);
	panel_ground = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
	UV = panel_strip_uv(UV, UV2, TIME);
	POSITION = panel_position(VERTEX, UV2.y, MODELVIEW_MATRIX, PROJECTION_MATRIX);
}

void fragment() {
	vec3 albedo;
	float alpha;
	vec3 emission;
	float flip_sign = dFdx(UV.x) < 0.0 ? -1.0 : 1.0;
	vec2 uv = panel_wind_uv(UV, panel_ground, TIME, flip_sign);
	vec2 uv_dx = dFdx(uv);
	vec2 uv_dy = dFdy(uv);
	panel_shade(uv, albedo, alpha, emission);
	// (RD) Dessiné après le flou de l'écran : il se floute lui-même selon sa profondeur.
	float blur = focus_radius(-VERTEX.z) * VIEWPORT_SIZE.y / 720.0;
	if (blur >= 0.5) {
		vec4 soft = focus_sample(albedo_texture, uv, uv_dx, uv_dy, blur);
		albedo = soft.rgb * tint.rgb;
		alpha = soft.a;
	}
	albedo = panel_apply_tone(albedo, panel_variation);
	ALBEDO = albedo;
	ALPHA = alpha * tint.a;
	ROUGHNESS = 1.0;
	EMISSION = emission;
}
