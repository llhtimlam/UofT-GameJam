shader_type canvas_item;

const vec2 CIE_RED = vec2(0.6400, 0.3300);
const vec2 CIE_GREEN = vec2(0.3000, 0.6000);
const vec2 CIE_BLUE = vec2(0.1500, 0.0600);

uniform vec3 custom_color_middle = vec3(1.0, 0.0, 0.0);
uniform vec3 custom_color_left = vec3(0.0, 1.0, 0.0);
uniform vec3 custom_color_right = vec3(0.0, 0.0, 1.0);

uniform float fill_percentage : hint_range(0.0, 1.0) = 0.0;

void fragment() {
    // 1. Equilateral coordinates (60 degrees, equal sides)
    vec2 eq_green = vec2(0.5, 0.15);
    vec2 eq_blue  = vec2(0.15, 0.75);
    vec2 eq_red   = vec2(0.85, 0.75);
    
    // 2. Geometric Equilateral Boundary Check
    float det = (eq_blue.y - eq_red.y) * (eq_green.x - eq_red.x) + (eq_red.x - eq_blue.x) * (eq_green.y - eq_red.y);
    float w_g = ((eq_blue.y - eq_red.y) * (UV.x - eq_red.x) + (eq_red.x - eq_blue.x) * (UV.y - eq_red.y)) / det;
    float w_b = ((eq_red.y - eq_green.y) * (UV.x - eq_red.x) + (eq_green.x - eq_red.x) * (UV.y - eq_red.y)) / det;
    float w_r = 1.0 - w_g - w_b;
    
    if (w_r < 0.0 || w_g < 0.0 || w_b < 0.0) {
        discard;
    }
    
    // 3. Remap space back to the CIE data profile
    vec2 current_xy = w_r * CIE_RED + w_g * CIE_GREEN + w_b * CIE_BLUE;
    
    // 4. Calculate variable luminance tracking
    float Y = (w_r * 0.2126) + (w_g * 0.7152) + (w_b * 0.0722);
    
    float x = current_xy.x;
    float y = current_xy.y;
    float z = 1.0 - x - y;
    
    float X = (x / y) * Y;
    float Z = (z / y) * Y;
    
    float r_lin =  3.2404542 * X - 1.5371385 * Y - 0.4985314 * Z;
    float g_lin = -0.9692660 * X + 1.8760108 * Y + 0.0415560 * Z;
    float b_lin =  0.0556434 * X - 0.2040259 * Y + 1.0572252 * Z;
    
    vec3 chromaticity_rgb = vec3(r_lin, g_lin, b_lin);
    
    // 5. Multiply your custom color vectors directly onto the weights
    vec3 linear_rgb = vec3(0.0);
    linear_rgb += clamp(chromaticity_rgb.r, 0.0, 1.0) * w_r * custom_color_right;	// Red
    linear_rgb += clamp(chromaticity_rgb.g, 0.0, 1.0) * w_g * custom_color_middle;	// Green
    linear_rgb += clamp(chromaticity_rgb.b, 0.0, 1.0) * w_b * custom_color_left;	// Blue
    
    // 6. Track the target intensity of the mixed custom color 
    vec3 local_target_color = w_r * custom_color_right + w_g * custom_color_middle + w_b * custom_color_left;
    float target_intensity = max(local_target_color.r, max(local_target_color.g, local_target_color.b));
    
    // 7. Apply the normalization boost
    float max_component = max(linear_rgb.r, max(linear_rgb.g, linear_rgb.b));
    if (max_component > 0.0) {
        linear_rgb /= max_component;
    }
    
    // 8. Scale the normalized mix back down by the intended target intensity.
    linear_rgb *= clamp(target_intensity, 0.0, 1.0);
    
    // 9. Shift smoothly toward white point based on slider inputs
    vec3 target_white = vec3(1.0, 1.0, 1.0);
    linear_rgb = mix(linear_rgb, target_white, fill_percentage);
    
    // Extract the maximum overall value/strength of each custom input color vector
    float intensity_r = max(custom_color_right.r, max(custom_color_right.g, custom_color_right.b));		// Red
    float intensity_g = max(custom_color_middle.r, max(custom_color_middle.g, custom_color_middle.b));	// Green
    float intensity_b = max(custom_color_left.r, max(custom_color_left.g, custom_color_left.b));		// Blue
    
    // Fallback safe defaults if all colors are turned completely to 0
    float total_intensity = intensity_r + intensity_g + intensity_b;
    float target_w_r = 0.3333;
    float target_w_g = 0.3333;
    float target_w_b = 0.3333;
    
    if (total_intensity > 0.001) {
        // Calculate barycentric targets proportionally based on active color weights
        target_w_r = intensity_r / total_intensity;
        target_w_g = intensity_g / total_intensity;
        target_w_b = intensity_b / total_intensity;
    }
    
    // Map the calculated color center back into the physical 2D screen UV space
    vec2 dynamic_center = target_w_r * eq_red + target_w_g * eq_green + target_w_b * eq_blue;
    
    // Render the dynamic center indicator dot
    float dist_to_center = distance(UV, dynamic_center);
    if (dist_to_center < 0.015) {
        // Overlay a sharp white center indicator dot smoothly over the calculated layout position
        linear_rgb = mix(linear_rgb, vec3(1.0, 1.0, 1.0), smoothstep(0.015, 0.01, dist_to_center));
    }
    
    // 10. Gamma Correction and Final Render Output
    COLOR = vec4(pow(clamp(linear_rgb, 0.0, 1.0), vec3(1.0 / 2.2)), 1.0);
}