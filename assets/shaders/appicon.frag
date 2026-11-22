#version 440

// App icon recolored to follow the theme (components/AppIcon.qml).
// mode 1 = tinted: duotone from a dark to a light shade of `tint`, mixed
//          with the original by `amount`.
// mode 2 = mono: a silhouette in `tint` (the ink); lighter parts of the
//          icon are fainter so its inner shapes stay readable.
// Badges drawn inside an icon can't be told apart from a red icon here:
// they follow the recolor like the rest.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 tint;
    float mode;
    float amount;
    float threshold;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    vec4 c = texture(source, qt_TexCoord0);
    if (c.a <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }
    vec3 rgb = c.rgb / c.a;
    float lum = dot(rgb, vec3(0.2126, 0.7152, 0.0722));

    vec3 outRgb;
    float outA = c.a;
    if (mode < 1.5) {
        vec3 dark = tint.rgb * 0.3;
        vec3 light = mix(tint.rgb, vec3(1.0), 0.45);
        outRgb = mix(rgb, mix(dark, light, lum), amount);
    } else {
        outRgb = tint.rgb;
        outA = c.a * mix(1.0, 0.45, smoothstep(threshold, threshold + 0.25, lum));
    }
    fragColor = vec4(outRgb * outA, outA) * qt_Opacity;
}
