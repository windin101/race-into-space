shader_type canvas_item;
// Chrome lettering for the title logo: a vertical metal gradient per word with a dark
// horizon band and a bright sky reflection, like 1990s chrome type. `height` is the
// label's height in pixels so the gradient spans the glyphs.
uniform float height = 120.0;
uniform float top_pad = 0.27;     // fraction of the label above the cap height
uniform float cap = 0.50;         // fraction of the label the capitals occupy
uniform vec4 c_top : source_color = vec4(0.97, 0.98, 1.0, 1.0);
uniform vec4 c_mid : source_color = vec4(0.74, 0.79, 0.88, 1.0);
uniform vec4 c_band : source_color = vec4(0.20, 0.23, 0.34, 1.0);
uniform vec4 c_low : source_color = vec4(0.90, 0.93, 0.99, 1.0);
uniform vec4 c_foot : source_color = vec4(0.55, 0.64, 0.86, 1.0);
varying float ly;

void vertex() {
	ly = VERTEX.y;
}

void fragment() {
	float t = clamp((ly / height - top_pad) / cap, 0.0, 1.0);
	vec3 col;
	if (t < 0.45) col = mix(c_top.rgb, c_mid.rgb, t / 0.45);
	else if (t < 0.52) col = mix(c_mid.rgb, c_band.rgb, (t - 0.45) / 0.07);
	else if (t < 0.60) col = mix(c_band.rgb, c_low.rgb, (t - 0.52) / 0.08);
	else col = mix(c_low.rgb, c_foot.rgb, (t - 0.60) / 0.40);
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	// Keep the font's outline colour (COLOR carries it) where the glyph is outline only.
	COLOR = vec4(mix(tex.rgb, col, step(0.5, COLOR.r + COLOR.g + COLOR.b)), tex.a);
}
