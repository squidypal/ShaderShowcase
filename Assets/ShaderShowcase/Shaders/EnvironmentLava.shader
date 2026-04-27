Shader "ShaderShowcase/EnvironmentLava"
{
    Properties
    {
        _CrustColor ("Crust Color", Color) = (0.04, 0.02, 0.01, 1.0)
        _WarmColor ("Warm Color", Color) = (1.20, 0.30, 0.04, 1.0)
        _HotColor  ("Hot Color",  Color) = (2.00, 1.40, 0.45, 1.0)
        _DeepColor ("Deep Color", Color) = (0.55, 0.10, 0.02, 1.0)
        _FlowSpeed ("Flow Speed", Float) = 0.07
        _NoiseScaleA ("Noise Scale A", Float) = 1.4
        _NoiseScaleB ("Noise Scale B", Float) = 4.2
        _CrustThreshold ("Crust Threshold", Range(0, 1)) = 0.46
        _CrustSharpness ("Crust Sharpness", Range(0.001, 0.5)) = 0.07
        _Emissive ("Emissive Strength", Range(0, 12)) = 4.0
        _BubbleAmplitude ("Bubble Amplitude", Float) = 0.05
        _BubbleSpeed ("Bubble Speed", Float) = 1.6
        _BubbleScale ("Bubble Scale", Float) = 7.0
        _CrackTint ("Crack Tint", Color) = (1.0, 0.55, 0.18, 1.0)
        _CrackPower ("Crack Power", Range(1, 16)) = 6.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" }
        LOD 200

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 positionWS  : TEXCOORD0;
                float3 normalWS    : TEXCOORD1;
                float2 uv          : TEXCOORD2;
            };

            CBUFFER_START(UnityPerMaterial)
                float4 _CrustColor;
                float4 _WarmColor;
                float4 _HotColor;
                float4 _DeepColor;
                float  _FlowSpeed;
                float  _NoiseScaleA;
                float  _NoiseScaleB;
                float  _CrustThreshold;
                float  _CrustSharpness;
                float  _Emissive;
                float  _BubbleAmplitude;
                float  _BubbleSpeed;
                float  _BubbleScale;
                float4 _CrackTint;
                float  _CrackPower;
            CBUFFER_END

            float Hash2(float2 p)
            {
                p = frac(p * float2(123.34, 456.21));
                p += dot(p, p + 45.32);
                return frac(p.x * p.y);
            }

            float ValueNoise2(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);
                float a = Hash2(i);
                float b = Hash2(i + float2(1, 0));
                float c = Hash2(i + float2(0, 1));
                float d = Hash2(i + float2(1, 1));
                return lerp(lerp(a, b, f.x), lerp(c, d, f.x), f.y);
            }

            float Fbm2(float2 p)
            {
                float v = 0;
                float a = 0.5;
                for (int i = 0; i < 5; i++)
                {
                    v += a * ValueNoise2(p);
                    p *= 2.07;
                    a *= 0.5;
                }
                return v;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                float t = _Time.y * _BubbleSpeed;
                float bubble = sin(IN.positionOS.x * _BubbleScale + t)
                             * cos(IN.positionOS.z * _BubbleScale * 0.8 + t * 0.7);
                float3 displaced = IN.positionOS.xyz + IN.normalOS * bubble * _BubbleAmplitude;

                VertexPositionInputs vpi = GetVertexPositionInputs(displaced);
                OUT.positionHCS = vpi.positionCS;
                OUT.positionWS  = vpi.positionWS;
                OUT.normalWS    = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv          = IN.uv;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float t = _Time.y * _FlowSpeed;
                float2 uv1 = IN.uv * _NoiseScaleA + float2(t, t * 0.32);
                float2 uv2 = IN.uv * _NoiseScaleB - float2(t * 0.74, t * 1.08);

                float n1 = Fbm2(uv1);
                float n2 = Fbm2(uv2);
                float h = saturate(n1 * 0.6 + n2 * 0.4);

                float crust = smoothstep(_CrustThreshold - _CrustSharpness,
                                         _CrustThreshold + _CrustSharpness, h);

                float3 deep  = lerp(_DeepColor.rgb, _WarmColor.rgb, smoothstep(0.20, 0.55, h));
                float3 hotMix = lerp(_WarmColor.rgb, _HotColor.rgb, smoothstep(0.55, 0.95, h));
                float3 col = lerp(deep, hotMix, crust);
                col = lerp(_CrustColor.rgb, col, crust);

                float emissive = (1.0 - crust) * pow(h, 2.0) * _Emissive;
                col += hotMix * emissive;

                float crack = pow(saturate(1.0 - abs(n1 - n2) * 6.0), _CrackPower) * (1.0 - crust);
                col += _CrackTint.rgb * crack * 4.0;

                Light light = GetMainLight();
                float3 N = normalize(IN.normalWS);
                float NdotL = saturate(dot(N, light.direction));
                float3 ambient = SampleSH(N);
                col += _CrustColor.rgb * crust * (NdotL * light.color * 0.4 + ambient * 0.6);

                return half4(col, 1);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
