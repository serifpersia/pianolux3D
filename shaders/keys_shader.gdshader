shader_type spatial;

render_mode unshaded;
uniform vec3 color: source_color;

void fragment() {
	
	ALBEDO = color;
	EMISSION = color;
}