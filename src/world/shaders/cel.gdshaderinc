// Éclairage « cel » discret, partagé par le sol, la roche, l'herbe et les décors de l'île :
// deux paliers doux (le terminateur, puis le plein soleil dès qu'une face regarde un peu le
// soleil), sans reflet spéculaire ; sauf si CEL_NO_RIM est défini avant l'inclusion, un léger
// liseré de lumière sur les contours éclairés, plus marqué à contre-jour. Les zones à l'ombre ne
// reçoivent que la lumière ambiante (bleutée, island.tscn).
// Compatible Compatibility / WebGL 2 : fonction light() appelée dans la passe du soleil.

#ifndef CEL_NO_RIM
uniform float cel_rim = 0.4;
#endif

void light() {
	float ndl = dot(NORMAL, LIGHT);
	float lit = smoothstep(-0.04, 0.08, ndl) * 0.55 + smoothstep(0.14, 0.28, ndl) * 0.45;
	vec3 sun = LIGHT_COLOR * ATTENUATION / PI;
	DIFFUSE_LIGHT += sun * lit;
#ifndef CEL_NO_RIM
	float facing = 1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0);
	float rim = facing * facing * facing;
	float backlit = clamp(-dot(VIEW, LIGHT), 0.0, 1.0);
	rim *= smoothstep(-0.15, 0.2, ndl) * (0.3 + 0.7 * backlit);
	DIFFUSE_LIGHT += sun * rim * cel_rim;
#endif
}
