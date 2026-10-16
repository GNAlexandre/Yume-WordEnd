// (H9) Cœur des panneaux HD-2D, partagé par panel.gdshader et panel_foreground.gdshader (à
// inclure après hd2d_light.gdshaderinc et pixel_art.gdshaderinc) : uniformes de l'image, bande
// animée (docs/ASSETS_HD2D_MONDE.md, section 3.4), décalage vers la caméra et couleur d'un
// pixel. Les données propres à chaque exemplaire passent par UV2 (le PropBatcher les garde quand
// il fond les panneaux d'une même image en un mesh) :
// - UV2.x : phase de la bande animée (0..1, tirée de la position du panneau) ; (RD) sa partie
//   entière porte la variation de teinte de l'exemplaire (panel_tone, posée par le PropBatcher
//   d'après DecorPanel.tone) ;
// - UV2.y : décalage vers la caméra (m) d'un panneau posé contre un mur ou sur un toit.
// (RD) Vent (panel_wind_uv) : la cime des arbres, les herbes, les roseaux et les haies se
// balancent (wind_px, wind_from, posés par DecorPanel selon le genre du décor, DecorGenre ; 0 pour
// le reste), d'une phase tirée de la position du pixel dans le monde (une onde qui traverse la
// carte) : rien ne dépend de l'exemplaire, le vent marche sur le mesh fondu du PropBatcher.
// Compatible Compatibility / WebGL 2.

uniform sampler2D albedo_texture : source_color, filter_linear, repeat_enable;
uniform vec4 tint : source_color = vec4(1.0);
uniform float alpha_cut = 0.5;
// Lueur propre (fenêtres, cristaux) : les pixels proches de glow_color s'allument sans lumière.
// (QC) glow_color est une couleur de l'image (sRGB), sans conversion : l'image, elle, est lue en
// linéaire (source_color), on la ramène en sRGB pour comparer. Avec source_color sur glow_color,
// le rendu Compatibility comparait une couleur sRGB à un pixel linéaire : aucune vitre ne
// s'allumait la nuit (docs/QUALITE.md, QC-01).
uniform vec4 glow_color = vec4(1.0, 0.9, 0.65, 1.0);
// (QO) Constat : le rendu Compatibility lit l'image telle quelle (sRGB, sans conversion en
// linéaire) ; le pixel comparé est donc la couleur du fichier à la puissance 1/2,2, et le réglage
// par défaut allume les pixels proches de #FFCA63 (pas #FFE6A6). glow_tolerance : distance (dans
// cet espace) au-delà de laquelle un pixel reste éteint ; il s'allume en plein en deçà de 5/12 de
// cette distance. Par bâtiment : Building.window_glow_color et window_glow_tolerance, réglées sur
// les carreaux de l'image (DecorPanel.set_glow_rule ; docs/QUALITE.md, QC-02).
uniform float glow_tolerance = 0.12;
uniform float glow_strength = 0.0;
// Bande animée : nombre d'images côte à côte (1 : image fixe) et cadence (images par seconde ;
// 0 : chaque exemplaire garde l'image de sa phase).
uniform float frames = 1.0;
uniform float fps = 0.0;
// (RD) Vent : déplacement (px de l'image) du haut de l'image, part de la hauteur (0 : le pied,
// 1 : le haut) où le balancement commence ; 0 : immobile.
uniform float wind_px = 0.0;
uniform float wind_from = 0.3;
// (RD) Pas des variations de teinte codées dans UV2.x (TONE_LEVELS niveaux de luminosité, de
// −TONE_BRIGHT à +TONE_BRIGHT, par niveau de teinte, de −TONE_HUE à +TONE_HUE en part du tour) :
// voir DecorPanel.tone_code().
const float TONE_LEVELS = 25.0;
const float TONE_BRIGHT = 0.06;
const float TONE_HUE_LEVELS = 13.0;
const float TONE_HUE = 0.03;

