// Terreno: color de cada zona (viene en los vértices) + detalle de ruido para que no se vea plano.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform sampler2D detail : filter_linear_mipmap, repeat_enable;
varying vec3 wpos;
varying vec3 wnorm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnorm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	float fine = texture(detail, wpos.xz * 0.11).r;
	float mid = texture(detail, wpos.xz * 0.025).r;
	float big = texture(detail, wpos.xz * 0.004).r;
	vec3 c = COLOR.rgb;
	c *= 0.78 + 0.34 * fine;          // granulado del pasto y la tierra
	c *= 0.88 + 0.24 * mid;           // manchas medianas
	c = mix(c, c * vec3(1.08, 1.04, 0.86), smoothstep(0.55, 0.8, big) * 0.5);   // zonas más secas
	// en pendientes fuertes, vetas de roca
	float slope = 1.0 - clamp(wnorm.y, 0.0, 1.0);
	float strata = texture(detail, vec2(wpos.x * 0.02, wpos.y * 0.35)).r;
	c = mix(c, c * (0.75 + 0.4 * strata), smoothstep(0.35, 0.7, slope));
	ALBEDO = c;
	ROUGHNESS = 0.95;
}
