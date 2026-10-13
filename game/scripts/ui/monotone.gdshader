shader_type canvas_item;
// Monotone room backdrop (ui-style-guide section 3): desaturate, tint toward the side's
// hue, then darken so panels read on top. One painting serves both sides.
uniform vec4 tint : source_color = vec4(0.16, 0.30, 0.55, 1.0);
uniform float strength : hint_range(0.0, 1.0) = 0.65;
uniform float brightness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float l = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	vec3 mono = vec3(l);
	vec3 toned = mix(mono, mono * tint.rgb * 2.0, strength);
	COLOR = vec4(toned * brightness, c.a);
}
