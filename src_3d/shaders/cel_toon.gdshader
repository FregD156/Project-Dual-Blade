shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_toon, specular_toon;

uniform vec4 base_color : source_color = vec4(0.85, 0.85, 0.9, 1.0);
uniform sampler2D main_texture : source_color, filter_nearest, repeat_enable;
uniform bool use_texture = false;
uniform bool use_world_triplanar = false;
uniform float uv_scale = 0.5; // 0.5 = 1 tile per 2 meters

// Toon shading steps
uniform vec4 shadow_color : source_color = vec4(0.2, 0.22, 0.32, 1.0);
uniform float shadow_threshold : hint_range(-1.0, 1.0) = 0.1;
uniform float shadow_softness : hint_range(0.001, 0.5) = 0.05;

// Rim lighting
uniform vec4 rim_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float rim_threshold : hint_range(0.0, 1.0) = 0.65;
uniform float rim_smoothness : hint_range(0.001, 0.5) = 0.08;

// Specular
uniform vec4 specular_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform float specular_size : hint_range(0.01, 1.0) = 0.15;
uniform float specular_smoothness : hint_range(0.001, 0.2) = 0.04;

// Emission (Glow for blades/eyes)
uniform vec4 emission_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy : hint_range(0.0, 10.0) = 0.0;

varying vec3 v_world_pos;
varying vec3 v_world_normal;

void vertex() {
	v_world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_world_normal = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec4 albedo_tex = vec4(1.0);
	if (use_texture) {
		if (use_world_triplanar) {
			vec3 abs_norm = abs(v_world_normal);
			if (abs_norm.y > abs_norm.x && abs_norm.y > abs_norm.z) {
				// Top / Bottom surfaces
				albedo_tex = texture(main_texture, v_world_pos.xz * uv_scale);
			} else if (abs_norm.z >= abs_norm.x) {
				// Front / Back vertical faces
				albedo_tex = texture(main_texture, v_world_pos.xy * uv_scale);
			} else {
				// Side vertical faces
				albedo_tex = texture(main_texture, v_world_pos.zy * uv_scale);
			}
		} else {
			albedo_tex = texture(main_texture, UV * uv_scale);
		}
	}
	ALBEDO = base_color.rgb * albedo_tex.rgb;
	ROUGHNESS = 0.4;
	METALLIC = 0.0;
	EMISSION = emission_color.rgb * emission_energy;
}

void light() {
	float NdotL = max(0.0, dot(NORMAL, LIGHT));
	float light_factor = smoothstep(shadow_threshold - shadow_softness, shadow_threshold + shadow_softness, NdotL);
	
	// Light step modulated by ATTENUATION to prevent light accumulation blowout
	vec3 light_step = mix(shadow_color.rgb * ALBEDO, LIGHT_COLOR.rgb * ALBEDO, light_factor);
	vec3 diffuse_light = light_step * ATTENUATION;

	// Toon Specular
	vec3 half_vector = normalize(VIEW + LIGHT);
	float NdotH = max(0.0, dot(NORMAL, half_vector));
	float spec_factor = smoothstep(1.0 - specular_size - specular_smoothness, 1.0 - specular_size + specular_smoothness, NdotH);
	vec3 spec_light = specular_color.rgb * spec_factor * light_factor * ATTENUATION;

	// Anime Rim Light
	float rim = 1.0 - max(0.0, dot(NORMAL, VIEW));
	float rim_factor = smoothstep(rim_threshold - rim_smoothness, rim_threshold + rim_smoothness, rim);
	vec3 rim_light = rim_color.rgb * rim_factor * LIGHT_COLOR.rgb * NdotL * ATTENUATION;

	DIFFUSE_LIGHT += diffuse_light + rim_light;
	SPECULAR_LIGHT += spec_light;
}
