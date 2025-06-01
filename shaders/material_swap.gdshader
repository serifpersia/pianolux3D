shader_type spatial;

uniform vec4 color_from : source_color;
uniform vec4 color_to : source_color;
uniform float blend_factor : hint_range(0.0, 1.0);

uniform vec4 emission_from : source_color;
uniform vec4 emission_to : source_color;
uniform float emission_blend : hint_range(0.0, 1.0);

uniform float emission_multiplier_from;
uniform float emission_multiplier_to;
uniform float emission_multiplier_blend : hint_range(0.0, 1.0);

void fragment() {
    ALBEDO = mix(color_from.rgb, color_to.rgb, blend_factor);
    
    vec3 emission_color = mix(emission_from.rgb, emission_to.rgb, emission_blend);
    float multiplier = mix(emission_multiplier_from, emission_multiplier_to, emission_multiplier_blend);

    EMISSION = emission_color * multiplier;
}
