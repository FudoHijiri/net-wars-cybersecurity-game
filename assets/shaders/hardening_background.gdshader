shader_type canvas_item;

// Animated dot-grid background for the Hardening phase. Put it on a ColorRect that
// covers the screen and give it assets/background/hardening_tile.png (8x8) as `tile`.
// Any other square tile works too (the Response phase can use response_grid_tile.png, 40x40): set `tile_size` to its
// side in pixels, and `light_chance` to 0 when the tile has no dots that should glow.
// The grid drifts diagonally one whole pixel at a time (keeps the pixel art crisp)
// and a few dots slowly glow amber, like status lights. Nothing flashes.
uniform sampler2D tile : filter_nearest;
uniform int tile_size = 8; // side of the tile in pixels
uniform vec2 area = vec2(640.0, 360.0);
uniform float scroll_speed = 4.0; // pixels per second, 0 = still
uniform float light_chance = 0.06; // share of dots that glow
uniform float light_strength : hint_range(0.0, 1.0) = 0.6;
uniform vec4 light_color : source_color = vec4(1.0, 0.803922, 0.458824, 1.0);

float hash(vec2 c) {
	return fract(sin(dot(c, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	ivec2 q = ivec2(floor(UV * area)) + ivec2(int(floor(TIME * scroll_speed)));
	vec4 c = texelFetch(tile, q % tile_size, 0);
	float h = hash(vec2(q / tile_size));
	if (h < light_chance && c.rgb != texelFetch(tile, ivec2(0), 0).rgb) {
		float pulse = 0.5 + 0.5 * sin(TIME * 1.2 + h * 60.0);
		c.rgb = mix(c.rgb, light_color.rgb, pulse * light_strength);
	}
	COLOR = c;
}
