shader_type canvas_item;

void fragment() {
    // By default, draw the sprite from its texture.
    // This will be visible in the dark because we are not using a light_mode.
    COLOR = texture(TEXTURE, UV);
}

void light() {
    // If any light touches this sprite, make it fully transparent.
    // Since the sprite's light_mask is set to only see 'reveal_light',
    // this will only trigger for that specific light type.
    ALPHA = 0.0;
}