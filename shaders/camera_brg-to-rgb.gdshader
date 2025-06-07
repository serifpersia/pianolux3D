shader_type canvas_item;

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV); // Sample the texture
    vec3 color;
    color.r = tex_color.b; // Red channel = texture's blue channel
    color.g = tex_color.g; // Green channel = texture's green channel
    color.b = tex_color.r; // Blue channel = texture's red channel
    COLOR = vec4(color, tex_color.a); // Preserve original alpha
}