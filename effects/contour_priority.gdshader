shader_type canvas_item;
render_mode blend_mix;

// Shader to make a sprite visible under a specific "tagged" light (echo_light)
// and hide it under any other light (reveal_light).

// Convention:
// - echo_light (Layer 3) must have its Shadow Color set to red (1,0,0,1).
// - reveal_light (Layer 4) must have a normal Shadow Color (e.g., black).

void fragment() {
	// The final alpha is determined by the sum of ALPHA values from the light() passes.
	// By default, the sprite is transparent.
	COLOR.a = 0.0;
}

void light() {
	// This function runs for each light affecting the sprite.
	// Check if the light is an "echo_light" by looking for the red shadow color tag.
	if (SHADOW_COLOR.r > 0.9) {
		// This is an echo_light. Make the sprite visible.
		// We set the COLOR from the texture and set ALPHA to 1.0.
		COLOR = texture(TEXTURE, UV);
		ALPHA = 1.0;
	} else {
		// This is any other light, which we treat as a "reveal_light".
		// It should erase the effect of the echo_light.
		// We output a large negative alpha. Since light passes are additive,
		// this will cancel out the positive alpha from any echo_light, making the sprite invisible.
		ALPHA = -100.0;
	}
}
