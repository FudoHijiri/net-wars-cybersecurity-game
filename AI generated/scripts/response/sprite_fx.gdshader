shader_type canvas_item;
// Effects for the two fighters of the Response phase (set from response_fx.gd).
//   flash       0..1  whole sprite goes white (a hit)
//   tint        colour the sprite is mixed with, tint_amount 0..1 says how much (a wind-up, a red hurt)
//   gray        0..1  loses its colour (knocked out)
//   dissolve    0..1  pixels vanish one by one, the last ones glow in the tint colour (defeated)
// The pixels are the sprite's own pixels, so nothing is blurred.

uniform float flash : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint : source_color = vec4(1.0, 0.3, 0.3, 1.0);
uniform float tint_amount : hint_range(0.0, 1.0) = 0.0;
uniform float gray : hint_range(0.0, 1.0) = 0.0;
uniform float dissolve : hint_range(0.0, 1.0) = 0.0;

float hash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

void fragment() {
	vec4 c = COLOR; // the texture, already multiplied by the modulate
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	c.rgb = mix(c.rgb, vec3(lum), gray);
	c.rgb = mix(c.rgb, tint.rgb, tint_amount * c.a);
	c.rgb = mix(c.rgb, vec3(1.0), flash);
	float n = hash(floor(UV / TEXTURE_PIXEL_SIZE));
	if (n < dissolve) {
		c.a = 0.0;
	} else if (n < dissolve + 0.1 && dissolve > 0.0) {
		c.rgb = mix(c.rgb, tint.rgb, 0.85);
	}
	COLOR = c;
}
