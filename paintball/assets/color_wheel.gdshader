shader_type canvas_item;

uniform vec3 c1 = vec3(1,0,0);
uniform vec3 c2 = vec3(0,1,0);
uniform vec3 c3 = vec3(0,0,1);

uniform float p1 = 1;
uniform float p2 = 1;
uniform float p3 = 1;

const float dot_size = .02;

void fragment() {
    float resolution = .2 / SCREEN_PIXEL_SIZE.y; //approximate vertical resolution for aa
    vec2 uv = vec2(UV.x, 1.-UV.y);

    // corner weights
    vec3 w = vec3(uv.y,1.-uv.x-.5*uv.y,uv.x-.5*uv.y);

    // apply colors
    vec3 col = mat3(c1, c2, c3) * (w * vec3(p1,p2,p3));

    // draw dot
    vec2 uvs = uv * vec2(1,0.866025); // square UV
    vec2 dp = (p1 * vec2(0.5, 0.866025) + p3 * vec2(1,0) + vec2(.5, 0.288675)*1e-10)/(p1+p2+p3+1e-10); // dot position
    float dot_mix = clamp((dot_size - length(uvs - dp)) * resolution, 0., 1.);
    col = mix(col, vec3(1,1,1), dot_mix);

    // Output to screen
    COLOR = vec4(col,clamp(min(w.y, w.z) * resolution,0.,1.));
}
