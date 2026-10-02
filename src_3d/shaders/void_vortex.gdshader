shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, unshaded;

uniform vec4 portal_color_core : source_color = vec4(0.3, 0.8, 1.0, 1.0);
uniform vec4 portal_color_outer : source_color = vec4(0.4, 0.1, 0.9, 1.0);
uniform float speed : hint_range(0.1, 5.0) = 1.8;

void fragment() {
	vec2 uv = UV - vec2(0.5);
	float dist = length(uv);
	float angle = atan(uv.y, uv.x);
	
	// Spiral twist
	float spiral = sin(dist * 18.0 - TIME * speed * 2.0 + angle * 4.0);
	float inner_glow = clamp(1.0 - (dist * 2.0), 0.0, 1.0);
	float alpha = clamp((inner_glow * 1.5) + (spiral * 0.3), 0.0, 1.0);
	
	vec3 col = mix(portal_color_outer.rgb, portal_color_core.rgb, inner_glow);
	ALBEDO = col;
	ALPHA = alpha * smoothstep(0.5, 0.35, dist);
}
