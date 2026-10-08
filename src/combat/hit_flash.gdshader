// Éclair blanc d'un combattant touché (src/combat/hit_flash.gd, lot H7) : la silhouette de l'image
// affichée par le sprite du CharacterVisual, peinte d'une couleur claire, posée juste devant lui.
// Compatible WebGL 2 (Compatibility) : non éclairé, alpha découpé (pas de tri), billboard axe Y
// comme les planches, sans test de profondeur perdu (avancé de lift m vers la caméra).
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, shadows_disabled;

// Planche entière : les images du sprite sont des AtlasTexture de cette texture.
uniform sampler2D sheet : source_color, filter_nearest;
uniform vec4 flash_color : source_color = vec4(1.0, 0.97, 0.9, 1.0);
// 1 : silhouette pleine de flash_color ; 0 : l'image d'origine.
uniform float strength : hint_range(0.0, 1.0) = 1.0;
uniform float lift = 0.03;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(
			vec4(normalize(cross(vec3(0.0, 1.0, 0.0), INV_VIEW_MATRIX[2].xyz)), 0.0),
			vec4(0.0, 1.0, 0.0, 0.0),
			vec4(normalize(cross(INV_VIEW_MATRIX[0].xyz, vec3(0.0, 1.0, 0.0))), 0.0),
			MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(
			vec4(length(MODEL_MATRIX[0].xyz), 0.0, 0.0, 0.0),
			vec4(0.0, length(MODEL_MATRIX[1].xyz), 0.0, 0.0),
			vec4(0.0, 0.0, length(MODEL_MATRIX[2].xyz), 0.0),
			vec4(0.0, 0.0, 0.0, 1.0));
	MODELVIEW_MATRIX[3].z += lift;
}

void fragment() {
	vec4 image = texture(sheet, UV);
	if (image.a < 0.5) {
		discard;
	}
	ALBEDO = mix(image.rgb, flash_color.rgb, strength);
}
