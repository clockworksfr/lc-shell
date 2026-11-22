#version 440

// App icon following the theme (components/AppIcon.qml).
// mode 0 = native colors, 1 = tinted (duotone from a dark to a light shade
// of `tint`, mixed with the original by `amount`), 2 = mono (a silhouette
// in `tint`, the ink; lighter parts fainter above `threshold` so inner
// shapes stay readable).
// Contrast guard (modes 0 and 1, `guard` > 0): when the icon's average
// color (smallest mipmap level) contrasts less than 1.6:1 with `bg`, its
// lightness is inverted, hue kept (a white icon on a light bar…).
// Badges drawn inside an icon can't be told apart from a red icon here:
// they follow the recolor like the rest.

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 tint;
    vec4 bg;
    float mode;
    float amount;
    float threshold;
    float guard;
};

layout(binding = 1) uniform sampler2D source;

float luma(vec3 c) {
    return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

float contrast(float a, float b) {
    return (max(a, b) + 0.05) / (min(a, b) + 0.05);
}

void main() {
    vec4 c = texture(source, qt_TexCoord0);
    if (c.a <= 0.0) {
        fragColor = vec4(0.0);
        return;
    }
    vec3 rgb = c.rgb / c.a;

    if (guard > 0.5 && mode < 1.5) {
        vec4 avg = textureLod(source, vec2(0.5), 16.0);
        float avgLum = avg.a > 0.0 ? luma(avg.rgb / avg.a) : 0.5;
        if (contrast(avgLum, luma(bg.rgb)) < 1.6)
            rgb = clamp(rgb + vec3(1.0 - 2.0 * luma(rgb)), 0.0, 1.0);
    }

    float lum = luma(rgb);
    vec3 outRgb = rgb;
    float outA = c.a;
    if (mode > 1.5) {
        outRgb = tint.rgb;
        outA = c.a * mix(1.0, 0.45, smoothstep(threshold, threshold + 0.25, lum));
    } else if (mode > 0.5) {
        vec3 dark = tint.rgb * 0.3;
        vec3 light = mix(tint.rgb, vec3(1.0), 0.45);
        outRgb = mix(rgb, mix(dark, light, lum), amount);
    }
    fragColor = vec4(outRgb * outA, outA) * qt_Opacity;
}
