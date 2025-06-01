shader_type spatial;

uniform vec4 color_from : source_color;
uniform vec4 color_to : source_color;
uniform float blend_factor : hint_range(0.0, 1.0);

void fragment() {
    ALBEDO = mix(color_from.rgb, color_to.rgb, blend_factor);
}
