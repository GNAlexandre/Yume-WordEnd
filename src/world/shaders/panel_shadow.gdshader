// (RD) Ombre peinte d'un décor (DecorPanel, Building) : au lieu de la tache ronde d'autrefois, une
// ombre de contact à la taille du décor (le cœur, sombre au pied, qui tient lieu d'occlusion
// ambiante) et une ombre portée allongée à l'opposé du soleil (la traîne), dont la direction et la
// longueur suivent la lumière du moment (Atmosphere → AtmosphereRig.apply : sun_away,
// sun_length, tail_strength, core_strength). Un seul matériau pour toutes : le PropBatcher les fond
// en un draw call par case. Chaque ombre est faite de quadrilatères à plat (DecorPanel.shadow_mesh_for) :
// - UV : coin (0..1) ; partie entière de UV.x / 2 : la forme (0 cœur ovale, 1 cœur en bande pour
//   les clôtures, murs et façades, 2 traîne ronde, 3 ombre portée d'un décor long) ; partie entière de UV.y / 2 : l'opacité (sur 20) ;
// - UV2 : écart du sommet à l'ancre du décor (m), dans le repère où la traîne va vers l'est (x)
//   et le sud (z) : le sommet de la traîne est tourné autour de l'ancre vers sun_away, et sa part
//   vers l'est allongée de sun_length.
// Les sommets sont posés pour une traîne vers l'est (le couchant de toujours) : la boîte du mesh
// reste juste. L'ombre se floute elle-même selon sa profondeur (depth_focus.gdshaderinc) : elle est
// dessinée après le flou de l'écran. Non éclairée, mélangée, sans écrire la profondeur.
// Compatible Compatibility / WebGL 2.
shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never, shadows_disabled, fog_disabled;

#include "res://src/world/shaders/depth_focus.gdshaderinc"

const float CORE = 0.0;
const float STRIP = 1.0;
const float TAIL = 2.0;
const float TAIL_LONG = 3.0;

// Direction (plan du sol x, z, unitaire) où partent les ombres : à l'opposé du soleil.
uniform vec2 sun_away = vec2(0.957, -0.288);
// Allongement de la traîne (1 : soleil à 20° au-dessus de l'horizon) ; force de la traîne et du
// cœur (0..1).
uniform float sun_length = 1.0;
uniform float tail_strength = 1.0;
uniform float core_strength = 1.0;
// Couleur de l'ombre (un violet sombre plutôt qu'un noir : la lumière du ciel dans l'ombre).
uniform vec4 shadow_color : source_color = vec4(0.11, 0.08, 0.16, 1.0);

varying float shape;
varying float opacity;
// Coin (0..1) du quadrilatère, sans les parties entières (calculé au sommet : pas de saut entre
// deux pixels voisins, donc des dérivées justes).
varying vec2 corner;

void vertex() {
	shape = floor(UV.x * 0.5 + 0.001);
	float level = floor(UV.y * 0.5 + 0.001);
	opacity = level / 20.0;
	corner = UV - vec2(shape, level) * 2.0;
	if (shape > TAIL_LONG - 0.5) {
		// Décor long : l'écart en travers reste le long de x (sa largeur), la traîne le pousse.
		vec2 anchor = VERTEX.xz - vec2(UV2.x + UV2.y, 0.0);
		VERTEX.xz = anchor + vec2(UV2.y, 0.0) + sun_away * UV2.x * sun_length;
	} else if (shape > TAIL - 0.5) {
		vec2 local = UV2;
		vec2 anchor = VERTEX.xz - local;
		local.x *= sun_length;
		vec2 across = vec2(-sun_away.y, sun_away.x);
		VERTEX.xz = anchor + sun_away * local.x + across * local.y;
	}
}

void fragment() {
	// Coordonnées de -1 à 1 à travers la forme (x le long, y en travers).
	vec2 p = corner * 2.0 - 1.0;
	vec2 width = fwidth(p);
	float soft = focus_radius(-VERTEX.z) * VIEWPORT_SIZE.y / 720.0;
	vec2 edge = width * (1.0 + soft) + 0.02;
	float a;
	if (shape < STRIP - 0.5) {
		// Cœur ovale : sombre au centre (le pied), fondu vers le bord.
		float r = length(p);
		a = (1.0 - smoothstep(0.35, 1.0 + edge.x, r)) * mix(1.0, 0.75, smoothstep(0.0, 0.6, r));
		a *= core_strength;
	} else if (shape < TAIL - 0.5) {
		// Bande au pied d'une clôture, d'un mur, d'une façade : le pied est aux trois quarts de la
		// bande (y = 0,5), l'ombre s'étend surtout devant lui (vers le sud, y = -1).
		float along = 1.0 - smoothstep(0.7, 1.0 + edge.x, abs(p.x));
		float dy = p.y - 0.5;
		float depth_part = dy < 0.0 ? 1.0 - smoothstep(0.0, 1.5 + edge.y, -dy) : 1.0 - smoothstep(0.0, 0.5 + edge.y, dy);
		a = along * depth_part * core_strength;
	} else if (shape > TAIL_LONG - 0.5) {
		// Ombre portée d'un décor long : toute sa largeur, qui s'efface vers son bout.
		float t = corner.x;
		float across = 1.0 - smoothstep(0.85, 1.0 + edge.y, abs(p.y));
		float fade = smoothstep(0.0, 0.12, t) * (1.0 - smoothstep(0.3, 1.0 + edge.x, t));
		a = across * fade * tail_strength;
	} else {
		// Traîne : part du pied (x = -1), s'amincit et s'efface vers son bout (x = 1).
		float t = corner.x;
		float half_width = mix(1.0, 0.55, t);
		float across = 1.0 - smoothstep(half_width * 0.45, half_width + edge.y, abs(p.y));
		float fade = smoothstep(0.0, 0.18, t) * (1.0 - smoothstep(0.35, 1.0 + edge.x, t));
		a = across * fade * tail_strength;
	}
	ALBEDO = shadow_color.rgb;
	ALPHA = clamp(a * opacity, 0.0, 1.0);
}
