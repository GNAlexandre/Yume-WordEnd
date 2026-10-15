shader_type canvas_item;
// (U1) Verre dépoli « Nuit douce » : posé par UiStyle.frost() sur un panneau dont la boîte est une
// NuitBox, il remplace le fond translucide par l'arrière-plan flouté, teinté de la couleur du
// fond. Seuls les pixels du fond (couleur `tint` de la boîte) sont touchés : l'ombre, le filet
// doré et le point gardent leur dessin ; les enfants (texte, portrait) n'ont pas ce matériau.
// Le flou lit les niveaux de détail de la copie de l'écran (flou gaussien du rendu
// Compatibility, Web compris), adoucis par huit prises autour du pixel.

uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
// Couleur du fond de la boîte (NuitBox.fill), sans conversion : comparée à COLOR.
uniform vec4 tint = vec4(0.15, 0.11, 0.18, 0.66);
// Rayon des prises (px de l'écran) et niveau de détail lu.
uniform float radius = 9.0;
uniform float lod = 2.5;

const vec2 TAPS[8] = vec2[8](
	vec2(1.0, 0.0), vec2(0.707, 0.707), vec2(0.0, 1.0), vec2(-0.707, 0.707),
	vec2(-1.0, 0.0), vec2(-0.707, -0.707), vec2(0.0, -1.0), vec2(0.707, -0.707)
);

void fragment() {
	vec4 base = COLOR;
	if (tint.a > 0.0 && distance(base.rgb, tint.rgb) < 0.02) {
		vec2 step_uv = SCREEN_PIXEL_SIZE * radius;
		vec3 blur = textureLod(screen_tex, SCREEN_UV, lod).rgb * 0.2;
		for (int i = 0; i < 8; i++) {
			blur += textureLod(screen_tex, SCREEN_UV + TAPS[i] * step_uv, lod).rgb * 0.1;
		}
		// Couverture : l'alpha du fond (bords lissés, fondu du nœud) rapporté à celui de la boîte.
		float cover = clamp(base.a / tint.a, 0.0, 1.0);
		COLOR = vec4(mix(blur, base.rgb, tint.a), cover);
	}
}
