// (AN) Planche d'un personnage (CharacterVisual, enfant « Sprite ») lue « nette mais lissée »,
// comme le décor (pixel_art.gdshaderinc) : la planche est réduite d'environ 1,4 à 1,6 pixel de
// planche par pixel d'écran ; lue au plus proche, des lignes de pixels apparaissaient et
// disparaissaient quand la caméra glissait (scintillement). Ici, quatre échantillons bilinéaires
// sur l'empreinte du pixel d'écran (de loin) ou une frontière de pixel lissée sur un pixel d'écran
// (de près) ; la transparence moyennée reste découpée à alpha_cut (pas de tri, profondeur écrite).
// Remplace le matériau que l'AnimatedSprite3D se fabrique : billboard axe Y (comme billboard = 2),
// non éclairé, double face ; la couleur du sommet est le modulate du sprite (teinte de la lumière,
// EnemyData.tint). Les images sont des AtlasTexture de la planche : CharacterVisual pose la
// planche entière dans sheet, les UV du sprite sont ceux de la région.
// Compatible Compatibility / WebGL 2.
shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_opaque, shadows_disabled;

#include "res://src/world/shaders/pixel_art.gdshaderinc"

uniform sampler2D sheet : source_color, filter_linear, repeat_disable;
uniform float alpha_cut = 0.5;

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
	MODELVIEW_NORMAL_MATRIX = mat3(MODELVIEW_MATRIX);
}

void fragment() {
	vec4 c = pixel_art(sheet, UV);
	ALBEDO = c.rgb * COLOR.rgb;
	ALPHA = c.a * COLOR.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_cut;
}
