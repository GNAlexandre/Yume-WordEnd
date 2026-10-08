// (H9) Premier plan qui s'efface devant le joueur (panel_foreground.gdshader, DecorPanel
// marqué foreground) : le panneau, plus proche de la caméra que le joueur, s'efface en trame
// ordonnée de 4 × 4 pixels d'écran dans une ellipse autour de son corps (comme la découpe du
// décor du village, lot H2) ; au cœur de l'ellipse il reste foreground_keep des pixels (le
// tronc flou devient translucide), rien au bord. foreground_center et foreground_strength sont
// posés à chaque image par DecorPanel (corps du joueur, groupe « player »). Compatible
// Compatibility / WebGL 2.

uniform vec3 foreground_center = vec3(0.0);
// Demi-largeur et demi-hauteur de l'ellipse (m, à la profondeur du joueur), profondeur (m) sur
// laquelle l'effacement s'installe devant lui, part gardée au cœur, force (0 : aucun effet).
uniform vec2 foreground_size = vec2(1.4, 1.9);
uniform float foreground_depth = 0.6;
uniform float foreground_keep = 0.2;
uniform float foreground_strength = 0.0;

// Part (0..1) du fragment à effacer ; vertex : position du fragment dans le repère de la vue.
float foreground_amount(vec3 vertex, mat4 view_matrix) {
	if (foreground_strength <= 0.0) {
		return 0.0;
	}
	vec3 center = (view_matrix * vec4(foreground_center, 1.0)).xyz;
	float ahead = vertex.z - center.z;
	if (ahead <= 0.0 || center.z > -0.05 || vertex.z > -0.05) {
		return 0.0;
	}
	// Écart à l'écran ramené en mètres à la profondeur du joueur.
	vec2 offset = (vertex.xy / -vertex.z - center.xy / -center.z) * -center.z;
	float inside = 1.0 - smoothstep(0.35, 1.0, length(offset / foreground_size));
	return inside * smoothstep(0.0, foreground_depth, ahead) * foreground_strength
			* (1.0 - foreground_keep);
}

// Seuil de la trame ordonnée 4 × 4 d'un pixel d'écran (0..1).
float foreground_dither(vec2 pixel) {
	vec2 c = mod(floor(pixel), 4.0);
	int i = int(c.x) + int(c.y) * 4;
	int m[16] = int[16](0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5);
	return (float(m[i]) + 0.5) / 16.0;
}
