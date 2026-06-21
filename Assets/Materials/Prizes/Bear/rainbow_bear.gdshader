shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_lambert, specular_schlick_ggx;

group_uniforms Rainbow_Settings;
// How fast the rainbow cycles through colors.
uniform float speed = 1.0;
// How tightly packed the rainbow bands are across the mesh.
uniform float frequency = 0.5;
// The angle (in degrees) of the rainbow stripes (0 = vertical stripes, 90 = horizontal stripes).
uniform float angle : hint_range(0.0, 360.0) = 90.0;
// Controls the color intensity (0.0 = grayscale, 1.0 = fully vibrant).
uniform float saturation = 1.0;
// Controls overall brightness.
uniform float brightness = 1.0;

group_uniforms Material_Properties;
// Metallic feel of the surface (0.0 = plastic/fur, 1.0 = metal).
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
// How shiny or matte the surface is (0.0 = mirror, 1.0 = completely rough).
uniform float roughness : hint_range(0.0, 1.0) = 0.5;

// Helper function to convert HSV values into RGB colors smoothly
vec3 hsv2rgb(vec3 c) {
	vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
	vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
	return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

void fragment() {
	// 1. Convert the angle from degrees to radians for the math functions
	float angle_rad = radians(angle);
	
	// 2. Calculate a 2D rotation using sine and cosine to create a diagonal axis
	float projection = (VERTEX.x * cos(angle_rad)) + (VERTEX.y * sin(angle_rad));
	
	// 3. Calculate a unique hue value based on time and our new angled projection
	float hue = (TIME * speed) + (projection * frequency);
	
	// Keep the hue clamped between a clean 0.0 and 1.0 cycle
	hue = fract(hue);
	
	// 4. Convert our Hue, Saturation, and Brightness into an RGB color vector
	vec3 rainbow_color = hsv2rgb(vec3(hue, saturation, brightness));
	
	// 5. Pass our values to Godot's built-in PBR rendering outputs
	ALBEDO = rainbow_color;
	METALLIC = metallic;
	ROUGHNESS = roughness;
}