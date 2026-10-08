// Découpe du décor autour du joueur (Lot H2, src/world/zones/village/see_through.gd) : incluse
// dans une copie de src/world/shaders/panel.gdshader faite au lancement, elle efface en trame
// ordonnée de 4 × 4 pixels d'écran le décor qui passe devant le corps du joueur (plus près de la
// caméra que lui), dans une ellipse autour de lui : un bâtiment, un arbre ou un drap ne le cache
// jamais. Le décor qui est derrière lui reste entier. Compatible Compatibility / WebGL 2.
// (P2) Toile de fond : une image marquée see_through_backdrop (la lisière derrière la palissade
// nord, les arbres du bord nord) s'efface tout entière, en trame, quand le joueur sort du
// village par le nord (au nord de see_through_backdrop_line) et passe au nord d'elle : elle est
// alors entre la caméra et lui et cacherait les bois sur 15 m.

// Centre du corps du joueur (monde) ; demi-largeur et demi-hauteur de l'ellipse (m, à sa
// profondeur) ; profondeur (m) sur laquelle la découpe s'installe devant lui ; force (0 : aucune).
uniform vec3 see_through_center = vec3(0.0);
uniform vec2 see_through_size = vec2(0.8, 1.1);
uniform float see_through_depth = 0.35;
uniform float see_through_strength = 0.0;
// (P2) Toile de fond : 1 pour les images qui s'effacent tout entières quand le joueur est au nord
// d'elles ; z du monde de la limite nord du village (l'effacement s'installe sur le premier
// mètre au-delà) ; écart nord-sud (m) entre le panneau et le joueur où l'effacement commence, et
// longueur (m) sur laquelle il se fait.
uniform float see_through_backdrop = 0.0;
uniform float see_through_backdrop_line = 0.0;
uniform float see_through_backdrop_from = 0.4;
uniform float see_through_backdrop_ramp = 2.6;

// Part (0..1) du fragment à effacer ; vertex : position du fragment dans le repère de la vue.
float see_through_amount(vec3 vertex, mat4 view_matrix, mat4 inv_view_matrix) {
	if (see_through_strength <= 0.0) {
		return 0.0;
	}
	float backdrop = 0.0;
	if (see_through_backdrop > 0.0) {
		// Écart nord-sud du fragment au joueur (z du monde : le sud est +z).
		float south = (inv_view_matrix * vec4(vertex, 1.0)).z - see_through_center.z;
		float outside = smoothstep(0.0, 1.0, see_through_backdrop_line - see_through_center.z);
		backdrop = smoothstep(
				see_through_backdrop_from,
				see_through_backdrop_from + see_through_backdrop_ramp,
				south)
				* outside * see_through_backdrop * see_through_strength;
	}
	vec3 center = (view_matrix * vec4(see_through_center, 1.0)).xyz;
	float ahead = vertex.z - center.z;
	if (ahead <= 0.0 || center.z > -0.05 || vertex.z > -0.05) {
		return backdrop;
	}
	// Écart à l'écran ramené en mètres à la profondeur du joueur.
	vec2 offset = (vertex.xy / -vertex.z - center.xy / -center.z) * -center.z;
	float inside = 1.0 - smoothstep(0.7, 1.0, length(offset / see_through_size));
	return max(inside * smoothstep(0.0, see_through_depth, ahead) * see_through_strength, backdrop);
}

// Seuil de la trame ordonnée 4 × 4 d'un pixel d'écran (0..1).
float see_through_dither(vec2 pixel) {
	vec2 c = mod(floor(pixel), 4.0);
	int i = int(c.x) + int(c.y) * 4;
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i]) + 0.5) / 16.0;
}
