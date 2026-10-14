shader_type canvas_item;
// Photo-reconnaissance view of the Moon: haze 0..1 flattens the contrast toward a dull
// grey, as early, poor photographs would. The blur comes from a low-resolution copy;
// disc (the sharp original) keeps its outline crisp.
uniform float haze = 0.0;
uniform sampler2D disc : filter_linear;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	c.rgb = mix(c.rgb, vec3(0.42), haze);
	c.a = texture(disc, UV).a;
	COLOR = c * COLOR;
}
