// Agua del río y el lago: color con ondas que se mueven y brillo según el ángulo.
shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_opaque;

uniform sampler2D ripples : filter_linear_mipmap, repeat_enable;
varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	float a = texture(ripples, wpos.xz * 0.035 + vec2(TIME * 0.012, TIME * 0.008)).r;
	float b = texture(ripples, wpos.xz * 0.09 - vec2(TIME * 0.02, -TIME * 0.015)).r;
	float n = a * 0.6 + b * 0.4;
	vec3 deep = vec3(0.08, 0.33, 0.55);
	vec3 shallow = vec3(0.28, 0.66, 0.82);
	float fres = pow(1.0 - clamp(dot(NORMAL, VIEW), 0.0, 1.0), 3.0);
	ALBEDO = mix(deep, shallow, n) + vec3(0.9) * smoothstep(0.72, 0.8, n) * 0.25;
	ALPHA = clamp(0.78 + fres * 0.2, 0.0, 0.97);
	ROUGHNESS = 0.08;
	METALLIC = 0.2;
	SPECULAR = 0.7;
}
