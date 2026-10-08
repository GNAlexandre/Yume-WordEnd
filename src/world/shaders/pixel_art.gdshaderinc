// Échantillonnage du pixel art « net mais lissé » (H5), partagé par les panneaux, les murs et
// toits des bâtiments et la roche de l'île. Les images sont à 96 px par mètre : selon la
// distance et la taille de l'écran, un pixel d'image couvre plus ou moins d'un pixel d'écran.
// - De près (un pixel d'image plus grand qu'un pixel d'écran) : pixels nets, et seule la
//   frontière entre deux pixels d'image est lissée, sur la largeur d'un pixel d'écran (pas
//   d'escalier qui saute d'un pixel quand la caméra glisse).
// - De loin (plusieurs pixels d'image par pixel d'écran) : quatre échantillons bilinéaires
//   répartis sur l'empreinte du pixel d'écran (sur-échantillonnage local), sans mipmaps : les
//   images importées n'en ont pas. Fini le moiré et le scintillement des herbes et des planches.
// Le sampler doit être filtré (filter_linear) ; l'alpha moyenné reste découpé par le shader.
// pixel_art_grad() prend les dérivées des UV calculées par l'appelant hors de tout branchement
// (dFdx n'est pas défini dans une branche qui diffère d'un pixel à son voisin).
// Compatible Compatibility / WebGL 2.

vec4 pixel_art_grad(sampler2D tex, vec2 uv, vec2 uv_dx, vec2 uv_dy) {
	vec2 size = vec2(textureSize(tex, 0));
	vec2 texel = uv * size;
	vec2 dx = uv_dx * size;
	vec2 dy = uv_dy * size;
	float spread = max(length(dx), length(dy));
	if (spread <= 1.0) {
		vec2 width = clamp(abs(dx) + abs(dy), vec2(0.001), vec2(1.0));
		vec2 sharp = floor(texel) + 0.5 + clamp((fract(texel) - 0.5) / width, -0.5, 0.5);
		return textureLod(tex, sharp / size, 0.0);
	}
	vec2 ox = uv_dx * 0.25;
	vec2 oy = uv_dy * 0.25;
	return 0.25
			* (textureLod(tex, uv - ox - oy, 0.0) + textureLod(tex, uv + ox - oy, 0.0)
					+ textureLod(tex, uv - ox + oy, 0.0) + textureLod(tex, uv + ox + oy, 0.0));
}

vec4 pixel_art(sampler2D tex, vec2 uv) {
	return pixel_art_grad(tex, uv, dFdx(uv), dFdy(uv));
}
