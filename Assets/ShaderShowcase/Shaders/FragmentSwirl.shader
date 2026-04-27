Shader "ShaderShowcase/FragmentSwirl"
{
    Properties
    {
        _ColorA ("Color A", Color) = (0.95, 0.25, 0.85, 1.0)
        _ColorB ("Color B", Color) = (0.10, 0.55, 1.00, 1.0)
        _ColorC ("Color C", Color) = (1.00, 0.92, 0.35, 1.0)
        _ColorD ("Color D", Color) = (0.05, 0.02, 0.10, 1.0)
        _SwirlSpeed ("Swirl Speed", Float) = 0.35
        _PatternScale ("Pattern Scale", Float) = 5.0
        _SwirlStrength ("Swirl Strength", Float) = 3.0
        _ArmCount ("Arm Count", Float) = 5.0
        _Iterations ("Fractal Iterations", Range(1,8)) = 5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        LOD 200

        Pass
        {
            Name "Forward"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _ColorA;
                float4 _ColorB;
                float4 _ColorC;
                float4 _ColorD;
                float  _SwirlSpeed;
                float  _PatternScale;
                float  _SwirlStrength;
                float  _ArmCount;
                float  _Iterations;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv = IN.uv;
                return OUT;
            }

            float Hash(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            float ValueNoise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);
                float a = Hash(i);
                float b = Hash(i + float2(1, 0));
                float c = Hash(i + float2(0, 1));
                float d = Hash(i + float2(1, 1));
                return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
            }

            float Fbm(float2 p)
            {
                float v = 0;
                float amp = 0.5;
                int it = (int)_Iterations;
                for (int i = 0; i < it; i++)
                {
                    v += amp * ValueNoise(p);
                    p *= 2.07;
                    amp *= 0.5;
                }
                return v;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float2 uv = IN.uv * 2.0 - 1.0;
                float t = _Time.y * _SwirlSpeed;

                float r = length(uv);
                float baseAngle = atan2(uv.y, uv.x);
                float spiral = baseAngle + r * _SwirlStrength - t * 1.7;

                float arms = 0.5 + 0.5 * cos(spiral * _ArmCount);

                float2 q = float2(cos(spiral), sin(spiral)) * r * _PatternScale;
                float n1 = Fbm(q + t);
                float n2 = Fbm(q * 1.7 - t * 0.8 + 11.0);

                float3 col = lerp(_ColorD.rgb, _ColorB.rgb, smoothstep(0.10, 0.65, n1));
                col = lerp(col, _ColorA.rgb, smoothstep(0.40, 0.85, arms * n1));
                col = lerp(col, _ColorC.rgb, smoothstep(0.65, 0.95, n2 * arms));

                float core = exp(-r * r * 5.0);
                col += _ColorC.rgb * core * 0.8;

                float vignette = saturate(1.0 - smoothstep(0.85, 1.05, r));
                col *= vignette;

                return half4(col, 1);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
