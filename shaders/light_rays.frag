#version 460 core
#include <flutter/runtime_effect.glsl>

precision mediump float;

uniform float uTime;
uniform vec2  uResolution;
uniform vec2  uRayPos;
uniform vec2  uRayDir;
uniform vec3  uRaysColor;
uniform float uRaysSpeed;
uniform float uLightSpread;
uniform float uRayLength;
uniform float uPulsating;
uniform float uFadeDistance;
uniform float uSaturation;
uniform float uNoiseAmount;
uniform float uDistortion;

out vec4 fragColor;

float noise(vec2 st) {
    return fract(sin(dot(st.xy, vec2(12.9898, 78.233))) * 43758.5453123);
}

float rayStrength(vec2 raySource, vec2 rayRefDirection, vec2 coord,
                  float seedA, float seedB, float speed) {
    vec2 sourceToCoord = coord - raySource;
    vec2 dirNorm = normalize(sourceToCoord);
    float cosAngle = dot(dirNorm, rayRefDirection);

    float distortedAngle = cosAngle
        + uDistortion * sin(uTime * 2.0 + length(sourceToCoord) * 0.01) * 0.2;

    float spreadFactor = pow(max(distortedAngle, 0.0), 1.0 / max(uLightSpread, 0.001));

    float distance = length(sourceToCoord);
    float maxDistance = uResolution.x * uRayLength;
    float lengthFalloff = clamp((maxDistance - distance) / maxDistance, 0.0, 1.0);

    float fadeFalloff = clamp(
        (uResolution.x * uFadeDistance - distance) / (uResolution.x * uFadeDistance),
        0.5, 1.0
    );
    float pulse = uPulsating > 0.5 ? (0.8 + 0.2 * sin(uTime * speed * 3.0)) : 1.0;

    float baseStrength = clamp(
        (0.45 + 0.15 * sin(distortedAngle * seedA + uTime * speed)) +
        (0.3 + 0.2 * cos(-distortedAngle * seedB + uTime * speed)),
        0.0, 1.0
    );

    return baseStrength * lengthFalloff * fadeFalloff * spreadFactor * pulse;
}

void main() {
    vec2 fragCoord = FlutterFragCoord().xy;
    vec2 coord = vec2(fragCoord.x, uResolution.y - fragCoord.y);

    vec4 rays1 = vec4(1.0) *
        rayStrength(uRayPos, uRayDir, coord, 36.2214, 21.11349, 1.5 * uRaysSpeed);
    vec4 rays2 = vec4(1.0) *
        rayStrength(uRayPos, uRayDir, coord, 22.3991, 18.0234, 1.1 * uRaysSpeed);

    vec4 col = rays1 * 0.5 + rays2 * 0.4;

    if (uNoiseAmount > 0.0) {
        float n = noise(coord * 0.01 + uTime * 0.1);
        col.rgb *= (1.0 - uNoiseAmount + uNoiseAmount * n);
    }

    float brightness = 1.0 - (coord.y / uResolution.y);
    col.x *= 0.1 + brightness * 0.8;
    col.y *= 0.3 + brightness * 0.6;
    col.z *= 0.5 + brightness * 0.5;

    if (uSaturation != 1.0) {
        float gray = dot(col.rgb, vec3(0.299, 0.587, 0.114));
        col.rgb = mix(vec3(gray), col.rgb, uSaturation);
    }

    col.rgb *= uRaysColor;
    fragColor = col;
}
