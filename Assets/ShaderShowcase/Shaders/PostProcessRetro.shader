Shader "ShaderShowcase/PostProcessRetro"
{
    Properties
    {
        _ChromaticAmount ("Chromatic Aberration", Range(0, 6)) = 1.6
        _ScanlineIntensity ("Scanline Intensity", Range(0, 1)) = 0.22
        _ScanlineCount ("Scanline Count", Float) = 220
        _VignetteIntensity ("Vignette Intensity", Range(0, 2)) = 0.55
        _VignetteSmoothness ("Vignette Smoothness", Range(0, 1)) = 0.62
        _Saturation ("Saturation", Range(0, 2)) = 1.18
        _Contrast ("Contrast", Range(0, 2)) = 1.06
        _Exposure ("Exposure", Range(0, 2)) = 1.05
        _NoiseAmount ("Noise Amount", Range(0, 0.5)) = 0.05
        _Curvature ("Screen Curvature", Range(0, 0.5)) = 0.045
        _BloomThreshold ("Bloom Threshold", Range(0, 2)) = 0.85
        _BloomIntensity ("Bloom Intensity", Range(0, 4)) = 0.9
        _ColorTint ("Color Tint", Color) = (1.0, 0.97, 1.05, 1.0)
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            Name "RetroPostProcess"

            HLSLPROGRAM
            #pragma vertex Vert
            #pragma fragment frag
            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.core/Runtime/Utilities/Blit.hlsl"

            float _ChromaticAmount;
            float _ScanlineIntensity;
            float _ScanlineCount;
            float _VignetteIntensity;
            float _VignetteSmoothness;
            float _Saturation;
            float _Contrast;
            float _Exposure;
            float _NoiseAmount;
            float _Curvature;
            float _BloomThreshold;
            float _BloomIntensity;
            float4 _ColorTint;

            float Hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            float2 BarrelDistort(float2 uv, float k)
            {
                float2 c = uv - 0.5;
                float r2 = dot(c, c);
                c *= 1.0 + k * r2 * 4.0;
                return c + 0.5;
            }

            float3 SampleBlit(float2 uv)
            {
                return SAMPLE_TEXTURE2D(_BlitTexture, sampler_LinearClamp, uv).rgb;
            }

            float3 BoxBlur(float2 uv, float radius)
            {
                float2 px = (1.0 / max(_BlitTextureSize, 1.0)) * radius;
                float3 c = 0;
                c += SampleBlit(uv + float2(-px.x, -px.y));
                c += SampleBlit(uv + float2( 0.0,  -px.y));
                c += SampleBlit(uv + float2( px.x, -px.y));
                c += SampleBlit(uv + float2(-px.x,  0.0));
                c += SampleBlit(uv);
                c += SampleBlit(uv + float2( px.x,  0.0));
                c += SampleBlit(uv + float2(-px.x,  px.y));
                c += SampleBlit(uv + float2( 0.0,   px.y));
                c += SampleBlit(uv + float2( px.x,  px.y));
                return c / 9.0;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 uv = IN.texcoord;
                float2 duv = BarrelDistort(uv, _Curvature);

                if (any(duv < 0.0) || any(duv > 1.0)) return half4(0, 0, 0, 1);

                float2 dir = duv - 0.5;
                float ca = _ChromaticAmount * 0.006;
                float r = SampleBlit(duv + dir * ca).r;
                float g = SampleBlit(duv).g;
                float b = SampleBlit(duv - dir * ca).b;
                float3 col = float3(r, g, b);

                float3 blurred = BoxBlur(duv, 3.0);
                float bright = max(0, max(blurred.r, max(blurred.g, blurred.b)) - _BloomThreshold);
                float3 bloom = blurred * bright * _BloomIntensity;
                col += bloom;

                col *= _ColorTint.rgb;

                float scan = sin(duv.y * _ScanlineCount * 3.14159) * 0.5 + 0.5;
                col *= lerp(1.0, scan, _ScanlineIntensity);

                float n = Hash21(duv * 1024.0 + frac(_Time.y * 60.0)) - 0.5;
                col += n * _NoiseAmount;

                col = (col - 0.5) * _Contrast + 0.5;
                float lum = dot(col, float3(0.299, 0.587, 0.114));
                col = lerp(float3(lum, lum, lum), col, _Saturation);
                col *= _Exposure;

                float vd = length(dir) * 1.45;
                float vig = smoothstep(_VignetteSmoothness,
                                       max(0.0, _VignetteSmoothness - _VignetteIntensity), vd);
                col *= vig;

                return half4(col, 1);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
