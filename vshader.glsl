attribute vec2 aPos;
attribute vec3 eyePos;

void main() {
    gl_Position = vec4(aPos, 0.0, 1.0);
}