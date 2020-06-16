precision mediump float;
uniform float MIN_DIST;
uniform float MAX_DIST;
uniform vec2 iResolution;
uniform vec3 eye;
uniform float power;

uniform vec3 lookDir;

const int MAX_MARCHING_STEPS = 250;
const float EPSILON = 0.001;

vec2 mandelBulb(vec3 pos) {
    pos /= 20.0;
	vec3 z = pos;
	float dr = 1.0;
	float r = 0.0;
    int n = 0;
	for (int i = 0; i < 25; i++) {
        n++;
		r = length(z);
		if (r > 2.0) break;
		
		// convert to polar coordinates
		float theta = acos(z.z/r);
		float phi = atan(z.y,z.x);
		dr =  pow( r, power-1.0)*power*dr + 1.0;
		
		// scale and rotate the point
		float zr = pow( r,power);
		theta = theta*power;
		phi = phi*power;
		
		// convert back to cartesian coordinates
		z = zr*vec3(sin(theta)*cos(phi), sin(phi)*sin(theta), cos(theta));
		z += pos;
	}
	return vec2((0.5*log(r)*r/dr) * 20.0, n);
}

vec2 sceneSDF(vec3 point) {
    return mandelBulb(point);
}



vec3 shortestDistanceToSurface(vec3 eye, vec3 marchingDirection, float start, float end) {
    float depth = start;
    for (int i = 0; i < MAX_MARCHING_STEPS; i++) {
        vec2 dist = sceneSDF(eye + depth * marchingDirection);
        if (dist.x < EPSILON) {
			return vec3(1.0 - float(i)/float(MAX_MARCHING_STEPS), depth, dist.y); //depth
        }
        depth += dist.x;
        if (depth >= end) {
            return vec3(0.0, end, 0.0); //end
        }
    }
    return vec3(0.0, end, 0.0); //end
}

vec3 rayDirection(float fieldOfView, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.0;
    float z = size.x / tan(radians(fieldOfView) / 2.0);
    return normalize(vec3(xy, -z));
}

vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        sceneSDF(vec3(p.x + EPSILON, p.y, p.z)).x - sceneSDF(vec3(p.x - EPSILON, p.y, p.z)).x,
        sceneSDF(vec3(p.x, p.y + EPSILON, p.z)).x - sceneSDF(vec3(p.x, p.y - EPSILON, p.z)).x,
        sceneSDF(vec3(p.x, p.y, p.z  + EPSILON)).x - sceneSDF(vec3(p.x, p.y, p.z - EPSILON)).x
    ));
}


vec3 phongContribForLight(vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye,
                          vec3 lightPos, vec3 lightIntensity) {
    vec3 N = estimateNormal(p);
    vec3 L = normalize(lightPos - p);
    vec3 V = normalize(eye - p);
    vec3 R = normalize(reflect(-L, N));
    
    float dotLN = dot(L, N);
    float dotRV = dot(R, V);
    
    if (dotLN < 0.0) {
        // Light not visible from this point on the surface
        return vec3(0.0, 0.0, 0.0);
    } 
    
    if (dotRV < 0.0) {
        // Light reflection in opposite direction as viewer, apply only diffuse
        // component
        return lightIntensity * (k_d * dotLN);
    }
    return lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
}

vec3 phongIllumination(vec3 k_a, vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye) {
    const vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0);
    vec3 color = ambientLight * k_a;
    
    vec3 light1Pos = vec3(24.0 ,
                          24.0,
                          24.0);
    vec3 light1Intensity = vec3(1.0, 0.8, 0.8);
    
    color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light1Pos,
                                  light1Intensity);
    
    vec3 light2Pos = vec3(-24.0,
                          24.0,
                          -24.0);
    vec3 light2Intensity = vec3(1.0, 0.6, 0.6);
    
    color += phongContribForLight(k_d, k_s, alpha, p, eye,
                                  light2Pos,
                                  light2Intensity);    
    return color;
}


mat4 viewMatrix(vec3 up) {
    // Based on gluLookAt man page
    vec3 f = lookDir;
    vec3 s = normalize(cross(f, up));
    vec3 u = cross(s, f);
    return mat4(
        vec4(s, 0.0),
        vec4(u, 0.0),
        vec4(-f, 0.0),
        vec4(0.0, 0.0, 0.0, 1)
    );
}

float hue2rgb(float f1, float f2, float hue) {
    if (hue < 0.0)
        hue += 1.0;
    else if (hue > 1.0)
        hue -= 1.0;
    float res;
    if ((6.0 * hue) < 1.0)
        res = f1 + (f2 - f1) * 6.0 * hue;
    else if ((2.0 * hue) < 1.0)
        res = f2;
    else if ((3.0 * hue) < 2.0)
        res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
    else
        res = f1;
    return res;
}

vec3 hsl2rgb(vec3 hsl) {
    vec3 rgb;
    
    if (hsl.y == 0.0) {
        rgb = vec3(hsl.z); // Luminance
    } else {
        float f2;
        
        if (hsl.z < 0.5)
            f2 = hsl.z * (1.0 + hsl.y);
        else
            f2 = hsl.z + hsl.y - hsl.y * hsl.z;
            
        float f1 = 2.0 * hsl.z - f2;
        
        rgb.r = hue2rgb(f1, f2, hsl.x + (1.0/3.0));
        rgb.g = hue2rgb(f1, f2, hsl.x);
        rgb.b = hue2rgb(f1, f2, hsl.x - (1.0/3.0));
    }   
    return rgb;
}

void main()
{
	vec3 viewDir = rayDirection(100.0, iResolution.xy, gl_FragCoord.xy);
    // vec3 eye = vec3(16.0 , -5.0, 7.0);
     
    mat4 viewToWorld = viewMatrix(vec3(0.0, 1.0, 0.0));
    
    vec3 worldDir = (viewToWorld * vec4(viewDir, 0.0)).xyz;
    
    vec3 distanceInfo = shortestDistanceToSurface(eye, worldDir, MIN_DIST, MAX_DIST);
        
    if (distanceInfo.y > MAX_DIST - (EPSILON)) {
        // Didn't hit anything
        gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
	    return;
    }
    
    // The closest point on the surface to the eyepoint along the view ray
    // vec3 p = eye + distanceInfo.y * worldDir;
    
    // vec3 K_a = vec3(0.3, 0.3, 0.3);
    // vec3 K_d = vec3(0.5, 0.2, 0.2);
    // vec3 K_s = vec3(0.0, 0.0, 0.0);
    // float shininess = 10.0;
    
    // vec3 color = phongIllumination(K_a, K_d, K_s, shininess, p, eye);
    
    // gl_FragColor = vec4(color * distanceInfo.x, 1.0);

    vec3 color = hsl2rgb(vec3(distanceInfo.z/15.0 , 1.0, 0.9));
    gl_FragColor = vec4(color * distanceInfo.x,1.0);
}