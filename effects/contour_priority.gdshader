shader_type canvas_item;
render_mode blend_mix;

void fragment() {
	COLOR.a = 0.0;
}

void light() {
	if (LIGHT_COLOR.r > 0.9) {
		LIGHT = texture(TEXTURE, UV);
	} else {
		LIGHT = vec4(0.0, 0.0, 0.0, 0.0);
	}
}
