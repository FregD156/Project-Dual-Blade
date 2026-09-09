shader_type canvas_item;

uniform bool flash_active = false;
uniform vec4 flash_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	vec4 texture_color = texture(TEXTURE, UV);
	if (flash_active) {
		COLOR = vec4(mix(texture_color.rgb, flash_color.rgb, flash_color.a), texture_color.a);
	} else {
		COLOR = texture_color;
	}
}
