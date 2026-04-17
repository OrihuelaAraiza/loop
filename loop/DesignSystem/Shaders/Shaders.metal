#include <metal_stdlib>
#include <SwiftUI/SwiftUI.h>
using namespace metal;

// MARK: - Shimmer (nodos bloqueados)
[[stitchable]] half4 shimmer(
    float2 position,
    half4 color,
    float2 size,
    float time
) {
    float diag = (position.x + position.y) / (size.x + size.y);
    float shimmerPos = fmod(time * 0.4, 1.4) - 0.2;
    float width = 0.12;
    float dist = abs(diag - shimmerPos);
    float shimmerAmount = smoothstep(width, 0.0, dist);
    half4 shimmerColor = half4(1.0, 1.0, 1.0, 0.25);
    return mix(color, shimmerColor, shimmerAmount * color.a);
}

// MARK: - Noise Grain (textura sutil de fondo)
[[stitchable]] half4 noiseGrain(
    float2 position,
    half4 color,
    float time,
    float intensity
) {
    float2 uv = position / 400.0;
    float noise = fract(sin(dot(uv + time * 0.05,
        float2(127.1, 311.7))) * 43758.5453);
    return color + half4(noise * intensity,
                         noise * intensity,
                         noise * intensity, 0.0);
}

// MARK: - Ripple (transicion al entrar a ejercicio)
[[stitchable]] half4 ripple(
    float2 position,
    SwiftUI::Layer layer,
    float2 origin,
    float time,
    float amplitude,
    float frequency,
    float decay,
    float speed
) {
    float2 delta = position - origin;
    float dist = length(delta);
    float delay = dist / speed;
    float elapsed = time - delay;
    float2 direction = normalize(delta);
    float2 offset = elapsed < 0 ? float2(0, 0) :
        amplitude * exp(-decay * elapsed) *
        sin(frequency * elapsed) * direction;
    return layer.sample(position - offset);
}
