shader_type canvas_item;

uniform float outerRadius : hint_range(0.0, 5.0) = 1.0;
uniform float MainAlpha : hint_range(0.0, 1.0) = 1.0;
uniform float desaturation : hint_range(0.0, 1.0) = 0.5;
uniform float darkness : hint_range(0.0, 1.0) = 0.3;
uniform vec3 tint_color : source_color = vec3(0.4, 0.4, 0.5);

void fragment() {
	// Original radial effect
	float x = abs(UV.x-.5)*2.0;
	float y = abs(UV.y-.5)*2.0;
	float v = (sqrt((x*x)+(y*y))/outerRadius);
	
	// Get the original color from the scene
	vec4 original_color = texture(SCREEN_TEXTURE, SCREEN_UV);
	
	// Desaturate the color (make it greyer)
	float luminance = dot(original_color.rgb, vec3(0.299, 0.587, 0.114));
	vec3 desaturated = mix(original_color.rgb, vec3(luminance), desaturation);
	
	// Apply tint and darkness
	vec3 tinted = mix(desaturated, tint_color, 0.2);
	vec3 darkened = tinted * (1.0 - darkness);
	
	// Combine with radial overlay
	COLOR = vec4(darkened, 1.0) + vec4(0,0,0,v*MainAlpha);
}
