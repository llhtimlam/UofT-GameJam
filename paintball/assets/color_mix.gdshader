shader_type canvas_item;

vec3 erf(vec3 x) //https://www.reddit.com/r/vulkan/comments/c4r7qx/comment/esnvdnf/
{
	vec3 y, xa = abs(x);

	y = xa*(xa*(xa * 0.0038004543f + 0.020338153f) + 0.03533611f) + 1.0000062f;

	// y = y^32
	y = y*y;
	y = y*y;
	y = y*y;
	y = y*y;
	y = y*y;

	y = 1. - 1./y;

	return sign(x)*y;
}

float erf(float x)
{
	float y, xa = abs(x);

	y = xa*(xa*(xa * 0.0038004543f + 0.020338153f) + 0.03533611f) + 1.0000062f;

	// y = y^32
	y = y*y;
	y = y*y;
	y = y*y;
	y = y*y;
	y = y*y;

	y = 1. - 1./y;

	return sign(x)*y;
}

vec3 coverage(float k,float k_s,vec3 top,vec3 bottom) {
    return erf((top - k)/k_s) - erf((bottom - k)/k_s);
}

float coverage(float k,float k_s,float top,float bottom) {
    return erf((top - k)/k_s) - erf((bottom - k)/k_s);
}

void fragment() {
	// Normalized pixel coordinates (from 0 to 1)
	vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;

    vec2 uv = FRAGCOORD.xy/iResolution;

    vec3 raw_col = (vec3(sin(TIME*11./30.),sin(TIME*13./30.),sin(TIME*17./30.))+1.)/2.;

    vec3 cur_col = pow(raw_col,vec3(2.2)); //vec3(1.)-vec3(0.335,0.708,0.408);


    vec3 bottom = vec3(0.,1./3.,2./3.);
    vec3 top = bottom + cur_col/3.;

	float k_s = 2.*smoothstep(1./3.,1.,uv.x) + .7/iResolution.x;

    vec3 total_color = coverage(uv.y,k_s,top,bottom);
    float area = coverage(uv.y, k_s, 1., 0.);
    vec3 col = total_color/area * mix(1.,3.,smoothstep(1./3.,1.,uv.x));

    col = mat3(pow(vec3(0.906,0.416,0.420),vec3(2.2)),pow(vec3(0.310,0.769,0.529),vec3(2.2)),pow(vec3(0.322,0.667,0.925),vec3(2.2))) * col;

    // Output to screen
    COLOR = vec4(uv,0.,1.);
}
