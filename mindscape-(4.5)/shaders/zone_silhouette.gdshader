shader_type canvas_item;

// Silhouette shader for locked mindscape zones
// Creates a grayscale, faded appearance with subtle pulse animation

uniform float alpha_base : hint_range(0.0, 1.0) = 0.35;
uniform float pulse_intensity : hint_range(0.0, 0.3) = 0.08;
uniform float pulse_speed : hint_range(0.5, 3.0) = 1.2;
uniform vec4 tint_color : source_color = vec4(0.5, 0.5, 0.6, 1.0);
uniform bool is_locked = true;

void fragment() {
	vec4 tex_color = texture(TEXTURE, UV);

	if (is_locked) {
		// Convert to grayscale using luminance weights
		float gray = dot(tex_color.rgb, vec3(0.299, 0.587, 0.114));

		// Apply tint to grayscale
		vec3 tinted = vec3(gray) * tint_color.rgb;

		// Subtle pulse animation
		float pulse = sin(TIME * pulse_speed) * 0.5 + 0.5;
		float current_alpha = alpha_base + (pulse * pulse_intensity);

		// Output with reduced alpha
		COLOR = vec4(tinted, tex_color.a * current_alpha);
	} else {
		// Not locked - pass through original color
		COLOR = tex_color;
	}
}
