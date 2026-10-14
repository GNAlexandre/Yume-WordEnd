// (E3) Cœur des intérieurs, partagé par interior.gdshader (sols, murs, dessus de mur) et
// interior_panel.gdshader (portes, fenêtres, éléments de mur, meubles InteriorPanel) :
// - la coupe : tout ce dont la coordonnée de coupe (z du monde, portée par UV2.x des sommets :
//   la ligne d'un mur est-ouest, le z du sommet d'un mur nord-sud, le bord sud d'un meuble) est
//   au sud de cut_line - cut_margin n'est dessiné que sous sa hauteur de coupe : rien ne cache le
//   joueur (InteriorRoom pose cut_line à chaque image : la première limite de pièce au sud du
//   joueur) ;
// - la lumière de la pièce : deux cartes vues de dessus (InteriorRoom.LIGHT_TEXELS texels par
//   mètre, bornées à leur pièce), la lumière du jour des fenêtres et celle des lampes, ajoutées
//   en émission (albedo × lumière) par-dessus l'éclairage de la scène ; plus faibles en haut des
//   murs. Les énergies et la teinte du jour sont des uniformes : le moment de la journée (E9) les
//   change sans refaire les cartes.
// Compatible Compatibility / WebGL 2.

uniform float cut_line = 1000000.0;
uniform float cut_margin = 0.3;
uniform float floor_y = 0.0;
uniform sampler2D window_light : hint_default_black, filter_linear, repeat_disable;
uniform sampler2D lamp_light : hint_default_black, filter_linear, repeat_disable;
// Coin nord-ouest des cartes (x, z du monde) et inverse de leur taille (m).
uniform vec4 light_rect = vec4(0.0, 0.0, 1.0, 1.0);
uniform vec4 window_tint : source_color = vec4(1.0, 0.93, 0.8, 1.0);
uniform float window_energy = 1.0;
uniform float lamp_energy = 1.0;
// Les cartes sont en RGBA8 : valeur × light_scale.
uniform float light_scale = 2.0;
// Hauteur sur laquelle la lumière d'une flaque s'affaiblit le long d'un mur (m).
uniform float light_height = 3.0;

bool interior_is_cut(float coord) {
	return coord >= cut_line - cut_margin;
}

// Lumière ajoutée en (x, z) du monde, à height m au-dessus du sol.
vec3 interior_light(vec2 xz, float height) {
	vec2 uv = (xz - light_rect.xy) * light_rect.zw;
	vec3 day = texture(window_light, uv).rgb * window_tint.rgb * window_energy;
	vec3 lamps = texture(lamp_light, uv).rgb * lamp_energy;
	float fall = mix(1.0, 0.45, clamp(height / light_height, 0.0, 1.0));
	return (day + lamps) * light_scale * fall;
}
