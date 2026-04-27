Shader "ShaderShowcase/StarSky"
{
    Properties
    {
        _SkyTop ("Sky Top", Color) = (0.02, 0.02, 0.10, 1.0)
        _SkyBottom ("Sky Bottom", Color) = (0.20, 0.05, 0.40, 1.0)
        _NebulaColorA ("Nebula A", Color) = (0.55, 0.10, 0.95, 1.0)
        _NebulaColorB ("Nebula B", Color) = (0.10, 0.45, 1.00, 1.0)
        _NebulaIntensity ("Nebula Intensity", Range(0, 4)) = 1.4
        _StarDensity ("Star Density", Range(20, 600)) = 240
        _StarBrightness ("Star Brightness", Range(0, 6)) = 2.5
        _TwinkleSpeed ("Twinkle Speed", Float) = 1.4
        _Drift ("Drift Speed", Float) = 0.015
    }
    SubShader
    {
        Tags { "RenderType"="Background" "RenderPipeline"="UniversalPipeline" "Queue"="Background" }
        LOD 100

        Pass
        {
            Name "SkyDome"
            Tags { "LightMode"="UniversalForward" }
            Cull Front
            ZWrite Off

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 directionOS : TEXCOORD0;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _SkyTop;
                float4 _SkyBottom;
                float4 _NebulaColorA;
                float4 _NebulaColorB;
                float  _NebulaIntensity;
                float  _StarDensity;
                float  _StarBrightness;
                float  _TwinkleSpeed;
                float  _Drift;
            CBUFFER_END

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.directionOS = normalize(IN.positionOS.xyz);
                return OUT;
            }

            float Hash21(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            float Hash22(float2 p)
            {
                p = float2(dot(p, float2(127.1, 311.7)), dot(p, float2(269.5, 183.3)));
                return frac(sin(dot(p, float2(45.32, 78.233))) * 43758.5453);
            }

            float ValueNoise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);
                float a = Hash21(i);
                float b = Hash21(i + float2(1, 0));
                float c = Hash21(i + float2(0, 1));
                float d = Hash21(i + float2(1, 1));
                return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
            }

            float Fbm(float2 p)
            {
                float v = 0;
                float a = 0.5;
                for (int i = 0; i < 6; i++)
                {
                    v += a * ValueNoise(p);
                    p *= 2.05;
                    a *= 0.5;
                }
                return v;
            }

            float StarLayer(float2 uv, float density, float speed, float seed)
            {
                float2 cell = uv * density;
                float2 i = floor(cell);
                float2 f = frac(cell);
                float r = Hash21(i + seed);
                float thresh = step(0.985, r);
                float2 starPos = f - 0.5;
                float d = length(starPos);
                float twinkle = 0.5 + 0.5 * sin(_Time.y * _TwinkleSpeed + r * 30.0);
                float star = thresh * smoothstep(0.18, 0.0, d) * twinkle;
                return star;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float3 dir = normalize(IN.directionOS);
                float vGrad = saturate(dir.y * 0.5 + 0.5);
                float3 sky = lerp(_SkyBottom.rgb, _SkyTop.rgb, pow(vGrad, 1.4));

                float2 uv = float2(atan2(dir.z, dir.x) / 6.2831, asin(dir.y) / 1.5708 * 0.5 + 0.5);
                uv.x += _Time.y * _Drift;

                float n1 = Fbm(uv * 6.0);
                float n2 = Fbm(uv * 12.0 + 7.0);
                float nebula = saturate(n1 * n2 * 2.4);
                float3 nebulaCol = lerp(_NebulaColorA.rgb, _NebulaColorB.rgb, n2);
                sky += nebulaCol * nebula * _NebulaIntensity;

                float stars = 0;
                stars += StarLayer(uv, _StarDensity * 0.7, 0.0, 0.0) * 1.0;
                stars += StarLayer(uv, _StarDensity, 0.0, 11.0) * 0.7;
                stars += StarLayer(uv, _StarDensity * 1.6, 0.0, 27.0) * 0.5;

                sky += stars * _StarBrightness;

                return half4(sky, 1);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
