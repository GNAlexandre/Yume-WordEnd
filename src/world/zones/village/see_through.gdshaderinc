// Découpe du décor autour du joueur (Lot H2, src/world/zones/village/see_through.gd) : incluse
// dans une copie de src/world/shaders/panel.gdshader faite au lancement, elle efface en trame
// ordonnée de 4 × 4 pixels d'écran le décor qui passe devant le corps du joueur (plus près de la
// caméra que lui), dans une ellipse autour de lui : un bâtiment, un arbre ou un drap ne le cache
// jamais. Le décor qui est derrière lui reste entier. Compatible Compatibility / WebGL 2.

// Centre du corps du joueur (monde) ; demi-largeur et demi-hauteur de l'ellipse (m, à sa
// profondeur) ; profondeur (m) sur laquelle la découpe s'installe devant lui ; force (0 : aucune).
uniform vec3 see_through_center = vec3(0.0);
uniform vec2 see_through_size = vec2(0.8, 1.1);
uniform float see_through_depth = 0.35;
uniform float see_through_strength = 0.0;

// Part (0..1) du fragment à effacer ; vertex : position du fragment dans le repère de la vue.
float see_through_amount(vec3 vertex, mat4 view_matrix) {
	if (see_through_strength <= 0.0) {
		return 0.0;
	}
	vec3 center = (view_matrix * vec4(see_through_center, 1.0)).xyz;
	float ahead = vertex.z - center.z;
	if (ahead <= 0.0 || center.z > -0.05 || vertex.z > -0.05) {
		return 0.0;
	}
	// Écart à l'écran ramené en mètres à la profondeur du joueur.
	vec2 offset = (vertex.xy / -vertex.z - center.xy / -center.z) * -center.z;
	float inside = 1.0 - smoothstep(0.7, 1.0, length(offset / see_through_size));
	return inside * smoothstep(0.0, see_through_depth, ahead) * see_through_strength;
}

// Seuil de la trame ordonnée 4 × 4 d'un pixel d'écran (0..1).
float see_through_dither(vec2 pixel) {
	vec2 c = mod(floor(pixel), 4.0);
	int i = int(c.x) + int(c.y) * 4;
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i]) + 0.5) / 16.0;
}
