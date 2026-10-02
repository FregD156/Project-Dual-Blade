shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, unshaded;

uniform vec4 slash_color : source_color = vec4(0.3, 0.7, 1.0, 1.0);
uniform vec4 core_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float progress : hint_range(0.0, 1.0) = 0.0;
uniform float trail_length : hint_range(0.1, 1.0) = 0.6;

void fragment() {
	float u = UV.x;
	float v = UV.y;
	
	// Fade edges along V
	float edge_fade = sin(v * 3.14159);
	
	// Arc progression
	float head = progress;
	float tail = max(0.0, head - trail_length);
	
	float alpha = 0.0;
	if (u >= tail && u <= head) {
		float trail_factor = (u - tail) / max(0.001, (head - tail));
		alpha = pow(trail_factor, 1.5) * edge_fade;
	}
	
	vec3 col = mix(slash_color.rgb, core_color.rgb, pow(alpha, 3.0));
	ALBEDO = col;
	ALPHA = clamp(alpha * 1.5, 0.0, 1.0);
}
