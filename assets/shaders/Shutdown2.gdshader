shader_type canvas_item;

uniform float band_size = 1.0;
uniform float brightness = 1.0;
uniform float glow_size = 0.25;
uniform float center_glow = 0.0;
uniform float noise_power = 0.12;

float random(vec2 uv) {
	return fract(sin(dot(uv.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec2 uv = UV;

	float dist_y = abs(uv.y - 0.5);

	// faixa horizontal principal
	float band = smoothstep(band_size, 0.0, dist_y);

	// linha fina no centro
	float line = smoothstep(0.01, 0.0, dist_y);

	// brilho central
	float dist_center = distance(uv, vec2(0.5, 0.5));
	float glow = smoothstep(glow_size, 0.0, dist_center) * center_glow;

	// ruído pra deixar esfarelado
	float noise = random(uv * 220.0);
	float dirty = mix(1.0 - noise_power, 1.0, noise);

	float alpha = (band * 0.75 + line + glow) * brightness * dirty;

	COLOR = vec4(vec3(1.0), alpha);
}