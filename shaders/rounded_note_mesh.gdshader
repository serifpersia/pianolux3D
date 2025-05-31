shader_type spatial;

uniform int target_vertex_count;
uniform int target_vertex_indices[128];
uniform float z_offset = 0.0;
uniform vec4 white_key_color : source_color = vec4(1.65, 0.0, 0.0, 1.0);
uniform vec4 black_key_color : source_color = vec4(1.4, 0.0, 0.0, 1.0);
uniform bool is_black_key = false;

uniform vec3 parent_scale = vec3(1.0, 1.0, 1.0);

void vertex() {
    for (int i = 0; i < target_vertex_count; i++) {
        if (VERTEX_ID == target_vertex_indices[i]) {
            VERTEX.z += z_offset / parent_scale.z;
            break;
        }
    }
}

void fragment() {
    vec4 selected_color = is_black_key ? black_key_color : white_key_color;
    ALBEDO = selected_color.rgb;
    ALPHA = selected_color.a;
    EMISSION = selected_color.rgb * 2.0;
}
