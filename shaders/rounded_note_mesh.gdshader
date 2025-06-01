shader_type spatial;

uniform int target_vertex_count;
uniform int target_vertex_indices[128];
uniform float z_offset = 0.0;
uniform vec4 surface_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec3 parent_scale = vec3(1.0);

void vertex() {
    for (int i = 0; i < target_vertex_count; i++) {
        if (VERTEX_ID == target_vertex_indices[i]) {
            VERTEX.z += z_offset;
            break;
        }
    }
}

void fragment() {
    ALBEDO = surface_color.rgb;
	ALPHA = surface_color.a;
    EMISSION = surface_color.rgb * 2.0;
}