// UV dans l'image courante de la bande : l'image change avec le temps (TIME, qui continue
// pendant la pause), décalée de la phase de l'exemplaire.
vec2 panel_strip_uv(vec2 uv, vec2 uv2, float time) {
	if (frames < 1.5) {
		return uv;
	}
	float frame = floor(mod(time * fps + fract(uv2.x) * frames, frames));
	return vec2((frame + uv.x) / frames, uv.y);
}

// Position (clip) du sommet, tirée de offset m vers la caméra le long de son rayon : le panneau
// passe devant le mur ou le toit sur lequel il est posé sans bouger à l'écran.
vec4 panel_position(vec3 vertex, float offset, mat4 modelview, mat4 projection) {
	vec4 view = modelview * vec4(vertex, 1.0);
	if (offset > 0.0) {
		view.xyz *= max(1.0 - offset / max(length(view.xyz), 0.001), 0.0);
	}
	return projection * view;
}

// Couleur du pixel du panneau : image « nette mais lissée », teinte, transparence (découpée par
// l'appelant à alpha_cut), lueur des pixels couleur cristal.
void panel_shade(vec2 uv, out vec3 albedo, out float alpha, out vec3 emission) {
	vec4 c = pixel_art(albedo_texture, uv);
	albedo = c.rgb * tint.rgb;
	alpha = c.a;
	emission = vec3(0.0);
	if (glow_strength > 0.0) {
		vec3 image_color = pow(max(c.rgb, vec3(0.0)), vec3(1.0 / 2.2));
		float near_glow = 1.0 - smoothstep(
			glow_tolerance * 5.0 / 12.0, glow_tolerance, distance(image_color, glow_color.rgb)
		);
		emission = c.rgb * near_glow * glow_strength;
	}
}

// (RD) Variation de teinte de l'exemplaire, codée dans la partie entière de UV2.x (0 : aucune) :
// (luminosité relative, rotation de teinte en part du tour).
vec2 panel_tone(vec2 uv2) {
	float code = floor(uv2.x);
	if (code < 0.5) {
		return vec2(0.0);
	}
	code -= 1.0;
	float bright = mod(code, TONE_LEVELS);
	float hue = floor(code / TONE_LEVELS + 0.001);
	return vec2(
		(bright / (TONE_LEVELS - 1.0) * 2.0 - 1.0) * TONE_BRIGHT,
		(hue / (TONE_HUE_LEVELS - 1.0) * 2.0 - 1.0) * TONE_HUE
	);
}

// (RD) Applique la variation (panel_tone) à une couleur : luminosité, puis petite rotation de
// teinte autour de l'axe des gris (au premier ordre, assez pour quelques degrés).
vec3 panel_apply_tone(vec3 c, vec2 tone) {
	float turn = tone.y * 6.2831853 * 0.57735;
	vec3 rotated = c + turn * vec3(c.b - c.g, c.r - c.b, c.g - c.r);
	return max(rotated, vec3(0.0)) * (1.0 + tone.x);
}

// (RD) UV d'un pixel du panneau balancé par le vent : décalage horizontal de wind_px pixels de
// l'image au haut de l'image, nul sous wind_from, d'une onde lente (phase tirée de la position
// du pixel dans le monde, ground : x et z) et d'une rafale plus lente encore. flip_sign : signe
// de dFdx(uv.x) (image retournée : −1), pour que tout penche du même côté à l'écran.
vec2 panel_wind_uv(vec2 uv, vec2 ground, float time, float flip_sign) {
	if (wind_px <= 0.0) {
		return uv;
	}
	float height = 1.0 - uv.y;
	float weight = smoothstep(wind_from, 1.0, height);
	weight *= weight;
	float phase = dot(ground, vec2(0.12, 0.47));
	float gust = 0.55 + 0.45 * sin(time * 0.31 + ground.x * 0.045 - ground.y * 0.03);
	float sway = sin(time * 1.25 + phase) * 0.7 + sin(time * 2.9 + phase * 1.9) * 0.3;
	float shift = wind_px * weight * sway * gust / float(textureSize(albedo_texture, 0).x);
	return vec2(uv.x - shift * flip_sign, uv.y);
}
