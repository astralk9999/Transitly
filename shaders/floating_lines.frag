#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform float uTime;
uniform vec2  uResolution;
uniform float uAnimationSpeed;
uniform float uEnableTop;
uniform float uEnableMiddle;
uniform float uEnableBottom;
uniform float uTopLineCount;
uniform float uMiddleLineCount;
uniform float uBottomLineCount;
uniform float uTopLineDistance;
uniform float uMiddleLineDistance;
uniform float uBottomLineDistance;
uniform vec3  uTopWavePos;
uniform vec3  uMiddleWavePos;
uniform vec3  uBottomWavePos;
uniform vec3  uColor1;
uniform vec3  uColor2;
uniform vec3  uColor3;

out vec4 fragColor;

mat2 rotate2(float r) {
    return mat2(cos(r), sin(r), -sin(r), cos(r));
}

vec3 getLineColor(float t) {
    if (t <= 0.5) {
        return mix(uColor1, uColor2, t * 2.0);
    } else {
        return mix(uColor2, uColor3, (t - 0.5) * 2.0);
    }
}

float waveFn(vec2 uv, float offset) {
    float time = uTime * uAnimationSpeed;
    float x_offset   = offset;
    float x_movement = time * 0.1;
    float amp        = sin(offset + time * 0.2) * 0.3;
    float y          = sin(uv.x + x_offset + x_movement) * amp;
    float m = uv.y - y;
    return 0.0175 / max(abs(m) + 0.01, 1e-3) + 0.01;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 baseUv = (2.0 * fragCoord - uResolution.xy) / uResolution.y;
    baseUv.y *= -1.0;

    vec3 col = vec3(0.0);

    if (uEnableBottom > 0.5) {
        int count = int(uBottomLineCount);
        for (int i = 0; i < 8; ++i) {
            if (i >= count) break;
            float fi = float(i);
            float t = fi / max(uBottomLineCount - 1.0, 1.0);
            vec3 lineCol = getLineColor(t);
            float angle = uBottomWavePos.z * log(length(baseUv) + 1.0);
            vec2 ruv = baseUv * rotate2(angle);
            col += lineCol * waveFn(
                ruv + vec2(uBottomLineDistance * fi + uBottomWavePos.x,
                           uBottomWavePos.y),
                1.5 + 0.2 * fi
            ) * 0.2;
        }
    }

    if (uEnableMiddle > 0.5) {
        int count = int(uMiddleLineCount);
        for (int i = 0; i < 8; ++i) {
            if (i >= count) break;
            float fi = float(i);
            float t = fi / max(uMiddleLineCount - 1.0, 1.0);
            vec3 lineCol = getLineColor(t);
            float angle = uMiddleWavePos.z * log(length(baseUv) + 1.0);
            vec2 ruv = baseUv * rotate2(angle);
            col += lineCol * waveFn(
                ruv + vec2(uMiddleLineDistance * fi + uMiddleWavePos.x,
                           uMiddleWavePos.y),
                2.0 + 0.15 * fi
            );
        }
    }

    if (uEnableTop > 0.5) {
        int count = int(uTopLineCount);
        for (int i = 0; i < 8; ++i) {
            if (i >= count) break;
            float fi = float(i);
            float t = fi / max(uTopLineCount - 1.0, 1.0);
            vec3 lineCol = getLineColor(t);
            float angle = uTopWavePos.z * log(length(baseUv) + 1.0);
            vec2 ruv = baseUv * rotate2(angle);
            ruv.x *= -1.0;
            col += lineCol * waveFn(
                ruv + vec2(uTopLineDistance * fi + uTopWavePos.x,
                           uTopWavePos.y),
                1.0 + 0.2 * fi
            ) * 0.1;
        }
    }

    // Alpha basado en intensidad: zonas sin línea son transparentes.
    // Multiplicador 0.6 mantiene las líneas visibles pero suficientemente
    // sutiles para no tapar el texto de la UI que va por encima.
    float lineAlpha = clamp(length(col) * 0.6, 0.0, 0.7);
    fragColor = vec4(col, lineAlpha);
}
