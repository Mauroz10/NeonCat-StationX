shader_type canvas_item;

// El arte original tiene fondo verde JPEG. Quitamos el color al dibujarlo;
// el archivo fuente permanece intacto para poder sustituirlo por PNG después.
void fragment() {
	vec3 pixel_color = texture(TEXTURE, UV).rgb;
	vec3 background = vec3(0.02, 0.66, 0.15);
	float distance_to_green = distance(pixel_color, background);
	COLOR.a *= smoothstep(0.08, 0.21, distance_to_green);
}
