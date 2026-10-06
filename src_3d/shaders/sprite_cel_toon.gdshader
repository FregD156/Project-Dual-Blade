shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_toon, specular_toon;

// Base sprite texture and color tint
uniform sampler2D main_texture : source_color, filter_nearest;
uniform vec4 base_tint : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float alpha_scissor : hint_range(0.0, 1.0) = 0.5;

// Pixel-based Outline (Safe for 2D Sprite3D Quads)
uniform bool enable_outline = true;
uniform vec4 outline_color : source_color = vec4(0.06, 0.06, 0.1, 1.0);
uniform float outline_thickness : hint_range(0.0, 3.0) = 1.0;

// Cel-shading parameters
uniform vec4 shadow_color : source_color = vec4(0.2, 0.22, 0.32, 1.0);
uniform float shadow_threshold : hint_range(-1.0, 1.0) = 0.05;
uniform float shadow_softness : hint_range(0.001, 0.5) = 0.05;

// Rim lighting (Edge glow from 3D lights)
uniform vec4 rim_color : source_color = vec4(0.9, 0.95, 1.0, 1.0);
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.7;
uniform float rim_smoothness : hint_range(0.001, 0.5) = 0.08;

// Emission (Flashing / Glowing eyes / Runic blades)
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy : hint_range(0.0, 5.0) = 0.0;

void fragment() {
	vec2 tex_size = vec2(textureSize(main_texture, 0));
	vec2 pixel_step = (outline_thickness / tex_size);
	
	vec4 col = texture(main_texture, UV);
	
	if (col.a >= alpha_scissor) {
		// Inside sprite body
		ALBEDO = base_tint.rgb * col.rgb;
		ALPHA = 1.0;
		EMISSION = emission_color.rgb * emission_energy;
	} else if (enable_outline) {
		// Sample 8 surrounding neighbors for pixel outline
		float a_top    = texture(main_texture, UV + vec2(0.0, -pixel_step.y)).a;
		float a_bottom = texture(main_texture, UV + vec2(0.0,  pixel_step.y)).a;
		float a_left   = texture(main_texture, UV + vec2(-pixel_step.x, 0.0)).a;
		float a_right  = texture(main_texture, UV + vec2( pixel_step.x, 0.0)).a;
		
		float a_tl = texture(main_texture, UV + vec2(-pixel_step.x, -pixel_step.y)).a;
		float a_tr = texture(main_texture, UV + vec2( pixel_step.x, -pixel_step.y)).a;
		float a_bl = texture(main_texture, UV + vec2(-pixel_step.x,  pixel_step.y)).a;
		float a_br = texture(main_texture, UV + vec2( pixel_step.x,  pixel_step.y)).a;
		
		float max_neighbor_a = max(max(max(a_top, a_bottom), max(a_left, a_right)),
		                           max(max(a_tl, a_tr), max(a_bl, a_br)));
		
		if (max_neighbor_a >= alpha_scissor) {
			ALBEDO = outline_color.rgb;
			ALPHA = 1.0;
		} else {
			discard;
		}
	} else {
		discard;
	}
	
	ROUGHNESS = 0.5;
	METALLIC = 0.0;
}

void light() {
	float NdotL = max(0.0, dot(NORMAL, LIGHT));
	float light_factor = smoothstep(shadow_threshold - shadow_softness, shadow_threshold + shadow_softness, NdotL);
	
	vec3 light_step = mix(shadow_color.rgb * ALBEDO, LIGHT_COLOR.rgb * ALBEDO, light_factor);
	vec3 diffuse_light = light_step * ATTENUATION;

	// Rim Light
	float rim = 1.0 - max(0.0, dot(NORMAL, VIEW));
	float rim_factor = smoothstep(rim_threshold - rim_smoothness, rim_threshold + rim_smoothness, rim);
	vec3 rim_light = rim_color.rgb * rim_factor * LIGHT_COLOR.rgb * NdotL * ATTENUATION;

	DIFFUSE_LIGHT += diffuse_light + rim_light;
}
