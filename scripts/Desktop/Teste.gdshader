shader_type canvas_item;

uniform float opacity : hint_range(0.0, 1.0) = 0.45;
uniform float border_size : hint_range(0.0, 0.5) = 0.08;
uniform float roundness : hint_range(0.0, 0.5) = 0.18;
uniform float scanline_strength : hint_range(0.0, 1.0) = 0.18;
uniform float scanline_count = 420.0;

void fragment() {
	vec2 uv = UV;

	// distância do centro
	vec2 centered = uv - 0.5;

	// formato arredondado do "vidro"
	vec2 q = abs(centered) - vec2(0.5 - border_size, 0.5 - border_size);
	float outside = length(max(q, 0.0)) - roundness;

	// borda escura
	float border = smoothstep(-0.03, 0.03, outside);

	// vinheta nas laterais
	float vignette = smoothstep(0.25, 0.75, length(centered));

	// linhas CRT
	float scanlines = sin(uv.y * scanline_count * 3.14159);
	scanlines = scanlines * 0.5 + 0.5;

	float line_dark = scanlines * scanline_strength;

	// cor final
	vec3 color = vec3(0.75);
	color -= line_dark;
	color -= vignette * 0.35;

	// alpha: centro transparente, bordas mais fortes
	float alpha = opacity;
	alpha += vignette * 0.25;
	alpha *= 1.0 - border * 0.9;

	COLOR = vec4(color, alpha);
}