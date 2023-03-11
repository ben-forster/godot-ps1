// This is a custom shader for Godot 4.x
// It uses vertex lighting and skips the vertex transform
// It also uses specular Schlick GGX and diffuse Lambert wrapping

shader_type spatial;
render_mode vertex_lighting, skip_vertex_transform, 
			specular_schlick_ggx, diffuse_lambert_wrap;
 
// Define texture inputs
uniform sampler2D albedo_texture: hint_default_black;
uniform sampler2D specular_texture: hint_default_black;
uniform sampler2D emission_texture: hint_default_black;

// Define uniform inputs
// Amount to jitter vertices (0 = no jitter, 1 = maximum jitter)
uniform float vertex_jitter_amount: hint_range(0.0, 1.0) = 0.5;

// Whether or not to jitter the z coordinate
uniform bool jitter_z_coordinate = true;

// Whether or not to jitter vertices based on depth
uniform bool jitter_depth_independent = true;

// Whether or not to use affine texture mapping
uniform bool affine_texture_mapping = true;

// Alpha scissor threshold (0 = fully transparent, 1 = fully opaque)
uniform float alpha_scissor_threshold: hint_range(0.0, 1.0) = 1.0;

// UV_scale is used for scaling the UV coordinates of the texture
uniform vec2 uv_scale: hint_range(0.0, 10.0) = vec2(1.0, 1.0);
 
// Vertex function
void vertex() {
	// Transform normal vector
    NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);

	// Transform vertex position
	VERTEX = (MODELVIEW_MATRIX * vec4(VERTEX, 1.0)).xyz;
 
	// Save original z coordiante
	float z_orig = VERTEX.z;

	// Calculate amount to jitter vertices
	float jitter_amount = (1.0 - vertex_jitter_amount) * min(VIEWPORT_SIZE.x, VIEWPORT_SIZE.y) / 2.0;
 
	// Jitter vertices based on depth
	if (jitter_depth_independent) {
		float w = (PROJECTION_MATRIX * vec4(VERTEX, 1.0)).w;
		VERTEX = round(VERTEX / w * jitter_amount) / jitter_amount * w;
	} else {
		VERTEX = round(VERTEX * jitter_amount) / jitter_amount;
	}
 
     // Revert z coordinate if not using z jittering
	if (!jitter_z_coordinate) {
		VERTEX.z = z_orig;
	}
 
	// Apply affine texture mapping
	if (affine_texture_mapping) {
		UV *= VERTEX.z;
	}
}
 
// Fragment function
void fragment() {
	// Calculate UV coordinates
	vec2 uv = UV * uv_scale;
 
	// Revert affine texture mapping
	if (affine_texture_mapping) {
		uv /= VERTEX.z;
	}
 
	// Apply textures
	ALBEDO = texture(albedo_texture, uv).rgb;
	ALPHA = texture(albedo_texture, uv).a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
	EMISSION = texture(emission_texture, uv).rgb;
	SPECULAR = texture(specular_texture, uv).r;
}
