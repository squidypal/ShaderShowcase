Shader "ShaderShowcase/ItemDissolve"
{
    Properties
    {
        _BaseColor ("Base Color", Color) = (0.85, 0.85, 0.95, 1.0)
        _BaseMap ("Base Map", 2D) = "white" {}
        _RimColor ("Rim Color", Color) = (0.45, 0.95, 1.0, 1.0)
        _RimPower ("Rim Power", Range(0.1, 12)) = 3.0
        _RimIntensity ("Rim Intensity", Range(0, 6)) = 2.0
        _DissolveAmount ("Dissolve Amount", Range(0, 1)) = 0.0
        _DissolveEdgeWidth ("Edge Width", Range(0.0, 0.4)) = 0.06
        _DissolveEdgeColor ("Edge Color", Color) = (1.0, 0.55, 0.15, 1.0)
        _DissolveScale ("Dissolve Scale", Float) = 5.5
        _PulseSpeed ("Pulse Speed", Float) = 2.5
        _PulseStrength ("Pulse Strength", Range(0, 1)) = 0.35
        _HighlightColor ("Highlight Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _HighlightStrength ("Highlight Strength", Range(0, 4)) = 0.6
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "RenderPipeline"="UniversalPipeline" "Queue"="AlphaTest" }
        LOD 200

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }
            Cull Off

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
                float3 positionOS  : TEXCOORD3;
            };

            TEXTURE2D(_BaseMap); SAMPLER(sampler_BaseMap);

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float4 _RimColor;
                float  _RimPower;
                float  _RimIntensity;
                float  _DissolveAmount;
                float  _DissolveEdgeWidth;
                float4 _DissolveEdgeColor;
                float  _DissolveScale;
                float  _PulseSpeed;
                float  _PulseStrength;
                float4 _HighlightColor;
                float  _HighlightStrength;
            CBUFFER_END

            float Hash3(float3 p)
            {
                p = frac(p * float3(123.34, 234.56, 345.67));
                p += dot(p, p.yzx + 45.32);
                return frac(p.x * p.y + p.z);
            }

            float Noise3(float3 p)
            {
                float3 i = floor(p);
                float3 f = frac(p);
                f = f * f * (3.0 - 2.0 * f);
                float n000 = Hash3(i);
                float n100 = Hash3(i + float3(1, 0, 0));
                float n010 = Hash3(i + float3(0, 1, 0));
                float n110 = Hash3(i + float3(1, 1, 0));
                float n001 = Hash3(i + float3(0, 0, 1));
                float n101 = Hash3(i + float3(1, 0, 1));
                float n011 = Hash3(i + float3(0, 1, 1));
                float n111 = Hash3(i + float3(1, 1, 1));
                float nx00 = lerp(n000, n100, f.x);
                float nx10 = lerp(n010, n110, f.x);
                float nx01 = lerp(n001, n101, f.x);
                float nx11 = lerp(n011, n111, f.x);
                float nxy0 = lerp(nx00, nx10, f.y);
                float nxy1 = lerp(nx01, nx11, f.y);
                return lerp(nxy0, nxy1, f.z);
            }

            float Fbm3(float3 p)
            {
                float v = 0;
                float a = 0.5;
                for (int i = 0; i < 4; i++)
                {
                    v += a * Noise3(p);
                    p *= 2.03;
                    a *= 0.5;
                }
                return v;
            }

            Varyings vert(Attributes IN)
            {
                Varyings OUT;
                VertexPositionInputs vpi = GetVertexPositionInputs(IN.positionOS.xyz);
                OUT.positionHCS = vpi.positionCS;
                OUT.positionWS  = vpi.positionWS;
                OUT.normalWS    = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv          = TRANSFORM_TEX(IN.uv, _BaseMap);
                OUT.positionOS  = IN.positionOS.xyz;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_Target
            {
                float n = Fbm3(IN.positionOS * _DissolveScale);
                float threshold = _DissolveAmount;
                float diff = n - threshold;
                clip(diff);

                float3 N = normalize(IN.normalWS);
                float3 V = normalize(GetWorldSpaceViewDir(IN.positionWS));

                float3 albedo = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, IN.uv).rgb * _BaseColor.rgb;

                Light light = GetMainLight();
                float NdotL = saturate(dot(N, light.direction));
                float3 ambient = SampleSH(N);
                float3 lit = albedo * (NdotL * light.color + ambient * 0.7);

                float fres = pow(1.0 - saturate(dot(N, V)), _RimPower);
                float pulse = lerp(1.0 - _PulseStrength, 1.0, sin(_Time.y * _PulseSpeed) * 0.5 + 0.5);
                float3 rim = _RimColor.rgb * fres * _RimIntensity * pulse;

                float edgeMask = 1.0 - smoothstep(0.0, _DissolveEdgeWidth, diff);
                float3 edgeGlow = _DissolveEdgeColor.rgb * edgeMask * 4.5;

                float3 highlight = _HighlightColor.rgb * fres * _HighlightStrength;

                float3 finalCol = lit + rim + edgeGlow + highlight;
                return half4(finalCol, 1);
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }
            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma vertex DepthVert
            #pragma fragment DepthFrag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct DAttributes { float4 positionOS : POSITION; float2 uv : TEXCOORD0; };
            struct DVaryings { float4 positionHCS : SV_POSITION; float3 positionOS : TEXCOORD0; };

            CBUFFER_START(UnityPerMaterial)
                float4 _BaseMap_ST;
                float4 _BaseColor;
                float4 _RimColor;
                float  _RimPower;
                float  _RimIntensity;
                float  _DissolveAmount;
                float  _DissolveEdgeWidth;
                float4 _DissolveEdgeColor;
                float  _DissolveScale;
                float  _PulseSpeed;
                float  _PulseStrength;
                float4 _HighlightColor;
                float  _HighlightStrength;
            CBUFFER_END

            float DHash(float3 p)
            {
                p = frac(p * float3(123.34, 234.56, 345.67));
                p += dot(p, p.yzx + 45.32);
                return frac(p.x * p.y + p.z);
            }
            float DNoise(float3 p)
            {
                float3 i = floor(p); float3 f = frac(p); f = f * f * (3.0 - 2.0 * f);
                float a = lerp(lerp(lerp(DHash(i), DHash(i+float3(1,0,0)), f.x),
                                    lerp(DHash(i+float3(0,1,0)), DHash(i+float3(1,1,0)), f.x), f.y),
                               lerp(lerp(DHash(i+float3(0,0,1)), DHash(i+float3(1,0,1)), f.x),
                                    lerp(DHash(i+float3(0,1,1)), DHash(i+float3(1,1,1)), f.x), f.y), f.z);
                return a;
            }
            float DFbm(float3 p) { float v = 0; float a = 0.5; for (int i = 0; i < 4; i++) { v += a * DNoise(p); p *= 2.03; a *= 0.5; } return v; }

            DVaryings DepthVert(DAttributes IN)
            {
                DVaryings o;
                o.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                o.positionOS = IN.positionOS.xyz;
                return o;
            }

            half DepthFrag(DVaryings IN) : SV_Target
            {
                float n = DFbm(IN.positionOS * _DissolveScale);
                clip(n - _DissolveAmount);
                return 0;
            }
            ENDHLSL
        }
    }
    FallBack Off
}
